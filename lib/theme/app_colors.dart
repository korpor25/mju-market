import 'package:flutter/material.dart';

/// สีตาม design system ของ Maejo Market (รองรับ Light/Dark)
///
/// ค่าเหล่านี้ถูกสลับตอน runtime ด้วย [applyMode] จึงเป็น non-const
class AppColors {
  static bool _dark = false;
  static bool get isDark => _dark;

  /// สลับชุดสี (เรียกก่อน rebuild MaterialApp)
  static void applyMode(bool dark) => _dark = dark;

  static Color _p(Color light, Color dark) => _dark ? dark : light;

  // ---- แบรนด์ (เขียว/ส้ม คงโทนใกล้เคียงทั้ง 2 โหมด) ----
  static Color get primary => _p(const Color(0xFF2E7D32), const Color(0xFF66BB6A));
  static Color get primaryDark => _p(const Color(0xFF1B5E20), const Color(0xFF388E3C));
  static Color get primaryLight => _p(const Color(0xFF4CAF50), const Color(0xFF81C784));
  static Color get leafSoft => _p(const Color(0xFFE8F5E9), const Color(0xFF1E3324));
  static Color get accent => _p(const Color(0xFFFF9800), const Color(0xFFFFB74D));
  static Color get accentSoft => _p(const Color(0xFFFFF3E0), const Color(0xFF3A2E1A));

  // ---- พื้นหลัง/พื้นผิว ----
  static Color get bg => _p(const Color(0xFFF9F9F9), const Color(0xFF121513));
  static Color get surface => _p(Colors.white, const Color(0xFF1C201D));
  static Color get surface2 => _p(const Color(0xFFF2F6EC), const Color(0xFF262B27));

  // ---- ตัวอักษร ----
  static Color get text => _p(const Color(0xFF333333), const Color(0xFFECEFEA));
  static Color get muted => _p(const Color(0xFF6B7280), const Color(0xFF9AA4A0));
  static Color get faint => _p(const Color(0xFF9CA3AF), const Color(0xFF6B7671));
  static Color get border => _p(const Color(0xFFE5E7EB), const Color(0xFF343B36));

  // ---- สถานะ ----
  static Color get ok => _p(const Color(0xFF2E9E5B), const Color(0xFF57C98A));
  static Color get okSoft => _p(const Color(0xFFDCF0E2), const Color(0xFF16311F));
  static Color get warn => _p(const Color(0xFFD9932A), const Color(0xFFE6B35C));
  static Color get warnSoft => _p(const Color(0xFFF8E9CE), const Color(0xFF3A3115));
  static Color get bad => _p(const Color(0xFFCF4A34), const Color(0xFFE57358));
  static Color get badSoft => _p(const Color(0xFFF7DDD6), const Color(0xFF3A211B));
}
