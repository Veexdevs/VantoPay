"""Security primitives: Supabase JWT verification, token hashing, masking,
rate limiting and audit helpers.

The backend never trusts a client-supplied amount, balance or document: those
are derived server-side. Access tokens issued by Supabase Auth are verified
locally (HS256) using ``SUPABASE_JWT_SECRET``.
"""
from __future__ import annotations

import hashlib
import hmac
import time
from collections import defaultdict, deque
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone

from fastapi import Depends, Header, HTTPException, Request, status
from jose import JWTError, jwt
from sqlalchemy.orm import Session

from .config import settings
from .db import get_db


# ────────────────────────────────────────────────────────────────────────────
# Token handling
# ────────────────────────────────────────────────────────────────────────────


def hash_token(token: str) -> str:
    """Stable hash used to store session identifiers (never the raw token)."""
    return hashlib.sha256(token.encode("utf-8")).hexdigest()


def verify_supabase_token(token: str) -> dict:
    """Verify a Supabase-issued access token (HS256)."""
    if not settings.supabase_jwt_secret:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Autenticação do Supabase não configurada.",
        )
    try:
        claims = jwt.decode(
            token,
            settings.supabase_jwt_secret,
            algorithms=["HS256"],
            options={"require": ["exp", "sub"]},
        )
    except JWTError as exc:  # noqa: PERF203
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido ou expirado.",
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc

    if settings.supabase_jwt_issuer and claims.get("iss") != settings.supabase_jwt_issuer:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token com issuer inválido."
        )
    return claims


@dataclass
class Principal:
    user_id: str
    email: str | None
    role: str = "user"

    @property
    def is_admin(self) -> bool:
        return self.role == "admin"


def _extract_bearer(authorization: str | None) -> str | None:
    if not authorization:
        return None
    parts = authorization.split(None, 1)
    if len(parts) == 2 and parts[0].lower() == "bearer":
        return parts[1].strip()
    return None


def get_current_principal(
    authorization: str | None = Header(default=None),
    db: Session = Depends(get_db),
) -> Principal:
    token = _extract_bearer(authorization)
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Falha de autorização: token ausente.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    claims = verify_supabase_token(token)

    user_id = str(claims.get("sub"))
    email = claims.get("email")

    # Role is resolved from the account record so admin rights are centralized.
    from .models import Account

    account = db.query(Account).filter(Account.user_id == user_id).first()
    role = "admin" if (account and account.is_admin) else "user"

    return Principal(user_id=user_id, email=email, role=role)


def require_admin(principal: Principal = Depends(get_current_principal)) -> Principal:
    if not principal.is_admin:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Acesso restrito a administradores.",
        )
    return principal


# ────────────────────────────────────────────────────────────────────────────
# Masking / privacy helpers
# ────────────────────────────────────────────────────────────────────────────


def mask_document(value: str | None) -> str | None:
    """Mask a CPF/CNPJ keeping only the last 4 digits."""
    if not value:
        return None
    digits = "".join(ch for ch in value if ch.isdigit())
    if len(digits) <= 4:
        return "****"
    return "*" * (len(digits) - 4) + digits[-4:]


def mask_name(value: str | None, keep: int = 2) -> str | None:
    """Mask a name, e.g. 'João Silva' -> 'J*** S****'."""
    if not value:
        return None
    parts = value.strip().split()
    out = []
    for part in parts:
        if len(part) <= keep:
            out.append("*" * len(part))
        else:
            out.append(part[:1] + "*" * (len(part) - 1))
    return " ".join(out)


# ────────────────────────────────────────────────────────────────────────────
# Idempotency / replay protection
# ────────────────────────────────────────────────────────────────────────────


def new_correlation_id() -> str:
    return f"corr_{hashlib.sha1(str(time.time_ns()).encode()).hexdigest()}"


def is_replay(token: str | None, seen: set[str]) -> bool:
    """Reject a replayed request id (nonce) within the idempotency window."""
    if not token:
        return False
    if token in seen:
        return True
    seen.add(token)
    return False


# ────────────────────────────────────────────────────────────────────────────
# Rate limiting (per-client sliding window, in-memory)
# ────────────────────────────────────────────────────────────────────────────

_buckets: dict[str, deque[float]] = defaultdict(deque)


def _client_key(request: Request) -> str:
    forwarded = request.headers.get("x-forwarded-for")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.client.host if request.client else "unknown"


def enforce_rate_limit(request: Request) -> None:
    """Raise 429 when a client exceeds the configured requests/minute."""
    limit = settings.rate_limit_per_minute
    if limit <= 0:
        return
    key = f"{_client_key(request)}:{request.url.path}"
    now = time.monotonic()
    bucket = _buckets[key]
    while bucket and now - bucket[0] > 60:
        bucket.popleft()
    if len(bucket) >= limit:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Muitas solicitações. Tente novamente em instantes.",
        )
    bucket.append(now)


# ────────────────────────────────────────────────────────────────────────────
# Audit + suspicious activity
# ────────────────────────────────────────────────────────────────────────────


def record_audit(
    db: Session,
    *,
    actor_user_id: str | None,
    actor_role: str,
    action: str,
    target: str | None = None,
    ip_address: str | None = None,
    user_agent: str | None = None,
    metadata: dict | None = None,
) -> None:
    from .models import AuditLog

    db.add(
        AuditLog(
            actor_user_id=actor_user_id,
            actor_role=actor_role,
            action=action,
            target=target,
            ip_address=ip_address,
            user_agent=user_agent,
            meta=str(metadata) if metadata else None,
        )
    )
    db.commit()


def record_suspicious(
    db: Session,
    *,
    account_id: str | None,
    user_id: str | None,
    score: int,
    reason: str,
    metadata: dict | None = None,
) -> None:
    from .models import SuspiciousEvent

    db.add(
        SuspiciousEvent(
            account_id=account_id,
            user_id=user_id,
            score=score,
            reason=reason,
            meta=str(metadata) if metadata else None,
        )
    )
    db.commit()


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


def expiry(minutes: int) -> datetime:
    return datetime.now(timezone.utc) + timedelta(minutes=minutes)
