import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/community_manifest.dart';
import '../models/project_type.dart';

/// Central singleton registry for community-contributed language & project definitions.
class CommunityRegistry {
  static CommunityManifest _manifest = const CommunityManifest(languages: {});
  static bool _isInitialized = false;

  /// Returns true if the registry has been initialized.
  static bool get isInitialized => _isInitialized;

  /// Returns all currently registered language configurations.
  static List<CommunityLanguageConfig> get languages =>
      _manifest.languages.values.toList();

  /// Returns a map of language codes to their configurations.
  static Map<String, CommunityLanguageConfig> get languageMap =>
      _manifest.languages;

  /// Dynamically register or update a language configuration at runtime.
  static void registerLanguage(CommunityLanguageConfig config) {
    final updated = Map<String, CommunityLanguageConfig>.from(_manifest.languages);
    updated[config.code] = config;
    _manifest = CommunityManifest(
      globalRules: _manifest.globalRules,
      languages: updated,
    );
  }

  /// Register or dynamically update a language configuration from a raw JSON map.
  static bool registerLanguageFromMap(Map<String, dynamic> jsonMap) {
    try {
      final config = CommunityLanguageConfig.fromJson(jsonMap);
      if (config.code.isNotEmpty) {
        registerLanguage(config);
        return true;
      }
    } catch (e) {
      debugPrint('CommunityRegistry: Failed to register language from map: $e');
    }
    return false;
  }

  /// Initialize the registry.
  /// 1. Discovers and loads modular community files from `assets/communities/*.json`.
  /// 2. If [localDirectoryPath] is provided, overlays any downloaded or updated community files.
  static Future<void> init({
    String? localDirectoryPath,
    String? appName = 'wikinusa',
    SharedPreferences? prefs,
    String assetPath = '', // Kept for backwards compatibility
  }) async {
    final modularManifest = await _loadFromCommunitiesFolder(localDirectoryPath);
    if (modularManifest != null) {
      _manifest = modularManifest;
      _isInitialized = true;
      return;
    }

    _isInitialized = true;
  }

  /// Internal loader for modular assets/communities/*.json files with local overlay
  static Future<CommunityManifest?> _loadFromCommunitiesFolder([String? localDirectoryPath]) async {
    try {
      final assetManifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final communityAssetPaths = assetManifest
          .listAssets()
          .where(
            (p) => p.startsWith('assets/communities/') && p.endsWith('.json'),
          )
          .toList();

      Map<String, dynamic>? globalJson;
      final List<Map<String, dynamic>> languageJsons = [];

      if (communityAssetPaths.isNotEmpty) {
        await Future.wait(
          communityAssetPaths.map((path) async {
            try {
              final content = await rootBundle.loadString(path);
              final decoded = jsonDecode(content);
              if (decoded is Map<String, dynamic>) {
                if (path.endsWith('_global.json') ||
                    decoded.containsKey('global')) {
                  globalJson = decoded;
                } else {
                  languageJsons.add(decoded);
                }
              }
            } catch (e) {
              debugPrint('CommunityRegistry: Error loading $path: $e');
            }
          }),
        );
      }

      // Overlay any downloaded or updated files from localDirectoryPath
      if (!kIsWeb && localDirectoryPath != null) {
        try {
          final dir = Directory(localDirectoryPath);
          if (dir.existsSync()) {
            final files = dir
                .listSync()
                .whereType<File>()
                .where((f) => f.path.endsWith('.json'));
            for (final file in files) {
              try {
                final content = file.readAsStringSync();
                final decoded = jsonDecode(content);
                if (decoded is Map<String, dynamic>) {
                  if (file.path.endsWith('_global.json') ||
                      decoded.containsKey('global')) {
                    globalJson = decoded;
                  } else {
                    final code = decoded['code'] as String?;
                    if (code != null && code.isNotEmpty) {
                      languageJsons.removeWhere((item) => item['code'] == code);
                      languageJsons.add(decoded);
                    }
                  }
                }
              } catch (e) {
                debugPrint('CommunityRegistry: Error loading local file ${file.path}: $e');
              }
            }
          }
        } catch (e) {
          debugPrint('CommunityRegistry: Error scanning local directory: $e');
        }
      }

      if (languageJsons.isNotEmpty) {
        return CommunityManifest.fromMaps(
          globalJson: globalJson,
          languageJsons: languageJsons,
        );
      }
    } catch (e) {
      debugPrint('CommunityRegistry: AssetManifest loading failed: $e');
    }
    return null;
  }

