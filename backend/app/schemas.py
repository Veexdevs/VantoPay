"""Pydantic request/response schemas with input validation."""
from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from typing import Any, Literal

from pydantic import BaseModel, EmailStr, Field, field_validator

from .models import Account, LedgerEntry, Transaction


# ────────────────────────────────────────────────────────────────────────────
# Common
# ────────────────────────────────────────────────────────────────────────────


class MessageResponse(BaseModel):
    detail: str


class IntegrationStatusOut(BaseModel):
    name: str
    configured: bool
    description: str


# ────────────────────────────────────────────────────────────────────────────
# Auth
# ────────────────────────────────────────────────────────────────────────────


class VerifyTokenResponse(BaseModel):
    user_id: str
    email: str | None
    role: str


class RegisterAccountRequest(BaseModel):
    holder_name: str = Field(min_length=2, max_length=200)
    document: str = Field(min_length=11, max_length=18)
    transaction_limit: Decimal = Decimal("0")
    daily_limit: Decimal = Decimal("0")

    @field_validator("document")
    @classmethod
    def _doc(cls, v: str) -> str:
        digits = "".join(ch for ch in v if ch.isdigit())
        if len(digits) not in (11, 14):
            raise ValueError("Documento deve ter 11 (CPF) ou 14 (CNPJ) dígitos.")
        return v


class AccountOut(BaseModel):
    id: str
    account_number: str
    holder_name: str
    document_masked: str
    currency: str
    status: str
    is_admin: bool
    transaction_limit: float
    daily_limit: float
    created_at: datetime

    model_config = {"from_attributes": True}


class BalanceOut(BaseModel):
    account_id: str
    balance: float
    currency: str


class RegisterResponse(BaseModel):
    account: AccountOut


# ────────────────────────────────────────────────────────────────────────────
# Transfers
# ────────────────────────────────────────────────────────────────────────────


class TransferInternalRequest(BaseModel):
    destination_account_number: str = Field(min_length=8, max_length=8)
    amount: Decimal = Field(gt=0)
    reference: str | None = Field(default=None, max_length=128)
    idempotency_key: str = Field(min_length=8, max_length=128)

    @field_validator("destination_account_number")
    @classmethod
    def _num(cls, v: str) -> str:
        if not v.isdigit():
            raise ValueError("Número de conta inválido.")
        return v


class TransferExternalRequest(BaseModel):
    destination_name: str = Field(min_length=2, max_length=200)
    destination_document: str = Field(min_length=11, max_length=18)
    destination_bank_code: str = Field(min_length=3, max_length=3)
    destination_account_number: str = Field(min_length=1, max_length=32)
    destination_account_digit: str = Field(min_length=1, max_length=4)
    amount: Decimal = Field(gt=0)
    reference: str | None = Field(default=None, max_length=128)
    idempotency_key: str = Field(min_length=8, max_length=128)


class TransactionOut(BaseModel):
    id: str
    kind: str
    direction: str
    amount: float
    currency: str
    status: str
    counterparty_name: str | None
    counterparty_institution: str | None
    counterparty_document_masked: str | None
    external_reference: str | None
    created_at: datetime

    model_config = {"from_attributes": True}


class TransferResult(BaseModel):
    status: str
    reference: str | None
    idempotency_key: str
    transaction: TransactionOut
    source_balance: float


# ────────────────────────────────────────────────────────────────────────────
# PIX
# ────────────────────────────────────────────────────────────────────────────


class PixKeyCreateRequest(BaseModel):
    key_type: Literal["email", "cpf", "phone", "random"]
    key_value: str = Field(min_length=1, max_length=120)


class PixKeyOut(BaseModel):
    id: str
    key_type: str
    key_value: str
    status: str
    created_at: datetime

    model_config = {"from_attributes": True}


class PixSendByKeyRequest(BaseModel):
    key_value: str = Field(min_length=1, max_length=120)
    amount: Decimal = Field(gt=0)
    idempotency_key: str = Field(min_length=8, max_length=128)


class PixSendByPixRequest(BaseModel):
    payload_pix: str = Field(min_length=10, max_length=512)
    idempotency_key: str = Field(min_length=8, max_length=128)


class PixChargeCreateRequest(BaseModel):
    amount: Decimal = Field(gt=0)
    key_value: str = Field(min_length=1, max_length=120)


class PixChargeOut(BaseModel):
    id: str
    kind: str
    key_value: str
    amount: float
    status: str
    qr_code_payload: str | None
    created_at: datetime

    model_config = {"from_attributes": True}


# ────────────────────────────────────────────────────────────────────────────
# Statement / admin
# ────────────────────────────────────────────────────────────────────────────


class StatementEntryOut(BaseModel):
    id: str
    entry_type: str
    amount: float
    currency: str
    description: str
    reference: str | None
    balance_after: float
    created_at: datetime

    model_config = {"from_attributes": True}


class SuspiciousEventOut(BaseModel):
    id: str
    account_id: str | None
    score: int
    reason: str
    resolved: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class AuditLogOut(BaseModel):
    id: str
    actor_role: str
    action: str
    target: str | None
    ip_address: str | None
    created_at: datetime

    model_config = {"from_attributes": True}
