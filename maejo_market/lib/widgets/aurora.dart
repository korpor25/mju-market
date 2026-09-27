import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// ========================================================================
/// พื้นหลัง "โฮโลแกรม / ผ้าไหม" — เทคนิค mesh gradient blobs
///
/// แนวคิด: แทนที่จะวาดเส้นบาง ๆ วิ่ง (แบบ aurora.dart เดิม) เราวาด "ก้อนสี"
/// ขนาดใหญ่มาก 8 ก้อน ด้วย RadialGradient ที่จางหายแบบนุ่ม ๆ (soft falloff)
/// ซ้อนทับกันจนสีละลายเข้าหากันเหมือน mesh gradient — ไม่มีขอบคม ไม่เห็นเป็นเส้น
///
/// ทำไมไม่ใช้ MaskFilter.blur กับก้อนสี: falloff ของ RadialGradient นุ่มพออยู่แล้ว
/// และการเบลอรัศมีใหญ่ ๆ หลายชั้นช้ามากบน Flutter Web CanvasKit จึงเก็บ blur ไว้ใช้
/// เฉพาะ "ริ้วผ้า" ที่วาดทับด้านบน (คือสิ่งที่ทำให้ดูเป็นรอยพับของผ้าไหม)
///
/// รวมแล้ววาดประมาณ 14 ชิ้นต่อเฟรม และใช้ AnimationController ตัวเดียว
/// ========================================================================

// ---- จานสี (โทนขาวเป็นหลัก แตะเขียวบาง ๆ พอไม่ให้จืด) ----
const Color _kMintPale = Color(0xFFF8FDFA); // ขาวอมเขียวจาง
const Color _kMintSoft = Color(0xFFF1FAF5);
const Color _kMint = Color(0xFFE4F6EC); // มิ้นต์ของแบรนด์ เวอร์ชันจางมาก
const Color _kLeaf = Color(0xFFEDF9F2);
const Color _kGrass = Color(0xFFDAF2E5); // เขียวอ่อน
const Color _kGrassSoft = Color(0xFFF5FCF8);
const Color _kForest = Color(0xFFCBEBDA); // เข้มสุดในชุด — ยังเป็นพาสเทลจาง
const Color _kWhite = Color(0xFFFFFFFF); // ขาว = สีหลักของพื้นหลัง
const Color _kSilk = Color(0xFFD6EFE2); // ริ้ว "รอยพับ" — เขียวจาง เพราะริ้วขาวจะจมหายไปในพื้นขาว

/// ก้อนสีหนึ่งก้อนของ mesh — ศูนย์กลางเคลื่อนบนเส้น Lissajous
///
/// [fx]/[fy] ต้องเป็น "จำนวนเต็ม" เพราะ controller วน 0→1 แล้วกระโดดกลับ 0
/// ถ้าความถี่เป็นจำนวนเต็ม ค่า sin ตอน t=1 จะเท่ากับตอน t=0 พอดี = ลูปไร้รอยต่อ
class _Blob {
  final Color color;
  final double cx; // จุดกึ่งกลางของวงโคจร (สัดส่วนของจอ)
  final double cy;
  final double ax; // รัศมีการแกว่งแนวนอน / แนวตั้ง
  final double ay;
  final double fx; // ความถี่ (จำนวนเต็ม, ค่าลบ = โคจรกลับทาง)
  final double fy;
  final double px; // เฟสเริ่มต้น — ให้แต่ละก้อนไม่ขยับพร้อมกัน
  final double py;
  final double radius; // สัดส่วนของด้านสั้นของจอ
  final double pulse; // รัศมีหายใจเข้า-ออกเล็กน้อย ทำให้รอยต่อของสีบิดไปมา
  final double alpha;

  const _Blob({
    required this.color,
    required this.cx,
    required this.cy,
    required this.ax,
    required this.ay,
    required this.fx,
    required this.fy,
    required this.px,
    required this.py,
    required this.radius,
    required this.alpha,
    this.pulse = 0.05,
  });
}

