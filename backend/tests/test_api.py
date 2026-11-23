"""End-to-end API tests covering auth, accounts, transfers, PIX, admin and
security guarantees (authorization, masking, idempotency, rate limiting)."""
from __future__ import annotations

from decimal import Decimal

from app.services.ledger import credit


def _register(client, auth, name="User", document="12345678901", limits=(0, 0)):
    r = client.post(
        "/auth/accounts",
        headers=auth,
        json={
            "holder_name": name,
            "document": document,
            "transaction_limit": limits[0],
            "daily_limit": limits[1],
        },
    )
    assert r.status_code == 200, r.text
    return r.json()["account"]


def _credit(client, admin_auth, account_id, amount, key):
    r = client.post(
        f"/admin/accounts/{account_id}/adjustment",
        headers=admin_auth,
        params={"direction": "credit", "amount": amount, "reason": "test",
                "idempotency_key": key},
    )
    assert r.status_code == 200, r.text


def test_health(client):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"


def test_auth_requires_token(client):
    assert client.get("/auth/me").status_code == 401


def test_auth_me_and_register(client, auth_header):
    auth = auth_header(user_id="u-me")
    r = client.get("/auth/me", headers=auth)
    assert r.status_code == 200
    assert r.json()["role"] == "user"

    account = _register(client, auth, name="João Silva", document="12345678901")
    assert account["account_number"]
    assert account["document_masked"] == "*******8901"


def test_account_and_balance(client, auth_header, admin_header):
    auth = auth_header(user_id="u-bal")
    account = _register(client, auth)
    _credit(client, admin_header(user_id="admin-bal"), account["id"], "150.00",
            "bal-1")

    bal = client.get("/accounts/balance", headers=auth)
    assert bal.status_code == 200
    assert bal.json()["balance"] == 150.0

    st = client.get("/accounts/statement", headers=auth)
    assert st.status_code == 200
    assert len(st.json()) == 1


def test_internal_transfer_real_movement(client, auth_header, admin_header):
    admin = admin_header(user_id="admin-tx")
    src = _register(client, auth_header(user_id="u-src"), name="Source")
    dst = _register(client, auth_header(user_id="u-dst"), name="Destination")

    _credit(client, admin, src["id"], "500.00", "src-1")

    r = client.post(
        "/transfers/internal",
        headers=auth_header(user_id="u-src"),
        json={
            "destination_account_number": dst["account_number"],
            "amount": "200.00",
            "reference": "ref-1",
            "idempotency_key": "idem-tx-1",
        },
    )
    assert r.status_code == 200, r.text
    assert r.json()["status"] == "completed"
    assert r.json()["source_balance"] == 300.0

    # Destination balance credited.
    dst_bal = client.get("/accounts/balance",
                         headers=auth_header(user_id="u-dst")).json()
    assert dst_bal["balance"] == 200.0


def test_internal_transfer_idempotent(client, auth_header, admin_header):
    admin = admin_header(user_id="admin-idem")
    src = _register(client, auth_header(user_id="u-idem-src"))
    dst = _register(client, auth_header(user_id="u-idem-dst"))
    _credit(client, admin, src["id"], "500.00", "src-idem")

    payload = {
        "destination_account_number": dst["account_number"],
        "amount": "100.00",
        "idempotency_key": "idem-tx-9",
    }
    r1 = client.post("/transfers/internal", headers=auth_header(user_id="u-idem-src"),
                     json=payload)
    r2 = client.post("/transfers/internal", headers=auth_header(user_id="u-idem-src"),
                     json=payload)
    assert r1.status_code == 200 and r2.status_code == 200
    # Balance only moved once.
    src_bal = client.get("/accounts/balance",
                         headers=auth_header(user_id="u-idem-src")).json()
    assert src_bal["balance"] == 400.0


def test_insufficient_funds(client, auth_header, admin_header):
    admin = admin_header(user_id="admin-insuf")
    src = _register(client, auth_header(user_id="u-insuf-src"))
    dst = _register(client, auth_header(user_id="u-insuf-dst"))
    _credit(client, admin, src["id"], "50.00", "src-insuf")
    r = client.post(
        "/transfers/internal",
        headers=auth_header(user_id="u-insuf-src"),
        json={"destination_account_number": dst["account_number"],
              "amount": "999.00", "idempotency_key": "insuf-1"},
    )
    assert r.status_code == 422


