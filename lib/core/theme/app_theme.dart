import 'package:flutter/material.dart';

class AppTheme {
  // Brand & Accent Colors — deep teal + warm copper, replacing the generic
  // indigo/purple "SaaS starter" look with something a health/fasting
  // tracker can actually claim as its own.
  static const Color primary = Color(0xFF14B8A6); // Teal
  static const Color primaryGradientStart = Color(0xFF2DD4BF); // Bright teal
  static const Color primaryGradientEnd = Color(0xFF0F766E); // Deep teal

  static const Color accent = Color(0xFFC2703D); // Warm copper — secondary highlight
  static const Color accentLight = Color(0xFFD98F5F); // Lighter copper, for gradients

  static const Color success = Color(0xFF65A30D); // Moss green
  static const Color warning = Color(0xFFD97706); // Amber (Ketosis)
  static const Color danger = Color(0xFFDC2626); // Red
  static const Color cyan = Color(0xFF2563EB); // Water (blue — kept separate from teal primary)
  static const Color cyanLight = Color(0xFF60A5FA); // Lighter blue, for gradients
  static const Color violet = Color(0xFF7C3AED); // Reserved accent (unused by default theme)
  static const Color gold = Color(0xFFEAB308); // Achievement / personal-record indicator
  static const Color tangerine = Color(0xFFF97316); // Streak indicator

  // Dark Theme Palette — neutral charcoal rather than blue-black, so it
  // doesn't fight the teal brand color the way the old slate tones did.
  static const Color darkBg = Color(0xFF0D1210);
  static const Color darkSurface = Color(0xFF141C1A);
  static const Color darkCard = Color(0xFF1C2624);
  static const Color darkBorder = Color(0xFF2C3937);
  static const Color darkTextPrimary = Color(0xFFF7FAF9);
  static const Color darkTextSecondary = Color(0xFF9BAAA7);
  static const Color darkTextTertiary = Color(0xFF8A9A97); // ~5.3:1 on darkCard

  // Light Theme Palette
  static const Color lightBg = Color(0xFFF7FAF9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE1E8E6);
  static const Color lightTextPrimary = Color(0xFF10201D);
  static const Color lightTextSecondary = Color(0xFF5C6E6A);
  static const Color lightTextTertiary = Color(0xFF66766F); // ~4.8:1 on lightCard

  // Shared corner radii — keep consistent across the app
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 28;

  // Pill-badge tints (e.g. History's COMPLETE / ENDED EARLY tags) — named
  // text/background pairs rather than withAlpha() on the base semantic color,
  // so contrast is guaranteed (each pair verified >=4.5:1) instead of incidental.
  static const Color successBadgeBgLight = Color(0xFFDCFCE7);
  static const Color successBadgeTextLight = Color(0xFF166534);
  static const Color successBadgeBgDark = Color(0xFF14532D);
  static const Color successBadgeTextDark = Color(0xFF4ADE80);

  static const Color warningBadgeBgLight = Color(0xFFFEF3C7);
  static const Color warningBadgeTextLight = Color(0xFF92400E);
  static const Color warningBadgeBgDark = Color(0xFF78350F);
  static const Color warningBadgeTextDark = Color(0xFFFBBF24);

  static Color successBadgeBg(bool isDark) =>
      isDark ? successBadgeBgDark : successBadgeBgLight;
  static Color successBadgeText(bool isDark) =>
      isDark ? successBadgeTextDark : successBadgeTextLight;
  static Color warningBadgeBg(bool isDark) =>
      isDark ? warningBadgeBgDark : warningBadgeBgLight;
  static Color warningBadgeText(bool isDark) =>
      isDark ? warningBadgeTextDark : warningBadgeTextLight;

