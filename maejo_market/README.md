# 🌿 Maejo Market · แอปจัดการตลาดแม่โจ้

แอป Flutter + Firebase สำหรับบริหารจัดการตลาดแม่โจ้ รองรับ **3 บทบาท**:

| บทบาท | ความสามารถ |
|-------|-----------|
| 🛒 **ผู้บริโภค** | หน้าแรก, ค้นหาร้าน/หมวดหมู่, แผนผังตลาด, รายละเอียดร้าน, โปรไฟล์ |
| 🏪 **ผู้ขาย** | Dashboard ร้าน, จัดการร้านค้า/สินค้า, จองพื้นที่ขาย (ส่งคำขอ) |
| 🛡️ **ผู้ดูแลระบบ** | Dashboard, **อนุมัติคำขอ**, แผนผังตลาด, ตรวจมาตรฐานร้าน |

ธีมตาม design system: เขียว `#2E7D32` / `#4CAF50` · ส้ม `#FF9800` · ฟอนต์ **Kanit**

---

## 🧪 Demo Mode (รันได้ทันที — ไม่ต้องตั้ง Firebase)

ค่าเริ่มต้น `AppConfig.useFirebase = false` แอปจะใช้ **ข้อมูลจำลองในเครื่อง** — ล็อกอิน + อนุมัติคำขอ + จองแผง ทำงานได้จริงเลย

**บัญชีทดลอง (รหัสผ่าน `123456` ทุกบัญชี):**
- ผู้ดูแลระบบ → `admin@maejo.com`
- ผู้ขาย → `seller@maejo.com`
- ผู้บริโภค → `buyer@maejo.com`

> ในหน้า Login มีปุ่มแตะกรอกอัตโนมัติให้ด้วย

---

## 🚀 เริ่มต้นใช้งาน (Step-by-step)

### 1) ติดตั้ง Flutter (ครั้งเดียว)
- ดาวน์โหลด: https://docs.flutter.dev/get-started/install/windows
- แตกไฟล์ไว้เช่น `C:\src\flutter` แล้วเพิ่ม `C:\src\flutter\bin` ลงใน PATH
- ตรวจสอบ: `flutter doctor`

### 2) สร้างโครง platform + ติดตั้งแพ็กเกจ
```bash
cd maejo_market
flutter create .            # สร้างโฟลเดอร์ web/android/ios + ไอคอน (ไม่ทับ lib/)
flutter pub get
```

### 3) รันแบบ Demo (เห็นแอปทำงานทันที)
```bash
flutter run -d chrome
```

เท่านี้ก็ลองใช้ได้เลย! 🎉

---

## 🔥 ต่อ Firebase จริง (เมื่อพร้อม)

### 1) สร้างโปรเจกต์ Firebase (ฟรี)
- ไปที่ https://console.firebase.google.com → **Add project**
- เปิด **Authentication** → Sign-in method → เปิด **Email/Password**
- เปิด **Firestore Database** → Create database (โหมด production)

### 2) เชื่อม Flutter กับ Firebase
```bash
dart pub global activate flutterfire_cli
flutterfire configure          # เลือกโปรเจกต์ + แพลตฟอร์ม → สร้าง lib/firebase_options.dart ให้อัตโนมัติ
```

### 3) เปิดใช้ Firebase ในแอป
แก้ไฟล์ [lib/app_config.dart](lib/app_config.dart):
```dart
static const bool useFirebase = true;   // เปลี่ยนจาก false
```

### 4) วาง Security Rules
คัดลอกเนื้อหาจาก [firestore.rules](firestore.rules) ไปวางใน Firebase Console → Firestore → Rules → Publish

> หมายเหตุ: สร้างบัญชีแอดมินคนแรกโดยสมัครผ่านแอปแล้วเข้าไปแก้ field `role` เป็น `admin` ใน Firestore ที่ collection `users`

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
├─ app_config.dart           # สวิตช์ Demo/Firebase
├─ firebase_options.dart     # (flutterfire สร้างทับ)
├─ theme/                    # สี + ธีม Kanit
├─ models/                   # AppUser, Shop, MarketRequest, Stall
├─ data/demo_data.dart       # ข้อมูลจำลอง
├─ state/                    # AppState (auth+data) + FirebaseBackend
├─ widgets/                  # common.dart, market_map.dart
└─ screens/
   ├─ auth/                  # login, signup (เลือกผู้บริโภค/ผู้ขาย)
   ├─ buyer/                 # หน้าแรก, ค้นหา, แผนที่, โปรไฟล์
   ├─ seller/                # dashboard, จัดการร้าน, จองพื้นที่
   └─ admin/                 # dashboard, อนุมัติ, แผนผัง, มาตรฐาน
```