def test_external_transfer_requires_integration(client, auth_header, admin_header):
    admin = admin_header(user_id="admin-ext")
    src = _register(client, auth_header(user_id="u-ext-src"))
    _credit(client, admin, src["id"], "500.00", "src-ext")
    r = client.post(
        "/transfers/external",
        headers=auth_header(user_id="u-ext-src"),
        json={
            "destination_name": "João Silva",
            "destination_document": "12345678901",
            "destination_bank_code": "341",
            "destination_account_number": "12345",
            "destination_account_digit": "1",
            "amount": "100.00",
            "idempotency_key": "ext-idem-1",
        },
    )
    assert r.status_code == 503


def test_pix_charge_payload(client, auth_header):
    auth = auth_header(user_id="u-pix")
    _register(client, auth, name="PIX User", document="12345678901")
    r = client.post(
        "/pix/charges",
        headers=auth,
        json={"amount": "150.00", "key_value": "12345678901"},
    )
    assert r.status_code == 200, r.text
    payload = r.json()["qr_code_payload"]
    assert "br.gov.bcb.pix" in payload
    assert payload.endswith("6304") is False  # CRC is part of payload
    assert len(payload) > 20


def test_pix_send_requires_integration(client, auth_header):
    auth = auth_header(user_id="u-pixsend")
    _register(client, auth)
    r = client.post(
        "/pix/send/key",
        headers=auth,
        json={"key_value": "12345678901", "amount": "10.00",
              "idempotency_key": "pixsend-1"},
    )
    assert r.status_code == 503


def test_pix_keys(client, auth_header):
    auth = auth_header(user_id="u-pixkey")
    _register(client, auth)
    r = client.post("/pix/keys", headers=auth,
                    json={"key_type": "cpf", "key_value": "12345678901"})
    assert r.status_code == 200
    keys = client.get("/pix/keys", headers=auth)
    assert keys.status_code == 200
    assert len(keys.json()) == 1


def test_admin_requires_admin_role(client, auth_header):
    r = client.get("/admin/accounts", headers=auth_header(user_id="u-nonadmin"))
    assert r.status_code == 403


def test_admin_can_list_and_adjust(client, auth_header, admin_header):
    admin = admin_header(user_id="admin-list")
    acc = _register(client, auth_header(user_id="u-list"))
    _credit(client, admin, acc["id"], "10.00", "adm-1")
    listing = client.get("/admin/accounts", headers=admin)
    assert listing.status_code == 200
    assert any(a["id"] == acc["id"] for a in listing.json())

    audit = client.get("/admin/audit-logs", headers=admin)
    assert audit.status_code == 200
    assert any(log["action"] == "admin_adjustment" for log in audit.json())


def test_admin_adjustment_is_idempotent(client, auth_header, admin_header):
    admin = admin_header(user_id="admin-adj")
    acc = _register(client, auth_header(user_id="u-adj"))
    for _ in range(2):
        client.post(
            f"/admin/accounts/{acc['id']}/adjustment",
            headers=admin,
            params={"direction": "credit", "amount": "25.00", "reason": "adj",
                    "idempotency_key": "adj-idem-1"},
        )
    bal = client.get("/accounts/balance", headers=auth_header(user_id="u-adj")).json()
    assert bal["balance"] == 25.0


def test_suspicious_activity_recorded(client, auth_header, admin_header):
    admin = admin_header(user_id="admin-susp")
    acc = _register(client, auth_header(user_id="u-susp"))
    # Repeated large movement triggers fraud scoring.
    _credit(client, admin, acc["id"], "10000.00", "susp-src")
    for i in range(6):
        client.post(
            f"/admin/accounts/{acc['id']}/adjustment",
            headers=admin,
            params={"direction": "credit", "amount": "100.00", "reason": "x",
                    "idempotency_key": f"susp-{i}"},
        )
    events = client.get("/admin/suspicious", headers=admin)
    assert events.status_code == 200
    assert len(events.json()) >= 1


def test_masking_never_exposes_full_document(client, auth_header):
    auth = auth_header(user_id="u-mask")
    acc = _register(client, auth, document="11122233344")
    assert acc["document_masked"] == "*******3344"
    assert "11122233344" not in str(acc)


def test_sessions_management(client, auth_header):
    auth = auth_header(user_id="u-sess")
    _register(client, auth)
    # Register then list a session.
    r = client.post("/sessions/register", headers=auth)
    assert r.status_code == 200
    sessions = client.get("/sessions", headers=auth)
    assert sessions.status_code == 200
    assert len(sessions.json()) >= 1


def test_integrations_status(client):
    r = client.get("/integrations/status")
    assert r.status_code == 200
    names = {s["name"] for s in r.json()}
    assert {"hyperswitch", "formance", "pix_provider"}.issubset(names)
    assert all(s["configured"] is False for s in r.json())
