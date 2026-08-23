import 'package:flutter/material.dart';

/// Page transition ที่นุ่มนวล (fade + เลื่อนขึ้นเล็กน้อย) ใช้ทั้งแอป
class SmoothPageTransitionsBuilder extends PageTransitionsBuilder {
  const SmoothPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  }
}

/// fade + เลื่อนขึ้น ตอน widget ปรากฏครั้งแรก (รองรับ delay สำหรับ stagger)
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offsetY;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 440),
    this.offsetY = 18,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (context, child) => Opacity(
        opacity: _a.value,
        child: Transform.translate(
          offset: Offset(0, (1 - _a.value) * widget.offsetY),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// ห่อ list ของ widget ให้ปรากฏแบบไล่ทีละชิ้น (stagger)
List<Widget> staggered(
  List<Widget> children, {
  int stepMs = 70,
  int startMs = 0,
}) {
  return [
    for (var i = 0; i < children.length; i++)
      FadeSlideIn(
        delay: Duration(milliseconds: startMs + i * stepMs),
        child: children[i],
      ),
  ];
}

/// ตัวเลขที่นับขึ้นจาก 0 → value (ใช้ในการ์ด KPI)
class AnimatedCount extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final String Function(int)? format;
  final Duration duration;

  const AnimatedCount(
    this.value, {
    super.key,
    this.style,
    this.format,
    this.duration = const Duration(milliseconds: 900),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        final n = v.round();
        return Text(format != null ? format!(n) : '$n', style: style);
      },
    );
  }
}
