import 'package:flutter/material.dart';

import 'models/app_user.dart';
import 'state/app_state.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';
import 'screens/splash_view.dart';
import 'screens/auth/login_screen.dart';
import 'screens/buyer/buyer_shell.dart';
import 'screens/seller/seller_shell.dart';
import 'screens/admin/admin_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // กันแครชตอนเริ่ม: ถ้าขั้นตอนใดพัง ก็ยังเข้าแอปได้ ไม่ค้างจอเปล่า
  try {
    await loadThemeMode();
  } catch (e) {
    debugPrint('loadThemeMode failed: $e');
  }
  try {
    await appState.init();
  } catch (e) {
    debugPrint('appState.init failed: $e');
  }
  runApp(MaejoApp());
}

class MaejoApp extends StatelessWidget {
  MaejoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeController,
      builder: (context, dark, _) {
        AppColors.applyMode(dark);
        return MaterialApp(
          title: 'Maejo Market',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.theme(dark),
          home: _Root(),
        );
      },
    );
  }
}

/// เลือกหน้าจอตามสถานะ auth + บทบาท
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        if (!appState.ready) return SplashView();
        final user = appState.user;
        if (user == null) return LoginScreen();
        if (user.status == 'suspended') return _SuspendedView();
        switch (user.role) {
          case UserRole.admin:
            return AdminShell();
          case UserRole.seller:
            return SellerShell();
          case UserRole.buyer:
            return BuyerShell();
        }
      },
    );
  }
}

/// หน้าจอเมื่อบัญชีถูกระงับ
class _SuspendedView extends StatelessWidget {
  const _SuspendedView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.block_rounded, color: AppColors.bad, size: 64),
              SizedBox(height: 16),
              Text('บัญชีถูกระงับการใช้งาน',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              SizedBox(height: 8),
              Text('บัญชีของคุณถูกระงับโดยผู้ดูแลระบบ\nกรุณาติดต่อผู้ดูแลระบบเพื่อขอเปิดใช้งาน',
                  textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
              SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => appState.signOut(),
                icon: Icon(Icons.logout_rounded),
                label: Text('ออกจากระบบ'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
