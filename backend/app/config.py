"""Application configuration.

All values are read from the environment (or a local ``.env`` file). Real
credentials are never committed: they are supplied through GitHub Secrets /
Vercel encrypted variables at deploy time. ``.env.example`` documents every
variable that can be set here.
"""
from __future__ import annotations

import os
from dataclasses import dataclass, field
from functools import lru_cache


def _env(key: str, default: str | None = None) -> str | None:
    value = os.environ.get(key)
    if value is None or value.strip() == "":
        return default
    return value.strip()


def _env_bool(key: str, default: bool = False) -> bool:
    value = os.environ.get(key)
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


def _env_int(key: str, default: int) -> int:
    value = os.environ.get(key)
    if value is None or value.strip() == "":
        return default
    try:
        return int(value)
    except ValueError:
        return default


@dataclass(frozen=True)
class Settings:
    # ── Core ────────────────────────────────────────────────────────────────
    app_name: str = _env("VANTOPAY_APP_NAME", "VantoPay API") or "VantoPay API"
    env: str = _env("VANTOPAY_ENV", "development") or "development"
    debug: bool = _env_bool("VANTOPAY_DEBUG", False)
    public_origin: str = _env("VANTOPAY_PUBLIC_ORIGIN", "http://localhost:8000") or ""

    # ── Database ─────────────────────────────────────────────────────────────
    # SQLAlchemy URL. Locally defaults to SQLite for fast dev/tests; production
    # points at the Supabase PostgreSQL pooler.
    database_url: str = (
        _env("DATABASE_URL", "sqlite:///./vantopay.db") or "sqlite:///./vantopay.db"
    )
    db_pool_size: int = _env_int("DB_POOL_SIZE", 10)
    db_max_overflow: int = _env_int("DB_MAX_OVERFLOW", 20)

    # ── Supabase / Auth ──────────────────────────────────────────────────────
    supabase_url: str = _env("SUPABASE_URL", "") or ""
    supabase_anon_key: str = _env("SUPABASE_ANON_KEY", "") or ""
    supabase_service_role_key: str = _env("SUPABASE_SERVICE_ROLE_KEY", "") or ""
    # JWT secret used to verify Supabase-issued access tokens (HS256).
    supabase_jwt_secret: str = _env("SUPABASE_JWT_SECRET", "") or ""
    supabase_jwt_issuer: str = _env("SUPABASE_JWT_ISSUER", "") or ""

    # ── Backend API ─────────────────────────────────────────────────────────
    api_url: str = _env("VANTOPAY_API_URL", "http://localhost:8000") or ""

    # ── Payment / financial services (integration layer) ────────────────────
    hyperswitch_url: str = _env("HYPERSWITCH_URL", "") or ""
    hyperswitch_api_key: str = _env("HYPERSWITCH_API_KEY", "") or ""
    hyperswitch_merchant_id: str = _env("HYPERSWITCH_MERCHANT_ID", "") or ""

    moov_base_url: str = _env("MOOV_BASE_URL", "") or ""
    moov_token: str = _env("MOOV_TOKEN", "") or ""

    formance_base_url: str = _env("FORMANCE_BASE_URL", "") or ""
    formance_api_key: str = _env("FORMANCE_API_KEY", "") or ""

    fineract_base_url: str = _env("FINERACT_BASE_URL", "") or ""
    fineract_username: str = _env("FINERACT_USERNAME", "") or ""
    fineract_password: str = _env("FINERACT_PASSWORD", "") or ""

    pix_provider_base_url: str = _env("PIX_PROVIDER_BASE_URL", "") or ""
    pix_provider_token: str = _env("PIX_PROVIDER_TOKEN", "") or ""

    # ── Security ─────────────────────────────────────────────────────────────
    # Secret used to sign internal service-to-service idempotency receipts.
    service_secret: str = _env("VANTOPAY_SERVICE_SECRET", "") or ""
    session_ttl_minutes: int = _env_int("VANTOPAY_SESSION_TTL_MINUTES", 720)
    rate_limit_per_minute: int = _env_int("VANTOPAY_RATE_LIMIT_PER_MINUTE", 30)
    suspicious_score_threshold: int = _env_int("VANTOPAY_SUSPICION_THRESHOLD", 50)

    # ── Google OAuth (passed through to the frontend) ───────────────────────
    google_client_id: str = _env("GOOGLE_CLIENT_ID", "") or ""

    raw: dict[str, str] = field(default_factory=dict, repr=False)

    def integrations_configured(self) -> dict[str, bool]:
        """Report which external integrations have credentials available.

        The frontend uses this to clearly show that a feature depends on an
        external integration that is not yet configured — never to fake data.
        """
        return {
            "hyperswitch": bool(self.hyperswitch_url and self.hyperswitch_api_key),
            "moov": bool(self.moov_base_url and self.moov_token),
            "formance": bool(self.formance_base_url and self.formance_api_key),
            "fineract": bool(self.fineract_base_url and self.fineract_username),
            "pix_provider": bool(self.pix_provider_base_url and self.pix_provider_token),
            "supabase": bool(self.supabase_url and self.supabase_jwt_secret),
        }


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
