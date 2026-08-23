import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/animations.dart';

/// หน้า Splash (แสดงระหว่างโหลด) — โลโก้เต้นเบาๆ + เนื้อหา fade เข้า
class SplashView extends StatefulWidget {
  SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 1500),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1.06).animate(
                CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
              ),
              child: Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white24, width: 1.4),
                ),
                child: Icon(Icons.storefront_rounded, color: Colors.white, size: 56),
              ),
            ),
            SizedBox(height: 22),
            FadeSlideIn(
              delay: Duration(milliseconds: 150),
              child: Text('Maejo Market',
                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
            ),
            FadeSlideIn(
              delay: Duration(milliseconds: 280),
              child: Text('ตลาดแม่โจ้', style: TextStyle(color: Colors.white70, fontSize: 15)),
            ),
            SizedBox(height: 30),
            FadeSlideIn(
              delay: Duration(milliseconds: 420),
              child: SizedBox(
                width: 28, height: 28,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
