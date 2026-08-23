/// ตั้งค่าหลักของแอป
class AppConfig {
  /// false = Demo Mode (รันได้เลยไม่ต้องตั้ง Firebase, ใช้ข้อมูลจำลองในเครื่อง)
  /// true  = ใช้ Firebase จริง (ต้องรัน `flutterfire configure` และเปิด Auth/Firestore ก่อน)
  ///
  /// วิธีสลับ: เปลี่ยนเป็น true เมื่อคุณตั้ง Firebase เสร็จแล้ว
  static const bool useFirebase = true;

  // ---- Cloudinary (ที่เก็บรูป) ----
  // ใช้แทน Firebase Storage เพราะ Storage ต้องอัปเป็นแผน Blaze (ผูกบัตร)
  //
  // วิธีตั้งค่า:
  //   1) สมัคร cloudinary.com (ฟรี ไม่ต้องใช้บัตร)
  //   2) Dashboard จะบอก "Cloud name" -> เอามาใส่ cloudinaryCloudName
  //   3) Settings > Upload > Upload presets > Add upload preset
  //      ตั้ง Signing Mode = Unsigned แล้วเอาชื่อ preset มาใส่ cloudinaryUploadPreset
  //      แนะนำให้ล็อกใน preset ด้วย: อนุญาตเฉพาะไฟล์รูป จำกัดขนาด และกำหนดโฟลเดอร์
  //
  // ค่าสองตัวนี้ไม่ใช่ความลับ ฝังในแอปได้ (ไม่ใช่ API secret)
  // ถ้าเว้นว่างไว้ แอปจะยังใช้งานได้ปกติแต่ปุ่มอัปโหลดจะไม่ขึ้น เหลือแค่ช่องวางลิงก์
  static const String cloudinaryCloudName = 'c1xa0482';
  static const String cloudinaryUploadPreset = 'maejo_unsigned';

  static bool get cloudinaryReady =>
      cloudinaryCloudName.isNotEmpty && cloudinaryUploadPreset.isNotEmpty;

  // ---- ช่องทางรับชำระค่าเช่าแผง ----
  // แสดงให้ผู้ขายเห็นในหน้าชำระเงิน แล้วให้โอนมาแล้วแนบสลิป
  // ใส่ของตลาดจริงตรงนี้ ถ้าเว้นว่างหน้าชำระเงินจะบอกว่ายังไม่ได้ตั้งค่า
  static const String payPromptPay = ''; // เบอร์พร้อมเพย์ เช่น 081-234-5678
  static const String payAccountName = ''; // ชื่อบัญชี
  static const String payBankAccount = ''; // ธนาคาร + เลขบัญชี (ถ้ามี)

  static bool get payInfoReady => payPromptPay.isNotEmpty || payBankAccount.isNotEmpty;

  /// จำนวนวันต่อรอบบิล — ค่าเช่ารายเดือนคิดจากราคาแผงต่อวัน x ค่านี้
  static const int billingDays = 30;

  /// เงื่อนไขการเช่าแผงที่ผู้ขายต้องยอมรับก่อนยื่นขอเปิดร้าน
  /// แก้ข้อความให้ตรงกับกติกาจริงของตลาดได้ที่นี่ที่เดียว
  static const List<String> shopTerms = [
    'ชำระค่าเช่าแผงตามรอบที่ตลาดกำหนด หากค้างเกินกำหนดตลาดขอสงวนสิทธิ์ระงับการขาย',
    'ขายสินค้าตามหมวดที่แจ้งไว้ หากต้องการเปลี่ยนหมวดให้แจ้งผู้ดูแลตลาดก่อน',
    'ดูแลความสะอาดบริเวณแผงของตนเอง และคัดแยกขยะตามที่ตลาดกำหนด',
    'ไม่ปล่อยเช่าช่วงหรือโอนสิทธิ์แผงให้ผู้อื่นโดยไม่ได้รับอนุญาต',
    'ข้อมูลที่กรอกต้องเป็นความจริง ตลาดขอสงวนสิทธิ์ยกเลิกสิทธิ์หากพบว่าเป็นเท็จ',
  ];

  static const String appName = 'Maejo Market';
  static const String appNameTh = 'ตลาดแม่โจ้';
}
