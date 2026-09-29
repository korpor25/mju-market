// ตรวจว่า deploy แล้วตั้ง env ครบไหม — ไม่เปิดเผยค่าจริง บอกแค่ว่ามีหรือไม่มี
export default function handler(_req, res) {
  res.status(200).json({
    ok: true,
    env: {
      LINE_CHANNEL_SECRET: Boolean(process.env.LINE_CHANNEL_SECRET),
      LINE_CHANNEL_ACCESS_TOKEN: Boolean(process.env.LINE_CHANNEL_ACCESS_TOKEN),
      FIREBASE_SERVICE_ACCOUNT: Boolean(process.env.FIREBASE_SERVICE_ACCOUNT),
      APP_URL: process.env.APP_URL || '(ค่าเริ่มต้น)',
    },
  });
}
