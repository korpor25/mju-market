// ล้างฐานข้อมูลให้เหลือแค่บัญชีแอดมิน
//
//   ลบ  : users (ยกเว้น KEEP), shops, products, requests, reviews, notifications, sales
//         รวมถึงบัญชี Firebase Auth ของ user ที่ถูกลบ
//   คง  : stalls (รีเซ็ตเป็นว่าง แต่เก็บ category / pricePerDay ไว้), banners
//   รีเซ็ต: แอดมิน -> shopId = null, status = active
//
// วิธีใช้:
//   node wipe.js           <- ดูอย่างเดียว ไม่ลบ (ค่าเริ่มต้น)
//   node wipe.js --apply   <- ลบจริง กู้คืนไม่ได้

const admin = require('firebase-admin');
const path = require('path');

admin.initializeApp({
  credential: admin.credential.cert(require(path.join(__dirname, 'serviceAccountKey.json'))),
});
const db = admin.firestore();
const auth = admin.auth();

const KEEP = new Set(['u-admin']);
const WIPE = ['shops', 'products', 'requests', 'reviews', 'notifications', 'sales'];
const apply = process.argv.includes('--apply');

async function deleteAll(name) {
  const snap = await db.collection(name).get();
  if (apply) {
    const docs = snap.docs;
    for (let i = 0; i < docs.length; i += 400) {
      const batch = db.batch();
      for (const d of docs.slice(i, i + 400)) batch.delete(d.ref);
      await batch.commit();
    }
  }
  console.log(`  ${apply ? 'ลบแล้ว' : 'จะลบ'} ${String(snap.size).padStart(3)}  ${name}`);
}

async function main() {
  console.log(apply ? '=== ลบจริง ===\n' : '=== dry run (ยังไม่ลบอะไร) ===\n');

  for (const c of WIPE) await deleteAll(c);

  // ผู้ใช้: เก็บเฉพาะ KEEP ทั้งใน Firestore และ Auth
  const users = await db.collection('users').get();
  for (const d of users.docs) {
    if (KEEP.has(d.id)) continue;
    console.log(`  ${apply ? 'ลบแล้ว' : 'จะลบ'}      user ${d.data().email || d.id}`);
    if (apply) {
      await d.ref.delete();
      try {
        await auth.deleteUser(d.id);
      } catch (e) {
        if (e.code !== 'auth/user-not-found') throw e;
      }
    }
  }

  // แผง: คงไว้แต่รีเซ็ตให้ว่าง — เก็บ category / pricePerDay ที่ตั้งไว้
  const stalls = await db.collection('stalls').get();
  if (apply) {
    for (let i = 0; i < stalls.docs.length; i += 400) {
      const batch = db.batch();
      for (const d of stalls.docs.slice(i, i + 400)) {
        batch.set(d.ref, { status: 'empty', shopName: null }, { merge: true });
      }
      await batch.commit();
    }
  }
  console.log(`  ${apply ? 'รีเซ็ตแล้ว' : 'จะรีเซ็ต'} ${stalls.size}  stalls (คง category/pricePerDay)`);

  // แอดมินต้องไม่ค้าง shopId ของร้านที่เพิ่งถูกลบ
  if (apply) {
    for (const uid of KEEP) {
      const ref = db.collection('users').doc(uid);
      if ((await ref.get()).exists) {
        await ref.update({ shopId: null, status: 'active' });
      }
    }
  }
  console.log(`  ${apply ? 'รีเซ็ตแล้ว' : 'จะรีเซ็ต'}      admin: shopId = null, status = active`);

  const banners = await db.collection('banners').get();
  console.log(`  คงไว้    ${String(banners.size).padStart(3)}  banners`);

  console.log(apply ? '\n✅ ล้างเสร็จแล้ว' : '\n📋 สั่ง  node wipe.js --apply  เพื่อลบจริง');
  process.exit(0);
}

main().catch((e) => {
  console.error('❌ ผิดพลาด:', e);
  process.exit(1);
});
