"""Concrete integration clients.

Each client mirrors the relevant open-source project:

* ``HyperswitchClient``      — juspay/hyperswitch  (payment gateway)
* ``MoovClient``             — moov-io/moov-io      (payment infrastructure)
* ``FormanceClient``         — formancehq/ledger     (financial ledger)
* ``FineractClient``         — apache/fineract       (core banking)
* ``PixProviderClient``      — authorized PIX participant/provider

They perform real HTTP calls when configured.
"""
from __future__ import annotations

from typing import Any

from .base import BaseIntegration, IntegrationError


class HyperswitchClient(BaseIntegration):
    name = "hyperswitch"
    description = "Payment gateway (juspay/hyperswitch)"

    def __init__(self, base_url: str = "", api_key: str = "", merchant_id: str = ""):
        super().__init__(base_url, api_key, {"merchant_id": merchant_id})

    def _headers(self) -> dict[str, str]:
        return {
            "Authorization": f"Bearer {self.token}",
            "X-MERCHANT-ID": self.extra.get("merchant_id", ""),
            "Content-Type": "application/json",
        }

    def create_payment(self, *, amount: int, currency: str, reference: str,
                       method: str = "pix") -> dict[str, Any]:
        self._require()
        try:
            resp = httpx_post(
                self.base_url,
                "/v1/payments/request",
                headers=self._headers(),
                json={
                    "merchant_id": self.extra.get("merchant_id"),
                    "amount": amount,
                    "currency": currency,
                    "reference": reference,
                    "method": method,
                },
            )
            resp.raise_for_status()
            return resp.json()
        except Exception as exc:  # noqa: BLE001
            raise IntegrationError(f"Hyperswitch: {exc}") from exc


class MoovClient(BaseIntegration):
    name = "moov"
    description = "Payment infrastructure (moov-io/moov-io)"

    def list_accounts(self, account_id: str) -> dict[str, Any]:
        self._require()
        try:
            resp = httpx_get(self.base_url, f"/v1/accounts/{account_id}",
                             headers={"Authorization": f"Bearer {self.token}"})
            resp.raise_for_status()
            return resp.json()
        except Exception as exc:  # noqa: BLE001
            raise IntegrationError(f"Moov: {exc}") from exc


class FormanceClient(BaseIntegration):
    name = "formance"
    description = "Financial ledger (formancehq/ledger)"

    def move(self, *, from_account: str, to_account: str, amount: int,
             currency: str, reference: str) -> dict[str, Any]:
        self._require()
        try:
            resp = httpx_post(
                self.base_url,
                "/v2/moves",
                headers={"Authorization": f"Bearer {self.token}",
                         "Content-Type": "application/json"},
                json={
                    "from": from_account,
                    "to": to_account,
                    "amount": amount,
                    "currency": currency,
                    "reference": reference,
                },
            )
            resp.raise_for_status()
            return resp.json()
        except Exception as exc:  # noqa: BLE001
            raise IntegrationError(f"Formance: {exc}") from exc


class FineractClient(BaseIntegration):
    name = "fineract"
    description = "Core banking (apache/fineract)"

    def get_client(self, client_id: str) -> dict[str, Any]:
        self._require()
        import base64

        raw = base64.b64encode(self.token.encode("utf-8")).decode("ascii")
        try:
            resp = httpx_get(
                self.base_url,
                f"/fineract-api/api/v1/clients/{client_id}",
                headers={
                    "Authorization": f"Basic {raw}",
                    "Fineract-Tenant-Id": self.extra.get("tenant", "1"),
                },
            )
            resp.raise_for_status()
            return resp.json()
        except Exception as exc:  # noqa: BLE001
            raise IntegrationError(f"Fineract: {exc}") from exc


class PixProviderClient(BaseIntegration):
    name = "pix_provider"
    description = "Authorized PIX participant / provider"

    def create_charge(self, *, account_id: str, amount: int, key: str,
                      correlation_id: str) -> dict[str, Any]:
        self._require()
        try:
            resp = httpx_post(
                self.base_url,
                "/v1/pix/charges",
                headers={"Authorization": f"Bearer {self.token}",
                         "Content-Type": "application/json"},
                json={
                    "account_id": account_id,
                    "amount": amount,
                    "key": key,
                    "correlation_id": correlation_id,
                },
            )
            resp.raise_for_status()
            return resp.json()
        except Exception as exc:  # noqa: BLE001
            raise IntegrationError(f"PIX provider: {exc}") from exc

    def create_pix_payment(self, *, amount: int, payload_pix: str,
                           correlation_id: str) -> dict[str, Any]:
        self._require()
        try:
            resp = httpx_post(
                self.base_url,
                "/v1/pix/payments",
                headers={"Authorization": f"Bearer {self.token}",
                         "Content-Type": "application/json"},
                json={
                    "amount": amount,
                    "payload_pix": payload_pix,
                    "correlation_id": correlation_id,
                },
            )
            resp.raise_for_status()
            return resp.json()
        except Exception as exc:  # noqa: BLE001
            raise IntegrationError(f"PIX provider: {exc}") from exc


# ── small module-local http helpers (avoids importing httpx at module import) ──
def httpx_get(base: str, path: str, headers: dict):
    import httpx

    return httpx.get(f"{base}{path}", headers=headers)


def httpx_post(base: str, path: str, headers: dict, json: dict):
    import httpx

    return httpx.post(f"{base}{path}", headers=headers, json=json)
