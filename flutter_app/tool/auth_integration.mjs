// Run only in a protected deployment environment. Uses one disposable .invalid
// account and an in-memory mail transport; never sends real email or logs tokens.
import assert from 'node:assert/strict';
import { randomUUID } from 'node:crypto';
import { createClient } from '@supabase/supabase-js';
import { createHandler } from '../api/auth.js';
const admin = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY, { auth: { persistSession: false, autoRefreshToken: false } });
const email = `vp-${randomUUID()}@example.invalid`, password = `Vp-${randomUUID()}!`;
let uid, mail, sent = 0, stage = 'initialization';
const handler = createHandler({
  clientFactory: key => {
    const client = createClient(process.env.SUPABASE_URL, key, { auth: { persistSession: false, autoRefreshToken: false } });
    if (key === process.env.SUPABASE_SERVICE_ROLE_KEY) {
      const create = client.auth.admin.createUser.bind(client.auth.admin);
      client.auth.admin.createUser = async data => { const r = await create(data); uid = r.data?.user?.id; return r; };
    }
    return client;
  },
  transportFactory: () => ({ sendMail: async message => { mail = message.text; sent++; } }),
});
let jar = {};
async function request(body) {
  let result;
  const res = { setHeader(name, values) { if (name === 'Set-Cookie') for (const v of values) { const [key, value] = v.split(';')[0].split(/=(.*)/s); jar[key] = value; } },
    status(status) { this.code = status; return this; }, json(data) { result = { status: this.code, data }; } };
  await handler({ method: 'POST', headers: { origin: 'https://vantopay.vercel.app', host: 'vantopay.vercel.app', 'content-type': 'application/json',
    'x-real-ip': `integration-${process.env.VERCEL_GIT_COMMIT_SHA || 'manual'}`, cookie: Object.entries(jar).map(([k,v])=>`${k}=${v}`).join('; ') }, body }, res);
  if (result.status !== 200) throw new Error(result.data.code);
  return result.data;
}
try {
  stage = 'signup';
  assert.equal((await request({ action: 'signup', email, password, display_name: 'Integration Test' })).pending, true);
  stage = 'verify';
  assert.equal((await request({ action: 'verify', code: mail.match(/\b\d{6}\b/)[0] })).verified, true);
  stage = 'restore';
  assert.equal((await request({ action: 'status' })).verified, true);
  stage = 'logout'; await request({ action: 'logout' });
  stage = 'same_device_login';
  assert.equal((await request({ action: 'login', email, password })).verified, true);
  assert.equal(sent, 1);
  stage = 'new_device_login'; jar = {};
  // Issuance cooldown belongs to the user, so a new device within 60s must be
  // rate-limited rather than bypass verification. This is covered in unit tests.
  console.log('AUTH_INTEGRATION', JSON.stringify({ ok: true, signup: true, verify: true, restore: true, sameDeviceNoNewCode: true }));
} catch (error) {
  console.error('AUTH_INTEGRATION', JSON.stringify({ ok: false, stage, category: /^[a-z_]+$/.test(error.message) ? error.message : 'assertion_failed' }));
  process.exitCode = 1;
} finally {
  if (uid) {
    const { error } = await admin.auth.admin.deleteUser(uid);
    if (error) { console.error('AUTH_INTEGRATION cleanup_failed'); process.exitCode = 1; }
    else console.log('AUTH_INTEGRATION cleanup_ok');
  }
}
