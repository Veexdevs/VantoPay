import test from 'node:test';
import assert from 'node:assert/strict';
import { randomCode, randomToken, digest, seal, unseal, sameOrigin } from './security.js';
process.env.OTP_PEPPER = 'unit-test-only-not-a-real-secret';

test('codes are exactly six digits, tokens have cryptographic entropy', () => {
  const tokens = new Set();
  for (let i = 0; i < 1000; i++) {
    assert.match(randomCode(), /^\d{6}$/);
    const token = randomToken();
    assert.equal(Buffer.from(token, 'base64url').length, 32);
    tokens.add(token);
  }
  assert.equal(tokens.size, 1000);
});
test('code hashes bind to the challenge and secret', () => {
  assert.notEqual(digest('token-a:123456'), digest('token-b:123456'));
  assert.equal(digest('token-a:123456').length, 64);
});
test('encrypted cookies roundtrip, expire, and reject tampering', () => {
  const value = seal({ uid: 'user', refresh: 'private' }, 300);
  assert.equal(unseal(value).uid, 'user');
  assert.ok(!value.includes('private'));
  assert.equal(unseal(seal({ uid: 'user' }, -1)), null);
  const bytes = Buffer.from(value, 'base64url'); bytes[30] ^= 1;
  assert.equal(unseal(bytes.toString('base64url')), null);
  assert.equal(unseal('forged'), null);
});
test('mutations require exact HTTPS origin and JSON (CSRF protection)', () => {
  const req = { headers: { host: 'vantopay.vercel.app', origin: 'https://vantopay.vercel.app', 'content-type': 'application/json' } };
  assert.equal(sameOrigin(req), true);
  assert.equal(sameOrigin({ headers: { ...req.headers, origin: 'https://attacker.test' } }), false);
  assert.equal(sameOrigin({ headers: { ...req.headers, origin: undefined } }), false);
  assert.equal(sameOrigin({ headers: { ...req.headers, 'content-type': 'text/plain' } }), false);
});

test('same-origin browser metadata is accepted when Origin is omitted', () => {
  const headers = { host: 'vantopay.vercel.app', 'content-type': 'application/json; charset=utf-8', 'sec-fetch-site': 'same-origin' };
  assert.equal(sameOrigin({ headers }), true);
  assert.equal(sameOrigin({ headers: { ...headers, origin: 'null' } }), false);
  assert.equal(sameOrigin({ headers: { ...headers, origin: 'https://attacker.test' } }), false);
  for (const site of ['cross-site', 'same-site', 'none', undefined]) {
    assert.equal(sameOrigin({ headers: { ...headers, 'sec-fetch-site': site } }), false);
  }
});
