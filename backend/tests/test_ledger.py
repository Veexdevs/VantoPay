"""Unit tests for the double-entry ledger."""
from __future__ import annotations

import itertools
from decimal import Decimal

import pytest

from app.models import Account
from app.services.ledger import (
    InsufficientFunds,
    credit,
    debit,
    get_balance,
    transfer_internal,
)


_counter = itertools.count(1)


def _account(db, user_id: str) -> Account:
    acc = Account(
        user_id=user_id,
        account_number=f"{7000000000 + next(_counter):010d}",
        holder_name="User",
        document_masked="***1234",
        currency="BRL",
        status="active",
    )
    db.add(acc)
    db.commit()
    return acc


def test_credit_and_balance(db):
    acc = _account(db, "u1")
    credit(db, account=acc, amount=Decimal("150.00"), description="deposit")
    assert get_balance(db, acc.id) == Decimal("150.00")


def test_debit_reduces_balance(db):
    acc = _account(db, "u1")
    credit(db, account=acc, amount=Decimal("200.00"), description="d")
    debit(db, account=acc, amount=Decimal("50.00"), description="s")
    assert get_balance(db, acc.id) == Decimal("150.00")


def test_insufficient_funds(db):
    acc = _account(db, "u1")
    with pytest.raises(InsufficientFunds):
        debit(db, account=acc, amount=Decimal("10.00"), description="s")


def test_negative_amount_rejected(db):
    acc = _account(db, "u1")
    with pytest.raises(Exception):
        credit(db, account=acc, amount=Decimal("-5"), description="x")


def test_idempotent_credit_no_double_booking(db):
    acc = _account(db, "u1")
    credit(db, account=acc, amount=Decimal("100.00"), description="d",
           idempotency_key="key-1")
    credit(db, account=acc, amount=Decimal("100.00"), description="d",
           idempotency_key="key-1")
    # Same key -> same single entry, balance not doubled.
    assert get_balance(db, acc.id) == Decimal("100.00")


def test_internal_transfer_moves_money(db):
    a = _account(db, "a")
    b = _account(db, "b")
    credit(db, account=a, amount=Decimal("500.00"), description="d")
    transfer_internal(db, source=a, destination=b, amount=Decimal("200.00"),
                      idempotency_key="transfer-1")
    assert get_balance(db, a.id) == Decimal("300.00")
    assert get_balance(db, b.id) == Decimal("200.00")


def test_internal_transfer_idempotent(db):
    a = _account(db, "a2")
    b = _account(db, "b2")
    credit(db, account=a, amount=Decimal("500.00"), description="d")
    transfer_internal(db, source=a, destination=b, amount=Decimal("200.00"),
                      idempotency_key="transfer-2")
    transfer_internal(db, source=a, destination=b, amount=Decimal("200.00"),
                      idempotency_key="transfer-2")
    assert get_balance(db, a.id) == Decimal("300.00")
    assert get_balance(db, b.id) == Decimal("200.00")
