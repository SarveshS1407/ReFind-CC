import 'package:flutter/material.dart';

/// Responsive viewport breakpoints for mobile, tablet, and desktop screens
class AppBreakpoints {
  static const double mobileMax = 640;
  static const double tabletMax = 1024;
  static const double desktopContentMaxWidth = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileMax;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileMax && width < tabletMax;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletMax;
}

/// Unified Design System & Design Tokens for Finders Keepers?
/// Follows a prestigious university aesthetic:
/// - Warm off-white neutral background
/// - Deep forest teal primary (#134E4A)
/// - Warm amber accent (#D97706)
/// - Accessible high-contrast typography
class AppTheme {
  // Brand Colors
  static const Color primaryTeal = Color(0xFF134E4A); // Deep Forest Teal
  static const Color primaryTealLight = Color(0xFF0F766E);
  static const Color primaryTealDark = Color(0xFF042F2E);
  static const Color accentAmber = Color(0xFFD97706); // Warm Amber Accent
  static const Color accentAmberLight = Color(0xFFF59E0B);

  // Neutral Background & Surface Tokens
  static const Color backgroundWarm = Color(0xFFFAF9F6); // Warm Off-White
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceSubtle = Color(0xFFF3F4F6);
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color cardBorderHover = Color(0xFFCBD5E1);

  // Typography Tokens
  static const Color textPrimary = Color(0xFF0F172A); // High Contrast Dark
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);

  // Accessible Status Colors (High contrast, WCAG AA compliant)
  static const Color statusLost = Color(0xFFDC2626); // Strong Crimson
  static const Color statusLostBg = Color(0xFFFEF2F2);
  static const Color statusLostBorder = Color(0xFFFECACA);

  static const Color statusFound = Color(0xFF0284C7); // Sky Blue
  static const Color statusFoundBg = Color(0xFFF0F9FF);
  static const Color statusFoundBorder = Color(0xFFBAE6FD);

  static const Color statusClaimed = Color(0xFF6366F1); // Indigo / Violet
  static const Color statusClaimedBg = Color(0xFFEEF2FF);
  static const Color statusClaimedBorder = Color(0xFFC7D2FE);

  static const Color statusReturned = Color(0xFF16A34A); // Forest Emerald
  static const Color statusReturnedBg = Color(0xFFF0FDF4);
  static const Color statusReturnedBorder = Color(0xFFBBF7D0);

  static const Color syncWarning = Color(0xFFD97706); // Amber for local queue
  static const Color syncWarningBg = Color(0xFFFFFBEB);
  static const Color syncWarningBorder = Color(0xFFFDE68A);

  // Subtle Box Shadow for clean elevation
  static const List<BoxShadow> subtleCardShadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 8)),
  ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      splashFactory: InkRipple.splashFactory,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryTeal,
        primary: primaryTeal,
        secondary: accentAmber,
        surface: surfaceWhite,
        error: statusLost,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundWarm,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceWhite,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
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
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryTeal,
          side: const BorderSide(color: primaryTeal, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
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
          borderSide: const BorderSide(color: primaryTeal, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: statusLost, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textMuted),
      ),
    );
  }
}
