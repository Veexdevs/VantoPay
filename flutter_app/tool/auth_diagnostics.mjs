// Deployment-only diagnostics: no mail is sent, accounts created, or secret values logged.
import { createClient } from '@supabase/supabase-js';
import nodemailer from 'nodemailer';
const report = (name, data) => console.log('AUTH_DIAGNOSTIC', name, JSON.stringify(data));
try {
  const origin = 'https://vantopay.vercel.app';
  const response = await fetch(`${origin}/api/auth`, { method: 'POST', headers: { Origin: origin, 'Content-Type': 'application/json' }, body: JSON.stringify({ action: 'status' }), signal: AbortSignal.timeout(20000) });
  const data = await response.json().catch(() => ({}));
  report('production_status', { status: response.status, code: data.code, verified: data.verified, pending: data.pending });
} catch { report('production_status', { reachable: false }); }
try {
  const client = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY, { auth: { persistSession: false, autoRefreshToken: false } });
  const { error, status } = await client.from('vantopay_trusted_devices').select('token_hash').limit(0);
  report('database', { ok: !error, status, code: error?.code });
  const auth = await client.auth.admin.listUsers({ page: 1, perPage: 1 });
  report('auth_admin', { ok: !auth.error, status: auth.error?.status, code: auth.error?.code });
} catch { report('supabase', { configured: false }); }
try {
  const transport = nodemailer.createTransport({ host: 'smtp.gmail.com', port: 587, secure: false, requireTLS: true,
    tls: { minVersion: 'TLSv1.2', rejectUnauthorized: true }, auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS },
    connectionTimeout: 8000, socketTimeout: 10000 });
  await transport.verify();
  report('smtp', { authenticated: true });
  transport.close();
} catch (error) { report('smtp', { authenticated: false, code: error.code, responseCode: error.responseCode }); }
