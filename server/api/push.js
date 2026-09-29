// ส่งการแจ้งเตือนที่แอปเพิ่งเขียนลง Firestore ต่อเข้า LINE OA
//
// แอปเรียกมาพร้อม Firebase ID token + รหัสเอกสารใน collection `notifications`
// ที่นี่ไม่รับ "ข้อความอิสระ" จากแอปเลย — อ่านหัวข้อ/เนื้อหาจากเอกสารจริงเท่านั้น
// ผู้ใช้ทั่วไปจึงยิงข้อความอะไรก็ได้เข้า LINE ในนามตลาดไม่ได้ (กฎ Firestore
// ยอมให้แอดมินเท่านั้นที่สร้างเอกสารแจ้งเตือน) และซ้ำก็ไม่ส่งซ้ำเพราะปั๊ม linePushed
import { db, auth, FieldValue } from '../lib/firebase.js';
import { pushText } from '../lib/line.js';
import { applyCors, json } from '../lib/http.js';

const APP_URL = process.env.APP_URL || 'https://maejo-market.web.app';

export default async function handler(req, res) {
  applyCors(req, res);
  if (req.method === 'OPTIONS') return res.status(204).end();
  if (req.method !== 'POST') return json(res, 405, { error: 'method not allowed' });

  const token = (req.headers.authorization || '').replace(/^Bearer\s+/i, '');
  if (!token) return json(res, 401, { error: 'missing token' });

  try {
    await auth().verifyIdToken(token);
  } catch {
    return json(res, 401, { error: 'invalid token' });
  }

  const body = typeof req.body === 'string' ? safeParse(req.body) : req.body || {};
  const notificationId = body.notificationId;
  if (!notificationId) return json(res, 400, { error: 'missing notificationId' });

  try {
    return json(res, 200, await deliver(String(notificationId)));
  } catch (e) {
    console.error('push failed', e?.message);
    return json(res, 500, { error: 'push failed' });
  }
}

async function deliver(notificationId) {
  const ref = db().collection('notifications').doc(notificationId);
  const snap = await ref.get();
  if (!snap.exists) return { sent: false, reason: 'not-found' };

  const n = snap.data();
  if (n.linePushed) return { sent: false, reason: 'already-pushed' };

  const userSnap = await db().collection('users').doc(String(n.uid || '')).get();
  const lineUserId = userSnap.exists ? userSnap.data().lineUserId : null;

  // ยังไม่ได้ผูกไลน์ก็ไม่ใช่ความผิดพลาด — ปั๊มไว้ไม่ให้ลองซ้ำเรื่อย ๆ
  if (!lineUserId) {
    await ref.update({ linePushed: true, lineSkipped: 'not-linked' });
    return { sent: false, reason: 'not-linked' };
  }

  const parts = [n.title || 'แจ้งเตือนจากตลาดแม่โจ้'];
  if (n.body) parts.push('', n.body);
  parts.push('', APP_URL);

  await pushText(lineUserId, parts.join('\n'));
  await ref.update({ linePushed: true, linePushedAt: FieldValue.serverTimestamp() });
  return { sent: true };
}

function safeParse(s) {
  try {
    return JSON.parse(s);
  } catch {
    return {};
  }
}
