import 'package:flutter/material.dart';
import '../../app_config.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/animations.dart';
import '../../widgets/aurora.dart';
import '../../widgets/common.dart';
import '../../widgets/shop_ui.dart';
import 'signup_screen.dart';

/// หน้าเข้าสู่ระบบ — พื้นหลังออโรราเคลื่อนไหว + การ์ดฟอร์มลอยอยู่ด้านหน้า
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
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('ส่งลิงก์')),
        ],
      ),
    );
    if (ok == true) {
      final email = emailC.text.trim();
      if (email.contains('@')) {
        final err = await appState.resetPassword(email);
        if (mounted) {
          showSnack(context, err ?? 'ส่งลิงก์ตั้งรหัสผ่านใหม่ไปที่ $email แล้ว',
              bad: err != null);
        }
      } else if (mounted) {
        showSnack(context, 'กรอกอีเมลให้ถูกต้อง', bad: true);
      }
    }
    emailC.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuroraBackground(
        speed: 0.8,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: staggered(stepMs: 90, [
                    // ---- โลโก้ + ชื่อแอป ----
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      child: Column(children: [
                        const AppLogo(size: 120, showText: false),
                        const SizedBox(height: 16),
                        ShimmerText(
                          'Maejo Market',
                          highlight: AppColors.primaryLight,
                          style: TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('ตลาดแม่โจ้ · ของสดของดีจากชุมชน',
                            style: TextStyle(color: AppColors.muted, fontSize: 13.5)),
                      ]),
                    ),
                    const SizedBox(height: 24),

                    // ---- การ์ดฟอร์ม ----
                    _GlassCard(
                      child: Form(
                        key: _form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('ยินดีต้อนรับ',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.text)),
                            const SizedBox(height: 2),
                            Text('เข้าสู่ระบบเพื่อใช้งานแอป',
                                style: TextStyle(color: AppColors.muted, fontSize: 13.5)),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                hintText: 'อีเมล',
                                prefixIcon: Icon(Icons.mail_outline_rounded),
                              ),
                              validator: (v) =>
                                  (v == null || !v.contains('@')) ? 'กรอกอีเมลให้ถูกต้อง' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _password,
                              obscureText: _obscure,
                              onFieldSubmitted: (_) => _busy ? null : _login(),
                              decoration: InputDecoration(
                                hintText: 'รหัสผ่าน',
                                prefixIcon: const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
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
                            const SizedBox(height: 4),
                            _LoginButton(busy: _busy, onTap: _login),
                            const SizedBox(height: 16),
                            // ฟอนต์ Kanit กว้างกว่าปกติ บนจอแคบบรรทัดนี้เคยล้น
                            // จึงย่อให้พอดีแทนที่จะตัดคำ
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('ยังไม่มีบัญชี? ',
                                      style: TextStyle(color: AppColors.muted)),
                                  GestureDetector(
                                    onTap: () => Navigator.push(context,
                                        MaterialPageRoute(builder: (_) => SignupScreen())),
                                    child: Text('สมัครสมาชิก',
                                        style: TextStyle(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w800)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (!AppConfig.useFirebase) ...[
                      const SizedBox(height: 18),
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
    );
  }
}

/// การ์ดพื้นโปร่งเล็กน้อยสำหรับวางบนพื้นหลังออโรรา
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: softShadow(blur: 30, y: 14, opacity: 0.12),
      ),
      child: child,
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
                : const Row(
                    key: ValueKey('idle'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('เข้าสู่ระบบ'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
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
              Text(email, style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
            ]),
          ),
        );
    return _GlassCard(
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
          Text('แตะเพื่อกรอกอัตโนมัติ',
              style: TextStyle(color: AppColors.faint, fontSize: 11)),
        ],
      ),
    );
  }
}
