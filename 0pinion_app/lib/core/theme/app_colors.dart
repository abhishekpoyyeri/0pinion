import 'dart:ui';

/// 0pinion Monochrome Color System
/// No forbidden colors: red, green, blue, purple, yellow, orange
class AppColors {
  AppColors._();

  // ─── Light Mode ───
  static const Color lightBackground = Color(0xFFFFFFFF);
  static const Color lightSurface = Color(0xFFFAFAFA);
  static const Color lightPrimaryText = Color(0xFF000000);
  static const Color lightSecondaryText = Color(0xFF666666);
  static const Color lightBorder = Color(0xFFE5E5E5);
  static const Color lightDisabled = Color(0xFFCCCCCC);

  // ─── Dark Mode ───
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF111111);
  static const Color darkPrimaryText = Color(0xFFFFFFFF);
  static const Color darkSecondaryText = Color(0xFFA0A0A0);
  static const Color darkBorder = Color(0xFF333333);
  static const Color darkDisabled = Color(0xFF555555);

  // ─── Shared ───
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color transparent = Color(0x00000000);
}
