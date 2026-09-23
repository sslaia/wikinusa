import 'package:flutter/material.dart';
import '../core/community_registry.dart';

enum ProjectType { wikipedia, wiktionary, wikibooks }

extension ProjectTypeExtension on ProjectType {
  String get name {
    switch (this) {
      case ProjectType.wikipedia:
        return 'Wikipedia';
      case ProjectType.wiktionary:
        return 'Wiktionary';
      case ProjectType.wikibooks:
        return 'Wikibooks';
    }
  }

  String getDisplayName(String langCode) {
    if (CommunityRegistry.isInitialized) {
      return CommunityRegistry.getDisplayName(langCode, this);
    }
    if (this == ProjectType.wikipedia) {
      switch (langCode.toLowerCase()) {
        case 'nia':
          return 'Niaspedia';
        case 'jv':
          return 'Jawapedia';
        default:
          return 'Nusapedia';
      }
    }
    return name;
  }

  Color get primaryColor {
    switch (this) {
      case ProjectType.wikipedia:
        return const Color(0xFF121298); // Indigo
      case ProjectType.wiktionary:
        return const Color(0xFFFF5722); // Deep Orange
      case ProjectType.wikibooks:
        return const Color(0xFF9B00A1); // Purple
    }
  }

  /// Returns a brighter, high-contrast accent color suitable for dark mode backgrounds
  Color get darkPrimaryColor {
    switch (this) {
      case ProjectType.wikipedia:
        return const Color(
          0xFF9EAEFF,
        ); // Bright Indigo / Periwinkle (accessible on dark surfaces)
      case ProjectType.wiktionary:
        return const Color(0xFFFFAB91); // Bright Coral / Warm Peach
      case ProjectType.wikibooks:
        return const Color(0xFFCE93D8); // Bright Lilac / Lavender
    }
  }

  /// Returns the appropriate primary or accent color depending on whether dark mode is active
  Color getThemedColor(bool isDark) => isDark ? darkPrimaryColor : primaryColor;

  String get homeHeroImagePath {
    switch (this) {
      case ProjectType.wikipedia:
        return 'assets/images/woman_reading_a_book_on_lap.webp';
      case ProjectType.wiktionary:
        return 'assets/images/power_of_words.webp';
      case ProjectType.wikibooks:
        return 'assets/images/reading_at_the_garden.webp';
    }
  }

  String get articleHeroImagePath {
    switch (this) {
      case ProjectType.wikipedia:
        return "assets/images/woman_reading_a_book_on_lap.webp";
      case ProjectType.wiktionary:
        return 'assets/images/power_of_words.webp';
      case ProjectType.wikibooks:
        return 'assets/images/reading_at_the_garden.webp';
    }
  }

  bool isSupported(String langCode) {
    if (CommunityRegistry.isInitialized) {
      return CommunityRegistry.isProjectSupported(langCode, this);
    }
    return this == ProjectType.wikipedia;
  }
}
