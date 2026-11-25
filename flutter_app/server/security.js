import { randomBytes, randomInt, createHmac, createHash, createCipheriv, createDecipheriv } from 'node:crypto';
export const randomToken = () => randomBytes(32).toString('base64url');
export const randomCode = () => randomInt(0, 1000000).toString().padStart(6, '0');
export const digest = value => createHmac('sha256', process.env.OTP_PEPPER).update(value).digest('hex');
const key = () => createHash('sha256').update(process.env.OTP_PEPPER).digest();
export function seal(data, ttl) {
  const iv = randomBytes(12);
  const cipher = createCipheriv('aes-256-gcm', key(), iv);
  const encrypted = Buffer.concat([cipher.update(JSON.stringify({ ...data, exp: Date.now() + ttl * 1000 })), cipher.final()]);
  return Buffer.concat([iv, cipher.getAuthTag(), encrypted]).toString('base64url');
}
export function unseal(value) {
  try {
    const bytes = Buffer.from(value || '', 'base64url');
    const decipher = createDecipheriv('aes-256-gcm', key(), bytes.subarray(0, 12));
    decipher.setAuthTag(bytes.subarray(12, 28));
    const data = JSON.parse(Buffer.concat([decipher.update(bytes.subarray(28)), decipher.final()]));
    return data.exp > Date.now() ? data : null;
  } catch { return null; }
}
export function sameOrigin(req) {
  // No CORS; all browser requests must originate on this deployment.
  return req.headers.origin === `https://${req.headers.host}` &&
    req.headers['content-type']?.split(';')[0] === 'application/json';
}
