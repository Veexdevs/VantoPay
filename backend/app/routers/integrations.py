"""Integration status endpoint — reports honestly which external services are
configured, so the frontend can gate features and clearly state dependencies."""
from __future__ import annotations

from fastapi import APIRouter

from ..config import settings
from ..integrations import registry
from ..schemas import IntegrationStatusOut

router = APIRouter(prefix="/integrations", tags=["integrations"])


@router.get("/status", response_model=list[IntegrationStatusOut])
def status_all() -> list[dict]:
    return [s.as_dict() for s in registry.statuses()]


@router.get("/config")
def public_config() -> dict:
    """Non-sensitive configuration the frontend needs."""
    return {
        "env": settings.env,
        "api_url": settings.api_url,
        "google_client_id": settings.google_client_id,
        "supabase_url": settings.supabase_url or None,
        "integrations": settings.integrations_configured(),
    }
