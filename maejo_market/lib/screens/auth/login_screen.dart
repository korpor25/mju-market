import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app_config.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/animations.dart';
import '../../widgets/common.dart';
import '../../widgets/wave_header.dart';
import 'signup_screen.dart';

/// หน้าเข้าสู่ระบบ — หัวจอสีแบรนด์ทรงคลื่น + ฟอร์มพื้นขาว
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final err = await appState.signIn(_email.text, _password.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) showSnack(context, err, bad: true);
  }

  /// เข้าดูตลาดโดยไม่ลงทะเบียน — _Root จะพาไปมุมมองผู้ซื้อเองเมื่อ guest = true
  Future<void> _browseAsGuest() async {
    setState(() => _busy = true);
    await appState.continueAsGuest();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _forgotPassword() async {
    final emailC = TextEditingController(text: _email.text.trim());
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ลืมรหัสผ่าน'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('กรอกอีเมลของคุณ ระบบจะส่งลิงก์ตั้งรหัสผ่านใหม่ไปให้',
                style: TextStyle(fontSize: 13, color: AppColors.muted)),
            const SizedBox(height: 12),
            TextField(
              controller: emailC,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                  hintText: 'อีเมล', prefixIcon: Icon(Icons.mail_outline_rounded)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true), child: const Text('ส่งลิงก์')),
        ],
      ),
    );
    if (ok == true) {
      final email = emailC.text.trim();
      if (email.contains('@')) {
        final err = await appState.resetPassword(email);
        if (mounted) {
          showSnack(context, err ?? 'ส่งลิงก์ตั้งรหัสผ่านใหม่ไปที่ $email แล้ว', bad: err != null);
        }
      } else if (mounted) {
        showSnack(context, 'กรอกอีเมลให้ถูกต้อง', bad: true);
      }
    }
    emailC.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // หัวจอสูงตามจอ แต่คุมไม่ให้เตี้ยจนโลโก้อึดอัด หรือสูงจนฟอร์มตกขอบ
    final headerH = math.max(250.0, math.min(size.height * 0.40, 340.0));

    return Scaffold(
      backgroundColor: AppColors.surface,
      // IntrinsicHeight + Expanded ทำให้ฟอร์มจัดกลางพื้นที่ใต้หัวจอเมื่อจอสูง
      // แต่ยังเลื่อนได้ตามปกติเมื่อจอเตี้ย (หรือคีย์บอร์ดเด้งขึ้นมา)
      body: LayoutBuilder(
        builder: (context, box) => SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: box.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  WaveHeader(
                    height: headerH,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const LogoBadge(size: 112),
                        const SizedBox(height: 14),
                        const Text(
                          'Maejo Market',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ตลาดสดแม่โจ้ · ของสดของดีจากชุมชน',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: Form(
                            key: _form,
                            child: Column(
                              // min = ให้ Center จัดฟอร์มไว้กลางพื้นที่ใต้หัวจอจริง ๆ
                              // (ถ้าเป็น max คอลัมน์จะยืดเต็มแล้วเนื้อหาไปกองอยู่ด้านบน)
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: staggered(stepMs: 80, [
                                Center(
                                  child: Text('เข้าสู่ระบบ',
                                      style: TextStyle(
                                          fontSize: 21,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.text)),
                                ),
                                const SizedBox(height: 22),
                                UnderlineField(
                                  controller: _email,
                                  label: 'อีเมล',
                                  hint: 'you@example.com',
                                  keyboard: TextInputType.emailAddress,
                                  validator: (v) => (v == null || !v.contains('@'))
                                      ? 'กรอกอีเมลให้ถูกต้อง'
                                      : null,
                                ),
                                UnderlineField(
                                  controller: _password,
                                  label: 'รหัสผ่าน',
                                  hint: 'อย่างน้อย 6 ตัวอักษร',
                                  obscure: _obscure,
                                  onSubmitted: (_) => _busy ? null : _login(),
                                  suffix: IconButton(
                                    iconSize: 20,
                                    color: AppColors.faint,
                                    icon: Icon(_obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined),
                                    onPressed: () => setState(() => _obscure = !_obscure),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.length < 6) ? 'อย่างน้อย 6 ตัวอักษร' : null,
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _forgotPassword,
                                    child: const Text('ลืมรหัสผ่าน?'),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // ปุ่มคู่: เข้าสู่ระบบ (ทึบ) และ สมัครสมาชิก (ขอบ)
                                Row(
                                  children: [
                                    Expanded(child: _LoginButton(busy: _busy, onTap: _login)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => Navigator.push(context,
                                            MaterialPageRoute(builder: (_) => SignupScreen())),
                                        child: const FittedBox(
                                            fit: BoxFit.scaleDown, child: Text('สมัครสมาชิก')),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // ผู้บริโภคที่ยังไม่อยากสมัคร เข้าไปดูร้าน/ผังตลาดได้เลย
                                Center(
                                  child: TextButton.icon(
                                    onPressed: _busy ? null : _browseAsGuest,
                                    icon: const Icon(Icons.storefront_outlined, size: 18),
                                    label: const Text('เข้าชมตลาดโดยไม่ต้องสมัคร'),
                                  ),
                                ),
                                if (!AppConfig.useFirebase) ...[
                                  const SizedBox(height: 22),
                                  _DemoHint(onFill: (e) {
                                    _email.text = e;
                                    _password.text = '123456';
                                  }),
                                ],
                              ]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ปุ่มเข้าสู่ระบบ — ย่อลงตอนกด และเปลี่ยนเป็นวงกลมหมุนตอนกำลังส่ง
class _LoginButton extends StatefulWidget {
  final bool busy;
  final VoidCallback onTap;
  const _LoginButton({required this.busy, required this.onTap});

  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _down ? 0.97 : 1,
      duration: const Duration(milliseconds: 120),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        child: ElevatedButton(
          onPressed: widget.busy ? null : widget.onTap,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: widget.busy
                ? const SizedBox(
                    key: ValueKey('busy'),
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                  )
                : const FittedBox(
                    key: ValueKey('idle'),
                    fit: BoxFit.scaleDown,
                    child: Text('เข้าสู่ระบบ'),
                  ),
          ),
        ),
      ),
    );
  }
}

class _DemoHint extends StatelessWidget {
  final void Function(String email) onFill;
  const _DemoHint({required this.onFill});

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String email) => InkWell(
          onTap: () => onFill(email),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(children: [
              Icon(Icons.touch_app_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('$label · ',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
              Expanded(
                child: Text(email, style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
              ),
            ]),
          ),
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.leafSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🧪 บัญชีทดลอง (Demo Mode) · รหัส 123456',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          const SizedBox(height: 6),
          row('ผู้ดูแลระบบ', 'admin@maejo.com'),
          row('ผู้ขาย', 'seller@maejo.com'),
          row('ผู้บริโภค', 'buyer@maejo.com'),
          const SizedBox(height: 2),
          Text('แตะเพื่อกรอกอัตโนมัติ', style: TextStyle(color: AppColors.faint, fontSize: 11)),
        ],
      ),
    );
  }
}
