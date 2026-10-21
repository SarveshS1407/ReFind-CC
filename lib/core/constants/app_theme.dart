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

/// Unified Design System & Design Tokens for ReFind — VIT Vellore
/// Contemporary campus-community aesthetic with an Indigo/Blue palette,
/// full Light & Dark mode support, and WCAG AA contrast.
class AppTheme {
  // Brand Colors — Indigo & Electric Blue Foundation
  static const Color primaryIndigo = Color(0xFF4338CA); // Deep Indigo
  static const Color primaryIndigoLight = Color(0xFF4F46E5); // Vibrant Indigo
  static const Color primaryIndigoDark = Color(0xFF312E81); // Midnight Indigo
  static const Color accentBlue = Color(0xFF0284C7); // Sky Blue Accent
  static const Color accentAmber = Color(0xFFD97706); // Warm Amber Accent
  static const Color accentAmberLight = Color(0xFFF59E0B);

  // Backward compatibility alias for legacy references
  static const Color primaryTeal = primaryIndigo;
  static const Color primaryTealLight = primaryIndigoLight;
  static const Color primaryTealDark = primaryIndigoDark;

  // Light Neutral Background & Surface Tokens
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceLightSubtle = Color(0xFFF1F5F9); // Slate 100
  static const Color cardBorderLight = Color(0xFFE2E8F0); // Slate 200
  static const Color cardBorderHoverLight = Color(0xFFCBD5E1);

  // Dark Neutral Background & Surface Tokens
  static const Color backgroundDark = Color(0xFF0B0F19); // Deep Slate Navy
  static const Color surfaceDark = Color(0xFF131B2E); // Elevated Dark Card
  static const Color surfaceDarkSubtle = Color(0xFF1E293B); // Slate 800
  static const Color cardBorderDark = Color(0xFF243049); // Subtle Dark Border
  static const Color cardBorderHoverDark = Color(0xFF3B4D71);

  // Backward-compatible constants
  static const Color backgroundWarm = backgroundLight;
  static const Color surfaceSubtle = surfaceLightSubtle;
  static const Color cardBorder = cardBorderLight;
  static const Color cardBorderHover = cardBorderHoverLight;

  // Typography Tokens - Light
  static const Color textPrimary = Color(0xFF0F172A); // High Contrast Dark
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);

  // Typography Tokens - Dark
  static const Color textPrimaryDark = Color(0xFFF8FAFC); // High Contrast White
  static const Color textSecondaryDark = Color(0xFFCBD5E1);
  static const Color textMutedDark = Color(0xFF64748B);

  // Accessible Status Colors (High contrast, WCAG AA compliant)
  static const Color statusLost = Color(0xFFDC2626); // Strong Crimson
  static const Color statusLostBgLight = Color(0xFFFEF2F2);
  static const Color statusLostBorderLight = Color(0xFFFECACA);
  static const Color statusLostBgDark = Color(0xFF3B1214);
  static const Color statusLostBorderDark = Color(0xFF7F1D1D);

  static const Color statusFound = Color(0xFF0284C7); // Sky Blue
  static const Color statusFoundBgLight = Color(0xFFF0F9FF);
  static const Color statusFoundBorderLight = Color(0xFFBAE6FD);
  static const Color statusFoundBgDark = Color(0xFF082F49);
  static const Color statusFoundBorderDark = Color(0xFF0369A1);

  static const Color statusClaimed = Color(0xFF6366F1); // Indigo / Violet
  static const Color statusClaimedBgLight = Color(0xFFEEF2FF);
  static const Color statusClaimedBorderLight = Color(0xFFC7D2FE);
  static const Color statusClaimedBgDark = Color(0xFF1E1B4B);
  static const Color statusClaimedBorderDark = Color(0xFF4338CA);

  static const Color statusReturned = Color(0xFF16A34A); // Forest Emerald
  static const Color statusReturnedBgLight = Color(0xFFF0FDF4);
  static const Color statusReturnedBorderLight = Color(0xFFBBF7D0);
  static const Color statusReturnedBgDark = Color(0xFF052E16);
  static const Color statusReturnedBorderDark = Color(0xFF15803D);

  // Backward-compatible status backgrounds
  static const Color statusLostBg = statusLostBgLight;
  static const Color statusLostBorder = statusLostBorderLight;
  static const Color statusFoundBg = statusFoundBgLight;
  static const Color statusFoundBorder = statusFoundBorderLight;
  static const Color statusClaimedBg = statusClaimedBgLight;
  static const Color statusClaimedBorder = statusClaimedBorderLight;
  static const Color statusReturnedBg = statusReturnedBgLight;
  static const Color statusReturnedBorder = statusReturnedBorderLight;

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

  static const List<BoxShadow> darkSubtleShadow = [
    BoxShadow(color: Color(0x40000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  // Dynamic Theme Helpers
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Color cardColor(BuildContext context) {
    return isDark(context) ? surfaceDark : surfaceWhite;
  }

  static Color surfaceSubtleColor(BuildContext context) {
    return isDark(context) ? surfaceDarkSubtle : surfaceLightSubtle;
  }

  static Color borderColor(BuildContext context) {
    return isDark(context) ? cardBorderDark : cardBorderLight;
  }

  static Color textPrimaryColor(BuildContext context) {
    return isDark(context) ? textPrimaryDark : textPrimary;
  }

  static Color textSecondaryColor(BuildContext context) {
    return isDark(context) ? textSecondaryDark : textSecondary;
  }

  static Color textMutedColor(BuildContext context) {
    return isDark(context) ? textMutedDark : textMuted;
  }

  // --- LIGHT THEME DEFINITION ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      splashFactory: InkRipple.splashFactory,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryIndigo,
        primary: primaryIndigo,
        secondary: accentBlue,
        tertiary: accentAmber,
        surface: surfaceWhite,
        error: statusLost,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundLight,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceWhite,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorderLight, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceWhite,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: cardBorderLight),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryIndigo,
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
          foregroundColor: primaryIndigo,
          side: const BorderSide(color: primaryIndigo, width: 1.5),
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
          borderSide: const BorderSide(color: cardBorderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryIndigo, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: statusLost, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textMuted),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: primaryIndigo,
        unselectedLabelColor: textSecondary,
        indicatorColor: primaryIndigo,
      ),
    );
  }

  // --- DARK THEME DEFINITION ---
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      splashFactory: InkRipple.splashFactory,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryIndigo,
        primary: primaryIndigoLight,
        secondary: accentBlue,
        tertiary: accentAmber,
        surface: surfaceDark,
        error: statusLost,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: backgroundDark,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: textPrimaryDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimaryDark,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorderDark, width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDark,
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: cardBorderDark),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryIndigoLight,
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
          foregroundColor: primaryIndigoLight,
          side: const BorderSide(color: primaryIndigoLight, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDarkSubtle,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: cardBorderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryIndigoLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: statusLost, width: 1.5),
        ),
        labelStyle: const TextStyle(color: textSecondaryDark),
        hintStyle: const TextStyle(color: textMutedDark),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: primaryIndigoLight,
        unselectedLabelColor: textSecondaryDark,
        indicatorColor: primaryIndigoLight,
      ),
    );
  }
}
