// Seed ข้อมูลเริ่มต้นเข้า Firestore + สร้างบัญชีทดลอง (admin/seller/buyer)
//
// วิธีใช้:
//   1) ดาวน์โหลด service account key จาก Firebase Console
//      Project settings > Service accounts > Generate new private key
//      แล้วบันทึกเป็นไฟล์ชื่อ  serviceAccountKey.json  ในโฟลเดอร์นี้
//   2) npm install
//   3) npm run seed
//
// รันซ้ำได้ (idempotent) — ใช้ set/merge และอัปเดตรหัสผ่านบัญชีเดิม

const admin = require('firebase-admin');
const path = require('path');

const serviceAccount = require(path.join(__dirname, 'serviceAccountKey.json'));
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

const db = admin.firestore();
const auth = admin.auth();

// ---------------- บัญชีทดลอง ----------------
const accounts = [
  // เจ้าของตลาดที่เป็นแม่ค้าในตลาดด้วย — ตัวอย่างผู้ใช้หลายบทบาท
  { uid: 'u-admin',  email: 'admin@maejo.com',  password: '123456',
    name: 'คุณสมชาย ผู้จัดการ', phone: '081-000-0000', role: 'admin',
    roles: ['admin', 'seller'], status: 'active', shopId: null },
  { uid: 'u-seller', email: 'seller@maejo.com', password: '123456',
    name: 'ณิชชา ใจดี',        phone: '089-111-2222', role: 'seller', status: 'active', shopId: 's1' },
  { uid: 'u-buyer',  email: 'buyer@maejo.com',  password: '123456',
    name: 'คุณผู้ซื้อ ทดลอง',   phone: '086-333-4444', role: 'buyer',  status: 'active', shopId: null },
];

// ---------------- ร้านค้า ----------------
// s1 ผูกกับบัญชีผู้ขายทดลอง (u-seller) เพื่อให้ล็อกอินแล้วเห็นร้านของตัวเอง
const shops = {
  s1: { name: 'ร้านป้าจันทร์ อาหารเหนือ', category: 'อาหาร',       ownerName: 'ณิชชา ใจดี', ownerUid: 'u-seller', stallId: 'A-2',  zone: 'A', status: 'open', payStatus: 'ok',  rating: 4.8, reviews: 125 },
  s2: { name: 'สวนผักป้านวล',            category: 'ผักสด',        ownerName: 'ป้านวล',    ownerUid: '', stallId: 'A-14', zone: 'A', status: 'open', payStatus: 'ok',  rating: 4.9, reviews: 88 },
  s3: { name: 'สวนมะม่วงลุงคำ',          category: 'ผลไม้',        ownerName: 'ลุงคำ',     ownerUid: '', stallId: 'B-3',  zone: 'B', status: 'open', payStatus: 'ok',  rating: 4.7, reviews: 64 },
  s4: { name: 'ครัวข้าวซอยแม่โจ้',        category: 'อาหาร',       ownerName: 'ศรีนวล',    ownerUid: '', stallId: 'C-11', zone: 'C', status: 'open', payStatus: 'due', rating: 4.6, reviews: 52 },
  s5: { name: 'ปลาสดน้องหมวย',          category: 'ประมง',        ownerName: 'สมพร',      ownerUid: '', stallId: 'D-7',  zone: 'D', status: 'open', payStatus: 'bad', rating: 4.5, reviews: 40 },
  s6: { name: 'กาแฟดอยแม่โจ้',           category: 'เครื่องดื่ม',   ownerName: 'วิภา ดอยคำ', ownerUid: '', stallId: 'C-3',  zone: 'C', status: 'open', payStatus: 'ok',  rating: 4.7, reviews: 73 },
  s7: { name: 'สวนผักปลอดสารแม่โจ้',      category: 'ผัก / ผลไม้',  ownerName: 'บุญมา',     ownerUid: '', stallId: 'B-1',  zone: 'B', status: 'open', payStatus: 'ok',  rating: 4.6, reviews: 45 },
};

