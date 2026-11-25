// Real browser against production, but intercept signup/login/OTP so no user
// is created or email delivered. Only read-only status reaches the real API.
import chromium from '@sparticuz/chromium';
import { chromium as playwright } from 'playwright-core';
let browser, stage = 'launch';
try {
  browser = await playwright.launch({ executablePath: await chromium.executablePath(), args: chromium.args, headless: true });
  const page = await browser.newPage({ viewport: { width: 440, height: 1100 }, reducedMotion: 'reduce' });
  const actions = [];
  page.on('response', response => {
    if (new URL(response.url()).pathname === '/api/auth') console.log('AUTH_BROWSER_API', response.status());
  });
  await page.route('**/api/auth', async route => {
    const body = route.request().postDataJSON();
    actions.push(body.action);
    if (body.action === 'status') return route.continue();
    const verified = body.action === 'verify' || body.action === 'login';
    return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({ verified, pending: body.action === 'signup', email: 'browser-test@example.invalid' }) });
  });
  stage = 'page_load';
  await page.goto('https://vantopay.vercel.app/#/login', { waitUntil: 'networkidle', timeout: 45000 });
  await page.locator('flt-semantics-placeholder').evaluate(el => el.click(), { timeout: 20000 });
  stage = 'open_signup';
  await page.getByRole('button', { name: 'Criar Conta', exact: true }).click({ timeout: 15000 });
  const type = async (name, value) => {
    await page.getByRole('textbox', { name, exact: true }).click();
    // Flutter's semantic textbox is a proxy, not the editing element. Send
    // real keyboard events after focus rather than modifying its DOM value.
    await page.keyboard.type(value, { delay: 25 });
  };
  stage = 'fill_signup';
  await type('Nome de exibição', 'Browser Test');
  await type('E-mail', 'browser-test@example.invalid');
  await type('Senha', 'TestPassword123!');
  stage = 'submit_signup';
  await page.getByRole('button', { name: 'Criar conta', exact: true }).click();
  await page.getByRole('textbox', { name: 'Código de verificação' }).waitFor({ timeout: 15000 });
  stage = 'submit_code';
  await type('Código de verificação', '123456');
  await page.getByRole('button', { name: 'Verificar e-mail' }).click();
  await page.getByRole('button', { name: 'Sair da conta' }).waitFor({ timeout: 15000 });
  console.log('AUTH_BROWSER', JSON.stringify({ ok: true, actions }));
} catch (error) {
  console.log('AUTH_BROWSER', JSON.stringify({ ok: false, stage, type: error.name }));
  // Print only visible semantic labels, never user data or request bodies.
  const page = browser?.contexts()[0]?.pages()[0];
  if (page) console.log('AUTH_BROWSER_LABELS', JSON.stringify((await page.locator('flt-semantics').allTextContents().catch(() => [])).slice(-15)));
} finally { await browser?.close(); }
