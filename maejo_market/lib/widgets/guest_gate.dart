import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';

/// ตัวช่วยสำหรับ "โหมดผู้เยี่ยมชม" (เข้าดูตลาดโดยไม่ลงทะเบียน)
///
/// ผู้เยี่ยมชมดูร้าน สินค้า ผังตลาด และโปรโมชั่นได้ทั้งหมด สิ่งที่ต้องมีบัญชีจริง ๆ
/// คือสิ่งที่ผูกกับตัวบุคคล — ติดตามร้าน เขียนรีวิว รับแจ้งเตือน และเปิดร้าน

/// พาไปหน้าเข้าสู่ระบบ
///
/// ต้องปิดหน้าที่ซ้อนอยู่ให้หมดก่อน เพราะหน้าล็อกอินมาจาก _Root ที่อยู่ล่างสุดของ stack
/// ถ้าไม่ปิด หน้าร้านที่เปิดค้างไว้จะทับหน้าล็อกอินอยู่
void goToSignIn(BuildContext context) {
  Navigator.of(context).popUntil((r) => r.isFirst);
  appState.leaveGuest();
}

/// ชวนผู้เยี่ยมชมเข้าสู่ระบบก่อนทำสิ่งที่ต้องมีบัญชี
///
/// [action] คือสิ่งที่ผู้ใช้กำลังจะทำ เช่น 'ติดตามร้าน' — เอาไปต่อในประโยคเลย
Future<void> promptSignIn(BuildContext context, String action) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('เข้าสู่ระบบก่อนนะ'),
      content: Text(
        '$action ต้องใช้บัญชีผู้ใช้ เพราะเป็นข้อมูลของคุณเอง\n'
        'เข้าชมร้านค้า สินค้า และผังตลาดยังทำได้ตามปกติโดยไม่ต้องสมัคร',
        style: const TextStyle(height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: const Text('ดูต่อก่อน'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(c, true),
          child: const Text('เข้าสู่ระบบ'),
        ),
      ],
    ),
  );
  if (ok == true && context.mounted) goToSignIn(context);
}

/// แถบบางบนสุดของหน้า บอกว่ากำลังดูแบบไม่ได้ล็อกอิน + ทางลัดไปเข้าสู่ระบบ
class GuestBanner extends StatelessWidget {
  const GuestBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!appState.isGuest) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.leafSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Icon(Icons.visibility_outlined, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'กำลังเข้าชมแบบไม่ลงทะเบียน',
            style: TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
          ),
        ),
        TextButton(
          onPressed: () => goToSignIn(context),
          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          child: const Text('เข้าสู่ระบบ'),
        ),
      ]),
    );
  }
}
