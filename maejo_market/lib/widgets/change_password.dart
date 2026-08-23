import 'package:flutter/material.dart';
import '../state/app_state.dart';
import 'common.dart';

/// เปิด dialog เปลี่ยนรหัสผ่าน (ยืนยันรหัสเดิม + รหัสใหม่)
Future<void> showChangePasswordDialog(BuildContext rootContext) async {
  final curC = TextEditingController();
  final newC = TextEditingController();
  final confirmC = TextEditingController();
  final formKey = GlobalKey<FormState>();

  await showDialog<void>(
    context: rootContext,
    builder: (dialogContext) {
      var busy = false;
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> submit() async {
            if (!formKey.currentState!.validate()) return;
            setState(() => busy = true);
            final err = await appState.changePassword(curC.text, newC.text);
            if (!dialogContext.mounted) return;
            setState(() => busy = false);
            if (err != null) {
              showSnack(dialogContext, err, bad: true);
            } else {
              Navigator.pop(dialogContext);
              if (rootContext.mounted) showSnack(rootContext, 'เปลี่ยนรหัสผ่านสำเร็จ');
            }
          }

          return AlertDialog(
            title: const Text('เปลี่ยนรหัสผ่าน'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: curC,
                    obscureText: true,
                    decoration: const InputDecoration(hintText: 'รหัสผ่านปัจจุบัน', prefixIcon: Icon(Icons.lock_outline)),
                    validator: (v) => (v == null || v.isEmpty) ? 'กรอกรหัสผ่านปัจจุบัน' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: newC,
                    obscureText: true,
                    decoration: const InputDecoration(hintText: 'รหัสผ่านใหม่', prefixIcon: Icon(Icons.lock_reset_rounded)),
                    validator: (v) => (v == null || v.length < 6) ? 'อย่างน้อย 6 ตัวอักษร' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: confirmC,
                    obscureText: true,
                    decoration: const InputDecoration(hintText: 'ยืนยันรหัสผ่านใหม่', prefixIcon: Icon(Icons.lock_reset_rounded)),
                    validator: (v) => (v != newC.text) ? 'รหัสผ่านไม่ตรงกัน' : null,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: busy ? null : () => Navigator.pop(dialogContext), child: const Text('ยกเลิก')),
              ElevatedButton(
                onPressed: busy ? null : submit,
                child: busy
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2))
                    : const Text('บันทึก'),
              ),
            ],
          );
        },
      );
    },
  );

  curC.dispose();
  newC.dispose();
  confirmC.dispose();
}
