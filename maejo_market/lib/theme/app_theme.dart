import 'package:flutter/material.dart';
import 'app_colors.dart';
import '../widgets/animations.dart';

class AppTheme {
  /// ฟอนต์ Kanit ฝังในแอป (assets/fonts) — ไม่ดึงจากเน็ตตอน runtime
  static const String _fontFamily = 'Kanit';

  static TextStyle _kanit({double? fontSize, FontWeight? fontWeight, Color? color}) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  /// สร้างธีมตามโหมด (ต้องเรียก AppColors.applyMode(dark) ก่อน)
  static ThemeData theme(bool dark) {
    final brightness = dark ? Brightness.dark : Brightness.light;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: _fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: brightness,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.bg,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: _fontFamily,
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: _kanit(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintStyle: TextStyle(color: AppColors.faint),
        border: _inputBorder(AppColors.border),
        enabledBorder: _inputBorder(AppColors.border),
        focusedBorder: _inputBorder(AppColors.primary, width: 1.6),
        errorBorder: _inputBorder(AppColors.bad),
        focusedErrorBorder: _inputBorder(AppColors.bad, width: 1.6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: _kanit(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: Size.fromHeight(52),
          side: BorderSide(color: AppColors.primary, width: 1.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: _kanit(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        labelStyle: _kanit(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 66,
        elevation: 3,
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.leafSoft,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => _kanit(
              fontSize: 11.5,
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
              color: states.contains(WidgetState.selected) ? AppColors.primary : AppColors.muted,
            )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected) ? AppColors.primary : AppColors.muted,
            )),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: AppColors.surface,
      ),
      snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating),
      pageTransitionsTheme: PageTransitionsTheme(builders: {
        TargetPlatform.android: SmoothPageTransitionsBuilder(),
        TargetPlatform.iOS: SmoothPageTransitionsBuilder(),
        TargetPlatform.windows: SmoothPageTransitionsBuilder(),
        TargetPlatform.macOS: SmoothPageTransitionsBuilder(),
        TargetPlatform.linux: SmoothPageTransitionsBuilder(),
      }),
    );
  }

  static OutlineInputBorder _inputBorder(Color c, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c, width: width),
    );
  }
}
