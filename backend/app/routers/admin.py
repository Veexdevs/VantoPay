"""Administrative panel endpoints (admin role required).

Administrators can inspect and manage users, accounts, transactions and
suspicious activity. Balance changes are never done "directly": they go through
the auditable ledger (``/adjustment``), which appends an idempotent entry and
writes an audit log.
"""
from __future__ import annotations

from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from ..db import get_db
from ..models import Account, AuditLog, SuspiciousEvent, Transaction
from ..schemas import (
    AccountOut,
    AuditLogOut,
    MessageResponse,
    SuspiciousEventOut,
    TransactionOut,
)
from ..security import get_current_principal, Principal, record_audit, require_admin
from ..services.ledger import credit, debit, get_balance

router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/accounts", response_model=list[AccountOut])
def list_accounts(
    limit: int = Query(default=50, ge=1, le=200),
    _: Principal = Depends(require_admin),
    db: Session = Depends(get_db),
) -> list[Account]:
    return db.query(Account).order_by(Account.created_at.desc()).limit(limit).all()


@router.get("/accounts/{account_id}", response_model=AccountOut)
def get_account(
    account_id: str,
    _: Principal = Depends(require_admin),
    db: Session = Depends(get_db),
) -> Account:
    account = db.query(Account).filter(Account.id == account_id).first()
    if account is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Conta não encontrada."
        )
    return account


@router.post("/accounts/{account_id}/block", response_model=MessageResponse)
def block_account(
    account_id: str,
    principal: Principal = Depends(require_admin),
    db: Session = Depends(get_db),
) -> MessageResponse:
    account = db.query(Account).filter(Account.id == account_id).first()
    if account is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,
                            detail="Conta não encontrada.")
    account.status = "blocked"
    db.commit()
    record_audit(
        db, actor_user_id=principal.user_id, actor_role=principal.role,
        action="admin_block_account", target=account_id,
    )
    return MessageResponse(detail="Conta bloqueada.")


@router.post("/accounts/{account_id}/unblock", response_model=MessageResponse)
def unblock_account(
    account_id: str,
    principal: Principal = Depends(require_admin),
    db: Session = Depends(get_db),
) -> MessageResponse:
    account = db.query(Account).filter(Account.id == account_id).first()
    if account is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,
                            detail="Conta não encontrada.")
    account.status = "active"
    db.commit()
    record_audit(
        db, actor_user_id=principal.user_id, actor_role=principal.role,
        action="admin_unblock_account", target=account_id,
    )
    return MessageResponse(detail="Conta liberada.")


@router.post("/accounts/{account_id}/adjustment", response_model=MessageResponse)
def adjustment(
    account_id: str,
    direction: str,
    amount: Decimal,
    reason: str,
    idempotency_key: str,
    principal: Principal = Depends(require_admin),
    db: Session = Depends(get_db),
) -> MessageResponse:
    """Auditable balance adjustment through the ledger (never a direct write)."""
    account = db.query(Account).filter(Account.id == account_id).first()
    if account is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,
                            detail="Conta não encontrada.")
    if direction not in ("credit", "debit"):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,
                            detail="direção inválida.")
    if amount <= 0:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST,
                            detail="O valor deve ser maior que zero.")
    if direction == "credit":
        credit(db, account=account, amount=amount, description=f"Ajuste: {reason}",
               idempotency_key=idempotency_key)
    else:
        debit(db, account=account, amount=amount, description=f"Ajuste: {reason}",
              idempotency_key=idempotency_key)
    record_audit(
        db, actor_user_id=principal.user_id, actor_role=principal.role,
        action="admin_adjustment", target=account_id,
        metadata={"direction": direction, "amount": float(amount), "reason": reason},
    )
    return MessageResponse(detail="Ajuste registrado no ledger.")


@router.get("/transactions", response_model=list[TransactionOut])
def list_transactions(
    limit: int = Query(default=100, ge=1, le=500),
    _: Principal = Depends(require_admin),
    db: Session = Depends(get_db),
) -> list[Transaction]:
    return db.query(Transaction).order_by(Transaction.created_at.desc()).limit(limit).all()


@router.get("/suspicious", response_model=list[SuspiciousEventOut])
def list_suspicious(
    limit: int = Query(default=100, ge=1, le=500),
    _: Principal = Depends(require_admin),
    db: Session = Depends(get_db),
) -> list[SuspiciousEvent]:
    return (
        db.query(SuspiciousEvent)
        .order_by(SuspiciousEvent.created_at.desc())
        .limit(limit)
        .all()
    )


@router.post("/suspicious/{event_id}/resolve", response_model=MessageResponse)
def resolve_suspicious(
    event_id: str,
    principal: Principal = Depends(require_admin),
    db: Session = Depends(get_db),
) -> MessageResponse:
    event = db.query(SuspiciousEvent).filter(SuspiciousEvent.id == event_id).first()
    if event is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND,
                            detail="Evento não encontrado.")
    event.resolved = True
    db.commit()
    record_audit(
        db, actor_user_id=principal.user_id, actor_role=principal.role,
        action="admin_resolve_suspicious", target=event_id,
    )
    return MessageResponse(detail="Evento resolvido.")


@router.get("/audit-logs", response_model=list[AuditLogOut])
def audit_logs(
    limit: int = Query(default=100, ge=1, le=500),
    _: Principal = Depends(require_admin),
    db: Session = Depends(get_db),
) -> list[AuditLog]:
    return db.query(AuditLog).order_by(AuditLog.created_at.desc()).limit(limit).all()
