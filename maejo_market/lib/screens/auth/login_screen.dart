import 'package:flutter/material.dart';
import '../../app_config.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import 'signup_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    const AppLogo(size: 76),
                    const SizedBox(height: 24),
                    const Text('ยินดีต้อนรับ',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text('เข้าสู่ระบบเพื่อใช้งานแอป Maejo Market',
                        style: TextStyle(color: AppColors.muted)),
                    const SizedBox(height: 22),
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
                      decoration: InputDecoration(
                        hintText: 'รหัสผ่าน',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6) ? 'อย่างน้อย 6 ตัวอักษร' : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => showSnack(context, 'ฟีเจอร์ลืมรหัสผ่าน — ตั้งค่าใน Firebase Auth'),
                        child: const Text('ลืมรหัสผ่าน?'),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ElevatedButton(
                      onPressed: _busy ? null : _login,
                      child: _busy
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4))
                          : const Text('เข้าสู่ระบบ'),
                    ),
                    const SizedBox(height: 18),
                    Row(children: const [
                      Expanded(child: Divider(color: AppColors.border)),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('หรือ', style: TextStyle(color: AppColors.muted))),
                      Expanded(child: Divider(color: AppColors.border)),
                    ]),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(child: _SocialButton(label: 'Google', icon: Icons.g_mobiledata_rounded)),
                      const SizedBox(width: 12),
                      Expanded(child: _SocialButton(label: 'Facebook', icon: Icons.facebook_rounded)),
                    ]),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('ยังไม่มีบัญชี? ', style: TextStyle(color: AppColors.muted)),
                        GestureDetector(
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const SignupScreen())),
                          child: const Text('สมัครสมาชิก',
                              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    if (!AppConfig.useFirebase) ...[
                      const SizedBox(height: 22),
                      _DemoHint(onFill: (e) {
                        _email.text = e;
                        _password.text = '123456';
                      }),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SocialButton({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => showSnack(context, 'ล็อกอินด้วย $label — เปิดใช้เมื่อตั้งค่า Firebase Auth'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.border),
      ),
      icon: Icon(icon, size: 22),
      label: Text(label),
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
              const Icon(Icons.touch_app_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('$label · ', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
              Text(email, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
            ]),
          ),
        );
    return AppCard(
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
          const Text('แตะเพื่อกรอกอัตโนมัติ', style: TextStyle(color: AppColors.faint, fontSize: 11)),
        ],
      ),
    );
  }
}
