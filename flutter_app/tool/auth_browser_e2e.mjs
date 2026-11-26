// Real compiled Flutter + real HTTPS API + real Supabase + browser-managed cookies.
// Only SMTP delivery is replaced, in this isolated test process (never in deployment).
import assert from 'node:assert/strict';
import https from 'node:https';
import { execFileSync } from 'node:child_process';
import { readFile, mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join, resolve, extname } from 'node:path';
import { randomUUID } from 'node:crypto';
import chromium from '@sparticuz/chromium';
import { chromium as playwright } from 'playwright-core';
import { createClient } from '@supabase/supabase-js';
import { createHandler } from '../api/auth.js';

const admin = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_ROLE_KEY,
  { auth: { persistSession: false, autoRefreshToken: false } });
const email = `vp-browser-${randomUUID()}@example.invalid`, password = `Vp-${randomUUID()}!`;
let uid, otp, sent = 0, browser, server, stage = 'setup';
const submitted = [];
const scratch = await mkdtemp(join(tmpdir(), 'vp-auth-e2e-'));
const handler = createHandler({
  clientFactory: key => {
    const client = createClient(process.env.SUPABASE_URL, key, { auth: { persistSession: false, autoRefreshToken: false } });
    if (key === process.env.SUPABASE_SERVICE_ROLE_KEY) {
      const create = client.auth.admin.createUser.bind(client.auth.admin);
      client.auth.admin.createUser = async data => { const result = await create(data); uid = result.data?.user?.id; return result; };
    }
    return client;
  },
  transportFactory: () => ({ sendMail: async message => { otp = message.text.match(/\b\d{6}\b/)[0]; sent++; } }),
});
try {
  execFileSync('openssl', ['req', '-x509', '-newkey', 'rsa:2048', '-nodes', '-days', '1', '-subj', '/CN=localhost',
    '-keyout', join(scratch, 'key.pem'), '-out', join(scratch, 'cert.pem')], { stdio: 'ignore' });
  const root = resolve('build/web');
  server = https.createServer({ key: await readFile(join(scratch, 'key.pem')), cert: await readFile(join(scratch, 'cert.pem')) }, async (req, res) => {
    try {
      const path = new URL(req.url, 'https://localhost').pathname;
      if (path === '/api/auth') {
        const chunks = []; for await (const chunk of req) chunks.push(chunk);
        req.body = JSON.parse(Buffer.concat(chunks).toString());
        if (['signup', 'login'].includes(req.body.action)) {
          submitted.push({ action: req.body.action, emailMatches: req.body.email === email,
            passwordMatches: req.body.password === password });
        }
        res.status = code => { res.statusCode = code; return res; };
        res.json = data => res.end(JSON.stringify(data));
        res.setHeader('Content-Type', 'application/json');
        await handler(req, res);
      } else {
        const file = resolve(root, `.${path === '/' ? '/index.html' : path}`);
        if (!file.startsWith(`${root}/`)) { res.writeHead(403).end(); return; }
        res.setHeader('Content-Type', ({ '.js': 'text/javascript', '.html': 'text/html', '.json': 'application/json', '.wasm': 'application/wasm', '.png': 'image/png', '.woff2': 'font/woff2' })[extname(file)] || 'application/octet-stream');
        res.end(await readFile(file));
      }
    } catch { res.writeHead(500).end(); }
  });
  await new Promise(resolve => server.listen(0, '0.0.0.0', resolve));
  const origin = `https://localhost:${server.address().port}`;
  browser = await playwright.launch({ executablePath: await chromium.executablePath(), args: chromium.args.filter(arg => arg !== '--disable-web-security'), headless: true });
  const context = await browser.newContext({ ignoreHTTPSErrors: true, viewport: { width: 440, height: 1100 }, reducedMotion: 'reduce' });
  const page = await context.newPage();
  const statuses = [];
  page.on('response', response => { if (new URL(response.url()).pathname === '/api/auth') statuses.push(response.status()); });
  const type = async (name, value) => { await page.getByRole('textbox', { name, exact: true }).click(); await page.keyboard.press('ControlOrMeta+A'); await page.keyboard.type(value, { delay: 15 }); };
  const ready = async () => {
    const semantics = page.locator('flt-semantics-placeholder');
    if (await semantics.count()) await semantics.evaluate(el => el.click());
    await page.getByRole('button', { name: 'Criar Conta', exact: true }).waitFor();
  };
  stage = 'load';
  await page.goto(origin, { waitUntil: 'networkidle', timeout: 45000 });
  await ready();
  stage = 'signup';
  await page.getByRole('button', { name: 'Criar Conta', exact: true }).click();
  await type('Nome de exibição', 'Browser Test'); await type('E-mail', email); await type('Senha', password);
  await page.getByRole('button', { name: 'Criar conta', exact: true }).click();
  await page.getByRole('textbox', { name: 'Código de verificação' }).waitFor({ timeout: 20000 });
  assert.ok(otp);
  stage = 'verify';
  await type('Código de verificação', otp);
  await page.getByRole('button', { name: 'Verificar e-mail' }).click();
  await page.getByRole('button', { name: 'Sair da conta' }).waitFor({ timeout: 20000 });
  // No token values are logged. Check actual browser acceptance, not a fake cookie jar.
  const cookies = await context.cookies();
  assert.ok(cookies.some(cookie => cookie.name === '__Host-vp_session' && cookie.httpOnly && cookie.secure));
  assert.ok(cookies.some(cookie => cookie.name === `__Host-vp_device_${uid}` && cookie.httpOnly));
  stage = 'restore';
  await page.reload({ waitUntil: 'networkidle' });
  await page.locator('flt-semantics-placeholder').evaluate(el => el.click());
  await page.getByRole('button', { name: 'Sair da conta' }).waitFor({ timeout: 20000 });
  stage = 'logout_login';
  await page.getByRole('button', { name: 'Sair da conta' }).click();
  await page.getByRole('button', { name: 'Entrar', exact: true }).click();
  await type('E-mail', email); await type('Senha', password);
  await page.getByRole('button', { name: 'Entrar', exact: true }).click();
  await page.getByRole('button', { name: 'Sair da conta' }).waitFor({ timeout: 20000 });
  assert.equal(sent, 1);
  assert.ok(statuses.every(status => status === 200));
  console.log('AUTH_BROWSER_E2E', JSON.stringify({ ok: true, signup: true, verify: true, restored: true, loginWithoutNewCode: true, browserCookies: true }));
} catch (error) {
  console.error('AUTH_BROWSER_E2E', JSON.stringify({ ok: false, stage, type: error.name, submitted }));
  process.exitCode = 1;
} finally {
  await browser?.close();
  await new Promise(resolve => server ? server.close(resolve) : resolve());
  if (uid) {
    const { error } = await admin.auth.admin.deleteUser(uid);
    if (error) { console.error('AUTH_BROWSER_E2E cleanup_failed'); process.exitCode = 1; }
  }
  await rm(scratch, { recursive: true, force: true });
}
