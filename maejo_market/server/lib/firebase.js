// เข้าถึง Firestore/Auth ด้วยสิทธิ์ service account
// ใช้สิทธิ์ระดับ admin จึงข้าม security rules ได้ — ทุก handler ต้องตรวจสิทธิ์ผู้เรียกเอง
import { initializeApp, getApps, cert } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';

function ensureApp() {
  const existing = getApps();
  if (existing.length) return existing[0];

  const raw = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!raw) throw new Error('ยังไม่ได้ตั้ง env FIREBASE_SERVICE_ACCOUNT');

  // รับได้ทั้ง JSON ตรง ๆ และ base64 — วาง JSON หลายบรรทัดในหน้า Vercel มักเพี้ยน
  // จึงแนะนำ base64 แต่ยังรองรับแบบดิบไว้เพื่อทดสอบในเครื่อง
  const text = raw.trim().startsWith('{')
    ? raw
    : Buffer.from(raw, 'base64').toString('utf8');

  return initializeApp({ credential: cert(JSON.parse(text)) });
}

export const db = () => getFirestore(ensureApp());
export const auth = () => getAuth(ensureApp());
export { FieldValue };
