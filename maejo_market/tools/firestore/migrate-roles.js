// เพิ่มฟิลด์ roles / activeRole ให้เอกสารผู้ใช้เดิมที่มีแต่ role เดี่ยว
//
// ต้องรันก่อน (หรือพร้อมกับ) การ deploy firestore.rules ชุดใหม่
// rules ชุดใหม่รับทั้งสองแบบอยู่แล้ว การ migrate จึงไม่ทำให้ใครหลุดสิทธิ์
//
// วิธีใช้:
//   node migrate-roles.js           ← ดูอย่างเดียว ไม่แก้ข้อมูล (ค่าเริ่มต้น)
//   node migrate-roles.js --apply   ← เขียนจริง
//
// ให้สิทธิ์หลายบทบาทกับคนใดคนหนึ่ง:
//   node migrate-roles.js --apply --grant admin@maejo.com=admin,seller
//
// ต้องมีไฟล์ serviceAccountKey.json ในโฟลเดอร์นี้

const admin = require('firebase-admin');
const path = require('path');

admin.initializeApp({
  credential: admin.credential.cert(require(path.join(__dirname, 'serviceAccountKey.json'))),
});
const db = admin.firestore();

const RANK = { admin: 3, seller: 2, buyer: 1 };
const VALID = Object.keys(RANK);

const apply = process.argv.includes('--apply');

// --grant email=role1,role2   (ระบุซ้ำได้หลายครั้ง)
// รองรับทั้ง  --grant a@b.com=admin,seller  และ  --grant=a@b.com=admin,seller
const grants = new Map();
for (let i = 0; i < process.argv.length; i++) {
  const arg = process.argv[i];
  let raw = null;
  if (arg === '--grant') raw = process.argv[i + 1];
  else if (arg.startsWith('--grant=')) raw = arg.slice('--grant='.length);
  if (!raw) continue;

  const eq = raw.indexOf('=');
  if (eq < 0) continue;
  const email = raw.slice(0, eq).trim().toLowerCase();
  const roles = raw
    .slice(eq + 1)
    .split(',')
    .map((r) => r.trim())
    .filter((r) => VALID.includes(r));
  if (email && roles.length) grants.set(email, roles);
}

function primaryOf(roles) {
  return roles.reduce((a, b) => ((RANK[a] ?? 0) >= (RANK[b] ?? 0) ? a : b));
}

async function main() {
  const snap = await db.collection('users').get();
  console.log(`พบผู้ใช้ ${snap.size} คน${apply ? '' : '  (dry run — ยังไม่เขียนอะไร)'}\n`);

  let changed = 0;
  let skipped = 0;

  for (const doc of snap.docs) {
    const d = doc.data();
    const email = (d.email || '').toLowerCase();
    const legacy = VALID.includes(d.role) ? d.role : 'buyer';

    // ถ้าสั่ง grant ไว้ ใช้ตามนั้น ไม่งั้นแปลง role เดี่ยวเป็น array
    const existing = Array.isArray(d.roles) ? d.roles.filter((r) => VALID.includes(r)) : [];
    let roles = grants.get(email) ?? (existing.length ? existing : [legacy]);
    roles = [...new Set(roles)];

    const primary = primaryOf(roles);
    const activeRole =
      VALID.includes(d.activeRole) && roles.includes(d.activeRole) ? d.activeRole : primary;

    const same =
      existing.length === roles.length &&
      existing.every((r) => roles.includes(r)) &&
      d.role === primary &&
      d.activeRole === activeRole;

    if (same) {
      skipped++;
      continue;
    }

    console.log(
      `  ${email || doc.id}\n` +
        `    role      : ${d.role ?? '-'}  ->  ${primary}\n` +
        `    roles     : ${existing.length ? existing.join(', ') : '(ไม่มี)'}  ->  ${roles.join(', ')}\n` +
        `    activeRole: ${d.activeRole ?? '(ไม่มี)'}  ->  ${activeRole}`,
    );

    if (apply) {
      await doc.ref.update({ role: primary, roles, activeRole });
    }
    changed++;
  }

  console.log(
    `\n${apply ? '✅ อัปเดตแล้ว' : '📋 จะอัปเดต'} ${changed} คน · ไม่ต้องแก้ ${skipped} คน`,
  );
  if (!apply && changed > 0) {
    console.log('   สั่ง  node migrate-roles.js --apply  เพื่อเขียนจริง');
  }
  process.exit(0);
}

main().catch((e) => {
  console.error('❌ ผิดพลาด:', e);
  process.exit(1);
});