/// ก้อนสีทั้งหมด — จัดให้ทุกมุมจอมีเจ้าของสี จะได้ไม่มีมุมไหนจืด
const List<_Blob> _kBlobs = [
  // บนซ้าย: เขียวอ่อน (ก้อนใหญ่สุด เป็นโทนหลักของภาพ)
  _Blob(
      color: _kMintPale, cx: 0.20, cy: 0.22, ax: 0.14, ay: 0.11,
      fx: 1, fy: -1, px: 0.0, py: 1.2, radius: 0.82, alpha: 0.55, pulse: 0.06),
  // บนขวา: เขียวอ่อนกว่า
  _Blob(
      color: _kMintSoft, cx: 0.80, cy: 0.16, ax: 0.12, ay: 0.13,
      fx: -1, fy: 2, px: 2.1, py: 0.4, radius: 0.70, alpha: 0.48, pulse: 0.05),
  // ล่างกลาง: เขียวมิ้นต์ของแบรนด์
  _Blob(
      color: _kMint, cx: 0.46, cy: 0.82, ax: 0.16, ay: 0.10,
      fx: 2, fy: 1, px: 3.4, py: 2.6, radius: 0.74, alpha: 0.46, pulse: 0.07),
  // ซ้ายล่าง: เขียวใบไม้อ่อน
  _Blob(
      color: _kLeaf, cx: 0.10, cy: 0.64, ax: 0.13, ay: 0.14,
      fx: 1, fy: 2, px: 1.5, py: 4.0, radius: 0.80, alpha: 0.50, pulse: 0.05),
  // กลางขวา: เขียวกลาง
  _Blob(
      color: _kGrass, cx: 0.74, cy: 0.54, ax: 0.15, ay: 0.12,
      fx: -2, fy: 1, px: 0.9, py: 5.1, radius: 0.66, alpha: 0.50, pulse: 0.06),
  // กลางจอ: เขียวอ่อน — ตัวเชื่อมระหว่างโซนอ่อนกับโซนเข้ม
  _Blob(
      color: _kGrassSoft, cx: 0.40, cy: 0.44, ax: 0.18, ay: 0.15,
      fx: 1, fy: -2, px: 4.6, py: 2.0, radius: 0.58, alpha: 0.42, pulse: 0.08),
  // ขวาล่าง: เขียวเข้มสุดของชุด
  _Blob(
      color: _kForest, cx: 0.88, cy: 0.86, ax: 0.12, ay: 0.12,
      fx: -1, fy: -1, px: 2.8, py: 0.8, radius: 0.76, alpha: 0.52, pulse: 0.06),
  // ขาวก้อนใหญ่กลางจอ — กดให้ทั้งภาพเป็นโทนขาวและละลายรอยต่อของสีทั้งหมด
  _Blob(
      color: _kWhite, cx: 0.56, cy: 0.30, ax: 0.20, ay: 0.16,
      fx: 1, fy: 1, px: 5.6, py: 3.3, radius: 0.86, alpha: 0.62, pulse: 0.09),
];

/// พื้นหลังโฮโลแกรมแบบผ้าไหม วาง [child] ทับอยู่ด้านบน
class AuroraBackground extends StatefulWidget {
  final Widget child;

  /// ความเร็วรวม (1 = ช้าแบบธรรมชาติ ประมาณ 34 วินาทีต่อรอบ)
  final double speed;

  /// true = สีเข้มขึ้นเล็กน้อย (ยังเป็นพาสเทลสว่าง ไม่ใช่พื้นเข้ม)
  final bool intense;

