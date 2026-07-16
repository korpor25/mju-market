import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// หน้า Splash (แสดงระหว่างโหลด)
class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront_rounded, color: Colors.white, size: 64),
            SizedBox(height: 16),
            Text('Maejo Market',
                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
            Text('ตลาดแม่โจ้', style: TextStyle(color: Colors.white70, fontSize: 15)),
            SizedBox(height: 28),
            SizedBox(
              width: 30, height: 30,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }
}
