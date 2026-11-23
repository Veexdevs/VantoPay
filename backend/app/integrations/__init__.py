"""Integration registry: builds provider clients from settings and reports
their configuration status so the API can expose honest availability."""
from __future__ import annotations

from .base import (
    BaseIntegration,
    IntegrationError,
    IntegrationNotConfigured,
    IntegrationStatus,
)
from .providers import (
    FineractClient,
    FormanceClient,
    HyperswitchClient,
    MoovClient,
    PixProviderClient,
)

__all__ = [
    "BaseIntegration",
    "IntegrationError",
    "IntegrationNotConfigured",
    "IntegrationStatus",
    "registry",
    "FineractClient",
    "FormanceClient",
    "HyperswitchClient",
    "MoovClient",
    "PixProviderClient",
]


class IntegrationRegistry:
    def __init__(self) -> None:
        from ..config import settings

        self.hyperswitch = HyperswitchClient(
            settings.hyperswitch_url,
            settings.hyperswitch_api_key,
            settings.hyperswitch_merchant_id,
        )
        self.moov = MoovClient(settings.moov_base_url, settings.moov_token)
        self.formance = FormanceClient(settings.formance_base_url,
                                       settings.formance_api_key)
        self.fineract = FineractClient(
            settings.fineract_base_url,
            f"{settings.fineract_username}:{settings.fineract_password}",
            extra={"tenant": settings.fineract_username or "1"},
        )
        self.pix = PixProviderClient(settings.pix_provider_base_url,
                                     settings.pix_provider_token)

    def statuses(self) -> list[IntegrationStatus]:
        return [s.status() for s in (
            self.hyperswitch, self.moov, self.formance, self.fineract, self.pix
        )]


registry = IntegrationRegistry()
