import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/animations.dart';
import '../widgets/aurora.dart';
import '../widgets/common.dart';

/// หน้า Splash / กำลังโหลด — พื้นหลังออโรราเส้นบิดไหล + โลโก้วงแหวนเรืองแสง
/// + ชื่อแอปที่มีแสงกวาดผ่าน
class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final Animation<double> _scale = CurvedAnimation(
    parent: _in,
    curve: Curves.easeOutBack,
  );

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: _scale,
                      child: const AppLogo(size: 150, showText: false),
                    ),
                    const SizedBox(height: 28),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 260),
                      child: ShimmerText(
                        'Maejo Market',
                        highlight: AppColors.primaryLight,
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    FadeSlideIn(
                      delay: const Duration(milliseconds: 420),
                      child: Text('ตลาดแม่โจ้ · ของสดของดีจากชุมชน',
                          style: TextStyle(color: AppColors.muted, fontSize: 14.5)),
                    ),
                  ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 54,
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 600),
                  child: Center(child: PulsingDots(color: AppColors.primary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
