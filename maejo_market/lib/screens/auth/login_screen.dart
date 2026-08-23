import 'package:flutter/material.dart';
import '../../app_config.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';
import '../../widgets/animations.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({super.key});

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
        title: Text('ลืมรหัสผ่าน'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('กรอกอีเมลของคุณ ระบบจะส่งลิงก์ตั้งรหัสผ่านใหม่ไปให้',
                style: TextStyle(fontSize: 13, color: AppColors.muted)),
            SizedBox(height: 12),
            TextField(
              controller: emailC,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(hintText: 'อีเมล', prefixIcon: Icon(Icons.mail_outline_rounded)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('ยกเลิก')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('ส่งลิงก์')),
        ],
      ),
    );
    if (ok == true) {
      final email = emailC.text.trim();
      if (email.contains('@')) {
        final err = await appState.resetPassword(email);
        if (mounted) showSnack(context, err ?? 'ส่งลิงก์ตั้งรหัสผ่านใหม่ไปที่ $email แล้ว', bad: err != null);
      } else if (mounted) {
        showSnack(context, 'กรอกอีเมลให้ถูกต้อง', bad: true);
      }
    }
    emailC.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 440),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: staggered(stepMs: 55, [
                    SizedBox(height: 8),
                    AppLogo(size: 76),
                    SizedBox(height: 24),
                    Text('ยินดีต้อนรับ',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    SizedBox(height: 4),
                    Text('เข้าสู่ระบบเพื่อใช้งานแอป Maejo Market',
                        style: TextStyle(color: AppColors.muted)),
                    SizedBox(height: 22),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'อีเมล',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      validator: (v) =>
                          (v == null || !v.contains('@')) ? 'กรอกอีเมลให้ถูกต้อง' : null,
                    ),
                    SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        hintText: 'รหัสผ่าน',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
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
                        onPressed: _forgotPassword,
                        child: Text('ลืมรหัสผ่าน?'),
                      ),
                    ),
                    SizedBox(height: 4),
                    ElevatedButton(
                      onPressed: _busy ? null : _login,
                      child: _busy
                          ? SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4))
                          : Text('เข้าสู่ระบบ'),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('ยังไม่มีบัญชี? ', style: TextStyle(color: AppColors.muted)),
                        GestureDetector(
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => SignupScreen())),
                          child: Text('สมัครสมาชิก',
                              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    if (!AppConfig.useFirebase) ...[
                      SizedBox(height: 22),
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

class _DemoHint extends StatelessWidget {
  final void Function(String email) onFill;
  const _DemoHint({required this.onFill});

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String email) => InkWell(
          onTap: () => onFill(email),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(children: [
              Icon(Icons.touch_app_outlined, size: 16, color: AppColors.primary),
              SizedBox(width: 8),
              Text('$label · ', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
              Text(email, style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
            ]),
          ),
        );
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🧪 บัญชีทดลอง (Demo Mode) · รหัส 123456',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          SizedBox(height: 6),
          row('ผู้ดูแลระบบ', 'admin@maejo.com'),
          row('ผู้ขาย', 'seller@maejo.com'),
          row('ผู้บริโภค', 'buyer@maejo.com'),
          SizedBox(height: 2),
          Text('แตะเพื่อกรอกอัตโนมัติ', style: TextStyle(color: AppColors.faint, fontSize: 11)),
        ],
      ),
    );
  }
}
