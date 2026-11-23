"""Transaction recording and history queries."""
from __future__ import annotations

from typing import Any

from sqlalchemy.orm import Session

from ..models import Transaction
from ..security import mask_document


def record_transaction(
    db: Session,
    *,
    account_id: str,
    kind: str,
    direction: str,
    amount: float,
    status: str = "completed",
    counterparty_name: str | None = None,
    counterparty_institution: str | None = None,
    counterparty_document: str | None = None,
    external_reference: str | None = None,
    correlation_id: str | None = None,
    idempotency_key: str | None = None,
    metadata: dict[str, Any] | None = None,
) -> Transaction:
    tx = Transaction(
        account_id=account_id,
        kind=kind,
        direction=direction,
        amount=float(amount),
        currency="BRL",
        status=status,
        counterparty_name=counterparty_name,
        counterparty_institution=counterparty_institution,
        counterparty_document_masked=mask_document(counterparty_document),
        external_reference=external_reference,
        correlation_id=correlation_id,
        idempotency_key=idempotency_key,
        meta=str(metadata) if metadata else None,
    )
    db.add(tx)
    db.commit()
    db.refresh(tx)
    return tx


def history(db: Session, account_id: str, limit: int = 50) -> list[Transaction]:
    return (
        db.query(Transaction)
        .filter(Transaction.account_id == account_id)
        .order_by(Transaction.created_at.desc())
        .limit(limit)
        .all()
    )
