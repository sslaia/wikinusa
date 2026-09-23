import 'dart:ui' as ui;

/// Utilities for determining device and initial application locale.
class LocaleUtils {
  static const Set<String> _indonesianLanguages = {
    'id',
    'nia',
    'jv',
    'su',
    'min',
    'bbc',
    'btm',
    'bjn',
    'bew',
    'gor',
    'mad',
  };

  /// Returns 'id' if the user's default locale indicates Indonesia (by country code 'ID'
  /// or Indonesian / Indonesian regional language code), otherwise returns 'en'.
  static String getOnboardingLanguage() {
    final dispatcher = ui.PlatformDispatcher.instance;
    final primary = dispatcher.locale;

    if (isIndonesianLocale(primary)) {
      return 'id';
    }

    // Check secondary system locales if available
    for (final loc in dispatcher.locales) {
      if (isIndonesianLocale(loc)) {
        return 'id';
      }
    }

    return 'en';
  }

  /// Checks whether a locale indicates Indonesia by country code or language.
  static bool isIndonesianLocale(ui.Locale locale) {
    if (locale.countryCode?.toUpperCase() == 'ID') {
      return true;
    }
    if (_indonesianLanguages.contains(locale.languageCode.toLowerCase())) {
      return true;
    }
    return false;
  }
}
