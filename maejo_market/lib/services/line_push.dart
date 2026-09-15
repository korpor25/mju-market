import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../app_config.dart';

/// ส่งการแจ้งเตือนที่เพิ่งบันทึกลง Firestore ต่อเข้า LINE OA ผ่านตัวกลางใน server/
///
/// ส่งไปแค่ "รหัสเอกสาร" ไม่ส่งข้อความ — ตัวกลางจะไปอ่านหัวข้อ/เนื้อหาจาก
/// เอกสารจริงเอง แอปจึงปลอมข้อความส่งเข้าไลน์ในนามตลาดไม่ได้
///
/// เรียกแบบยิงแล้วลืม: ถ้าตัวกลางล่มหรือยังไม่ได้ตั้งค่า การแจ้งเตือนในแอป
/// ต้องทำงานได้ตามปกติ ฟังก์ชันนี้จึงกลืน error ทุกกรณี
Future<void> pushNotificationToLine(String notificationId) async {
  if (AppConfig.lineApiBase.isEmpty) return;

  try {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) return;

    await http
        .post(
          Uri.parse('${AppConfig.lineApiBase}/api/push'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'notificationId': notificationId}),
        )
        .timeout(const Duration(seconds: 10));
  } catch (_) {
    // เงียบไว้ — ผู้ใช้เห็นแจ้งเตือนในแอปอยู่แล้ว ไลน์เป็นของแถม
  }
}