  /// Load manifest from decoded maps (useful for tests or modular loaders)
  static void loadFromMaps({
    Map<String, dynamic>? globalJson,
    required Iterable<Map<String, dynamic>> languageJsons,
  }) {
    _manifest = CommunityManifest.fromMaps(
      globalJson: globalJson,
      languageJsons: languageJsons,
    );
    _isInitialized = true;
  }

  /// Manually load a manifest directly (useful for tests or runtime imports).
  static void loadManifest(CommunityManifest manifest) {
    _manifest = manifest;
    _isInitialized = true;
  }



  /// Retrieve language configuration by its language code.
  static CommunityLanguageConfig? getLanguage(String langCode) {
    return _manifest.languages[langCode.toLowerCase()];
  }

  /// Retrieve project configuration for a given language code and project type.
  static CommunityProjectConfig? getProject(String langCode, ProjectType project) {
    return getLanguage(langCode)?.getProject(project);
  }

  /// Check whether a project exists in the community manifest for the given language.
  /// Wikipedia is the anchor project and is always supported.
  static bool hasProject(String langCode, ProjectType project) {
    if (project == ProjectType.wikipedia) return true;
    return getProject(langCode, project) != null;
  }

  /// Check whether a project is supported/enabled in the given language.
  static bool isProjectSupported(String langCode, ProjectType project) {
    final projConfig = getProject(langCode, project);
    if (projConfig != null) {
      return projConfig.enabled;
    }

    // Default heuristic if not explicitly declared in manifest:
    return project == ProjectType.wikipedia;
  }

  /// Retrieve human-friendly project display name (e.g. Niaspedia, Jawapedia, Nusapedia).
  static String getDisplayName(String langCode, ProjectType project) {
    final projConfig = getProject(langCode, project);
    if (projConfig?.displayName != null && projConfig!.displayName!.isNotEmpty) {
      return projConfig.displayName!;
    }

    // Default fallback
    if (project == ProjectType.wikipedia) {
      switch (langCode.toLowerCase()) {
        case 'nia':
          return 'Niaspedia';
        case 'jv':
          return 'Jawapedia';
        default:
          return 'Nusapedia';
      }
    }
    return project.name;
  }

  /// Retrieve the default Main Page title for a language & project.
  static String getMainPageTitle(String langCode, ProjectType project) {
    final projConfig = getProject(langCode, project);
    if (projConfig?.mainPageTitle != null && projConfig!.mainPageTitle!.isNotEmpty) {
      return projConfig.mainPageTitle!;
    }

    // Fallback defaults
    switch (langCode.toLowerCase()) {
      case 'id':
        if (project == ProjectType.wiktionary) return 'Wikikamus:Halaman_Utama';
        return 'Halaman_Utama';
      case 'nia':
        if (project == ProjectType.wikipedia) return 'Wikipedia:Olayama';
        if (project == ProjectType.wiktionary) return 'Wikikamus:Olayama';
        return 'Olayama';
      case 'jv':
        if (project == ProjectType.wiktionary) return 'Wikisastra:Pendhapa';
        return 'Wikipédia:Pendhapa';
      case 'en':
        if (project == ProjectType.wiktionary) return 'Wiktionary:Main_Page';
        return 'Main_Page';
      default:
        return 'Main_Page';
    }
  }

  /// Returns true if a language is marked as experimental.
  /// Driven by `experimental` field in the community JSON, defaulting to true for non-primary languages.
  static bool isExperimental(String langCode) {
    final lang = getLanguage(langCode);
    if (lang != null) {
      return lang.isExperimental;
    }
    const priority = ['id', 'nia', 'en', 'jv'];
    return !priority.contains(langCode.toLowerCase());
  }

  /// Retrieve the community talk / chat page title.
  /// If explicitly declared in the manifest (even as empty ""), returns that value.
  static String getChatPageTitle(String langCode, ProjectType project) {
    final projConfig = getProject(langCode, project);
    if (projConfig?.chatPageTitle != null) {
      return projConfig!.chatPageTitle!;
    }

    final chatModule = getLanguage(langCode)?.modules['chat'];
    if (chatModule != null && chatModule.project == project) {
      return chatModule.pageTitle;
    }

    // Default fallback
    switch (project) {
      case ProjectType.wiktionary:
        return 'Wiktionary:Beer_parlour';
      case ProjectType.wikibooks:
        return 'Wikibooks:Staff_lounge';
      case ProjectType.wikipedia:
        switch (langCode.toLowerCase()) {
          case 'id':
            return 'Wikipedia:Warung_Kopi_(Semua)';
          case 'nia':
            return 'Wikipedia:Monganga_afo';
          case 'jv':
            return 'Wikipedia:Angkringan';
          case 'en':
            return 'Wikipedia:Teahouse';
          default:
            return 'Wikipedia:Village_pump';
        }
    }
  }

