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
      // หัวหน้าจอแบบ "เนื้อหามาก่อน" — พื้นเดียวกับหน้า ไม่มีแถบสีทึบ
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: _kanit(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.text,
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
      // ปุ่มทรงแคปซูลทั้งแอป (ให้เข้าชุดกับปุ่มกลม/ชิปลอยในชุด shop_ui)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: Size.fromHeight(52),
          shape: const StadiumBorder(),
          textStyle: _kanit(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: Size.fromHeight(52),
          side: BorderSide(color: AppColors.primary, width: 1.4),
          shape: const StadiumBorder(),
          textStyle: _kanit(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: const StadiumBorder(),
          textStyle: _kanit(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        labelStyle: _kanit(fontSize: 13, fontWeight: FontWeight.w600),
        shape: const StadiumBorder(),
        side: BorderSide(color: AppColors.border),
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
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: c, width: width),
    );
  }
}
