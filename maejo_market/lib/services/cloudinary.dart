import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../app_config.dart';

/// อัปโหลดรูปขึ้น Cloudinary ด้วย unsigned upload preset
///
/// ใช้แทน Firebase Storage เพราะ Storage ต้องอัปเป็นแผน Blaze (ผูกบัตร)
/// แบบ unsigned ไม่ต้องมี backend และไม่ต้องฝัง API secret ไว้ในแอป
/// (cloud name กับชื่อ preset ไม่ใช่ความลับ)
///
/// ข้อจำกัดที่ต้องรู้: ใครที่รู้ชื่อ preset ก็ยิงอัปโหลดเข้าบัญชีได้
/// กันได้โดยตั้งใน preset ว่ารับเฉพาะไฟล์รูป จำกัดขนาด และล็อกโฟลเดอร์
class Cloudinary {
  static bool get isReady => AppConfig.cloudinaryReady;

  static Uri get _endpoint => Uri.parse(
        'https://api.cloudinary.com/v1_1/${AppConfig.cloudinaryCloudName}/image/upload',
      );

  /// อัปโหลดแล้วคืน URL ของรูป — โยน [Exception] พร้อมข้อความไทยถ้าไม่สำเร็จ
  static Future<String> upload(Uint8List bytes, {required String filename}) async {
    if (!isReady) {
      throw Exception('ยังไม่ได้ตั้งค่า Cloudinary ใน AppConfig');
    }

    final req = http.MultipartRequest('POST', _endpoint)
      ..fields['upload_preset'] = AppConfig.cloudinaryUploadPreset
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));

    late http.Response res;
    try {
      res = await http.Response.fromStream(await req.send());
    } catch (e) {
      throw Exception('เชื่อมต่อ Cloudinary ไม่ได้ — ตรวจอินเทอร์เน็ตแล้วลองใหม่');
    }

    if (res.statusCode != 200) {
      // Cloudinary ส่งเหตุผลกลับมาใน error.message ถ้าอ่านได้ก็บอกผู้ใช้ตรง ๆ
      String detail = 'HTTP ${res.statusCode}';
      try {
        final m = jsonDecode(res.body);
        if (m is Map && m['error'] is Map && m['error']['message'] != null) {
          detail = m['error']['message'].toString();
        }
      } catch (_) {}
      throw Exception('อัปโหลดไม่สำเร็จ: $detail');
    }

    final body = jsonDecode(res.body);
    final url = (body is Map) ? body['secure_url'] : null;
    if (url is! String || url.isEmpty) {
      throw Exception('อัปโหลดสำเร็จแต่ไม่ได้ลิงก์รูปกลับมา');
    }
    return url;
  }

  /// เติมพารามิเตอร์ย่อ/บีบรูปให้ลิงก์ Cloudinary เพื่อให้โหลดเบาลง
  ///
  /// ลิงก์ที่ไม่ใช่ของ Cloudinary จะคืนค่าเดิมโดยไม่แตะต้อง
  /// (แอปนี้รับลิงก์รูปจากที่ไหนก็ได้ ไม่ใช่ทุกอันที่แปลงได้)
  static String sized(String url, {int width = 600}) {
    if (!url.contains('res.cloudinary.com') || !url.contains('/upload/')) return url;
    // แทรกครั้งเดียว ถ้าเคยแทรกแล้วอย่าซ้อน
    if (RegExp(r'/upload/[^/]*[wqf]_').hasMatch(url)) return url;
    return url.replaceFirst('/upload/', '/upload/w_$width,q_auto,f_auto/');
  }
}
