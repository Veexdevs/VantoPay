"""SQLAlchemy models for the VantoPay financial core.

Money is stored as a decimal string and always recomputed from the ledger
(double-entry entries) — never trusted from the client. The schema mirrors the
Supabase/PostgreSQL migration in ``backend/migrations/sql`` so the same tables
can run on the Supabase Postgres instance with Row Level Security enabled.
"""
from __future__ import annotations

import uuid
from datetime import datetime, timezone

from sqlalchemy import (
    Boolean,
    DateTime,
    ForeignKey,
    Index,
    Numeric,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship


def _uuid() -> str:
    return str(uuid.uuid4())


def _now() -> datetime:
    return datetime.now(timezone.utc)


class Base(DeclarativeBase):
    pass


class Account(Base):
    __tablename__ = "accounts"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    user_id: Mapped[str] = mapped_column(String(36), index=True, nullable=False)
    account_number: Mapped[str] = mapped_column(String(32), unique=True, nullable=False)
    holder_name: Mapped[str] = mapped_column(String(200), nullable=False)
    # Document is stored masked at rest; the full value lives only in the
    # encrypted vault column (never returned by the API).
    document_masked: Mapped[str] = mapped_column(String(20), nullable=False)
    currency: Mapped[str] = mapped_column(String(8), default="BRL", nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="active", nullable=False)
    is_admin: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    transaction_limit: Mapped[float] = mapped_column(
        Numeric(18, 2), default=0, nullable=False
    )
    daily_limit: Mapped[float] = mapped_column(Numeric(18, 2), default=0, nullable=False)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_now)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=_now, onupdate=_now
    )

    ledger_entries: Mapped[list["LedgerEntry"]] = relationship(back_populates="account")
    transactions: Mapped[list["Transaction"]] = relationship(back_populates="account")


class LedgerEntry(Base):
    """Immutable double-entry ledger line. Balances are derived from here."""

    __tablename__ = "ledger_entries"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    account_id: Mapped[str] = mapped_column(
        ForeignKey("accounts.id", ondelete="CASCADE"), index=True, nullable=False
    )
    entry_type: Mapped[str] = mapped_column(String(16), nullable=False)  # debit | credit
    amount: Mapped[float] = mapped_column(Numeric(18, 2), nullable=False)
    currency: Mapped[str] = mapped_column(String(8), default="BRL", nullable=False)
    description: Mapped[str] = mapped_column(String(255), nullable=False)
    reference: Mapped[str | None] = mapped_column(String(128), nullable=True)
    balance_after: Mapped[float] = mapped_column(Numeric(18, 2), nullable=False)
    idempotency_key: Mapped[str | None] = mapped_column(
        String(128), nullable=True, unique=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_now)

    account: Mapped["Account"] = relationship(back_populates="ledger_entries")


class Transaction(Base):
    __tablename__ = "transactions"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    account_id: Mapped[str] = mapped_column(
        ForeignKey("accounts.id", ondelete="CASCADE"), index=True, nullable=False
    )
    kind: Mapped[str] = mapped_column(String(40), nullable=False)
    direction: Mapped[str] = mapped_column(String(8), nullable=False)  # debit|credit
    amount: Mapped[float] = mapped_column(Numeric(18, 2), nullable=False)
    currency: Mapped[str] = mapped_column(String(8), default="BRL", nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="pending", nullable=False)
    # Counterparty details are masked; the counterparty name is shown only when
    # provided by the processing institution.
    counterparty_name: Mapped[str | None] = mapped_column(String(200), nullable=True)
    counterparty_institution: Mapped[str | None] = mapped_column(
        String(200), nullable=True
    )
    counterparty_document_masked: Mapped[str | None] = mapped_column(
        String(20), nullable=True
    )
    external_reference: Mapped[str | None] = mapped_column(String(128), nullable=True)
    correlation_id: Mapped[str | None] = mapped_column(String(64), nullable=True)
    idempotency_key: Mapped[str | None] = mapped_column(String(128), nullable=True)
    meta: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_now)

    account: Mapped["Account"] = relationship(back_populates="transactions")

    __table_args__ = (
        Index("ix_transactions_account_created", "account_id", "created_at"),
    )


class PixKey(Base):
    __tablename__ = "pix_keys"
    __table_args__ = (UniqueConstraint("key_value", name="uq_pix_key_value"),)

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    account_id: Mapped[str] = mapped_column(
        ForeignKey("accounts.id", ondelete="CASCADE"), index=True, nullable=False
    )
    key_type: Mapped[str] = mapped_column(String(20), nullable=False)  # email|cpf|phone|random
    key_value: Mapped[str] = mapped_column(String(120), nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="active", nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_now)


class PixCharge(Base):
    """A PIX charge (receive) or copy-paste/QR send payload."""

    __tablename__ = "pix_charges"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    account_id: Mapped[str] = mapped_column(
        ForeignKey("accounts.id", ondelete="CASCADE"), index=True, nullable=False
    )
    kind: Mapped[str] = mapped_column(String(20), nullable=False)  # charge|send
    key_value: Mapped[str] = mapped_column(String(120), nullable=False)
    amount: Mapped[float] = mapped_column(Numeric(18, 2), nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="pending", nullable=False)
    payload_pix: Mapped[str | None] = mapped_column(Text, nullable=True)
    qr_code_payload: Mapped[str | None] = mapped_column(Text, nullable=True)
    correlation_id: Mapped[str | None] = mapped_column(String(64), nullable=True)
    idempotency_key: Mapped[str | None] = mapped_column(String(128), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_now)


class Session(Base):
    __tablename__ = "sessions"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    user_id: Mapped[str] = mapped_column(String(36), index=True, nullable=False)
    device_label: Mapped[str] = mapped_column(String(200), nullable=False)
    token_hash: Mapped[str] = mapped_column(String(128), unique=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_now)
    last_seen_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_now)
    revoked_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )


class IdempotencyRecord(Base):
    __tablename__ = "idempotency_records"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    key: Mapped[str] = mapped_column(String(128), unique=True, nullable=False)
    endpoint: Mapped[str] = mapped_column(String(200), nullable=False)
    status: Mapped[str] = mapped_column(String(20), default="in_progress", nullable=False)
    response_body: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_now)


class SuspiciousEvent(Base):
    __tablename__ = "suspicious_events"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    account_id: Mapped[str | None] = mapped_column(String(36), index=True, nullable=True)
    user_id: Mapped[str | None] = mapped_column(String(36), index=True, nullable=True)
    score: Mapped[int] = mapped_column(default=0, nullable=False)
    reason: Mapped[str] = mapped_column(String(255), nullable=False)
    meta: Mapped[str | None] = mapped_column(Text, nullable=True)
    resolved: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_now)


class AuditLog(Base):
    __tablename__ = "audit_logs"

    id: Mapped[str] = mapped_column(String(36), primary_key=True, default=_uuid)
    actor_user_id: Mapped[str | None] = mapped_column(String(36), index=True, nullable=True)
    actor_role: Mapped[str] = mapped_column(String(20), default="user", nullable=False)
    action: Mapped[str] = mapped_column(String(100), nullable=False)
    target: Mapped[str | None] = mapped_column(String(200), nullable=True)
    ip_address: Mapped[str | None] = mapped_column(String(64), nullable=True)
    user_agent: Mapped[str | None] = mapped_column(String(255), nullable=True)
    meta: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_now)
