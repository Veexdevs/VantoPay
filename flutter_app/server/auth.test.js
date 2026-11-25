import test from 'node:test';
import assert from 'node:assert/strict';
import { createHandler } from '../api/auth.js';
import { seal, unseal, digest } from './security.js';
process.env.OTP_PEPPER = 'test-only-secret';
process.env.SMTP_USER = 'test@example.com';

function fixture({ trust = false, accept = true, smtpFails = false } = {}) {
  const calls = [], messages = [], challenges = new Map();
  const user = { id: 'user-1', email: 'person@example.com', email_confirmed_at: '2026-11-25' };
  const session = { access_token: 'private-access', refresh_token: 'private-refresh' };
  const ok = data => ({ data });
  const auth = {
    signInWithPassword: async () => ok({ user, session }),
    setSession: async () => ok({ user, session }),
    getUser: async () => ok({ user }), verifyOtp: async () => ok({ user, session }),
    admin: {
      createUser: async data => { calls.push(['create', data]); return ok({ user }); },
      updateUserById: async () => ok({ user }),
      generateLink: async () => ok({ properties: { hashed_token: 'internal-link' } }),
      signOut: async () => ok({}),
    },
  };
  const client = {
    auth,
    rpc: async (name, args) => {
      calls.push([name, args]);
      if (name.endsWith('auth_limit')) return ok(true);
      if (name.endsWith('issue_otp')) { challenges.set(args.p_token, args); return ok(accept); }
      if (name.endsWith('consume_otp')) {
        const c = challenges.get(args.p_token);
        if (!c || c.p_code !== args.p_code) return ok({ ok: false });
        challenges.delete(args.p_token);
        return ok({ ok: true, user_id: user.id, email: user.email, purpose: c.p_purpose });
      }
      return ok(null);
    },
    from: () => {
      const builder = { select: () => builder, eq: () => builder, gt: async () => ok(trust ? [{ user_id: user.id }] : []),
        insert: async data => { calls.push(['insert', data]); return ok({}); } };
      return builder;
    },
  };
  const handler = createHandler({ clientFactory: () => client, transportFactory: settings => {
    assert.equal(settings.port, 587); assert.equal(settings.requireTLS, true); assert.equal(settings.secure, false);
    return { sendMail: async mail => { if (smtpFails) throw new Error('SECRET SMTP error'); messages.push(mail); } };
  } });
  const jar = {};
  async function request(body, headers = {}) {
    const res = { headers: {}, setHeader(k, v) { this.headers[k] = v; }, status(n) { this.statusCode = n; return this; }, json(data) { this.body = data; return this; } };
    await handler({ method: 'POST', body, headers: { host: 'vantopay.vercel.app', origin: 'https://vantopay.vercel.app',
      'content-type': 'application/json', cookie: Object.entries(jar).map(([k, v]) => `${k}=${v}`).join('; '), ...headers } }, res);
    for (const value of res.headers['Set-Cookie'] || []) { const [k, v] = value.split(';')[0].split(/=(.*)/s); jar[k] = v; }
    return res;
  }
  return { request, jar, messages, calls, user, session };
}

test('signup sends Gmail code, saves display_name, never returns tokens', async () => {
  const f = fixture();
  const r = await f.request({ action: 'signup', email: f.user.email, display_name: 'Pessoa', password: 'password123' });
  assert.equal(r.statusCode, 200); assert.equal(r.body.verified, false); assert.equal(r.body.pending, true);
  assert.equal(f.calls.find(c => c[0] === 'create')[1].user_metadata.display_name, 'Pessoa');
  assert.match(f.messages[0].text, /\b\d{6}\b/);
  assert.equal(f.jar.__Host_vp_session, undefined);
  assert.ok(!JSON.stringify(r.body).includes('private'));
  assert.match(r.headers['Set-Cookie'][0], /HttpOnly; Secure; SameSite=Strict/);
});
test('password login on new device cannot create verified session until correct OTP', async () => {
  const f = fixture();
  const login = await f.request({ action: 'login', email: f.user.email, password: 'password123' });
  assert.equal(login.body.verified, false);
  const wrong = await f.request({ action: 'verify', code: 'wrong' });
  assert.equal(wrong.body.code, 'otp_expired');
  const code = f.messages[0].text.match(/\b\d{6}\b/)[0];
  const verified = await f.request({ action: 'verify', code });
  assert.equal(verified.body.verified, true);
  assert.ok(f.jar['__Host-vp_device']); assert.ok(unseal(f.jar['__Host-vp_session']));
  const replay = await f.request({ action: 'verify', code });
  assert.equal(replay.body.code, 'otp_expired');
});
test('trusted device skips code only after valid password login', async () => {
  const f = fixture({ trust: true }); f.jar['__Host-vp_device'] = 'trusted';
  const r = await f.request({ action: 'login', email: f.user.email, password: 'password123' });
  assert.equal(r.body.verified, true); assert.equal(f.messages.length, 0);
});
test('forged session and pending cookies never grant access', async () => {
  const f = fixture(); f.jar['__Host-vp_session'] = 'forged'; f.jar['__Host-vp_pending'] = 'forged';
  assert.equal((await f.request({ action: 'status' })).body.verified, false);
  assert.equal((await f.request({ action: 'verify', code: '123456' })).body.code, 'otp_expired');
});
test('cooldown refuses delivery and SMTP errors fail closed without leaking details', async () => {
  const limited = fixture({ accept: false });
  assert.equal((await limited.request({ action: 'login', email: limited.user.email, password: 'pass' })).statusCode, 429);
  assert.equal(limited.messages.length, 0);
  const failed = fixture({ smtpFails: true });
  const r = await failed.request({ action: 'login', email: failed.user.email, password: 'pass' });
  assert.equal(r.statusCode, 503); assert.equal(r.body.code, 'email_delivery_failed');
  assert.ok(!JSON.stringify(r.body).includes('SECRET')); assert.equal(failed.jar['__Host-vp_session'], '');
});
test('OAuth on a new device also requires email OTP', async () => {
  const f = fixture();
  const r = await f.request({ action: 'oauth', access_token: 'oauth-access', refresh_token: 'oauth-refresh' });
  assert.equal(r.body.verified, false); assert.equal(r.body.pending, true); assert.equal(f.messages.length, 1);
});
test('cross-origin request is rejected before touching backend', async () => {
  const f = fixture();
  assert.equal((await f.request({ action: 'status' }, { origin: 'https://attacker.test' })).statusCode, 403);
  assert.equal(f.calls.length, 0);
});
test('a copied session without trusted-device token cannot restore access', async () => {
  const f = fixture(); f.jar['__Host-vp_session'] = seal({ uid: f.user.id, access: 'private', refresh: 'private' }, 300);
  assert.equal((await f.request({ action: 'status' })).body.verified, false);
});