  /// Retrieve home page section extraction selectors.
  static Map<String, dynamic>? getHomePageSections(String langCode, ProjectType project) {
    return getProject(langCode, project)?.homePageSections;
  }

  /// Retrieve portal cards for home screen.
  static List<CommunityPortal> getPortals(String langCode, ProjectType project) {
    return getProject(langCode, project)?.portals ?? const [];
  }

  /// Retrieve quick shortcuts for drawer menu.
  static List<CommunityShortcut> getShortcuts(String langCode, ProjectType project) {
    return getProject(langCode, project)?.shortcuts ?? const [];
  }

  /// Retrieve module configuration.
  static CommunityModuleConfig? getModuleConfig(String langCode, String moduleKey) {
    return getLanguage(langCode)?.modules[moduleKey];
  }

  /// Retrieve all modules configured for a language.
  static Map<String, CommunityModuleConfig> getModules(String langCode) {
    return getLanguage(langCode)?.modules ?? const {};
  }

  /// Retrieve the domain for a given language code and project.
  /// Falls back to `<langCode>.<project>.org` if not specified.
  static String getDomain(String langCode, ProjectType project) {
    final projConfig = getProject(langCode, project);
    if (projConfig?.domain != null && projConfig!.domain!.isNotEmpty) {
      return projConfig.domain!;
    }
    return '${langCode.toLowerCase()}.${project.name.toLowerCase()}.org';
  }

  /// Retrieve the API prefix for a given language code and project.
  /// Falls back to an empty string.
  static String getApiPrefix(String langCode, ProjectType project) {
    final projConfig = getProject(langCode, project);
    return projConfig?.apiPrefix ?? '';
  }

  /// Get global rules for a project type.
  static Map<String, dynamic> getGlobalRules(ProjectType project) {
    return _manifest.globalRules[project] ??
        CommunityManifest.defaultGlobalRules[project] ??
        {};
  }

  /// Get combined rule list (e.g., 'remove', 'hide', 'referenceKeywords')
  /// from both global and language/project specific rules.
  static List<String> getCombinedRulesList(
    String langCode,
    ProjectType project,
    String key,
  ) {
    final Set<String> list = {};
    final globalRules = getGlobalRules(project);
    if (globalRules[key] is List) {
      list.addAll((globalRules[key] as List).map((e) => e.toString()));
    }

    final projConfig = getProject(langCode, project);
    if (projConfig != null) {
      switch (key) {
        case 'remove':
          list.addAll(projConfig.removeSelectors);
          list.removeAll(projConfig.keepSelectors);
          break;
        case 'hide':
          list.addAll(projConfig.hideSelectors);
          list.removeAll(projConfig.keepSelectors);
          break;
        case 'referenceKeywords':
          list.addAll(projConfig.referenceKeywords);
          break;
      }
    }
    return list.toList();
  }

  /// Retrieve processing flags for a language and project.
  static List<String> getProcessingFlags(String langCode, ProjectType project) {
    return getProject(langCode, project)?.processingFlags ?? const [];
  }

  /// Check if a specific processing flag exists for a language and project.
  static bool hasProcessingFlag(
    String langCode,
    ProjectType project,
    String flag,
  ) {
    return getProcessingFlags(langCode, project).contains(flag);
  }

  /// Retrieve a rules map compatible with legacy WikiConfig consumers.
  static Map<String, dynamic>? getRules(String langCode, ProjectType project) {
    final projConfig = getProject(langCode, project);
    if (projConfig == null) return null;

    final map = <String, dynamic>{};
    if (projConfig.domain != null) map['domainOverride'] = projConfig.domain;
    if (projConfig.apiPrefix != null) map['apiPrefix'] = projConfig.apiPrefix;
    if (projConfig.mainPageTitle != null) {
      map['mainPageTitle'] = projConfig.mainPageTitle;
    }
    if (projConfig.homePageSections != null) {
      map['homePageSections'] = projConfig.homePageSections;
    }
    if (projConfig.removeSelectors.isNotEmpty) {
      map['remove'] = projConfig.removeSelectors;
    }
    if (projConfig.hideSelectors.isNotEmpty) {
      map['hide'] = projConfig.hideSelectors;
    }
    if (projConfig.referenceKeywords.isNotEmpty) {
      map['referenceKeywords'] = projConfig.referenceKeywords;
    }
    if (projConfig.processingFlags.isNotEmpty) {
      map['processingFlags'] = projConfig.processingFlags;
    }
    return map;
  }

  /// Reset registry (for testing purposes).
  @visibleForTesting
  static void reset() {
    _manifest = const CommunityManifest(languages: {});
    _isInitialized = false;
  }
}
