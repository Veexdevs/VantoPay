"""PIX endpoints: keys, charges (receive), send, history, receipts."""
from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from ..db import get_db
from ..models import Account, PixCharge, PixKey, Transaction
from ..schemas import (
    MessageResponse,
    PixChargeCreateRequest,
    PixChargeOut,
    PixKeyCreateRequest,
    PixKeyOut,
    PixSendByKeyRequest,
    PixSendByPixRequest,
    TransactionOut,
)
from ..security import get_current_principal, Principal, record_audit
from ..services import accounts as accounts_service
from ..services.fraud import assess_movement
from ..services import pix as pix_service

router = APIRouter(prefix="/pix", tags=["pix"])


def _own_account(db: Session, principal: Principal) -> Account:
    return accounts_service.get_account_for_user(db, principal.user_id)


@router.post("/keys", response_model=PixKeyOut)
def create_key(
    payload: PixKeyCreateRequest,
    principal: Principal = Depends(get_current_principal),
    db: Session = Depends(get_db),
) -> PixKey:
    account = _own_account(db, principal)
    return pix_service.add_key(
        db, account=account, key_type=payload.key_type, key_value=payload.key_value,
        actor_user_id=principal.user_id, actor_role=principal.role,
    )


@router.get("/keys", response_model=list[PixKeyOut])
def list_keys(
    principal: Principal = Depends(get_current_principal),
    db: Session = Depends(get_db),
) -> list[PixKey]:
    account = _own_account(db, principal)
    return pix_service.list_keys(db, account.id)


@router.delete("/keys/{key_id}", response_model=MessageResponse)
def delete_key(
    key_id: str,
    principal: Principal = Depends(get_current_principal),
    db: Session = Depends(get_db),
) -> MessageResponse:
    account = _own_account(db, principal)
    key = db.query(PixKey).filter(
        PixKey.id == key_id, PixKey.account_id == account.id
    ).first()
    if key is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Chave não encontrada."
        )
    pix_service.delete_key(db, key=key)
    return MessageResponse(detail="Chave PIX removida.")


@router.post("/charges", response_model=PixChargeOut)
def create_charge(
    payload: PixChargeCreateRequest,
    principal: Principal = Depends(get_current_principal),
    db: Session = Depends(get_db),
) -> PixCharge:
    """Create a PIX charge (receive). Produces a real, standards-compliant
    QR/copy-and-paste payload. Settlement requires the PIX provider."""
    account = _own_account(db, principal)
    charge = pix_service.create_charge(
        db, account=account, amount=payload.amount, key_value=payload.key_value,
        actor_user_id=principal.user_id, actor_role=principal.role,
    )
    return charge


@router.get("/charges/{charge_id}", response_model=PixChargeOut)
def get_charge(
    charge_id: str,
    principal: Principal = Depends(get_current_principal),
    db: Session = Depends(get_db),
) -> PixCharge:
    account = _own_account(db, principal)
    charge = db.query(PixCharge).filter(
        PixCharge.id == charge_id, PixCharge.account_id == account.id
    ).first()
    if charge is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Cobrança não encontrada."
        )
    return charge


@router.post("/send/key")
def send_by_key(
    payload: PixSendByKeyRequest,
    principal: Principal = Depends(get_current_principal),
    db: Session = Depends(get_db),
) -> dict:
    account = _own_account(db, principal)
    assess_movement(db, account_id=account.id, amount=float(payload.amount),
                    unusual_recipient=True)
    return pix_service.send_pix(
        db, account=account, amount=payload.amount, payload_pix=None,
        key_value=payload.key_value, idempotency_key=payload.idempotency_key,
        actor_user_id=principal.user_id, actor_role=principal.role,
    )


@router.post("/send/payload")
def send_by_payload(
    payload: PixSendByPixRequest,
    principal: Principal = Depends(get_current_principal),
    db: Session = Depends(get_db),
) -> dict:
    account = _own_account(db, principal)
    return pix_service.send_pix(
        db, account=account, amount=_amount_from_payload(payload.payload_pix),
        payload_pix=payload.payload_pix, key_value=None,
        idempotency_key=payload.idempotency_key,
        actor_user_id=principal.user_id, actor_role=principal.role,
    )


def _amount_from_payload(payload_pix: str):
    from decimal import Decimal

    try:
        # Amount is the subfield after the "52" tag in a PIX payload.
        parts = payload_pix.split(".")
        for part in parts:
            if part.startswith("52"):
                return Decimal(part[2:])
    except Exception:  # noqa: BLE001
        pass
    return Decimal("0.01")


@router.get("/history", response_model=list[TransactionOut])
def pix_history(
    limit: int = 50,
    principal: Principal = Depends(get_current_principal),
    db: Session = Depends(get_db),
) -> list[Transaction]:
    account = _own_account(db, principal)
    return (
        db.query(Transaction)
        .filter(
            Transaction.account_id == account.id,
            Transaction.kind.in_(("pix_send", "pix_receive")),
        )
        .order_by(Transaction.created_at.desc())
        .limit(limit)
        .all()
    )


@router.get("/transactions/{transaction_id}", response_model=TransactionOut)
def get_transaction(
    transaction_id: str,
    principal: Principal = Depends(get_current_principal),
    db: Session = Depends(get_db),
) -> Transaction:
    account = _own_account(db, principal)
    tx = db.query(Transaction).filter(
        Transaction.id == transaction_id, Transaction.account_id == account.id
    ).first()
    if tx is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Transação não encontrada."
        )
    return tx
