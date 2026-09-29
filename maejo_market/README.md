# 🌿 Maejo Market · แอปจัดการตลาดแม่โจ้

แอป Flutter + Firebase สำหรับบริหารจัดการตลาดแม่โจ้ รองรับ **3 บทบาท**:

| บทบาท | ความสามารถ |
|-------|-----------|
| 🛒 **ผู้บริโภค** | หน้าแรก, ค้นหาร้าน/หมวดหมู่, แผนผังตลาด, รายละเอียดร้าน, โปรไฟล์ |
| 🏪 **ผู้ขาย** | Dashboard ร้าน, จัดการร้านค้า/สินค้า, จองพื้นที่ขาย (ส่งคำขอ) |
| 🛡️ **ผู้ดูแลระบบ** | Dashboard, **อนุมัติคำขอ**, แผนผังตลาด, ตรวจมาตรฐานร้าน |

**ไม่อยากลงทะเบียนก็เข้าดูได้** — หน้าเข้าสู่ระบบมีปุ่ม "เข้าชมตลาดโดยไม่ต้องสมัคร"
เห็นร้านค้า สินค้า ผังตลาด และโปรโมชั่นครบ ส่วนที่ต้องมีบัญชี (ติดตามร้าน รีวิว
แจ้งเตือน เปิดร้าน) จะชวนเข้าสู่ระบบตอนกด

**ถามตลาดผ่าน LINE OA ได้** — พิมพ์ "โปรโมชั่น" / "แผงว่าง" / "มีผักกาดขายมั้ย"
แล้วบอทตอบจากข้อมูลจริงในระบบ (ดู [server/README.md](server/README.md))

ธีมตาม design system: เขียว `#2E7D32` / `#4CAF50` · ส้ม `#FF9800` · ฟอนต์ **Kanit**

---

## 🚀 เริ่มต้นใช้งาน

### 1) ติดตั้ง Flutter (ครั้งเดียว)
- ดาวน์โหลด: https://docs.flutter.dev/get-started/install/windows
- แตกไฟล์ไว้เช่น `C:\src\flutter` แล้วเพิ่ม `C:\src\flutter\bin` ลงใน PATH
- ตรวจสอบ: `flutter doctor`

### 2) โหลดโค้ด + ติดตั้งแพ็กเกจ
```bash
git clone https://github.com/korpor25/mju-market.git
cd mju-market
flutter pub get
```

### 3) รัน
```bash
flutter run -d chrome
```

แอปต่อ Firebase โปรเจกต์ที่ตั้งไว้ใน [lib/firebase_options.dart](lib/firebase_options.dart) อยู่แล้ว

---

## 🔥 ตั้ง Firebase โปรเจกต์ใหม่ (ถ้าจะย้ายไปใช้โปรเจกต์ของตัวเอง)

### 1) สร้างโปรเจกต์ Firebase (ฟรี)
- ไปที่ https://console.firebase.google.com → **Add project**
- เปิด **Authentication** → Sign-in method → เปิด **Email/Password**
- เปิด **Firestore Database** → Create database (โหมด production)

### 2) เชื่อม Flutter กับ Firebase
```bash
dart pub global activate flutterfire_cli
flutterfire configure          # เลือกโปรเจกต์ + แพลตฟอร์ม → สร้าง lib/firebase_options.dart ให้อัตโนมัติ
```

### 3) วาง Security Rules
```bash
firebase deploy --only firestore:rules
```
หรือคัดลอก [firestore.rules](firestore.rules) ไปวางใน Firebase Console → Firestore → Rules → Publish

> สร้างบัญชีแอดมินคนแรกโดยสมัครผ่านแอป แล้วแก้ field `role` เป็น `admin` ใน Firestore ที่ collection `users`

---

## 📲 Deploy เป็น Web PWA + QR (ฟรี 100%)

### วิธี A — Firebase Hosting
```bash
npm install -g firebase-tools
firebase login
firebase init hosting          # public directory ให้ตอบ: build/web
flutter build web --release
firebase deploy --only hosting
```
ได้ URL เช่น `https://maejo-market.web.app` → เอาไปทำ QR code → สแกน → เปิด → กด "เพิ่มลงหน้าจอโฮม" = เหมือนแอปจริง

### วิธี B — สร้าง QR
- นำ URL ไปสร้าง QR ที่เว็บฟรี (เช่น qr-code-generator) หรือใช้แพ็กเกจ `qr_flutter` ในแอป

### สร้าง APK สำหรับ Android (ฟรี)
```bash
flutter build apk --release
# ได้ไฟล์ที่ build/app/outputs/flutter-apk/app-release.apk
```

---

## 📁 โครงสร้างโปรเจกต์
```
lib/
├─ main.dart                 # จุดเริ่ม + router ตามบทบาท
├─ app_config.dart           # ค่าตั้งค่า (Cloudinary, LINE OA, ค่าเช่า, เงื่อนไขร้าน)
├─ firebase_options.dart     # (flutterfire สร้างทับ)
├─ theme/                    # สี + ธีม Kanit
├─ models/                   # AppUser, Shop, Stall, Product, Sale, Review ฯลฯ
├─ data/                     # ผังตลาด + หมวดสินค้า
├─ state/                    # AppState (auth+data) + FirebaseBackend
├─ services/                 # Cloudinary, LINE push, ประวัติการเข้าชม
├─ widgets/                  # คอมโพเนนต์ที่ใช้ร่วมกัน
└─ screens/
   ├─ auth/                  # login, signup
   ├─ buyer/                 # หน้าแรก, ค้นหา, แผนที่
   ├─ seller/                # dashboard, จัดการร้าน, ยอดขาย, ชำระค่าเช่า
   └─ admin/                 # อนุมัติ, แผง, แบนเนอร์, ผู้ใช้, รายงาน
server/                      # ตัวกลาง LINE OA (Vercel)
tools/firestore/             # สคริปต์ดูแลฐานข้อมูล (wipe, migrate-roles)
test/                        # widget/unit tests
```
