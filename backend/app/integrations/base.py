"""Integration abstraction for external financial services.

Every provider is a thin, real client for the corresponding open-source
project. When credentials are not configured the provider reports
``is_configured == False`` and its operations raise
``IntegrationNotConfigured`` so the API can return a clear, honest message —
it never fabricates balances, receipts or confirmations.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any

import httpx


class IntegrationError(RuntimeError):
    """Raised when a configured integration call fails."""


class IntegrationNotConfigured(RuntimeError):
    """Raised when an integration is used without credentials."""


@dataclass
class IntegrationStatus:
    name: str
    configured: bool
    description: str

    def as_dict(self) -> dict[str, Any]:
        return {"name": self.name, "configured": self.configured,
                "description": self.description}


class BaseIntegration:
    name: str = "base"
    description: str = ""

    def __init__(self, base_url: str = "", token: str = "", extra: dict | None = None):
        self.base_url = (base_url or "").rstrip("/")
        self.token = token
        self.extra = extra or {}

    @property
    def is_configured(self) -> bool:
        return bool(self.base_url and self.token)

    def _require(self) -> None:
        if not self.is_configured:
            raise IntegrationNotConfigured(
                f"A integração '{self.name}' não está configurada. "
                "Adicione as credenciais em .env (ver .env.example) para ativá-la."
            )

    def _client(self, timeout: float = 30.0) -> httpx.Client:
        headers = {"Accept": "application/json"}
        if self.token:
            headers["Authorization"] = f"Bearer {self.token}"
        return httpx.Client(base_url=self.base_url, headers=headers, timeout=timeout)

    def status(self) -> IntegrationStatus:
        return IntegrationStatus(self.name, self.is_configured, self.description)
