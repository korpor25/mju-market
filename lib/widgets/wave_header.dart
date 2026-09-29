import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// ========================================================================
/// หัวจอทรงคลื่น — แถบสีแบรนด์ด้านบน แล้วไล่เป็นคลื่นขาวลงมาหาเนื้อหา
/// ใช้กับหน้าเข้าสู่ระบบ / สมัครสมาชิก ให้พื้นที่ฟอร์มเป็นสีขาวสะอาด
///
/// คลื่นวาดด้วย CustomPainter (ไม่ใช่ ClipPath) เพราะต้องซ้อนหลายชั้น
/// ชั้นโปร่งก่อนแล้วปิดท้ายด้วยขาวทึบ — ได้ความรู้สึก "ระลอกน้ำ" ไม่ใช่เส้นโค้งเดียว
/// ========================================================================
class WaveHeader extends StatelessWidget {
  final double height;
  final Widget child;

  const WaveHeader({super.key, required this.height, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryDark,
                  AppColors.primary,
                  AppColors.primaryLight,
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
            ),
          ),
          CustomPaint(painter: const _WavePainter()),
          SafeArea(
            bottom: false,
            // เว้นพื้นที่ด้านล่างไว้ให้คลื่น (ยอดคลื่นแรกอยู่ที่ 70% ของหัวจอ)
            // FittedBox ย่อเนื้อหาลงเองเมื่อหน้าต่างเตี้ยจนพื้นที่ไม่พอ
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 8, 24, height * 0.30),
              child: Center(
                child: FittedBox(fit: BoxFit.scaleDown, child: child),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// คลื่นขาว 3 ระลอกที่ก้นหัวจอ — สองระลอกแรกโปร่ง ระลอกสุดท้ายทึบต่อกับพื้นฟอร์ม
class _WavePainter extends CustomPainter {
  const _WavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    _wave(canvas, size, base: 0.70, amp: 0.055, alpha: 0.16, flip: false);
    _wave(canvas, size, base: 0.80, amp: 0.048, alpha: 0.28, flip: true);
    _wave(canvas, size, base: 0.90, amp: 0.042, alpha: 1.0, flip: false);
  }

  void _wave(
    Canvas canvas,
    Size size, {
    required double base, // ตำแหน่งยอดคลื่น (สัดส่วนความสูงหัวจอ)
    required double amp, // ความสูงของลอน
    required double alpha,
    required bool flip, // กลับด้านลอน ให้แต่ละระลอกไม่ซ้อนทับกันพอดี
  }) {
    final w = size.width;
    final h = size.height;
    final y = h * base;
    final a = h * amp * (flip ? -1 : 1);

    final path = Path()
      ..moveTo(0, y + a * 0.6)
      ..cubicTo(w * 0.18, y - a * 0.9, w * 0.38, y + a * 1.5, w * 0.56, y + a * 0.35)
      ..cubicTo(w * 0.74, y - a * 0.85, w * 0.88, y - a * 0.5, w, y + a * 0.15)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(
      path,
      Paint()..color = Colors.white.withValues(alpha: alpha),
    );
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => false;
}

/// โลโก้ในวงกลมขาว สำหรับวางบนหัวจอสีเข้ม
class LogoBadge extends StatelessWidget {
  final double size;
  const LogoBadge({super.key, this.size = 104});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.10),
      child: Image.asset(
        'assets/images/logo.png',
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}

/// ช่องกรอกแบบขีดเส้นใต้ (ป้ายชื่ออยู่เหนือเส้น) — สไตล์ฟอร์มของหน้า auth
class UnderlineField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboard;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;
  final String? helper;

  const UnderlineField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscure = false,
    this.suffix,
    this.keyboard,
    this.validator,
    this.onSubmitted,
    this.helper,
  });

  @override
  Widget build(BuildContext context) {
    OutlineBorderLike line(Color c, double w) =>
        UnderlineInputBorder(borderSide: BorderSide(color: c, width: w));

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
          TextFormField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboard,
            validator: validator,
            onFieldSubmitted: onSubmitted,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              filled: false,
              isDense: true,
              hintText: hint,
              helperText: helper,
              helperStyle: TextStyle(fontSize: 11.5, color: AppColors.faint),
              contentPadding: const EdgeInsets.only(top: 10, bottom: 8),
              suffixIcon: suffix,
              suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 32),
              border: line(AppColors.border, 1),
              enabledBorder: line(AppColors.border, 1),
              focusedBorder: line(AppColors.primary, 1.8),
              errorBorder: line(AppColors.bad, 1),
              focusedErrorBorder: line(AppColors.bad, 1.8),
            ),
          ),
        ],
      ),
    );
  }
}

/// alias สั้น ๆ ให้ helper ด้านบนอ่านง่าย (UnderlineInputBorder เป็น InputBorder)
typedef OutlineBorderLike = InputBorder;
