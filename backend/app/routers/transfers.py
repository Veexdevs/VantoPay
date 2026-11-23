"""Transfer endpoints.

* Internal transfers between VantoPay accounts execute as real, idempotent
  double-entry ledger movements.
* External transfers require a configured payment gateway. When no provider is
  configured the endpoint returns an explicit ``503`` stating that the operation
  depends on an external integration — it never simulates a transfer.
"""
from __future__ import annotations

from decimal import Decimal

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from ..db import get_db
from ..integrations import IntegrationError, IntegrationNotConfigured, registry
from ..models import Account
from ..schemas import (
    MessageResponse,
    TransactionOut,
    TransferInternalRequest,
    TransferResult,
    TransferExternalRequest,
)
from ..security import get_current_principal, Principal, new_correlation_id, record_audit
from ..services import accounts as accounts_service
from ..services.fraud import assess_movement
from ..services.ledger import debit, transfer_internal
from ..services.transactions import record_transaction

router = APIRouter(prefix="/transfers", tags=["transfers"])


def _own_account(db: Session, principal: Principal) -> Account:
    return accounts_service.get_account_for_user(db, principal.user_id)


@router.post("/internal", response_model=TransferResult)
def internal_transfer(
    payload: TransferInternalRequest,
    principal: Principal = Depends(get_current_principal),
    db: Session = Depends(get_db),
) -> TransferResult:
    source = _own_account(db, principal)
    destination = (
        db.query(Account)
        .filter(Account.account_number == payload.destination_account_number)
        .first()
    )
    if destination is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conta de destino VantoPay não encontrada.",
        )
    if destination.id == source.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Não é possível transferir para a própria conta.",
        )

    amount = float(payload.amount)

    # Fraud / suspicious-activity screening.
    risk = assess_movement(
        db, account_id=source.id, amount=amount,
        unusual_recipient=destination.id != source.id,
    )
    if risk.blocked:
        raise HTTPException(
            status_code=status.HTTP_423_LOCKED,
            detail="Operação bloqueada por atividade suspeita. Contate o suporte.",
        )

    # Idempotency + real ledger movement.
    out_entry, in_entry = transfer_internal(
        db,
        source=source,
        destination=destination,
        amount=payload.amount,
        reference=payload.reference,
        idempotency_key=payload.idempotency_key,
        actor_user_id=principal.user_id,
        actor_role=principal.role,
    )

    tx = record_transaction(
        db,
        account_id=source.id,
        kind="transfer_internal",
        direction="debit",
        amount=out_entry.amount,
        status="completed",
        counterparty_name=destination.holder_name,
        counterparty_institution="VantoPay",
        external_reference=payload.reference,
        idempotency_key=payload.idempotency_key,
        metadata={"destination_account": destination.account_number},
    )

    from ..services.ledger import get_balance

    return TransferResult(
        status="completed",
        reference=payload.reference,
        idempotency_key=payload.idempotency_key,
        transaction=TransactionOut.model_validate(tx),
        source_balance=float(get_balance(db, source.id)),
    )


@router.post("/external", response_model=MessageResponse)
def external_transfer(
    payload: TransferExternalRequest,
    principal: Principal = Depends(get_current_principal),
    db: Session = Depends(get_db),
) -> MessageResponse:
    """External transfer — requires a configured payment gateway.

    No gateway credentials are present, so the request is rejected honestly
    rather than simulated. Once HYPERSWITCH / PIX provider credentials are set,
    the integration is called and the ledger is debited only on success.
    """
    source = _own_account(db, principal)

    if not (registry.hyperswitch.is_configured or registry.pix.is_configured):
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=(
                "Transferência externa depende de uma integração de pagamento "
                "ainda não configurada (Hyperswitch / provedor PIX). Adicione as "
                "credenciais no .env para ativá-la."
            ),
        )

    correlation_id = new_correlation_id()
    try:
        if registry.pix.is_configured:
            result = registry.pix.create_pix_payment(
                amount=int(float(payload.amount) * 100),
                payload_pix=payload.destination_document,
                correlation_id=correlation_id,
            )
        else:
            result = registry.hyperswitch.create_payment(
                amount=int(float(payload.amount) * 100),
                currency="BRL",
                reference=payload.reference or correlation_id,
            )
    except (IntegrationNotConfigured, IntegrationError) as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Falha na integração de pagamento: {exc}",
        ) from exc

    # Only debit the ledger once the gateway accepted the payment.
    entry = debit(
        db,
        account=source,
        amount=payload.amount,
        description="Transferência externa (saída)",
        reference=payload.reference,
        idempotency_key=payload.idempotency_key,
    )
    record_transaction(
        db,
        account_id=source.id,
        kind="transfer_external",
        direction="debit",
        amount=entry.amount,
        status="completed",
        counterparty_name=payload.destination_name,
        counterparty_institution=payload.destination_bank_code,
        counterparty_document=payload.destination_document,
        external_reference=payload.reference,
        correlation_id=correlation_id,
        idempotency_key=payload.idempotency_key,
        metadata={"gateway": result.get("id") if isinstance(result, dict) else None},
    )
    record_audit(
        db, actor_user_id=principal.user_id, actor_role=principal.role,
        action="transfer_external", target=source.id,
    )
    return MessageResponse(detail="Transferência externa registrada.")
