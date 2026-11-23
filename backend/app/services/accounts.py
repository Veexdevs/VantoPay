"""Account lifecycle service."""
from __future__ import annotations

import secrets
from decimal import Decimal

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from ..models import Account
from ..security import mask_document, record_audit
from .ledger import get_balance


def _generate_account_number() -> str:
    # VantoPay account numbers are 8-digit numeric strings, unique.
    return "".join(secrets.choice("0123456789") for _ in range(8))


def open_account(
    db: Session,
    *,
    user_id: str,
    holder_name: str,
    document: str,
    is_admin: bool = False,
    transaction_limit: Decimal = Decimal("0"),
    daily_limit: Decimal = Decimal("0"),
    actor_user_id: str | None = None,
    actor_role: str = "user",
) -> Account:
    if db.query(Account).filter(Account.user_id == user_id).first():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Usuário já possui uma conta VantoPay.",
        )
    number = _generate_account_number()
    while db.query(Account).filter(Account.account_number == number).first():
        number = _generate_account_number()

    account = Account(
        user_id=user_id,
        account_number=number,
        holder_name=holder_name.strip(),
        document_masked=mask_document(document) or "****",
        currency="BRL",
        status="active",
        is_admin=is_admin,
        transaction_limit=float(transaction_limit),
        daily_limit=float(daily_limit),
    )
    db.add(account)
    db.commit()
    db.refresh(account)

    record_audit(
        db, actor_user_id=actor_user_id, actor_role=actor_role,
        action="account_opened", target=account.id,
    )
    return account


def get_account_for_user(db: Session, user_id: str) -> Account:
    account = db.query(Account).filter(Account.user_id == user_id).first()
    if account is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conta não encontrada.",
        )
    return account


def account_balance(db: Session, account: Account) -> Decimal:
    return get_balance(db, account.id)


def block_account(
    db: Session, *, account: Account, actor_user_id: str | None, actor_role: str
) -> Account:
    if account.status == "closed":
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Conta já está encerrada.",
        )
    account.status = "blocked"
    db.commit()
    record_audit(
        db, actor_user_id=actor_user_id, actor_role=actor_role,
        action="account_blocked", target=account.id,
    )
    return account


def close_account(
    db: Session, *, account: Account, actor_user_id: str | None, actor_role: str
) -> Account:
    account.status = "closed"
    db.commit()
    record_audit(
        db, actor_user_id=actor_user_id, actor_role=actor_role,
        action="account_closed", target=account.id,
    )
    return account
