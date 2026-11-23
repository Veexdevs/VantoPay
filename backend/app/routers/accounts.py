"""Account endpoints: balance, statement, limits, block/close."""
from __future__ import annotations

from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from sqlalchemy.orm import Session

from ..db import get_db
from ..models import Account, LedgerEntry, Transaction
from ..schemas import (
    AccountOut,
    BalanceOut,
    MessageResponse,
    StatementEntryOut,
    TransactionOut,
)
from ..security import get_current_principal, Principal, record_audit
from ..services import accounts as accounts_service
from ..services.ledger import get_balance
from ..services.transactions import history

router = APIRouter(prefix="/accounts", tags=["accounts"])


def _get_own_account(db: Session, principal: Principal) -> Account:
    return accounts_service.get_account_for_user(db, principal.user_id)


@router.get("", response_model=AccountOut)
def get_account(
    principal: Principal = Depends(get_current_principal),
    db: Session = Depends(get_db),
) -> Account:
    return _get_own_account(db, principal)


@router.get("/balance", response_model=BalanceOut)
def get_balance_endpoint(
    principal: Principal = Depends(get_current_principal),
    db: Session = Depends(get_db),
) -> BalanceOut:
    account = _get_own_account(db, principal)
    balance = get_balance(db, account.id)
    return BalanceOut(
        account_id=account.id, balance=float(balance), currency=account.currency
    )


@router.get("/statement", response_model=list[StatementEntryOut])
def statement(
    limit: int = Query(default=100, ge=1, le=500),
    principal: Principal = Depends(get_current_principal),
    db: Session = Depends(get_db),
) -> list[LedgerEntry]:
    account = _get_own_account(db, principal)
    return (
        db.query(LedgerEntry)
        .filter(LedgerEntry.account_id == account.id)
        .order_by(LedgerEntry.created_at.desc(), LedgerEntry.id.desc())
        .limit(limit)
        .all()
    )


@router.get("/transactions", response_model=list[TransactionOut])
def transactions(
    limit: int = Query(default=50, ge=1, le=200),
    principal: Principal = Depends(get_current_principal),
    db: Session = Depends(get_db),
) -> list[Transaction]:
    account = _get_own_account(db, principal)
    return history(db, account.id, limit=limit)


@router.patch("/limits", response_model=AccountOut)
def update_limits(
    transaction_limit: Decimal,
    daily_limit: Decimal,
    principal: Principal = Depends(get_current_principal),
    db: Session = Depends(get_db),
) -> Account:
    if transaction_limit < 0 or daily_limit < 0:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Os limites não podem ser negativos.",
        )
    account = _get_own_account(db, principal)
    account.transaction_limit = float(transaction_limit)
    account.daily_limit = float(daily_limit)
    db.commit()
    db.refresh(account)
    record_audit(
        db, actor_user_id=principal.user_id, actor_role=principal.role,
        action="limits_updated", target=account.id,
    )
    return account


@router.post("/block", response_model=MessageResponse)
def block(
    request: Request,
    principal: Principal = Depends(get_current_principal),
    db: Session = Depends(get_db),
) -> MessageResponse:
    account = _get_own_account(db, principal)
    accounts_service.block_account(
        db, account=account,
        actor_user_id=principal.user_id, actor_role=principal.role,
    )
    return MessageResponse(detail="Conta bloqueada com sucesso.")


@router.post("/close", response_model=MessageResponse)
def close(
    request: Request,
    principal: Principal = Depends(get_current_principal),
    db: Session = Depends(get_db),
) -> MessageResponse:
    account = _get_own_account(db, principal)
    accounts_service.close_account(
        db, account=account,
        actor_user_id=principal.user_id, actor_role=principal.role,
    )
    return MessageResponse(detail="Conta encerrada com sucesso.")
