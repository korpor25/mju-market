// ล้างข้อมูลตัวอย่างออกจาก Firestore (ลบถาวร)
//   - ลบทั้งหมด: shops, products, requests
//   - รีเซ็ต stalls ให้ว่างหมด (คงตาราง A-D 1..5 ไว้)
//   - ลบบัญชีทดลอง seller/buyer (เก็บ admin)
//
// วิธีใช้:  node clear.js
// ต้องมีไฟล์ serviceAccountKey.json ในโฟลเดอร์นี้

const admin = require('firebase-admin');
const path = require('path');

admin.initializeApp({
  credential: admin.credential.cert(require(path.join(__dirname, 'serviceAccountKey.json'))),
});

const db = admin.firestore();
const auth = admin.auth();

async function deleteCollection(name) {
  const snap = await db.collection(name).get();
  let n = 0;
  // ลบทีละ batch (สูงสุด 500 ต่อ batch)
  const docs = snap.docs;
  for (let i = 0; i < docs.length; i += 400) {
    const batch = db.batch();
    for (const d of docs.slice(i, i + 400)) batch.delete(d.ref);
    await batch.commit();
    n += Math.min(400, docs.length - i);
  }
  return n;
}

async function resetStalls() {
  const zones = { A: 5, B: 5, C: 5, D: 5 };
  const batch = db.batch();
  let n = 0;
  for (const [z, count] of Object.entries(zones)) {
    for (let i = 1; i <= count; i++) {
      const id = `${z}-${i}`;
      batch.set(db.collection('stalls').doc(id), {
        zone: z,
        status: 'empty',
        shopName: null,
      });
      n++;
    }
  }
  await batch.commit();
  return n;
}

async function deleteAccount(uid, email) {
  try {
    await auth.deleteUser(uid);
    console.log(`  - ลบ auth: ${email}`);
  } catch (e) {
    if (e.code === 'auth/user-not-found') {
      console.log(`  · ไม่พบ auth: ${email} (ข้าม)`);
    } else {
      throw e;
    }
  }
  await db.collection('users').doc(uid).delete();
}

async function main() {
  console.log('▶ ลบร้านค้า...');
  console.log(`  ลบ shops: ${await deleteCollection('shops')} รายการ`);
  console.log('▶ ลบสินค้า...');
  console.log(`  ลบ products: ${await deleteCollection('products')} รายการ`);
  console.log('▶ ลบคำขอ...');
  console.log(`  ลบ requests: ${await deleteCollection('requests')} รายการ`);
  console.log('▶ รีเซ็ตแผงให้ว่างหมด...');
  console.log(`  รีเซ็ต stalls: ${await resetStalls()} แผง (ว่างทั้งหมด)`);
  console.log('▶ ลบบัญชีทดลอง seller/buyer (เก็บ admin)...');
  await deleteAccount('u-seller', 'seller@maejo.com');
  await deleteAccount('u-buyer', 'buyer@maejo.com');

  console.log('\n✅ ล้างข้อมูลตัวอย่างเรียบร้อย!');
  console.log('   เหลือบัญชีเดียว: admin@maejo.com (รหัส 123456)');
  console.log('   ระบบพร้อมใช้กับข้อมูลจริง — สมัครสมาชิก/เปิดร้านได้เลย');
  process.exit(0);
}

main().catch((e) => { console.error('❌ ผิดพลาด:', e); process.exit(1); });
