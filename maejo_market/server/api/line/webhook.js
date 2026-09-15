// Webhook ของ LINE OA — ใช้ "ผูกบัญชีแอปเข้ากับ LINE" เป็นหลัก
//
// ผู้ใช้กด "เชื่อมต่อ LINE" ในแอป -> แอปสร้างรหัส 6 หลักเก็บใน lineLinks/{code}
// ผู้ใช้แอดเพื่อน OA แล้วพิมพ์รหัสส่งมา -> ที่นี่จับคู่แล้วเขียน lineUserId ลง users/{uid}
// จากนั้น /api/push จะรู้ว่าต้องส่งแจ้งเตือนไปหา LINE บัญชีไหน
import { db, FieldValue } from '../../lib/firebase.js';
import { verifySignature, replyText, fetchProfile } from '../../lib/line.js';
import { readRawBody } from '../../lib/http.js';

const APP_URL = process.env.APP_URL || 'https://maejo-market.web.app';

const HELP = [
  'พิมพ์ "รหัส 6 หลัก" ที่ได้จากแอป Maejo Market เพื่อรับแจ้งเตือนทางไลน์',
  '',
  'วิธีเอารหัส: เปิดแอป > โปรไฟล์ > เชื่อมต่อ LINE',
  APP_URL,
  '',
  'พิมพ์ "ยกเลิก" เพื่อหยุดรับแจ้งเตือน',
].join('\n');

const WELCOME = [
  'ยินดีต้อนรับสู่ตลาดแม่โจ้ 🌿',
  '',
  'เชื่อมบัญชีเพื่อรับแจ้งเตือนเรื่องร้าน แผง และค่าเช่าได้ที่นี่',
  '',
  HELP,
].join('\n');

export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).end();

  const raw = await readRawBody(req);
  if (!verifySignature(raw, req.headers['x-line-signature'])) {
    // ปุ่ม Verify ใน LINE console ก็เซ็นลายเซ็นมาถูกต้อง (events ว่าง) จึงผ่านด้านล่างได้
    // ที่ตกตรงนี้คือไม่ได้มาจาก LINE หรือ LINE_CHANNEL_SECRET ตั้งผิด
    return res.status(403).end();
  }

  let events = [];
  try {
    events = JSON.parse(raw || '{}').events || [];
  } catch {
    return res.status(200).end();
  }

  // ตอบ 200 ให้ LINE ก่อนเสมอ ไม่งั้น LINE จะ retry ซ้ำ
  // งานที่เหลือทำต่อจนจบใน invocation เดียวกัน (ไม่ยาวพอให้ timeout)
  for (const ev of events) {
    try {
      await handleEvent(ev);
    } catch (e) {
      console.error('line event failed', ev?.type, e?.message);
    }
  }
  return res.status(200).json({ ok: true });
}

async function handleEvent(ev) {
  const lineUserId = ev?.source?.userId;

  if (ev.type === 'follow') {
    return replyText(ev.replyToken, WELCOME);
  }

  if (ev.type === 'unfollow') {
    // บล็อก/ลบเพื่อน = ส่งไปก็ไม่ถึง ตัดการผูกทิ้งเพื่อไม่ให้ push ค้าง
    if (lineUserId) await unlinkByLineUserId(lineUserId);
    return;
  }

  if (ev.type !== 'message' || ev.message?.type !== 'text') return;

  const text = (ev.message.text || '').trim();

  if (/^(ยกเลิก|เลิกรับ|unlink|stop)$/i.test(text)) {
    const removed = lineUserId ? await unlinkByLineUserId(lineUserId) : 0;
    return replyText(
      ev.replyToken,
      removed
        ? 'ยกเลิกการรับแจ้งเตือนแล้ว ถ้าอยากกลับมารับอีกครั้ง ส่งรหัสจากแอปมาได้เลย'
        : 'บัญชีนี้ยังไม่ได้เชื่อมกับแอปอยู่แล้ว',
    );
  }

  const code = text.toUpperCase().replace(/[\s-]/g, '');
  if (/^[A-Z0-9]{6}$/.test(code)) {
    return replyText(ev.replyToken, await redeemCode(code, lineUserId));
  }

  return replyText(ev.replyToken, HELP);
}

/// ใช้รหัสผูกบัญชี — คืนข้อความที่จะตอบกลับผู้ใช้
async function redeemCode(code, lineUserId) {
  if (!lineUserId) return 'ไม่สามารถอ่านบัญชีไลน์ของคุณได้ ลองใหม่อีกครั้ง';

  const ref = db().collection('lineLinks').doc(code);
  const snap = await ref.get();
  if (!snap.exists) return `ไม่พบรหัส ${code} — ตรวจตัวอักษรอีกครั้ง หรือขอรหัสใหม่ในแอป`;

  const link = snap.data();
  if (link.usedAt) return 'รหัสนี้ถูกใช้ไปแล้ว กรุณาขอรหัสใหม่ในแอป';
  if (typeof link.expiresAt === 'number' && Date.now() > link.expiresAt) {
    return 'รหัสหมดอายุแล้ว (รหัสมีอายุ 15 นาที) กรุณาขอรหัสใหม่ในแอป';
  }

  const uid = link.uid;
  if (!uid) return 'ข้อมูลรหัสไม่สมบูรณ์ กรุณาขอรหัสใหม่ในแอป';

  const userRef = db().collection('users').doc(uid);
  const userSnap = await userRef.get();
  if (!userSnap.exists) return 'ไม่พบบัญชีผู้ใช้ กรุณาขอรหัสใหม่ในแอป';

  // บัญชีไลน์หนึ่งผูกได้กับผู้ใช้คนเดียว — ตัดของเดิมออกก่อนกันแจ้งเตือนไปผิดคน
  await unlinkByLineUserId(lineUserId, uid);

  const profile = await fetchProfile(lineUserId);
  await userRef.update({
    lineUserId,
    lineDisplayName: profile?.displayName ?? null,
    lineLinkedAt: FieldValue.serverTimestamp(),
  });
  await ref.update({ usedAt: FieldValue.serverTimestamp(), lineUserId });

  const name = userSnap.data()?.name || '';
  return `เชื่อมต่อสำเร็จ ✅${name ? `\nบัญชี: ${name}` : ''}\n\nจากนี้ตลาดแม่โจ้จะแจ้งเตือนเรื่องร้าน แผง และค่าเช่ามาที่นี่`;
}

/// ล้าง lineUserId ออกจากทุกบัญชีที่ผูกไว้ (ยกเว้น exceptUid) — คืนจำนวนที่ล้าง
async function unlinkByLineUserId(lineUserId, exceptUid = null) {
  const snap = await db().collection('users').where('lineUserId', '==', lineUserId).get();
  let n = 0;
  for (const doc of snap.docs) {
    if (doc.id === exceptUid) continue;
    await doc.ref.update({
      lineUserId: FieldValue.delete(),
      lineDisplayName: FieldValue.delete(),
      lineLinkedAt: FieldValue.delete(),
    });
    n++;
  }
  return n;
}
