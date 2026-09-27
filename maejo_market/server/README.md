# ตัวกลาง LINE OA — Maejo Market

Serverless functions เล็ก ๆ สำหรับ deploy ขึ้น Vercel (ฟรี ไม่ต้องผูกบัตร) ทำสองอย่าง:

1. **ตอบคำถามเรื่องตลาดในแชต** — โปรโมชั่น แผงว่าง ร้านค้า และ "มีของชิ้นนี้ขายไหม"
   ตอบจาก Firestore ชุดเดียวกับที่แอปใช้ ผู้บริโภคจึงถามได้โดยไม่ต้องลงทะเบียนแอป
2. **ส่งการแจ้งเตือนของแอปเข้า LINE** ของผู้ใช้ที่ผูกบัญชีไว้

## ทำไมต้องมี

Channel Access Token ของ LINE เป็นความลับ ใครได้ไปก็ส่งข้อความในนามตลาดได้
แอป Flutter เป็นเว็บที่เปิดอ่านโค้ดได้หมด จึงฝัง token ไว้ในแอปไม่ได้
ส่วน Cloud Functions ต้องอัปเป็นแผน Blaze (ผูกบัตร) ซึ่งโปรเจกต์นี้เลี่ยงมาตลอด
เหมือนที่ใช้ Cloudinary แทน Firebase Storage

## endpoint

| path | ใครเรียก | ทำอะไร |
|---|---|---|
| `POST /api/line/webhook` | LINE | รับ event — ตอบคำถามเรื่องตลาด, ทักทายตอนแอดเพื่อน, ผูกบัญชีด้วยรหัส 6 หลัก, ยกเลิก |
| `POST /api/push` | แอป | อ่านเอกสารใน `notifications` แล้วส่งเข้า LINE ของเจ้าของ |
| `GET /api/health` | เรา | เช็คว่าตั้ง env ครบไหม (ไม่โชว์ค่าจริง) |

## คำถามที่ OA ตอบได้ (`lib/market.js`)

| ผู้ใช้พิมพ์ | ตอบอะไร | อ่านจาก |
|---|---|---|
| โปรโมชั่น / มีโปรอะไรบ้าง / ลดราคา | แบนเนอร์ที่เปิดใช้งาน + ร้านและแผงที่จัด | `banners` + `shops` |
| แผงว่าง / เช่าแผง / ค่าเช่า | จำนวนแผงว่างรายโซน ราคาเริ่มต้น เลขแผงที่ว่าง | `stalls` |
| ร้านค้า / มีร้านอะไรบ้าง | จำนวนร้านแยกตามหมวด | `shops` |
| "มีผักกาดขายมั้ย" (อะไรก็ได้ที่เหลือ) | ร้านที่มีของชิ้นนั้น + แผง เวลาเปิด และราคา | `products` + `shops` |
| วิธีใช้ / สวัสดี | เมนูคำถาม + วิธีผูกบัญชีรับแจ้งเตือน | — |

ทุกคำตอบติดปุ่มลัด (quick reply) ไปด้วย ผู้ใช้จะได้ไม่ต้องจำว่าถามอะไรได้
คำถามถูกแยกใจความด้วย regex ไม่ได้เรียก AI — คำตอบจึงมาจากข้อมูลจริงเสมอและไม่มีค่าใช้จ่ายต่อข้อความ
สินค้าที่แม่ค้าปิดขายไว้ (`available: false`) จะไม่ถูกตอบว่ามี

## ความปลอดภัย

- `/api/line/webhook` ตรวจ `x-line-signature` (HMAC-SHA256 ของบอดี้ดิบ) ทุกครั้ง
- `/api/push` ต้องมี Firebase ID token ที่ถูกต้อง **และ** ไม่รับข้อความจากแอปเลย
  รับแค่ `notificationId` แล้วไปอ่านหัวข้อ/เนื้อหาจากเอกสารจริงใน Firestore
  กฎ Firestore ยอมให้แอดมินเท่านั้นที่สร้างเอกสารแจ้งเตือน แอปจึงปลอมข้อความไม่ได้
- ส่งซ้ำไม่ได้ — ปั๊ม `linePushed: true` ลงเอกสารหลังส่งสำเร็จ

## ตัวแปรสภาพแวดล้อม

ดู [.env.example](.env.example) — ตั้งใน Vercel ทั้ง 3 environment (Production/Preview/Development)

| ตัวแปร | เอามาจากไหน |
|---|---|
| `LINE_CHANNEL_SECRET` | LINE Developers Console > channel > Basic settings |
| `LINE_CHANNEL_ACCESS_TOKEN` | LINE Developers Console > channel > Messaging API (กด Issue) |
| `FIREBASE_SERVICE_ACCOUNT` | Firebase Console > Project settings > Service accounts > Generate new private key แล้วแปลงเป็น base64 |
| `APP_URL` | `https://maejo-market.web.app` |
| `ALLOWED_ORIGINS` | `https://maejo-market.web.app` |

แปลง service account เป็น base64 (Git Bash):

```bash
base64 -w0 service-account.json
```

> ห้าม commit ไฟล์ service account ลง git — `.gitignore` กันไว้แล้ว

## deploy

```bash
cd server
vercel --prod
```

จากนั้นเอา URL ที่ได้ไปใส่ `AppConfig.lineApiBase` ในแอป และไปใส่เป็น Webhook URL
ใน LINE Developers Console (ต่อท้ายด้วย `/api/line/webhook`)

## ข้อจำกัดที่รู้ตัว

- รหัสผูกบัญชีใน `lineLinks` ไม่มีตัวเก็บกวาดของหมดอายุ (ไม่มี cron ในแผนฟรี)
  เอกสารเล็กมากและ Firestore ฟรีให้เยอะ จึงปล่อยไว้ได้ ถ้าอยากล้างค่อยทำมือ
- แจ้งเตือน "มีรีวิวใหม่" ยังไม่ส่ง เพราะคนรีวิวเป็นผู้ใช้ทั่วไปที่กฎ Firestore
  ไม่ให้สร้างเอกสารแจ้งเตือน (กันการยิงข้อความมั่วเข้าไลน์) ถ้าอยากให้ทำงาน
  ต้องเพิ่ม endpoint ที่ตรวจว่ามีรีวิวจริงก่อนสร้างแจ้งเตือนให้
