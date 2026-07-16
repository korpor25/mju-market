/// ตั้งค่าหลักของแอป
class AppConfig {
  /// false = Demo Mode (รันได้เลยไม่ต้องตั้ง Firebase, ใช้ข้อมูลจำลองในเครื่อง)
  /// true  = ใช้ Firebase จริง (ต้องรัน `flutterfire configure` และเปิด Auth/Firestore ก่อน)
  ///
  /// วิธีสลับ: เปลี่ยนเป็น true เมื่อคุณตั้ง Firebase เสร็จแล้ว
  static const bool useFirebase = false;

  static const String appName = 'Maejo Market';
  static const String appNameTh = 'ตลาดแม่โจ้';
}