  const AuroraBackground({
    super.key,
    required this.child,
    this.speed = 1,
    this.intense = false,
  });

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    // clamp กันผู้เรียกส่ง speed = 0 หรือค่าติดลบมาแล้ว duration พัง
    duration: Duration(
      milliseconds: (34000 / math.max(0.05, widget.speed)).round(),
    ),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // RepaintBoundary กันไม่ให้ child (เนื้อหาหน้าจอ) ถูกวาดใหม่ทุกเฟรม
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, __) => CustomPaint(
              painter: _AuroraPainter(t: _c.value, intense: widget.intense),
              size: Size.infinite,
              isComplex: true,
              willChange: true,
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final double t;
  final bool intense;

  const _AuroraPainter({required this.t, required this.intense});

  static const double _tau = math.pi * 2;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = Offset.zero & size;
    // ก้อนสีถูกวาดเลยขอบจอ — คลิปไว้เพื่อลด overdraw
    canvas.clipRect(rect);

    // ---- ชั้นล่างสุด: gradient เต็มจอ กันพื้นที่ว่างกลายเป็นสีเทา ----
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFFFF), // ขาวล้วนที่มุมบนซ้าย
            Color(0xFFFCFEFD), // ขาวอมเขียวแทบไม่รู้สึก
            Color(0xFFF5FBF8), // เขียวจางมาก
            Color(0xFFEAF7F0), // เขียวจางสุดที่มุมล่าง
          ],
          stops: [0.0, 0.36, 0.68, 1.0],
        ).createShader(rect),
    );

    final short = size.shortestSide;
    final k = intense ? 1.28 : 1.0;

    // ---- ชั้นที่ 2: ก้อนสี mesh (8 ก้อน) ----
    for (final b in _kBlobs) {
      final center = Offset(
        size.width * (b.cx + b.ax * math.sin(_tau * b.fx * t + b.px)),
        size.height * (b.cy + b.ay * math.sin(_tau * b.fy * t + b.py)),
      );
      final r = short *
          (b.radius + b.pulse * math.sin(_tau * b.fy * t + b.px + 1.7));
      final a = (b.alpha * k).clamp(0.0, 1.0);

      // stops หลายจุด = falloff ใกล้เคียงเกาส์เซียน ขอบจึงนุ่มจนไม่เห็นเป็นวงกลม
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              b.color.withValues(alpha: a),
              b.color.withValues(alpha: a * 0.78),
              b.color.withValues(alpha: a * 0.36),
              b.color.withValues(alpha: a * 0.10),
              b.color.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.30, 0.58, 0.80, 1.0],
          ).createShader(Rect.fromCircle(center: center, radius: r)),
      );
    }

    // ---- ชั้นบนสุด: ริ้วเขียวจางพาดโค้ง = รอยพับของผ้าไหม ----
    // พื้นเป็นขาวแล้ว ริ้วจึงต้องเข้มกว่าพื้นเล็กน้อยถึงจะมองเห็น ขอบฟุ้งด้วย MaskFilter.blur
    _silk(canvas, size,
        yBase: 0.30, slope: -0.16, amp1: 0.075, amp2: 0.040,
        width: short * 0.17, blur: 26, alpha: 0.42 * k,
        speed: 1, phase: 0.4, core: true);
    _silk(canvas, size,
        yBase: 0.62, slope: 0.20, amp1: 0.090, amp2: 0.035,
        width: short * 0.22, blur: 32, alpha: 0.36 * k,
        speed: -1, phase: 2.7, core: true);
    _silk(canvas, size,
        yBase: 0.86, slope: -0.10, amp1: 0.060, amp2: 0.030,
        width: short * 0.14, blur: 22, alpha: 0.28 * k,
        speed: 2, phase: 4.9, core: true);
    _silk(canvas, size,
        yBase: 0.14, slope: 0.12, amp1: 0.055, amp2: 0.028,
        width: short * 0.12, blur: 20, alpha: 0.24 * k,
        speed: -2, phase: 1.8, core: false);
    // ริ้วทแยงอีกสองเส้น ให้รอยพับไม่ได้นอนขนานกันหมด
    // (ชันมากไม่ได้ ถ้าเส้นทแยงมาบรรจบกันจะกลายเป็นรูปลูกศร ดูเป็นกราฟิกไม่ใช่ผ้า)
    _silk(canvas, size,
        yBase: 0.40, slope: -0.26, amp1: 0.085, amp2: 0.040,
        width: short * 0.15, blur: 26, alpha: 0.26 * k,
        speed: 1, phase: 3.9, core: false);
    _silk(canvas, size,
        yBase: 0.74, slope: 0.22, amp1: 0.075, amp2: 0.045,
        width: short * 0.13, blur: 24, alpha: 0.22 * k,
        speed: -1, phase: 5.5, core: false);
  }

  /// วาดริ้วแสงหนึ่งเส้น: เส้นโค้งกว้าง ๆ พาดทั้งจอ + แกนกลางที่สว่างกว่า
  void _silk(
    Canvas canvas,
    Size size, {
    required double yBase,
    required double slope, // ความเอียง — ทำให้เป็นริ้วทแยง ไม่ใช่เส้นนอนแข็ง ๆ
    required double amp1,
    required double amp2,
    required double width,
    required double blur,
    required double alpha,
    required double speed, // จำนวนเต็ม = ลูปไร้รอยต่อเหมือนก้อนสี
    required double phase,
    required bool core,
  }) {
    final ph = _tau * speed * t + phase;
    final left = -size.width * 0.15;
    final right = size.width * 1.15;
    const steps = 40;

    final path = Path();
    for (var i = 0; i <= steps; i++) {
      final p = i / steps;
      final x = left + (right - left) * p;
      // คลื่นสองความถี่ซ้อนกัน เส้นจะได้ยับแบบผ้า ไม่ใช่โค้งสวยเกินจริง
      final y = size.height *
          (yBase +
              slope * (p - 0.5) +
              amp1 * math.sin(p * 2.3 + ph) +
              amp2 * math.sin(p * 1.1 - ph * 0.7));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // ไล่ความทึบตามแนวนอน ให้หัว-ท้ายริ้วจางหายไป จะได้ไม่เห็นปลายเส้น
    Shader shade(double a) => LinearGradient(
          colors: [
            _kSilk.withValues(alpha: 0),
            _kSilk.withValues(alpha: a),
            _kSilk.withValues(alpha: a * 0.85),
            _kSilk.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.26, 0.70, 1.0],
        ).createShader(Offset.zero & size);

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur)
        ..shader = shade(alpha),
    );

    // แกนกลางของริ้ว — สว่างกว่าและฟุ้งน้อยกว่า ทำให้เห็นเป็น "รอยพับ" ชัดขึ้น
    if (core) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width * 0.26
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur * 0.45)
          ..shader = shade((alpha * 1.9).clamp(0.0, 0.95)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) =>
      old.t != t || old.intense != intense;
}

