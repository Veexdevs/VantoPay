-- ──────────────────────────────────────────────────────────────────────────
-- VantoPay — Row Level Security & authorization policies (Supabase / Postgres)
-- Enables RLS on every table and restricts rows to the authenticated owner.
-- Administrators (accounts.is_admin = true) get full access via policies.
-- ──────────────────────────────────────────────────────────────────────────

-- Enable RLS on all application tables.
ALTER TABLE accounts           ENABLE ROW LEVEL SECURITY;
ALTER TABLE ledger_entries     ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions       ENABLE ROW LEVEL SECURITY;
ALTER TABLE pix_keys           ENABLE ROW LEVEL SECURITY;
ALTER TABLE pix_charges        ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions           ENABLE ROW LEVEL SECURITY;
ALTER TABLE idempotency_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE suspicious_events  ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs         ENABLE ROW LEVEL SECURITY;

-- For Supabase, the service role bypasses RLS (used by the backend).
-- Tables are writable only through the backend service role, never the anon key.

-- ── Helper predicates ────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION vantopay_current_user() RETURNS TEXT AS $$
    SELECT auth.jwt()->>'sub';
$$ LANGUAGE sql STABLE;

CREATE OR REPLACE FUNCTION vantopay_is_admin() RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1 FROM accounts
        WHERE user_id = auth.jwt()->>'sub' AND is_admin = true
    );
$$ LANGUAGE sql STABLE;

-- ── Accounts ─────────────────────────────────────────────────────────────────
CREATE POLICY accounts_select_owner ON accounts
    FOR SELECT USING (user_id = vantopay_current_user() OR vantopay_is_admin());

CREATE POLICY accounts_insert_owner ON accounts
    FOR INSERT WITH CHECK (user_id = vantopay_current_user());

CREATE POLICY accounts_update_owner ON accounts
    FOR UPDATE USING (user_id = vantopay_current_user() OR vantopay_is_admin())
    WITH CHECK (user_id = vantopay_current_user() OR vantopay_is_admin());

-- ── Ledger (read-only for the owner; write via service role) ─────────────────
CREATE POLICY ledger_select_owner ON ledger_entries
    FOR SELECT USING (
        account_id IN (SELECT id FROM accounts WHERE user_id = vantopay_current_user())
        OR vantopay_is_admin()
    );

-- ── Transactions ──────────────────────────────────────────────────────────────
CREATE POLICY tx_select_owner ON transactions
    FOR SELECT USING (
        account_id IN (SELECT id FROM accounts WHERE user_id = vantopay_current_user())
        OR vantopay_is_admin()
    );

-- ── PIX keys ──────────────────────────────────────────────────────────────────
CREATE POLICY pix_keys_select_owner ON pix_keys
    FOR SELECT USING (
        account_id IN (SELECT id FROM accounts WHERE user_id = vantopay_current_user())
        OR vantopay_is_admin()
    );
CREATE POLICY pix_keys_insert_owner ON pix_keys
    FOR INSERT WITH CHECK (
        account_id IN (SELECT id FROM accounts WHERE user_id = vantopay_current_user())
    );

-- ── PIX charges ──────────────────────────────────────────────────────────────
CREATE POLICY pix_charges_select_owner ON pix_charges
    FOR SELECT USING (
        account_id IN (SELECT id FROM accounts WHERE user_id = vantopay_current_user())
        OR vantopay_is_admin()
    );
CREATE POLICY pix_charges_insert_owner ON pix_charges
    FOR INSERT WITH CHECK (
        account_id IN (SELECT id FROM accounts WHERE user_id = vantopay_current_user())
    );

-- ── Sessions ───────────────────────────────────────────────────────────────────
CREATE POLICY sessions_select_owner ON sessions
    FOR SELECT USING (user_id = vantopay_current_user() OR vantopay_is_admin());
CREATE POLICY sessions_insert_owner ON sessions
    FOR INSERT WITH CHECK (user_id = vantopay_current_user());
CREATE POLICY sessions_update_owner ON sessions
    FOR UPDATE USING (user_id = vantopay_current_user())
    WITH CHECK (user_id = vantopay_current_user());

-- ── Idempotency / suspicious / audit (admin + service role only) ─────────────
CREATE POLICY idempotency_admin_all ON idempotency_records
    FOR ALL USING (vantopay_is_admin()) WITH CHECK (vantopay_is_admin());

CREATE POLICY suspicious_admin_select ON suspicious_events
    FOR SELECT USING (vantopay_is_admin());

CREATE POLICY audit_admin_select ON audit_logs
    FOR SELECT USING (vantopay_is_admin());

-- ── Defense-in-depth audit trigger on ledger changes ─────────────────────────
CREATE OR REPLACE FUNCTION vantopay_ledger_audit() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO audit_logs (actor_role, action, target, meta)
    VALUES ('system', 'ledger_entry', NEW.account_id,
            json_build_object('type', NEW.entry_type, 'amount', NEW.amount)::text);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_ledger_audit
    AFTER INSERT ON ledger_entries
    FOR EACH ROW EXECUTE FUNCTION vantopay_ledger_audit();
