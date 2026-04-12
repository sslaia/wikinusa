import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WikinusaThemeConfig {
  // Brand identity colors
  static const Color indigoBrandLight = Color(0xff121298);
  static const Color indigoBrandDark = Color(0xff8c9eff); // Lighter for Dark Mode contrast

  // Link colors (Light mode - standard)
  static const Color linkBlueLight = Color(0xff0645ad);
  static const Color linkRedLight = Color(0xffba0000);

  // Link colors (Dark mode - accessible/desaturated)
  static const Color linkBlueDark = Color(0xffc0bcfc);
  static const Color linkRedDark = Color(0xffa0482f);

  static Color getLinkBlue(Brightness brightness) =>
      brightness == Brightness.light ? linkBlueLight : linkBlueDark;

  static Color getLinkRed(Brightness brightness) =>
      brightness == Brightness.light ? linkRedLight : linkRedDark;

  static ThemeData createTheme(Color culturalSeedColor, Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: culturalSeedColor,
      primary: isDark ? indigoBrandDark : indigoBrandLight,
      brightness: brightness,
      surface: isDark ? const Color(0xFF121212) : const Color(0xFFFBF9F8),
    );

    final displayFont = GoogleFonts.literata().fontFamily;
    final bodyFont = GoogleFonts.notoSerif().fontFamily;
    final labelFont = GoogleFonts.inter().fontFamily;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surfaceContainerLow,

      textTheme: TextTheme(
        displayLarge: TextStyle(fontFamily: displayFont),
        displayMedium: TextStyle(fontFamily: displayFont),
        displaySmall: TextStyle(fontFamily: displayFont),
        headlineLarge: TextStyle(fontFamily: displayFont, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontFamily: displayFont, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(fontFamily: displayFont, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(fontFamily: bodyFont, fontWeight: FontWeight.bold, fontSize: 22),
        titleMedium: TextStyle(fontFamily: bodyFont, fontSize: 18),
        titleSmall: TextStyle(fontFamily: bodyFont, fontSize: 16),
        bodyLarge: TextStyle(fontFamily: bodyFont, fontSize: 18),
        bodyMedium: TextStyle(fontFamily: bodyFont, fontSize: 16),
        bodySmall: TextStyle(fontFamily: bodyFont, fontSize: 14),
        labelLarge: TextStyle(fontFamily: labelFont),
        labelMedium: TextStyle(fontFamily: labelFont),
        labelSmall: TextStyle(fontFamily: labelFont),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.primary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: displayFont,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
        ),
      ),

      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}
