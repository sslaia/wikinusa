import 'package:shared_preferences/shared_preferences.dart';
import 'package:wikimedia_core/wikimedia_core.dart';

/// Configuration and resolution for WikiChat discussion pages.
class ChatModuleConfig {
  static const String userAgent = 'WikiNusa/1.5.6 (contact: info@wikinusa.org)';

  /// Map of default talk pages per language and project.
  static final Map<String, Map<ProjectType, String>> _defaultTalkPages = {
    'nia': {
      ProjectType.wikipedia: 'Wikipedia:Monganga_afo',
      ProjectType.wiktionary: 'Wikikamus:Monganga_afo',
      ProjectType.wikibooks: 'Wikibooks:Monganga_afo',
    },
    'id': {
      ProjectType.wikipedia: 'Wikipedia:Warung_Kopi_(Semua)',
      ProjectType.wiktionary: 'Wikikamus:Warung_Kopi',
      ProjectType.wikibooks: 'Wikibooks:Warung_Kopi',
    },
    'jv': {
      ProjectType.wikipedia: 'Wikipedia:Angkringan',
      ProjectType.wiktionary: 'Wikisastra:Angkringan',
      ProjectType.wikibooks: 'Wikibooks:Angkringan',
    },
    'en': {
      ProjectType.wikipedia: 'Wikipedia:Village_pump_(general)',
      ProjectType.wiktionary: 'Wiktionary:Beer_parlour',
      ProjectType.wikibooks: 'Wikibooks:Staff_lounge',
    },
  };

  /// Returns the default community discussion page for a given language & project.
  static String getDefaultPageTitle(String langCode, ProjectType project) {
    final langPages = _defaultTalkPages[langCode.toLowerCase()];
    if (langPages != null && langPages.containsKey(project)) {
      return langPages[project]!;
    }
    // General fallback
    switch (project) {
      case ProjectType.wiktionary:
        return 'Wiktionary:Beer_parlour';
      case ProjectType.wikibooks:
        return 'Wikibooks:Staff_lounge';
      case ProjectType.wikipedia:
        return 'Wikipedia:Village_pump';
    }
  }

  /// SharedPreferences key for custom page title overrides
  static String _prefsKey(String langCode, ProjectType project) {
    return 'wikichat_page_title_${langCode.toLowerCase()}_${project.name.toLowerCase()}';
  }

  /// Get the active discussion page title, checking for user override first.
  static String getPageTitle(
    SharedPreferences? prefs,
    String langCode,
    ProjectType project,
  ) {
    if (prefs != null) {
      final custom = prefs.getString(_prefsKey(langCode, project));
      if (custom != null && custom.trim().isNotEmpty) {
        return custom.trim();
      }
    }
    return getDefaultPageTitle(langCode, project);
  }

  /// Check whether user has customized the page title for this language & project.
  static bool hasCustomPageTitle(
    SharedPreferences? prefs,
    String langCode,
    ProjectType project,
  ) {
    if (prefs == null) return false;
    final custom = prefs.getString(_prefsKey(langCode, project));
    return custom != null && custom.trim().isNotEmpty;
  }

  /// Set custom discussion page title for a given language & project.
  static Future<bool> setCustomPageTitle(
    SharedPreferences prefs,
    String langCode,
    ProjectType project,
    String title,
  ) async {
    final clean = title.trim();
    if (clean.isEmpty) {
      return await resetPageTitle(prefs, langCode, project);
    }
    return await prefs.setString(_prefsKey(langCode, project), clean);
  }

  /// Reset the discussion page title back to default.
  static Future<bool> resetPageTitle(
    SharedPreferences prefs,
    String langCode,
    ProjectType project,
  ) async {
    return await prefs.remove(_prefsKey(langCode, project));
  }

  /// Resolves the wiki domain for the current language & project.
  static String getDomain(String langCode, ProjectType project) {
    return WikiConfig.getDomain(langCode, project.name.toLowerCase());
  }
}
