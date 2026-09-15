import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/shop_ui.dart';
import 'app_colors.dart';

/// ควบคุมโหมดสว่าง/มืด (จำค่าไว้ในเครื่อง)
final ValueNotifier<bool> themeController = ValueNotifier<bool>(false);

const _kDarkModeKey = 'darkMode';

/// โหลดค่าที่บันทึกไว้ (เรียกตอนเริ่มแอป)
Future<void> loadThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final dark = prefs.getBool(_kDarkModeKey) ?? false;
  themeController.value = dark;
  AppColors.applyMode(dark);
}

/// สลับ/ตั้งค่าโหมด + บันทึก
Future<void> setDarkMode(bool dark) async {
  AppColors.applyMode(dark);
  themeController.value = dark;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_kDarkModeKey, dark);
}

/// ปุ่มสลับโหมดสว่าง/มืดแบบกลมลอย (ใช้บน header รูปภาพ ที่ไม่มี AppBar)
class ThemeToggleCircleButton extends StatelessWidget {
  const ThemeToggleCircleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeController,
      builder: (context, dark, _) => CircleIconButton(
        dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
        tooltip: dark ? 'โหมดสว่าง' : 'โหมดกลางคืน',
        onTap: () => setDarkMode(!dark),
      ),
    );
  }
}

/// ปุ่มสลับโหมดสว่าง/มืด (ใช้บน AppBar)
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeController,
      builder: (context, dark, _) => IconButton(
        tooltip: dark ? 'โหมดสว่าง' : 'โหมดกลางคืน',
        icon: Icon(dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
        onPressed: () => setDarkMode(!dark),
      ),
    );
  }
}