/// ข้อความที่มีแสงกวาดผ่านซ้ำ ๆ (ใช้กับชื่อแอปบนหน้า splash)
class ShimmerText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration period;

  /// สีของแสงที่กวาดผ่าน — พื้นเข้มใช้ขาว พื้นสว่างต้องใช้สีเน้น (เช่นส้ม)
  final Color? highlight;

  const ShimmerText(
    this.text, {
    super.key,
    required this.style,
    this.period = const Duration(milliseconds: 2600),
    this.highlight,
  });

  @override
  State<ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final p = _c.value * 2 - 0.5; // -0.5 → 1.5 แสงกวาดจากซ้ายไปขวา
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              widget.style.color ?? Colors.white,
              widget.highlight ?? Colors.white,
              widget.style.color ?? Colors.white,
            ],
            stops: [
              (p - 0.18).clamp(0.0, 1.0),
              p.clamp(0.0, 1.0),
              (p + 0.18).clamp(0.0, 1.0),
            ],
          ).createShader(rect),
          child: child,
        );
      },
      child: Text(widget.text, style: widget.style, textAlign: TextAlign.center),
    );
  }
}

/// จุดสามจุดเต้นสลับ (ตัวบอกสถานะกำลังโหลด)
class PulsingDots extends StatefulWidget {
  final Color color;
  final double size;
  const PulsingDots({super.key, this.color = Colors.white, this.size = 9});

  @override
  State<PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<PulsingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final v = (math.sin((_c.value * 2 * math.pi) - i * 0.9) + 1) / 2;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.size * 0.35),
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withValues(alpha: 0.35 + v * 0.65),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// วงแหวนเรืองแสงหมุนรอบโลโก้
class GlowRing extends StatefulWidget {
  final double size;
  final Widget child;

  /// สีวงกลมด้านใน (ค่าเริ่มต้น = เขียวเข้มของแบรนด์)
  final Color? fill;
  const GlowRing({super.key, required this.size, required this.child, this.fill});

  @override
  State<GlowRing> createState() => _GlowRingState();
}

class _GlowRingState extends State<GlowRing> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (_, __) => Transform.rotate(
              angle: _c.value * 2 * math.pi,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // วงแหวนเขียวอ่อน→ขาว (ไม่ใช้สีส้ม ให้ทั้งหน้าเป็นโทนเขียวล้วน)
                  gradient: SweepGradient(
                    colors: [
                      AppColors.primaryLight.withValues(alpha: 0),
                      AppColors.primaryLight.withValues(alpha: 0.9),
                      Colors.white.withValues(alpha: 0.95),
                      AppColors.primaryLight.withValues(alpha: 0.55),
                      AppColors.primaryLight.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.32, 0.52, 0.74, 1],
                  ),
                ),
              ),
            ),
          ),
          // เจาะตรงกลางให้เหลือแต่ขอบวง
          Container(
            width: widget.size - 9,
            height: widget.size - 9,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.fill ?? AppColors.primaryDark,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 22,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}
