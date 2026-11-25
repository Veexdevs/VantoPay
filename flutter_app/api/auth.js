import { createClient } from '@supabase/supabase-js';
import nodemailer from 'nodemailer';
import { randomToken, randomCode, digest, seal, unseal, sameOrigin } from '../server/security.js';

const options = { auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false } };
const makeClient = key => createClient(process.env.SUPABASE_URL, key, options);
const checked = result => { if (result.error) throw result.error; return result.data; };
const fail = (code, status = 400) => { throw Object.assign(new Error(code), { publicCode: code, status }); };
const names = { session: '__Host-vp_session', pending: '__Host-vp_pending', device: '__Host-vp_device' };

export function createHandler({ clientFactory = makeClient, transportFactory = nodemailer.createTransport } = {}) {
return async function handler(req, res) {
  res.setHeader('Cache-Control', 'no-store');
  res.setHeader('X-Content-Type-Options', 'nosniff');
  if (req.method !== 'POST') return res.status(405).json({ code: 'method_not_allowed' });
  if (!sameOrigin(req)) return res.status(403).json({ code: 'forbidden' });
  if (Number(req.headers['content-length'] || 0) > 16384) return res.status(413).json({ code: 'invalid_request' });
  const cookies = Object.fromEntries((req.headers.cookie || '').split(';').map(v => v.trim().split(/=(.*)/s)).filter(v => v[0]));
  const outgoing = [];
  const cookie = (name, value, age, uid) => {
    const cookieName = uid ? `${names[name]}_${uid}` : names[name];
    outgoing.push(`${cookieName}=${value}; Path=/; HttpOnly; Secure; SameSite=Strict; Max-Age=${age}`);
    res.setHeader('Set-Cookie', outgoing);
  };
  const save = (name, data, age) => cookie(name, seal(data, age), age);
  const read = name => unseal(cookies[names[name]]);
  let action = 'unknown';
  try {
  const admin = clientFactory(process.env.SUPABASE_SERVICE_ROLE_KEY);
  const auth = clientFactory(process.env.SUPABASE_ANON_KEY);
  const rpc = async (name, args) => checked(await admin.rpc(`vantopay_${name}`, args));
  const limit = async (key, max, seconds) => {
    if (!await rpc('auth_limit', { p_key: digest(key), p_limit: max, p_window: seconds })) fail('over_request_rate_limit', 429);
  };
  const trusted = async uid => {
    // Keep each verified account on this browser; switching accounts must not
    // overwrite the trust token of the previous account. Accept legacy cookies.
    const token = cookies[`${names.device}_${uid}`] || cookies[names.device];
    if (!token) return false;
    const rows = checked(await admin.from('vantopay_trusted_devices').select('user_id')
      .eq('token_hash', digest(token)).eq('user_id', uid).gt('expires_at', new Date().toISOString()));
    return rows.length === 1;
  };
  const issue = async pending => {
    const token = randomToken(), code = randomCode();
    if (!await rpc('issue_otp', { p_token: digest(token), p_user: pending.uid, p_email: pending.email,
      p_purpose: pending.purpose, p_code: digest(`${token}:${code}`) })) fail('over_email_send_rate_limit', 429);
    // Persist an opaque, authenticated continuation even if SMTP temporarily fails.
    save('pending', { ...pending, token }, 900);
    cookie('session', '', 0);
    const transport = transportFactory({ host: 'smtp.gmail.com', port: 587, secure: false,
      requireTLS: true, tls: { minVersion: 'TLSv1.2', rejectUnauthorized: true },
      auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS },
      connectionTimeout: 10000, socketTimeout: 15000, disableFileAccess: true, disableUrlAccess: true });
    try {
      await transport.sendMail({ from: { name: 'VantoPay', address: process.env.SMTP_USER },
        to: { address: pending.email, name: '' }, subject: 'Seu código de verificação VantoPay',
        text: `Seu código VantoPay é ${code}. Ele expira em 5 minutos e só pode ser usado uma vez. Não compartilhe este código. Se não foi você, ignore este e-mail.` });
    } catch { throw Object.assign(new Error('email_delivery_failed'), { publicCode: 'email_delivery_failed', status: 503, pendingEmail: pending.email }); }
    return { verified: false, pending: true, email: pending.email };
  };
  const mintSession = async email => {
    const link = checked(await admin.auth.admin.generateLink({ type: 'magiclink', email }));
    return checked(await auth.auth.verifyOtp({ token_hash: link.properties.hashed_token, type: 'magiclink' }));
  };
  const promote = (session, user) => {
    save('session', { access: session.access_token, refresh: session.refresh_token, uid: user.id }, 30 * 86400);
    cookie('pending', '', 0);
    return { verified: true, pending: false, email: user.email };
  };
    const body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
    if (!body || JSON.stringify(body).length > 16384) fail('invalid_request');
    action = body.action;
    // Vercel supplies x-real-ip; never trust a user-chosen forwarded-for chain.
    await limit(`ip:${req.headers['x-real-ip'] || req.socket?.remoteAddress || 'unknown'}`, 100, 600);
    let result;
    if (action === 'signup' || action === 'login') {
      const email = String(body.email || '').trim().toLowerCase();
      const password = body.password;
      if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email) || email.length > 254 || typeof password !== 'string' || password.length > 256) fail('invalid_request');
      await limit(`email:${email}`, 15, 3600);
      if (action === 'signup') {
        const displayName = String(body.display_name || '').trim();
        if (password.length < 8 || displayName.length < 3 || displayName.length > 80) fail('invalid_request');
        const created = await admin.auth.admin.createUser({ email, password, email_confirm: false, user_metadata: { display_name: displayName } });
        if (created.error && !['email_exists', 'user_already_exists'].includes(created.error.code)) {
          throw created.error;
        }
        let uid = created.data?.user?.id;
        // Repeat signup never changes an existing account's password or metadata.
        if (!uid) uid = await rpc('unconfirmed_user', { p_email: email });
        if (!uid) {
          // Do not claim that a code was sent when no challenge exists.
          fail('signup_unavailable', 409);
        } else result = await issue({ uid, email, purpose: 'signup' });
      } else {
        const response = await auth.auth.signInWithPassword({ email, password });
        if (response.error?.code === 'email_not_confirmed') {
          const uid = await rpc('unconfirmed_user', { p_email: email });
          if (!uid) fail('invalid_credentials', 401);
          result = await issue({ uid, email, purpose: 'signup' });
        } else {
          if (response.error) fail('invalid_credentials', 401);
          const { user, session } = response.data;
          result = await trusted(user.id) ? promote(session, user)
            : await issue({ uid: user.id, email: user.email, purpose: 'device', access: session.access_token, refresh: session.refresh_token });
        }
      }
    } else if (action === 'oauth') {
      const { user } = checked(await auth.auth.getUser(body.access_token));
      if (!user?.email || !user.email_confirmed_at) fail('invalid_credentials', 401);
      // Independent server session: clearing the browser OAuth session must not revoke it.
      const { session } = await mintSession(user.email);
      result = await trusted(user.id) ? promote(session, user)
        : await issue({ uid: user.id, email: user.email, purpose: 'device', access: session.access_token, refresh: session.refresh_token });
    } else if (action === 'resend') {
      const pending = read('pending');
      if (!pending?.uid) fail('otp_expired');
      result = await issue(pending);
    } else if (action === 'verify') {
      const pending = read('pending');
      if (!pending?.token || !/^\d{6}$/.test(body.code || '')) fail('otp_expired');
      const verified = await rpc('consume_otp', { p_token: digest(pending.token), p_code: digest(`${pending.token}:${body.code}`) });
      if (!verified.ok || verified.user_id !== pending.uid || verified.email !== pending.email) fail('otp_expired');
      let session, user;
      if (verified.purpose === 'signup') {
        checked(await admin.auth.admin.updateUserById(pending.uid, { email_confirm: true }));
        ({ session, user } = await mintSession(verified.email));
      } else {
        ({ session, user } = checked(await auth.auth.setSession({ access_token: pending.access, refresh_token: pending.refresh })));
      }
      if (user.id !== verified.user_id) fail('invalid_credentials', 401);
      const device = randomToken();
      checked(await admin.from('vantopay_trusted_devices').insert({ token_hash: digest(device), user_id: user.id }));
      cookie('device', device, 30 * 86400, user.id);
      result = promote(session, user);
    } else if (action === 'status') {
      const sessionCookie = read('session');
      if (sessionCookie && await trusted(sessionCookie.uid)) {
        const { session, user } = checked(await auth.auth.setSession({ access_token: sessionCookie.access, refresh_token: sessionCookie.refresh }));
        result = promote(session, user);
      } else {
        const pending = read('pending');
        result = { verified: false, pending: !!pending, email: pending?.email };
      }
    } else if (action === 'logout') {
      const current = read('session');
      if (current?.access) await admin.auth.admin.signOut(current.access, 'local');
      cookie('session', '', 0); cookie('pending', '', 0);
      result = { verified: false, pending: false };
    } else fail('invalid_request');
    return res.status(200).json(result);
  } catch (error) {
    // Log only allowlisted categories, never raw errors (which can contain credentials).
    const category = error.publicCode || (error.status === 401 || error.status === 403
      ? 'server_configuration' : 'service_unavailable');
    console.error('vantopay_auth_failure', JSON.stringify({
      action: ['signup', 'login', 'oauth', 'resend', 'verify', 'status', 'logout'].includes(action) ? action : 'unknown',
      category,
    }));
    return res.status(error.publicCode ? error.status : 503).json({ code: category,
      ...(error.pendingEmail ? { pending: true, email: error.pendingEmail } : {}) });
  }
}

}
export default createHandler();
