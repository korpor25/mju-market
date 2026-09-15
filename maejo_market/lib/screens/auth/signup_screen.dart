import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../state/app_state.dart';
import '../../theme/app_colors.dart';
import '../../widgets/common.dart';

class SignupScreen extends StatefulWidget {
  SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _form = GlobalKey<FormState>();
  UserRole _role = UserRole.buyer;

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _phone = TextEditingController();

  bool _obscure = true;
  bool _agree = false;
  bool _busy = false;

  bool get _isSeller => _role == UserRole.seller;

  @override
  void dispose() {
    for (final c in [_name, _email, _password, _confirm, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (!_agree) {
      showSnack(context, 'กรุณายอมรับข้อกำหนดและเงื่อนไข', bad: true);
      return;
    }
    setState(() => _busy = true);
    // สมัครแค่บัญชี — คำขอเปิดร้านยื่นทีหลังในหน้าผู้ขาย หลังเชื่อม LINE แล้ว
    // ไม่งั้นแอดมินอาจอนุมัติก่อนผู้ขายเชื่อม LINE แจ้งเตือนผลอนุมัติจะไม่ถึงไลน์
    final err = await appState.signUp(
      name: _name.text.trim(),
      email: _email.text,
      password: _password.text,
      phone: _phone.text.trim(),
      role: _role,
    );
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) {
      showSnack(context, err, bad: true);
    } else {
      showSnack(context,
          _isSeller ? 'สมัครสำเร็จ! ต่อไปเชื่อม LINE แล้วยื่นขอเปิดร้าน' : 'สมัครสมาชิกสำเร็จ 🎉');
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('สมัครสมาชิก')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 460),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppLogo(size: 64),
                    SizedBox(height: 8),
                    Center(
                      child: Text('สร้างบัญชีเพื่อใช้งานแอป Maejo Market',
                          style: TextStyle(color: AppColors.muted)),
                    ),
                    SizedBox(height: 20),
                    _label('1. เลือกประเภทบัญชี'),
                    Row(children: [
                      Expanded(
                        child: _RoleCard(
                          selected: _role == UserRole.buyer,
                          icon: Icons.person_outline_rounded,
                          title: 'ผู้บริโภค',
                          sub: '(ซื้อสินค้า)',
                          onTap: () => setState(() => _role = UserRole.buyer),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _RoleCard(
                          selected: _role == UserRole.seller,
                          icon: Icons.storefront_outlined,
                          title: 'ผู้ขาย',
                          sub: '(เปิดร้านค้า)',
                          onTap: () => setState(() => _role = UserRole.seller),
                        ),
                      ),
                    ]),
                    SizedBox(height: 18),
                    _label('2. ข้อมูลส่วนตัว'),
                    _field(_name, 'ชื่อ-นามสกุล *', Icons.person_outline,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'กรอกชื่อ-นามสกุล' : null),
                    _field(_email, 'อีเมล *', Icons.mail_outline,
                        keyboard: TextInputType.emailAddress,
                        validator: (v) => (v == null || !v.contains('@')) ? 'กรอกอีเมลให้ถูกต้อง' : null),
                    _field(_password, 'รหัสผ่าน *', Icons.lock_outline,
                        obscure: _obscure,
                        suffix: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                        helper: 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร',
                        validator: (v) => (v == null || v.length < 6) ? 'อย่างน้อย 6 ตัวอักษร' : null),
                    _field(_confirm, 'ยืนยันรหัสผ่าน *', Icons.lock_outline,
                        obscure: _obscure,
                        validator: (v) => (v != _password.text) ? 'รหัสผ่านไม่ตรงกัน' : null),
                    _field(_phone, _isSeller ? 'เบอร์โทรศัพท์ *' : 'เบอร์โทรศัพท์ (ไม่บังคับ)', Icons.phone_outlined,
                        keyboard: TextInputType.phone,
                        validator: (v) => (_isSeller && (v == null || v.trim().isEmpty)) ? 'กรอกเบอร์โทรศัพท์' : null),
                    if (_isSeller)
                      Container(
                        margin: EdgeInsets.only(top: 2, bottom: 8),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.leafSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'สมัครเสร็จแล้ว ขั้นต่อไปคือเชื่อม LINE ของตลาด '
                                'แล้วจึงกรอกข้อมูลร้านเพื่อยื่นขอเปิดร้าน',
                                style: TextStyle(fontSize: 12.5, color: AppColors.text, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 4),
                    CheckboxListTile(
                      value: _agree,
                      onChanged: (v) => setState(() => _agree = v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text('ฉันยอมรับข้อกำหนดและเงื่อนไข และนโยบายความเป็นส่วนตัว',
                          style: TextStyle(fontSize: 13)),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4))
                          : Text(_isSeller ? 'สมัครสำหรับผู้ขาย' : 'สมัครสมาชิก'),
                    ),
                    SizedBox(height: 14),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('มีบัญชีอยู่แล้ว? เข้าสู่ระบบ'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: EdgeInsets.only(bottom: 10, top: 4),
        child: Text(t, style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary)),
      );

  Widget _field(
    TextEditingController c,
    String hint,
    IconData icon, {
    bool obscure = false,
    Widget? suffix,
    String? helper,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        obscureText: obscure,
        keyboardType: keyboard,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon),
          suffixIcon: suffix,
          helperText: helper,
        ),
        validator: validator,
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback onTap;
  const _RoleCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.leafSoft : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.muted, size: 26),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  Text(sub, style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