// ---------------- สินค้า/เมนู (docId ตายตัว → รันซ้ำได้) ----------------
const products = {
  's1-p1': { shopId: 's1', name: 'ข้าวซอยไก่',       price: 60, available: true },
  's1-p2': { shopId: 's1', name: 'น้ำพริกหนุ่ม',      price: 35, available: true },
  's1-p3': { shopId: 's1', name: 'ไส้อั่ว',           price: 40, available: false },
  's2-p1': { shopId: 's2', name: 'ผักกาดขาว (กำ)',    price: 20, available: true },
  's2-p2': { shopId: 's2', name: 'คะน้า (กำ)',        price: 25, available: true },
  's3-p1': { shopId: 's3', name: 'มะม่วงน้ำดอกไม้ (กก.)', price: 80, available: true },
  's3-p2': { shopId: 's3', name: 'มะม่วงเขียวเสวย (กก.)', price: 70, available: true },
  's4-p1': { shopId: 's4', name: 'ข้าวซอยเนื้อ',      price: 65, available: true },
  's4-p2': { shopId: 's4', name: 'ขนมจีนน้ำเงี้ยว',   price: 45, available: true },
  's6-p1': { shopId: 's6', name: 'อเมริกาโน่',        price: 45, available: true },
  's6-p2': { shopId: 's6', name: 'ลาเต้',             price: 50, available: true },
  's6-p3': { shopId: 's6', name: 'เอสเพรสโซ่',        price: 40, available: true },
};

// ---------------- คำขอ ----------------
const requests = {
  r1: { type: 'sellerApply', title: 'ร้านกาแฟดอยแม่โจ้',           subtitle: 'แผง B-09 · โซนเครื่องดื่ม',        amount: '฿1,500/เดือน', requesterName: 'วิภา ดอยคำ',  status: 'pending' },
  r2: { type: 'payment',     title: 'สวนผักป้านวล · A-14',        subtitle: 'พร้อมเพย์ 8:02 น. · #PP-88214',   amount: '฿1,500',       requesterName: 'ป้านวล',      status: 'pending' },
  r3: { type: 'move',        title: 'ปลาสดน้องหมวย · D-07 → D-13', subtitle: 'เหตุผล: ใกล้ทางเข้าโซนประมง',      amount: '—',            requesterName: 'สมพร',       status: 'pending' },
  r4: { type: 'booking',     title: 'ร้านต้นกล้าอินทรีย์',          subtitle: 'ขอจองแผง C-23 · โซนอาหาร',         amount: '฿150/วัน',     requesterName: 'ธนา เขียวขจี', status: 'pending' },
  r5: { type: 'close',       title: 'ของทอดเจ๊แดง · C-05',        subtitle: 'ขอปิดร้านชั่วคราว 1–15 ส.ค.',      amount: '15 วัน',       requesterName: 'เจ๊แดง',      status: 'pending' },
};

// ---------------- แผง ----------------
function buildStalls() {
  const zones = { A: 5, B: 5, C: 5, D: 5 };
  const occupied = {
    'A-1': 'สลัดผักดอยแม่โจ้', 'A-2': 'ร้านป้าจันทร์', 'A-3': 'ข้าวอินทรีย์ดอยคำ',
    'B-1': 'สวนผักปลอดสาร', 'B-2': 'สวนมะม่วงลุงคำ', 'B-4': 'ส้มสายน้ำผึ้ง',
    'C-1': 'ครัวข้าวซอย', 'C-3': 'กาแฟดอยแม่โจ้',
    'D-1': 'ปลาสดน้องหมวย', 'D-2': 'หมูสดฟาร์มแม่โจ้',
  };
  const due = new Set(['A-5', 'B-5', 'C-2']);
  const closed = new Set(['C-5', 'B-3']);

  // หมวดประจำแผง — กำหนดรายแผง โซนหนึ่งจึงมีได้หลายหมวด
  // ต้องตรงกับ DemoData.categories ในแอป
  const category = {
    'A-1': 'ผัก / ผลไม้', 'A-2': 'อาหาร', 'A-3': 'ของแห้ง',
    'A-4': 'ผัก / ผลไม้', 'A-5': 'ของแห้ง',
    'B-1': 'ผัก / ผลไม้', 'B-2': 'ผัก / ผลไม้', 'B-3': 'ผัก / ผลไม้',
    'B-4': 'ผัก / ผลไม้', 'B-5': 'ของใช้',
    'C-1': 'อาหาร', 'C-2': 'อาหาร', 'C-3': 'เครื่องดื่ม',
    'C-4': 'เครื่องดื่ม', 'C-5': 'อาหาร',
    'D-1': 'ประมง', 'D-2': 'ประมง', 'D-3': 'ประมง',
    'D-4': 'ของใช้', 'D-5': 'ของแห้ง',
  };

  // ค่าเช่าฐานต่อวัน (บาท) ตามหมวด — หมวดที่ขายดีกว่าคิดแพงกว่า
  const basePrice = {
    'อาหาร': 220, 'เครื่องดื่ม': 200, 'ประมง': 180,
    'ผัก / ผลไม้': 150, 'ของแห้ง': 130, 'ของใช้': 120,
  };

  const out = {};
  for (const [z, n] of Object.entries(zones)) {
    for (let i = 1; i <= n; i++) {
      const id = `${z}-${i}`;
      let status = 'empty';
      if (occupied[id]) status = 'occupied';
      else if (due.has(id)) status = 'due';
      else if (closed.has(id)) status = 'closed';
      const cat = category[id] ?? '';
      const base = basePrice[cat] ?? 150;
      out[id] = {
        zone: z,
        status,
        shopName: occupied[id] ?? null,
        category: cat,
        // แผงเลข 1-2 อยู่ติดทางเข้าตลาด คนเดินผ่านเยอะกว่า จึงบวกเพิ่ม
        pricePerDay: i <= 2 ? base + 30 : base,
      };
    }
  }
  return out;
}

