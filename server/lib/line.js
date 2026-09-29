// เรียก LINE Messaging API + ตรวจลายเซ็น webhook
import crypto from 'node:crypto';

const API = 'https://api.line.me/v2/bot';

/// ตรวจว่า request มาจาก LINE จริง — เทียบ HMAC-SHA256 ของ "บอดี้ดิบ"
/// ต้องใช้ไบต์ดิบเท่านั้น ถ้า JSON.parse แล้ว stringify ใหม่ ลายเซ็นจะไม่ตรง
export function verifySignature(rawBody, signature) {
  const secret = process.env.LINE_CHANNEL_SECRET;
  if (!secret || !signature) return false;
  const expected = crypto.createHmac('sha256', secret).update(rawBody).digest('base64');
  const a = Buffer.from(expected);
  const b = Buffer.from(String(signature));
  return a.length === b.length && crypto.timingSafeEqual(a, b);
}

async function call(path, payload) {
  const token = process.env.LINE_CHANNEL_ACCESS_TOKEN;
  if (!token) throw new Error('ยังไม่ได้ตั้ง env LINE_CHANNEL_ACCESS_TOKEN');

  const res = await fetch(API + path, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
    body: JSON.stringify(payload),
  });

  if (!res.ok) {
    const detail = await res.text().catch(() => '');
    throw new Error(`LINE ${path} ${res.status}: ${detail}`);
  }
  return res;
}

export const replyText = (replyToken, text, quickReply) =>
  call('/message/reply', {
    replyToken,
    messages: [{ type: 'text', text, ...(quickReply ? { quickReply } : {}) }],
  });

/// ปุ่มลัดใต้ช่องพิมพ์ — ผู้ใช้กดถามต่อได้โดยไม่ต้องจำว่าถามอะไรได้บ้าง
/// LINE จำกัดป้ายไว้ 20 ตัวอักษร และไม่เกิน 13 ปุ่ม
export const quickReply = (labels) => ({
  items: labels.slice(0, 13).map((label) => ({
    type: 'action',
    action: { type: 'message', label: label.slice(0, 20), text: label },
  })),
});

export const pushText = (to, text) =>
  call('/message/push', { to, messages: [{ type: 'text', text }] });

/// ชื่อโปรไฟล์ผู้ใช้ — เก็บไว้ให้แอดมินดูออกว่าบัญชีไหนผูกกับใคร (ล้มเหลวได้ ไม่ critical)
export async function fetchProfile(userId) {
  const token = process.env.LINE_CHANNEL_ACCESS_TOKEN;
  if (!token) return null;
  try {
    const res = await fetch(`${API}/profile/${userId}`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    return res.ok ? await res.json() : null;
  } catch {
    return null;
  }
}
