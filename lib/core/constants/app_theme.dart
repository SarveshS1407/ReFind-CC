import 'package:flutter/material.dart';

class AppTheme {
  // Brand Primary & Accent
  static const Color primaryBlue = Color(0xFF1E3A8A); // Deep Indigo
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color secondaryTeal = Color(0xFF0D9488);
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE2E8F0);

  // Accessible Status Colors (High contrast, WCAG AA compliant)
  static const Color statusLost = Color(0xFFDC2626); // Strong Crimson / Red
  static const Color statusLostBg = Color(0xFFFEE2E2);
  
  static const Color statusFound = Color(0xFF0284C7); // Vibrant Blue / Cyan
  static const Color statusFoundBg = Color(0xFFE0F2FE);

  static const Color statusClaimed = Color(0xFF7C3AED); // Vivid Violet
  static const Color statusClaimedBg = Color(0xFFEDE9FE);

  static const Color statusReturned = Color(0xFF16A34A); // Emerald Green
  static const Color statusReturnedBg = Color(0xFFDCFCE7);

  static const Color syncWarning = Color(0xFFD97706); // Amber for local queue
  static const Color syncWarningBg = Color(0xFFFEF3C7);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: secondaryTeal,
        surface: surfaceWhite,
        error: statusLost,
      ),
      scaffoldBackgroundColor: backgroundLight,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceWhite,
        foregroundColor: Color(0xFF0F172A),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: primaryBlue, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: statusLost, width: 1.5),
        ),
        labelStyle: const TextStyle(color: Color(0xFF475569)),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      ),
    );
  }
}