async function upsertAccount(a) {
  try {
    await auth.createUser({ uid: a.uid, email: a.email, password: a.password, displayName: a.name });
    console.log(`  + auth สร้างใหม่: ${a.email}`);
  } catch (e) {
    if (e.code === 'auth/uid-already-exists' || e.code === 'auth/email-already-exists') {
      await auth.updateUser(a.uid, { email: a.email, password: a.password, displayName: a.name });
      console.log(`  ~ auth อัปเดต: ${a.email}`);
    } else {
      throw e;
    }
  }
  const roles = a.roles ?? [a.role];
  await db.collection('users').doc(a.uid).set({
    uid: a.uid, name: a.name, email: a.email, phone: a.phone,
    // role = บทบาทสูงสุด เก็บไว้ให้ security rules และ query เดิมใช้ได้
    role: a.role, roles, activeRole: a.role,
    status: a.status, shopId: a.shopId,
  }, { merge: true });
}

async function main() {
  console.log('▶ สร้างบัญชีทดลอง...');
  for (const a of accounts) await upsertAccount(a);

  console.log('▶ ใส่ข้อมูลร้านค้า...');
  for (const [id, data] of Object.entries(shops)) {
    await db.collection('shops').doc(id).set(data, { merge: true });
  }

  console.log('▶ ใส่ข้อมูลแผง...');
  const stalls = buildStalls();
  for (const [id, data] of Object.entries(stalls)) {
    await db.collection('stalls').doc(id).set(data, { merge: true });
  }

  console.log('▶ ใส่ข้อมูลแบนเนอร์...');
  // ไม่ใส่ imageUrl มาให้ เพราะลิงก์รูปภายนอกพังง่ายและจะทำให้หน้าแรกดูเสีย
  // แอดมินใส่รูปเองผ่านหน้า "จัดการแบนเนอร์" (แบนเนอร์ที่ไม่มีรูปจะใช้พื้นหลังไล่สีของแบรนด์)
  const banners = {
    'bn-welcome': { title: 'ตลาดแม่โจ้', subtitle: 'ของสดของดีจากชุมชน', imageUrl: '', shopId: '', order: 0, active: true },
    'bn-veg':     { title: 'เทศกาลผักสด', subtitle: 'จากชุมชนแม่โจ้',    imageUrl: '', shopId: '', order: 1, active: true },
  };
  for (const [id, data] of Object.entries(banners)) {
    await db.collection('banners').doc(id).set(data, { merge: true });
  }

  console.log('▶ ใส่ข้อมูลสินค้า...');
  for (const [id, data] of Object.entries(products)) {
    await db.collection('products').doc(id).set(data, { merge: true });
  }

  console.log('▶ ใส่ข้อมูลคำขอ...');
  for (const [id, data] of Object.entries(requests)) {
    await db.collection('requests').doc(id).set(
      { ...data, createdAt: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true },
    );
  }

  console.log('\n✅ เสร็จสิ้น! บัญชีทดลอง (รหัสผ่านทุกบัญชี = 123456):');
  console.log('   admin@maejo.com  · seller@maejo.com  · buyer@maejo.com');
  process.exit(0);
}

main().catch((e) => { console.error('❌ ผิดพลาด:', e); process.exit(1); });
