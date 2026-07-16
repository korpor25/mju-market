import 'package:flutter/material.dart';

import 'models/app_user.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/splash_view.dart';
import 'screens/auth/login_screen.dart';
import 'screens/buyer/buyer_shell.dart';
import 'screens/seller/seller_shell.dart';
import 'screens/admin/admin_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await appState.init();
  runApp(const MaejoApp());
}

class MaejoApp extends StatelessWidget {
  const MaejoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maejo Market',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const _Root(),
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
        if (!appState.ready) return const SplashView();
        final user = appState.user;
        if (user == null) return const LoginScreen();
        switch (user.role) {
          case UserRole.admin:
            return const AdminShell();
          case UserRole.seller:
            return const SellerShell();
          case UserRole.buyer:
            return const BuyerShell();
        }
      },
    );
  }
}
