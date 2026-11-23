-- ──────────────────────────────────────────────────────────────────────────
-- VantoPay — Core schema (PostgreSQL / Supabase)
-- Applied to the Supabase Postgres database. Mirrors the SQLAlchemy models in
-- backend/app/models.py. Balances are derived from the ledger, never stored.
-- ──────────────────────────────────────────────────────────────────────────

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ── Accounts ───────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS accounts (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             TEXT NOT NULL,
    account_number      TEXT NOT NULL UNIQUE,
    holder_name         TEXT NOT NULL,
    document_masked     TEXT NOT NULL,
    currency            TEXT NOT NULL DEFAULT 'BRL',
    status              TEXT NOT NULL DEFAULT 'active',
    is_admin            BOOLEAN NOT NULL DEFAULT false,
    transaction_limit   NUMERIC(18,2) NOT NULL DEFAULT 0,
    daily_limit         NUMERIC(18,2) NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_accounts_user_id ON accounts(user_id);

-- ── Ledger (append-only double-entry) ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS ledger_entries (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id          UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    entry_type          TEXT NOT NULL CHECK (entry_type IN ('debit','credit')),
    amount              NUMERIC(18,2) NOT NULL CHECK (amount > 0),
    currency            TEXT NOT NULL DEFAULT 'BRL',
    description         TEXT NOT NULL,
    reference           TEXT,
    balance_after       NUMERIC(18,2) NOT NULL,
    idempotency_key     TEXT UNIQUE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_ledger_account_created ON ledger_entries(account_id, created_at);

-- ── Transactions ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS transactions (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id                  UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    kind                        TEXT NOT NULL,
    direction                   TEXT NOT NULL CHECK (direction IN ('debit','credit')),
    amount                      NUMERIC(18,2) NOT NULL,
    currency                    TEXT NOT NULL DEFAULT 'BRL',
    status                      TEXT NOT NULL DEFAULT 'pending',
    counterparty_name           TEXT,
    counterparty_institution    TEXT,
    counterparty_document_masked TEXT,
    external_reference          TEXT,
    correlation_id              TEXT,
    idempotency_key             TEXT,
    meta                        TEXT,
    created_at                  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_transactions_account_created
    ON transactions(account_id, created_at);
CREATE INDEX IF NOT EXISTS ix_transactions_kind ON transactions(kind);

-- ── PIX ────────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS pix_keys (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id  UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    key_type    TEXT NOT NULL,
    key_value   TEXT NOT NULL UNIQUE,
    status      TEXT NOT NULL DEFAULT 'active',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_pix_keys_account ON pix_keys(account_id);

CREATE TABLE IF NOT EXISTS pix_charges (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id          UUID NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    kind                TEXT NOT NULL,
    key_value           TEXT NOT NULL,
    amount              NUMERIC(18,2) NOT NULL,
    status              TEXT NOT NULL DEFAULT 'pending',
    payload_pix         TEXT,
    qr_code_payload     TEXT,
    correlation_id      TEXT,
    idempotency_key     TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_pix_charges_account ON pix_charges(account_id);

-- ── Sessions ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS sessions (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       TEXT NOT NULL,
    device_label  TEXT NOT NULL,
    token_hash    TEXT NOT NULL UNIQUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_seen_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    revoked_at    TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS ix_sessions_user_id ON sessions(user_id);

-- ── Idempotency ────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS idempotency_records (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key            TEXT NOT NULL UNIQUE,
    endpoint       TEXT NOT NULL,
    status         TEXT NOT NULL DEFAULT 'in_progress',
    response_body  TEXT,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── Suspicious events ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS suspicious_events (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id  UUID,
    user_id     TEXT,
    score       INTEGER NOT NULL DEFAULT 0,
    reason      TEXT NOT NULL,
    meta        TEXT,
    resolved    BOOLEAN NOT NULL DEFAULT false,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_suspicious_account ON suspicious_events(account_id);

-- ── Audit log ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS audit_logs (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_user_id  TEXT,
    actor_role     TEXT NOT NULL DEFAULT 'user',
    action         TEXT NOT NULL,
    target         TEXT,
    ip_address     TEXT,
    user_agent     TEXT,
    meta           TEXT,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_audit_logs_created ON audit_logs(created_at);

-- ── updated_at trigger ───────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_accounts_updated
    BEFORE UPDATE ON accounts
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
