import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_config.dart';
import '../theme/app_colors.dart';
import '../widgets/common.dart';

/// สีแบรนด์ LINE — ใช้กับปุ่มที่พาไปบัญชีทางการของตลาดเท่านั้น
const _lineGreen = Color(0xFF06C755);

/// ช่วยเหลือ / ติดต่อเรา
///
/// ช่องทางหลักคือ LINE OA เพราะตอบได้ทันทีและถามได้โดยไม่ต้องมีบัญชีในแอป
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faq = [
    (
      'ไม่อยากสมัครสมาชิก ใช้งานได้ไหม',
      'ได้ — ที่หน้าเข้าสู่ระบบกด "เข้าชมตลาดโดยไม่ต้องสมัคร" แล้วดูร้านค้า สินค้า '
          'ผังตลาด และโปรโมชั่นได้ทั้งหมด ส่วนการติดตามร้าน เขียนรีวิว และรับแจ้งเตือน '
          'ต้องมีบัญชีเพราะเป็นข้อมูลของคุณเอง',
    ),
    (
      'อยากเช่าแผงขายของ ต้องทำอย่างไร',
      'สมัครสมาชิก > ที่หน้าบัญชีเลือกบทบาทผู้ขาย > เชื่อมต่อ LINE เพื่อรับแจ้งผลอนุมัติ > '
          'ยื่นขอเปิดร้าน เมื่อผู้ดูแลตลาดอนุมัติแล้วจึงเลือกจองแผงที่ว่างได้จากผังตลาด',
    ),
    (
      'ค่าเช่าแผงคิดอย่างไร',
      'คิดจากราคาแผงต่อวันคูณจำนวนวันต่อรอบบิล ดูยอดที่ต้องชำระและแจ้งโอนพร้อมแนบสลิป '
          'ได้ที่หน้าหลักของผู้ขาย เมนูค่าเช่าแผง',
    ),
    (
      'รีวิวร้านอย่างไร แก้ไขได้ไหม',
      'เปิดหน้าร้านแล้วกด "เขียนรีวิว" ให้ได้คนละ 1 รีวิวต่อร้าน กลับมาแก้ไขหรือลบรีวิวของตัวเอง '
          'ได้ตลอด (เจ้าของร้านรีวิวร้านตัวเองไม่ได้)',
    ),
    (
      'ลืมรหัสผ่านทำอย่างไร',
      'ที่หน้าเข้าสู่ระบบกด "ลืมรหัสผ่าน?" แล้วกรอกอีเมลที่สมัครไว้ ระบบจะส่งลิงก์ตั้งรหัสผ่านใหม่ไปให้',
    ),
    (
      'ทำไมยังไม่ได้รับแจ้งเตือนทางไลน์',
      'ต้องเพิ่มเพื่อนบัญชีทางการของตลาดและส่งรหัส 6 หลักจากหน้าตั้งค่าในแอปก่อน '
          'ถ้าเคยบล็อกหรือลบเพื่อนไว้ การเชื่อมจะถูกยกเลิกอัตโนมัติ ต้องเชื่อมใหม่อีกครั้ง',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ช่วยเหลือ / ติดต่อเรา')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (AppConfig.lineReady) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                          color: _lineGreen, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.chat_bubble_rounded, size: 17, color: Colors.white),
                    ),
                    const SizedBox(width: 13),
                    const Expanded(
                      child: Text('ถามผ่านไลน์ตลาดแม่โจ้',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Text('ทักไปแล้วพิมพ์คำถามได้เลย ไม่ต้องมีบัญชีในแอป:',
                      style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      _Hint('โปรโมชั่น'),
                      _Hint('แผงว่าง'),
                      _Hint('ร้านค้า'),
                      _Hint('มีผักกาดขายมั้ย'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => launchUrl(
                        Uri.parse(AppConfig.lineAddFriendUrl),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                      label: const Text('เพิ่มเพื่อนใน LINE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _lineGreen,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SectionTitle('คำถามที่พบบ่อย', icon: Icons.help_outline_rounded),
          AppCard(
            padding: EdgeInsets.zero,
            child: Theme(
              // เอาเส้นคั่นของ ExpansionTile ออก ให้ใช้เส้นคั่นชุดเดียวกับการ์ดอื่นในแอป
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              // ExpansionTile ข้างในเป็น ListTile ซึ่งต้องมี Material คั่นจากพื้นสีของการ์ด
              // ไม่งั้น Flutter เตือนว่าพื้นหลัง/ripple จะมองไม่เห็น
              child: Material(
                type: MaterialType.transparency,
                child: Column(
                  children: [
                    for (var i = 0; i < _faq.length; i++)
                      Container(
                        decoration: BoxDecoration(
                          border: i == _faq.length - 1
                              ? null
                              : Border(bottom: BorderSide(color: AppColors.border)),
                        ),
                        child: ExpansionTile(
                          title: Text(_faq[i].$1,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                          expandedCrossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_faq[i].$2,
                                style: TextStyle(
                                    color: AppColors.muted, fontSize: 13, height: 1.55)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SectionTitle('ติดต่อผู้ดูแลตลาด', icon: Icons.storefront_outlined),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppConfig.appNameTh,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 4),
                Text(
                  'เรื่องแผง ค่าเช่า หรือการอนุมัติร้าน ติดต่อผู้ดูแลตลาดได้ทางไลน์ของตลาด '
                  'หรือที่สำนักงานตลาดในเวลาทำการ',
                  style: TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// ตัวอย่างคำถามที่พิมพ์ทักไลน์ได้
class _Hint extends StatelessWidget {
  final String text;
  const _Hint(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text('"$text"',
          style: TextStyle(fontSize: 12, color: AppColors.text, fontWeight: FontWeight.w600)),
    );
  }
}
