// Webhook ของ LINE OA — ทำสองอย่าง
//
// 1) ตอบคำถามเรื่องตลาด (โปรโมชั่น / แผงว่าง / ร้านค้า / มีของชิ้นนี้ขายไหม)
//    ตอบจากข้อมูลจริงใน Firestore ชุดเดียวกับที่แอปใช้ — ถามได้โดยไม่ต้องลงทะเบียนแอป
//
// 2) ผูกบัญชีแอปเข้ากับ LINE เพื่อรับแจ้งเตือน
//    ผู้ใช้กด "เชื่อมต่อ LINE" ในแอป -> แอปสร้างรหัส 6 หลักเก็บใน lineLinks/{code}
//    ผู้ใช้แอดเพื่อน OA แล้วพิมพ์รหัสส่งมา -> ที่นี่จับคู่แล้วเขียน lineUserId ลง users/{uid}
//    จากนั้น /api/push จะรู้ว่าต้องส่งแจ้งเตือนไปหา LINE บัญชีไหน
import { db, FieldValue } from '../../lib/firebase.js';
import { verifySignature, replyText, quickReply, fetchProfile } from '../../lib/line.js';
import { readRawBody } from '../../lib/http.js';
import {
  promotions,
  freeStalls,
  shopDirectory,
  searchItems,
  extractKeyword,
} from '../../lib/market.js';

const APP_URL = process.env.APP_URL || 'https://maejo-market.web.app';

/// ปุ่มลัดติดไปกับทุกคำตอบ ผู้ใช้จะได้ไม่ต้องเดาว่าถามอะไรได้บ้าง
const MENU = quickReply(['โปรโมชั่น', 'แผงว่าง', 'ร้านค้า', 'วิธีใช้']);

const HELP = [
  'ถามตลาดแม่โจ้ได้เลย 🌿',
  '',
  '• "โปรโมชั่น" — โปรโมชั่นที่มีตอนนี้',
  '• "แผงว่าง" — เหลือกี่แผง เช่าวันละเท่าไหร่',
  '• "ร้านค้า" — ในตลาดมีร้านอะไรบ้าง',
  '• พิมพ์ชื่อของที่อยากได้ เช่น "มีผักกาดขายมั้ย"',
  '',
  'อยากรับแจ้งเตือนเรื่องร้าน แผง และค่าเช่า:',
  'พิมพ์รหัส 6 หลักจากแอป (โปรไฟล์ > เชื่อมต่อ LINE)',
  'พิมพ์ "ยกเลิก" เพื่อหยุดรับแจ้งเตือน',
  '',
  APP_URL,
].join('\n');

const WELCOME = ['ยินดีต้อนรับสู่ตลาดแม่โจ้ 🌿', '', HELP].join('\n');

/// จับใจความคำถาม — ตรวจก่อนรหัสผูกบัญชีเสมอ เพราะคำถามภาษาไทยไม่มีทางเป็นรหัส A-Z0-9
const INTENTS = [
  [/โปรโม|ลดราคา|ส่วนลด|ของถูก|promotion|promo|มีโปร|โปรอะไร|^โปร$/i, promotions],
  [/แผงว่าง|ว่างกี่|เช่าแผง|จองแผง|ขอแผง|อยากขาย|เปิดร้าน|ค่าเช่า/i, freeStalls],
  [/^(ร้านค้า|ร้าน|ร้านทั้งหมด|หมวด|สินค้า)$|มีร้านอะไร|ร้านอะไรบ้าง|ร้านค้าทั้งหมด/i, shopDirectory],
];

const HELP_RE = /^(วิธีใช้|ช่วยเหลือ|เมนู|help|hi|hello|สวัสดี|ทำอะไรได้|ถามอะไรได้)/i;

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
    return replyText(ev.replyToken, WELCOME, MENU);
  }

  if (ev.type === 'unfollow') {
    // บล็อก/ลบเพื่อน = ส่งไปก็ไม่ถึง ตัดการผูกทิ้งเพื่อไม่ให้ push ค้าง
    if (lineUserId) await unlinkByLineUserId(lineUserId);
    return;
  }

  if (ev.type !== 'message' || ev.message?.type !== 'text') return;

  const text = (ev.message.text || '').trim();
  return replyText(ev.replyToken, await answer(text, lineUserId), MENU);
}

/// เลือกคำตอบให้ข้อความหนึ่งข้อความ — คืนข้อความล้วน (ผู้เรียกเป็นคนส่ง)
/// export ไว้ให้เทสต์เรียกตรงได้โดยไม่ต้องปลอมลายเซ็น LINE
export async function answer(text, lineUserId) {
  if (/^(ยกเลิก|เลิกรับ|unlink|stop)$/i.test(text)) {
    const removed = lineUserId ? await unlinkByLineUserId(lineUserId) : 0;
    return removed
      ? 'ยกเลิกการรับแจ้งเตือนแล้ว ถ้าอยากกลับมารับอีกครั้ง ส่งรหัสจากแอปมาได้เลย'
      : 'บัญชีนี้ยังไม่ได้เชื่อมกับแอปอยู่แล้ว';
  }

  if (HELP_RE.test(text)) return HELP;

  for (const [re, run] of INTENTS) {
    if (!re.test(text)) continue;
    return withFallback(run());
  }

  const code = text.toUpperCase().replace(/[\s-]/g, '');
  if (/^[A-Z0-9]{6}$/.test(code)) return redeemCode(code, lineUserId);

  // เหลือจากนั้นถือว่าถามหาของ เช่น "มีผักกาดขายมั้ย" -> ค้นจากสินค้าที่ร้านลงไว้
  const keyword = extractKeyword(text);
  if (keyword.length >= 2) return withFallback(searchItems(keyword));

  return HELP;
}

/// ถามข้อมูลแล้วพังไม่ควรทำให้ผู้ใช้เจอความเงียบ — ตอบให้รู้ว่าเกิดอะไรขึ้น
async function withFallback(promise) {
  try {
    return await promise;
  } catch (e) {
    console.error('answer failed', e?.message);
    return `ตอนนี้ดึงข้อมูลตลาดไม่ได้ ลองใหม่อีกครั้งในอีกสักครู่นะ 🙏\n${APP_URL}`;
  }
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