  // Shared elevation scale — pick by how far off the surface something sits,
  // not by eyeballing a blur value. Sm: buttons/dots. Md: cards/dialogs picked
  // up off the page. Lg: floating chrome (bottom nav) closest to the user.
  static List<BoxShadow> shadowSm(bool isDark) => [
    BoxShadow(
      color: Colors.black.withAlpha(isDark ? 70 : 15),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowMd(bool isDark) => [
    BoxShadow(
      color: Colors.black.withAlpha(isDark ? 80 : 16),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> shadowLg(bool isDark) => [
    BoxShadow(
      color: Colors.black.withAlpha(isDark ? 90 : 18),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryGradientStart, primaryGradientEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient waterGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Muted, low-contrast surface used for inline status rows / chips so
  /// information doesn't compete with cards for attention.
  static Color subtleSurface(bool isDark) =>
      isDark ? const Color(0xFF19231F) : const Color(0xFFEFF4F2);

  static Color textPrimary(bool isDark) =>
      isDark ? darkTextPrimary : lightTextPrimary;

  static Color textSecondary(bool isDark) =>
      isDark ? darkTextSecondary : lightTextSecondary;

  static Color textTertiary(bool isDark) =>
      isDark ? darkTextTertiary : lightTextTertiary;

  static Color border(bool isDark) => isDark ? darkBorder : lightBorder;

  static Color surface(bool isDark) => isDark ? darkSurface : lightSurface;

  /// Shared selected-segment style for SegmentedButtons (e.g. Settings'
  /// Theme/Weight Unit toggles, History's Week/Month toggle) — defined once
  /// so every instance stays in sync instead of duplicating the same style
  /// inline per screen.
  static ButtonStyle primarySegmentedButtonStyle(bool isDark) {
    return SegmentedButton.styleFrom(
      selectedBackgroundColor: primary.withAlpha(isDark ? 60 : 35),
      selectedForegroundColor: primary,
      foregroundColor: textSecondary(isDark),
    );
  }

  static const _fontFamilyFallback = [
    'SF Pro Display',
    'Segoe UI',
    'Roboto',
  ];

  static TextTheme _textTheme(Color primaryText, Color secondaryText) {
    return TextTheme(
      headlineSmall: TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: primaryText,
        height: 1.2,
      ),
      titleLarge: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: primaryText,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: primaryText,
      ),
      bodyLarge: TextStyle(fontSize: 15, color: primaryText, height: 1.4),
      bodyMedium: TextStyle(fontSize: 13, color: secondaryText, height: 1.45),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: secondaryText,
        letterSpacing: 0.2,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: secondaryText,
        letterSpacing: 0.3,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      splashFactory: InkSparkle.splashFactory,
      fontFamilyFallback: _fontFamilyFallback,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: cyan,
        tertiary: success,
        surface: lightSurface,
        onSurface: lightTextPrimary,
        error: danger,
      ),
      textTheme: _textTheme(lightTextPrimary, lightTextSecondary),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: lightTextPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        iconTheme: IconThemeData(color: lightTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(color: lightBorder, thickness: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: lightSurface,
        indicatorColor: primary.withAlpha(30),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primary);
          }
          return const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: lightTextSecondary);
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusXl)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: lightTextPrimary,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
        actionTextColor: primaryGradientStart,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusSm)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      splashFactory: InkSparkle.splashFactory,
      fontFamilyFallback: _fontFamilyFallback,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: cyan,
        tertiary: success,
        surface: darkSurface,
        onSurface: darkTextPrimary,
        error: danger,
      ),
      textTheme: _textTheme(darkTextPrimary, darkTextSecondary),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
        ),
        iconTheme: IconThemeData(color: darkTextPrimary),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(color: darkBorder, thickness: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        indicatorColor: primary.withAlpha(50),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2DD4BF));
          }
          return const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: darkTextSecondary);
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusXl)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXl)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: darkCard,
        contentTextStyle: const TextStyle(color: darkTextPrimary, fontSize: 13),
        actionTextColor: primaryGradientStart,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          side: const BorderSide(color: darkBorder),
        ),
      ),
    );
  }
}
