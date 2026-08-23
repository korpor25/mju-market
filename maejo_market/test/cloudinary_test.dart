import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:maejo_market/app_config.dart';
import 'package:maejo_market/services/cloudinary.dart';

/// PNG สีเขียวขนาดเล็ก ใช้เป็นไฟล์ทดสอบอัปโหลด
Uint8List _tinyPng() => Uint8List.fromList(const [
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
      0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
      0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
      0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41,
      0x54, 0x78, 0x9C, 0x63, 0x60, 0x60, 0x60, 0x00,
      0x00, 0x00, 0x05, 0x00, 0x01, 0x87, 0xA1, 0x4E,
      0xD4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E,
      0x44, 0xAE, 0x42, 0x60, 0x82,
    ]);

void main() {
  group('Cloudinary.sized', () {
    test('เติมพารามิเตอร์ย่อรูปให้ลิงก์ Cloudinary', () {
      const url = 'https://res.cloudinary.com/c1xa0482/image/upload/v123/a.png';
      final out = Cloudinary.sized(url, width: 400);
      expect(out, contains('/upload/w_400,q_auto,f_auto/'));
      expect(out, endsWith('/v123/a.png'));
    });

    test('ลิงก์จากที่อื่นต้องไม่ถูกแตะต้อง', () {
      const url = 'https://example.com/photo.jpg';
      expect(Cloudinary.sized(url), url);
    });

    test('ลิงก์ที่เคยเติมแล้วต้องไม่ซ้อนอีกชั้น', () {
      const url =
          'https://res.cloudinary.com/c1xa0482/image/upload/w_400,q_auto,f_auto/v123/a.png';
      expect(Cloudinary.sized(url, width: 800), url);
    });
  });

  group('Cloudinary.upload', () {
    test('isReady สะท้อนค่าใน AppConfig', () {
      expect(Cloudinary.isReady, AppConfig.cloudinaryReady);
    });

    // ยิงขึ้น Cloudinary จริง — ข้ามถ้ายังไม่ได้ตั้งค่า
    test('อัปโหลดจริงแล้วได้ลิงก์ https กลับมา', () async {
      if (!Cloudinary.isReady) {
        markTestSkipped('ยังไม่ได้ตั้งค่า Cloudinary ใน AppConfig');
        return;
      }
      final url = await Cloudinary.upload(_tinyPng(), filename: 'unit_test.png');
      expect(url, startsWith('https://res.cloudinary.com/'));
      expect(url, contains(AppConfig.cloudinaryCloudName));

      // ลิงก์ที่ได้ต้องแปลงเป็นเวอร์ชันย่อได้ด้วย
      expect(Cloudinary.sized(url, width: 300), contains('w_300,q_auto,f_auto'));
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}
