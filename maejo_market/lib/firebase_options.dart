// ⚠️ ไฟล์ตัวอย่าง (placeholder)
// ไฟล์นี้จะถูกสร้างทับอัตโนมัติเมื่อคุณรัน:  flutterfire configure
// อย่าเพิ่งตั้ง AppConfig.useFirebase = true จนกว่าจะรันคำสั่งด้านบนเสร็จ

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'ยังไม่ได้ตั้งค่า Firebase — โปรดรัน `flutterfire configure` '
      'เพื่อสร้างไฟล์ firebase_options.dart ที่ถูกต้อง',
    );
  }
}
