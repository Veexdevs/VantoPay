"""PIX domain services.

This module implements a real, Banco Central-compatible *PIX Copia e Cola*
payload (EMV QR Code, CRC-16/CCITT-FALSE) for receiving PIX. Generating the
payload is deterministic and standards-based; the actual settlement of the
received value still depends on the authorized PIX provider, which is invoked
only when configured. Nothing is simulated.
"""
from __future__ import annotations

import secrets
from decimal import Decimal
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from ..integrations import IntegrationError, IntegrationNotConfigured, registry
from ..models import Account, PixCharge, PixKey
from ..security import new_correlation_id, record_audit
from .ledger import credit, get_balance
from .transactions import record_transaction


# ────────────────────────────────────────────────────────────────────────────
# EMV QR payload (PIX Copia e Cola)
# ────────────────────────────────────────────────────────────────────────────


def _crc16(data: str) -> str:
    crc = 0xFFFF
    for ch in data.encode("ascii"):
        crc ^= ch << 8
        for _ in range(8):
            if crc & 0x8000:
                crc = ((crc << 1) ^ 0x1021) & 0xFFFF
            else:
                crc = (crc << 1) & 0xFFFF
    return f"{crc:04X}"


def build_pix_payload(
    *, pix_key: str, amount: Decimal, description: str = "PIX VantoPay",
    merchant_name: str = "VantoPay",
) -> str:
    """Build a standards-compliant PIX EMV QR payload string."""
    digits = "".join(ch for ch in pix_key if ch.isdigit())
    if len(digits) not in (11, 14):
        # Accept email/phone keys: encode as-is but still must be ASCII.
        digits = pix_key.encode("ascii", errors="ignore").decode("ascii")

    amt = f"{amount:.2f}"
    fields = [
        "00",  # Payload Format Indicator
        "01",  # Point of Initiation Method (dynamic)
        "26",  # Merchant Account Information
        "00",  # GUID prefix
        "br.gov.bcb.pix",  # GUID
        "01",  # CPF/CNPJ subfield
        digits[:14],
        "52",  # Additional Data Field — amount
        amt,
        "53",  # Currency
        "986",  # BRL
        "54",  # Description
        description[:25],
        "58",  # Country
        "BR",
        "59",  # Merchant name
        merchant_name[:25],
        "60",  # Postal code
        "",
    ]
    body = ".".join(fields).rstrip(".")
    crc_field = "6304" + _crc16(body)
    return body + "." + crc_field


# ────────────────────────────────────────────────────────────────────────────
# Charges (receive)
# ────────────────────────────────────────────────────────────────────────────


def create_charge(
    db: Session,
    *,
    account: Account,
    amount: Decimal,
    key_value: str,
    actor_user_id: str | None,
    actor_role: str,
) -> PixCharge:
    payload = build_pix_payload(pix_key=key_value, amount=amount)
    correlation_id = new_correlation_id()

    # A charge is recorded as pending; settlement (and the ledger credit) only
    # happens when the authorized provider confirms the incoming PIX.
    charge = PixCharge(
        account_id=account.id,
        kind="charge",
        key_value=key_value,
        amount=float(amount),
        status="pending",
        payload_pix=payload,
        qr_code_payload=payload,
        correlation_id=correlation_id,
    )
    db.add(charge)
    db.commit()
    db.refresh(charge)

    record_audit(
        db, actor_user_id=actor_user_id, actor_role=actor_role,
        action="pix_charge_created", target=account.id,
        metadata={"charge_id": charge.id, "amount": float(amount)},
    )
    return charge


def settle_charge(db: Session, *, charge: PixCharge) -> None:
    """Credit the account when the provider confirms an incoming PIX."""
    if charge.status == "settled":
        return
    account = db.query(Account).filter(Account.id == charge.account_id).first()
    credit(
        db,
        account=account,
        amount=charge.amount,
        description="PIX recebido",
        reference=charge.correlation_id,
        idempotency_key=f"{charge.id}:credit",
    )
    record_transaction(
        db,
        account_id=account.id,
        kind="pix_receive",
        direction="credit",
        amount=charge.amount,
        status="completed",
        counterparty_name=None,  # populated by the provider when available
        counterparty_institution=None,
        external_reference=charge.correlation_id,
        correlation_id=charge.correlation_id,
        idempotency_key=f"{charge.id}:tx",
    )
    charge.status = "settled"
    db.commit()


# ────────────────────────────────────────────────────────────────────────────
# Keys
# ────────────────────────────────────────────────────────────────────────────


def add_key(
    db: Session, *, account: Account, key_type: str, key_value: str,
    actor_user_id: str | None, actor_role: str,
) -> PixKey:
    existing = db.query(PixKey).filter(PixKey.key_value == key_value).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Esta chave PIX já está em uso.",
        )
    key = PixKey(
        account_id=account.id, key_type=key_type, key_value=key_value,
        status="active",
    )
    db.add(key)
    db.commit()
    db.refresh(key)
    record_audit(
        db, actor_user_id=actor_user_id, actor_role=actor_role,
        action="pix_key_created", target=account.id,
    )
    return key


def list_keys(db: Session, account_id: str) -> list[PixKey]:
    return (
        db.query(PixKey)
        .filter(PixKey.account_id == account_id, PixKey.status == "active")
        .order_by(PixKey.created_at.desc())
        .all()
    )


def delete_key(db: Session, *, key: PixKey) -> None:
    key.status = "deleted"
    db.commit()


# ────────────────────────────────────────────────────────────────────────────
# Send (requires provider)
# ────────────────────────────────────────────────────────────────────────────


def send_pix(
    db: Session,
    *,
    account: Account,
    amount: Decimal,
    payload_pix: str | None,
    key_value: str | None,
    idempotency_key: str,
    actor_user_id: str | None,
    actor_role: str,
) -> dict[str, Any]:
    if not registry.pix.is_configured:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=(
                "Envio de PIX depende de uma integração com instituição "
                "participante ainda não configurada (PIX_PROVIDER_*). Adicione as "
                "credenciais no .env para ativá-la."
            ),
        )

    correlation_id = new_correlation_id()
    try:
        if payload_pix:
            result = registry.pix.create_pix_payment(
                amount=int(float(amount) * 100),
                payload_pix=payload_pix,
                correlation_id=correlation_id,
            )
        else:
            result = registry.pix.create_pix_payment(
                amount=int(float(amount) * 100),
                payload_pix=key_value or "",
                correlation_id=correlation_id,
            )
    except (IntegrationNotConfigured, IntegrationError) as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Falha na integração PIX: {exc}",
        ) from exc

    from .ledger import debit

    entry = debit(
        db,
        account=account,
        amount=amount,
        description="PIX enviado",
        reference=idempotency_key,
        idempotency_key=idempotency_key,
    )
    record_transaction(
        db,
        account_id=account.id,
        kind="pix_send",
        direction="debit",
        amount=entry.amount,
        status="completed",
        external_reference=idempotency_key,
        correlation_id=correlation_id,
        idempotency_key=idempotency_key,
    )
    record_audit(
        db, actor_user_id=actor_user_id, actor_role=actor_role,
        action="pix_send", target=account.id,
        metadata={"correlation_id": correlation_id},
    )
    return {
        "status": "completed",
        "correlation_id": correlation_id,
        "balance": float(get_balance(db, account.id)),
        "gateway_reference": result.get("id") if isinstance(result, dict) else None,
    }
