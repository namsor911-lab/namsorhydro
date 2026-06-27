import 'package:flutter/material.dart';

class AppColors {
  static const bgPrimary   = Color(0xFF071320);
  static const bgSecondary = Color(0xFF0B1D2E);
  static const bgTertiary  = Color(0xFF0F2438);
  static const bgCard      = Color(0xFF0D1E30);
  static const bgHover     = Color(0xFF14293D);
  static const border      = Color(0xFF1A3248);

  static const textPrimary   = Color(0xFFE0EEF8);
  static const textSecondary = Color(0xFF7FA8C4);
  static const textMuted     = Color(0xFF3D6480);

  static const accent      = Color(0xFF00B4D8);
  static const accentHover = Color(0xFF48CAE4);
  static const accentGlow  = Color(0x4000B4D8);

  static const success     = Color(0xFF2EC4B6);
  static const warning     = Color(0xFFF4A261);
  static const danger      = Color(0xFFE63946);
  static const info        = Color(0xFF4895EF);
  static const energy      = Color(0xFF90E0EF);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bgPrimary,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.accent,
      surface: AppColors.bgCard,
      onSurface: AppColors.textPrimary,
    ),
    fontFamily: 'PhetsarathOT',
    dividerColor: AppColors.border,
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: AppColors.textPrimary, fontFamily: 'PhetsarathOT'),
      bodySmall:  TextStyle(color: AppColors.textSecondary, fontFamily: 'PhetsarathOT'),
    ),
    cardTheme: const CardThemeData(
      color: AppColors.bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        side: BorderSide(color: AppColors.border),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.bgTertiary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.accent),
      ),
      hintStyle: const TextStyle(color: AppColors.textMuted),
      labelStyle: const TextStyle(color: AppColors.textSecondary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.bgPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    ),
  );
}