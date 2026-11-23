"""Shared test fixtures.

Environment is configured before the app is imported so the service uses an
in-memory SQLite database and a known JWT secret for tests.
"""
from __future__ import annotations

import os
import tempfile

_TMPDIR = tempfile.mkdtemp(prefix="vantopay-test-")
os.environ.update(
    {
        "VANTOPAY_ENV": "test",
        "DATABASE_URL": f"sqlite:///{_TMPDIR}/test.db",
        "SUPABASE_JWT_SECRET": "test-jwt-secret",
        "SUPABASE_JWT_ISSUER": "",
        "VANTOPAY_RATE_LIMIT_PER_MINUTE": "0",
        "VANTOPAY_SUSPICION_THRESHOLD": "50",
    }
)

import itertools  # noqa: E402

import pytest  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402
from jose import jwt  # noqa: E402
from sqlalchemy.orm import Session  # noqa: E402

from app.db import SessionLocal, init_db  # noqa: E402
from app.main import app  # noqa: E402
from app.models import Account  # noqa: E402

_SEQ = itertools.count(1)


def _unique_number() -> str:
    return f"{8000000000 + next(_SEQ):010d}"


@pytest.fixture(scope="session")
def client():
    init_db()
    with TestClient(app) as c:
        yield c


@pytest.fixture()
def db():
    session = SessionLocal()
    try:
        yield session
    finally:
        session.close()


@pytest.fixture()
def make_token(db):
    """Return a factory that mints a verified Supabase-style access token.

    The token sub (user id) is stable per ``(user_id, is_admin)`` so repeated
    calls in a test resolve to the same VantoPay account.
    """
    cache: dict[tuple[str, bool], str] = {}

    def _make(user_id: str = "user-1", email: str = "user@example.com",
              is_admin: bool = False) -> str:
        key = (user_id, is_admin)
        if key not in cache:
            uid = f"{user_id}-{next(_SEQ)}-{os.urandom(3).hex()}"
            # Only provision an account for admins; regular users register
            # their VantoPay account through the API, mirroring the real flow.
            if is_admin:
                db.add(
                    Account(
                        user_id=uid,
                        account_number=_unique_number(),
                        holder_name="Admin User",
                        document_masked="***456",
                        currency="BRL",
                        status="active",
                        is_admin=True,
                    )
                )
                db.commit()
            cache[key] = uid
        uid = cache[key]
        claims = {"sub": uid, "email": email, "exp": 4_000_000_000}
        return jwt.encode(claims, "test-jwt-secret", algorithm="HS256")

    return _make


@pytest.fixture()
def auth_header(make_token):
    def _header(**kwargs) -> dict:
        token = make_token(**kwargs)
        return {"Authorization": f"Bearer {token}"}

    return _header


@pytest.fixture()
def admin_header(make_token):
    def _header(user_id: str = "admin") -> dict:
        token = make_token(user_id=user_id, is_admin=True)
        return {"Authorization": f"Bearer {token}"}

    return _header
