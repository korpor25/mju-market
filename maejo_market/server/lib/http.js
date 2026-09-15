/// อ่านบอดี้ดิบของ request — จำเป็นสำหรับตรวจลายเซ็น LINE
///
/// Vercel (@vercel/node) ไม่สน `config.api.bodyParser` (นั่นของ Next.js) มันอ่านบอดี้
/// ทั้งก้อนไว้ก่อนเรียก handler แล้ว "เล่นซ้ำ" ให้เฉพาะผ่าน event `data`/`end`
/// จึงต้องฟังสองอีเวนต์นี้ — ห้ามใช้ `for await` (ไม่ผ่านตัวเล่นซ้ำ ค้างหรือได้บอดี้ว่าง)
/// และห้ามแตะ `req.body` (เป็นก้อนที่ parse แล้ว stringify กลับไม่ได้ไบต์เดิม)
export function readRawBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on('data', (c) => chunks.push(Buffer.isBuffer(c) ? c : Buffer.from(c)));
    req.on('end', () => resolve(Buffer.concat(chunks).toString('utf8')));
    req.on('error', reject);
  });
}

/// อนุญาตเฉพาะเว็บของเรา (และ localhost ตอนพัฒนา) เรียกข้ามโดเมนได้
export function applyCors(req, res) {
  const allowed = (process.env.ALLOWED_ORIGINS || 'https://maejo-market.web.app')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
  const origin = req.headers.origin;

  if (origin && (allowed.includes(origin) || /^http:\/\/localhost(:\d+)?$/.test(origin))) {
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Vary', 'Origin');
  }
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Access-Control-Max-Age', '86400');
}

export function json(res, status, body) {
  res.status(status).setHeader('Content-Type', 'application/json; charset=utf-8');
  res.end(JSON.stringify(body));
}
