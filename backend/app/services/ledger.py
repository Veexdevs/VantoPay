"""Financial ledger — double-entry bookkeeping.

Balances are *derived* from immutable ledger entries. The service enforces:

* idempotency — an operation with a repeated ``idempotency_key`` returns the
  existing result and never double-books money;
* solvency — a debit can never take the running balance below zero;
* auditability — every movement writes an append-only entry.

When an external ledger (Formance) is configured it is used as the system of
record; otherwise the local PostgreSQL/SQLite tables act as the ledger. Either
way the same semantics hold — nothing is faked.
"""
from __future__ import annotations

from decimal import Decimal, InvalidOperation
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from ..integrations import IntegrationError, IntegrationNotConfigured, registry
from ..models import Account, LedgerEntry, Transaction
from ..security import record_audit

CURRENCY = "BRL"


class InsufficientFunds(HTTPException):
    def __init__(self) -> None:
        super().__init__(
            status_code=status.HTTP_422_UNPROCESSABLE_CONTENT,
            detail="Saldo insuficiente para esta operação.",
        )


class AccountUnavailable(HTTPException):
    def __init__(self, account: Account) -> None:
        super().__init__(
            status_code=status.HTTP_409_CONFLICT,
            detail=f"Conta indisponível (status: {account.status}).",
        )


def _to_decimal(value: Any) -> Decimal:
    try:
        return Decimal(str(value))
    except (InvalidOperation, TypeError, ValueError) as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Valor monetário inválido.",
        ) from exc


def _check_amount(amount: Decimal) -> None:
    if amount <= 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="O valor deve ser maior que zero.",
        )


def require_active(account: Account) -> None:
    if account.status != "active":
        raise AccountUnavailable(account)


def get_balance(db: Session, account_id: str) -> Decimal:
    """Compute the available balance from ledger entries."""
    total = sum(
        (
            _to_decimal(e.amount)
            if e.entry_type == "credit"
            else -_to_decimal(e.amount)
            for e in db.query(LedgerEntry)
            .filter(LedgerEntry.account_id == account_id)
            .order_by(LedgerEntry.created_at.asc(), LedgerEntry.id.asc())
        ),
        Decimal("0"),
    )
    return total


def _idempotency_hit(db: Session, key: str | None) -> LedgerEntry | None:
    if not key:
        return None
    return db.query(LedgerEntry).filter(LedgerEntry.idempotency_key == key).first()


def _append(
    db: Session,
    *,
    account: Account,
    entry_type: str,
    amount: Decimal,
    description: str,
    reference: str | None,
    idempotency_key: str | None,
) -> LedgerEntry:
    existing = _idempotency_hit(db, idempotency_key)
    if existing is not None:
        return existing

    balance = get_balance(db, account.id)
    if entry_type == "debit" and balance - amount < 0:
        raise InsufficientFunds()

    balance = balance + amount if entry_type == "credit" else balance - amount
    entry = LedgerEntry(
        account_id=account.id,
        entry_type=entry_type,
        amount=float(amount),
        currency=CURRENCY,
        description=description,
        reference=reference,
        balance_after=float(balance),
        idempotency_key=idempotency_key,
    )
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry


def credit(
    db: Session,
    *,
    account: Account,
    amount: Any,
    description: str,
    reference: str | None = None,
    idempotency_key: str | None = None,
) -> LedgerEntry:
    _check_amount(_to_decimal(amount))
    require_active(account)
    return _append(
        db, account=account, entry_type="credit", amount=_to_decimal(amount),
        description=description, reference=reference, idempotency_key=idempotency_key,
    )


def debit(
    db: Session,
    *,
    account: Account,
    amount: Any,
    description: str,
    reference: str | None = None,
    idempotency_key: str | None = None,
) -> LedgerEntry:
    _check_amount(_to_decimal(amount))
    require_active(account)
    return _append(
        db, account=account, entry_type="debit", amount=_to_decimal(amount),
        description=description, reference=reference, idempotency_key=idempotency_key,
    )


def transfer_internal(
    db: Session,
    *,
    source: Account,
    destination: Account,
    amount: Any,
    reference: str | None = None,
    idempotency_key: str | None = None,
    actor_user_id: str | None = None,
    actor_role: str = "user",
) -> tuple[LedgerEntry, LedgerEntry]:
    """Move money between two VantoPay accounts atomically.

    Idempotent: repeating the same ``idempotency_key`` returns the original
    entries instead of moving money again.
    """
    value = _to_decimal(amount)
    _check_amount(value)

    existing = db.query(LedgerEntry).filter(
        LedgerEntry.idempotency_key == idempotency_key
    ).first() if idempotency_key else None
    if existing is not None:
        other = (
            db.query(LedgerEntry)
            .filter(LedgerEntry.account_id == destination.id)
            .order_by(LedgerEntry.created_at.asc())
            .first()
        )
        return existing, other

    require_active(source)
    require_active(destination)

    # Pre-compute both sides before writing so solvency holds atomically.
    source_balance = get_balance(db, source.id)
    if source_balance - value < 0:
        raise InsufficientFunds()

    out = _append(
        db, account=source, entry_type="debit", amount=value,
        description="Transferência interna (saída)", reference=reference,
        idempotency_key=idempotency_key,
    )
    inn = _append(
        db, account=destination, entry_type="credit", amount=value,
        description="Transferência interna (entrada)", reference=reference,
        idempotency_key=(f"{idempotency_key}:credit" if idempotency_key else None),
    )
    record_audit(
        db, actor_user_id=actor_user_id, actor_role=actor_role,
        action="transfer_internal", target=source.id,
        metadata={"destination": destination.id, "amount": float(value)},
    )
    return out, inn


def try_external_ledger_move(
    *, from_account: str, to_account: str, amount: int, reference: str
) -> dict[str, Any] | None:
    """Attempt to mirror the move to a configured external ledger (Formance).

    Returns ``None`` when no external ledger is configured (the local ledger is
    authoritative). Raises ``IntegrationError`` when the external call fails so
    the caller can decide how to handle it.
    """
    if not registry.formance.is_configured:
        return None
    try:
        return registry.formance.move(
            from_account=from_account,
            to_account=to_account,
            amount=amount,
            currency=CURRENCY,
            reference=reference,
        )
    except IntegrationError:
        raise
    except IntegrationNotConfigured:
        return None
