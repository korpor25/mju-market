// ตอบคำถามเกี่ยวกับตลาดจากข้อมูลจริงใน Firestore (ใช้โดย LINE OA)
//
// ทุกคำตอบอ่านจากคอลเลกชันเดียวกับที่แอปใช้ ไม่มีข้อความตายตัวเรื่องร้าน/ราคา
// แม่ค้าแก้ข้อมูลในแอปเมื่อไหร่ ไลน์ก็ตอบตามนั้นทันที
import { db } from './firebase.js';

const APP_URL = process.env.APP_URL || 'https://maejo-market.web.app';

// ป้องกันข้อความยาวเกินที่ LINE รับ (5,000 ตัวอักษร) และอ่านในแชตไม่ไหว
const MAX_SHOPS = 8;
const MAX_ITEMS_PER_SHOP = 4;
const MAX_STALL_IDS = 12;

const baht = (n) => `฿${Number(n || 0).toLocaleString('en-US')}`;

async function docs(name, limit = 1000) {
  const snap = await db().collection(name).limit(limit).get();
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

/// ป้ายบอกที่ตั้งร้าน — ร้านที่ยังไม่ได้จองแผงต้องไม่โชว์เลขแผงมั่ว
function whereLabel(shop) {
  if (!shop.stallId) return 'ยังไม่ได้จองแผง';
  return shop.zone ? `โซน ${shop.zone} · แผง ${shop.stallId}` : `แผง ${shop.stallId}`;
}

// ---------------- โปรโมชั่น ----------------

export async function promotions() {
  const [banners, shops] = await Promise.all([docs('banners', 100), docs('shops')]);
  const active = banners
    .filter((b) => b.active !== false)
    .sort((a, b) => (a.order || 0) - (b.order || 0));

  if (!active.length) {
    return [
      'ตอนนี้ยังไม่มีโปรโมชั่นที่ประกาศไว้ 🙏',
      '',
      'ลองถาม "แผงว่าง" หรือพิมพ์ชื่อของที่อยากได้ เช่น "มีผักกาดขายมั้ย" ได้เลย',
    ].join('\n');
  }

  const byId = new Map(shops.map((s) => [s.id, s]));
  const lines = [`โปรโมชั่นตอนนี้มี ${active.length} รายการ 🎉`, ''];
  for (const b of active.slice(0, MAX_SHOPS)) {
    lines.push(`• ${b.title || 'โปรโมชั่นจากตลาด'}`);
    if (b.subtitle) lines.push(`  ${b.subtitle}`);
    const shop = b.shopId ? byId.get(b.shopId) : null;
    if (shop) lines.push(`  ร้าน ${shop.name} · ${whereLabel(shop)}`);
  }
  if (active.length > MAX_SHOPS) lines.push(`… และอีก ${active.length - MAX_SHOPS} รายการ`);
  lines.push('', `ดูรูปและรายละเอียดในแอป: ${APP_URL}`);
  return lines.join('\n');
}

// ---------------- แผงว่าง ----------------

export async function freeStalls() {
  const stalls = await docs('stalls', 2000);
  const free = stalls.filter((s) => (s.status || 'empty') === 'empty');

  if (!free.length) {
    return [
      'ตอนนี้แผงเต็มหมดทุกแผงแล้ว 🙏',
      '',
      'ฝากชื่อไว้กับผู้ดูแลตลาดได้ ถ้ามีคนคืนแผงจะแจ้งให้ทราบ',
      APP_URL,
    ].join('\n');
  }

  // สรุปเป็นรายโซนก่อน คนถามมักอยากรู้ว่าว่างตรงไหนและเริ่มต้นเท่าไหร่
  const byZone = new Map();
  for (const s of free) {
    const zone = s.zone || String(s.id).split('-')[0] || '-';
    const cur = byZone.get(zone) || { count: 0, min: Infinity };
    cur.count++;
    cur.min = Math.min(cur.min, Number(s.pricePerDay) || 0);
    byZone.set(zone, cur);
  }

  const lines = [`ตอนนี้มีแผงว่าง ${free.length} แผง 🏪`, ''];
  for (const [zone, info] of [...byZone].sort((a, b) => a[0].localeCompare(b[0]))) {
    lines.push(`• โซน ${zone} · ว่าง ${info.count} แผง · เริ่ม ${baht(info.min)}/วัน`);
  }

  const ids = free.map((s) => s.id).sort();
  lines.push('', `เลขแผงที่ว่าง: ${ids.slice(0, MAX_STALL_IDS).join(', ')}`);
  if (ids.length > MAX_STALL_IDS) lines.push(`… และอีก ${ids.length - MAX_STALL_IDS} แผง`);
  lines.push('', 'สนใจเช่า: สมัครสมาชิกในแอปแล้วยื่นขอเปิดร้านได้เลย', APP_URL);
  return lines.join('\n');
}

// ---------------- ร้านค้าในตลาด ----------------

export async function shopDirectory() {
  const shops = await docs('shops');
  if (!shops.length) return `ยังไม่มีร้านลงทะเบียนในระบบ 🙏\n${APP_URL}`;

  const byCat = new Map();
  for (const s of shops) {
    const cat = (s.category || '').trim() || 'อื่น ๆ';
    byCat.set(cat, [...(byCat.get(cat) || []), s]);
  }

  const lines = [`ตลาดแม่โจ้มี ${shops.length} ร้าน 🌿`, ''];
  for (const [cat, list] of [...byCat].sort((a, b) => b[1].length - a[1].length)) {
    const names = list.slice(0, 5).map((s) => s.name).join(', ');
    const more = list.length > 5 ? ` … (+${list.length - 5})` : '';
    lines.push(`• ${cat} · ${list.length} ร้าน`, `  ${names}${more}`);
  }
  lines.push('', 'อยากรู้ว่าร้านไหนขายอะไร พิมพ์ชื่อของได้เลย เช่น "มีผักกาดขายมั้ย"');
  lines.push(APP_URL);
  return lines.join('\n');
}

// ---------------- ค้นหาสินค้า ----------------

/// ดึง "ชื่อของ" ออกจากประโยคคำถาม เช่น "มีผักกาดขายมั้ยครับ" -> "ผักกาด"
export function extractKeyword(text) {
  let t = String(text || '').replace(/[?？！!.,]/g, ' ').trim();
  const strippers = [
    /^(ที่|ใน)?ตลาด\s*/,
    /^(มี|ขาย|หา|อยากได้|ต้องการ|ซื้อ|ถาม|ช่วยหา)\s*/,
    /\s*(ขาย|มี)?\s*(มั้ย|มั๊ย|ไหม|ป่ะ|ปะ|รึเปล่า|หรือเปล่า|บ้าง|อยู่)\s*$/,
    /\s*(ครับ|ค่ะ|คะ|ค๊า|จ้า|จ๊ะ|ฮะ|นะ|น้า)\s*$/,
  ];
  // ประโยคจริงมักซ้อนกันหลายชั้น ("มี...ขายมั้ยครับ") จึงลอกทีละชั้นจนไม่เหลืออะไรให้ลอก
  for (let i = 0; i < 6; i++) {
    const before = t;
    for (const re of strippers) t = t.replace(re, ' ').trim();
    if (t === before) break;
  }
  return t.trim();
}

export async function searchItems(keyword) {
  const q = keyword.toLowerCase();
  const [shops, products] = await Promise.all([docs('shops'), docs('products', 2000)]);

  const hitProducts = products.filter(
    (p) => p.available !== false && String(p.name || '').toLowerCase().includes(q),
  );
  const hitShops = shops.filter((s) =>
    [s.name, s.category, s.description].some((v) => String(v || '').toLowerCase().includes(q)),
  );

  // ร้านที่ตรงเพราะ "มีของชิ้นนั้นขาย" มาก่อนร้านที่ตรงแค่ชื่อ/หมวด
  const order = new Map();
  for (const p of hitProducts) {
    const list = order.get(p.shopId) || [];
    list.push(p);
    order.set(p.shopId, list);
  }
  for (const s of hitShops) if (!order.has(s.id)) order.set(s.id, []);

  const byId = new Map(shops.map((s) => [s.id, s]));
  const results = [...order.entries()]
    .map(([shopId, items]) => ({ shop: byId.get(shopId), items }))
    .filter((r) => r.shop);

  if (!results.length) {
    const cats = [...new Set(shops.map((s) => (s.category || '').trim()).filter(Boolean))];
    return [
      `ยังไม่พบ "${keyword}" ในของที่ร้านลงไว้ 🙏`,
      '',
      cats.length ? `ตอนนี้ตลาดมีหมวด: ${cats.join(', ')}` : '',
      'ลองพิมพ์ชื่อสั้นลง เช่น "ผัก" หรือพิมพ์ "ร้านค้า" เพื่อดูทั้งหมด',
      APP_URL,
    ]
      .filter(Boolean)
      .join('\n');
  }

  const lines = [`"${keyword}" มีขายที่ ${results.length} ร้าน 🌿`, ''];
  for (const { shop, items } of results.slice(0, MAX_SHOPS)) {
    const closed = shop.status === 'closed' ? ' (ปิดปรับปรุง)' : '';
    lines.push(`• ${shop.name}${closed} · ${whereLabel(shop)}`);
    if (shop.hours) lines.push(`  เปิด ${shop.hours}`);
    for (const p of items.slice(0, MAX_ITEMS_PER_SHOP)) {
      lines.push(`  - ${p.name} ${baht(p.price)}`);
    }
    if (items.length > MAX_ITEMS_PER_SHOP) {
      lines.push(`  - … และอีก ${items.length - MAX_ITEMS_PER_SHOP} รายการ`);
    }
  }
  if (results.length > MAX_SHOPS) lines.push(`… และอีก ${results.length - MAX_SHOPS} ร้าน`);
  lines.push('', `ดูรูปสินค้าและรีวิวร้านในแอป: ${APP_URL}`);
  return lines.join('\n');
}
