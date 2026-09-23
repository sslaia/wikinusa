import 'project_type.dart';

/// Represents a thematic topic portal card on the home page.
class CommunityPortal {
  final String label;
  final String title;

  const CommunityPortal({
    required this.label,
    required this.title,
  });

  Map<String, dynamic> toJson() => {
    'label': label,
    'title': title,
  };

  factory CommunityPortal.fromJson(Map<String, dynamic> json) => CommunityPortal(
    label: json['label'] as String? ?? '',
    title: json['title'] as String? ?? '',
  );
}

/// Represents a drawer quick shortcut item for a project.
class CommunityShortcut {
  final String icon;
  final String title;
  final String pageTitle;

  const CommunityShortcut({
    required this.icon,
    required this.title,
    required this.pageTitle,
  });

  Map<String, dynamic> toJson() => {
    'icon': icon,
    'title': title,
    'pageTitle': pageTitle,
  };

  factory CommunityShortcut.fromJson(Map<String, dynamic> json) => CommunityShortcut(
    icon: json['icon'] as String? ?? 'shortcut',
    title: json['title'] as String? ?? '',
    pageTitle: json['pageTitle'] as String? ?? '',
  );
}

/// Configuration for a specific Wikimedia project (Wikipedia, Wiktionary, Wikibooks) within a language.
class CommunityProjectConfig {
  final bool enabled;
  final String? displayName;
  final String? domain;
  final String? apiPrefix;
  final String? mainPageTitle;
  final String? chatPageTitle;
  final Map<String, dynamic>? homePageSections;
  final List<CommunityPortal> portals;
  final List<CommunityShortcut> shortcuts;
  final List<String> removeSelectors;
  final List<String> hideSelectors;
  final List<String> referenceKeywords;
  final List<String> processingFlags;
  final List<String> keepSelectors;

  const CommunityProjectConfig({
    this.enabled = true,
    this.displayName,
    this.domain,
    this.apiPrefix,
    this.mainPageTitle,
    this.chatPageTitle,
    this.homePageSections,
    this.portals = const [],
    this.shortcuts = const [],
    this.removeSelectors = const [],
    this.hideSelectors = const [],
    this.referenceKeywords = const [],
    this.processingFlags = const [],
    this.keepSelectors = const [],
  });

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    if (displayName != null) 'displayName': displayName,
    if (domain != null) 'domain': domain,
    if (apiPrefix != null) 'apiPrefix': apiPrefix,
    if (mainPageTitle != null) 'mainPageTitle': mainPageTitle,
    if (chatPageTitle != null) 'chatPageTitle': chatPageTitle,
    if (homePageSections != null) 'homePageSections': homePageSections,
    if (portals.isNotEmpty) 'portals': portals.map((e) => e.toJson()).toList(),
    if (shortcuts.isNotEmpty) 'shortcuts': shortcuts.map((e) => e.toJson()).toList(),
    if (removeSelectors.isNotEmpty) 'remove': removeSelectors,
    if (hideSelectors.isNotEmpty) 'hide': hideSelectors,
    if (referenceKeywords.isNotEmpty) 'referenceKeywords': referenceKeywords,
    if (processingFlags.isNotEmpty) 'processingFlags': processingFlags,
    if (keepSelectors.isNotEmpty) 'keep': keepSelectors,
  };

  factory CommunityProjectConfig.fromJson(Map<String, dynamic> json) {
    return CommunityProjectConfig(
      enabled: json['enabled'] as bool? ?? true,
      displayName: json['displayName'] as String?,
      domain: json['domain'] as String?,
      apiPrefix: json['apiPrefix'] as String?,
      mainPageTitle: json['mainPageTitle'] as String?,
      chatPageTitle: json['chatPageTitle'] as String?,
      homePageSections: json['homePageSections'] as Map<String, dynamic>?,
      portals: (json['portals'] as List<dynamic>?)
              ?.map((e) => CommunityPortal.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      shortcuts: (json['shortcuts'] as List<dynamic>?)
              ?.map((e) => CommunityShortcut.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      removeSelectors: (json['remove'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      hideSelectors: (json['hide'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      referenceKeywords: (json['referenceKeywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      processingFlags: (json['processingFlags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      keepSelectors: (json['keep'] is List)
              ? (json['keep'] as List<dynamic>).map((e) => e.toString()).toList()
              : const [],
    );
  }
}

/// Configuration for an interactive module (crosswords, course, newsletter, gallery, chat) within a language.
class CommunityModuleConfig {
  final bool enabled;
  final ProjectType project;
  final String pageTitle;
  final String? dataFile;
  final bool isCustomDataFile;

  const CommunityModuleConfig({
    required this.enabled,
    this.project = ProjectType.wikipedia,
    this.pageTitle = '',
    this.dataFile,
    this.isCustomDataFile = false,
  });

  CommunityModuleConfig copyWith({
    bool? enabled,
    ProjectType? project,
    String? pageTitle,
    String? dataFile,
    bool? isCustomDataFile,
  }) {
    return CommunityModuleConfig(
      enabled: enabled ?? this.enabled,
      project: project ?? this.project,
      pageTitle: pageTitle ?? this.pageTitle,
      dataFile: dataFile ?? this.dataFile,
      isCustomDataFile: isCustomDataFile ?? this.isCustomDataFile,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'project': project.name.toLowerCase(),
    'pageTitle': pageTitle,
    if (dataFile != null) 'dataFile': dataFile,
    'isCustomDataFile': isCustomDataFile,
  };

  factory CommunityModuleConfig.fromJson(Map<String, dynamic> json) {
    ProjectType projectType = ProjectType.wikipedia;
    final projStr = json['project'] as String?;
    if (projStr != null) {
      try {
        projectType = ProjectType.values.byName(projStr.toLowerCase());
      } catch (_) {}
    }

    return CommunityModuleConfig(
      enabled: json['enabled'] as bool? ?? false,
      project: projectType,
      pageTitle: json['pageTitle'] as String? ?? '',
      dataFile: json['dataFile'] as String?,
      isCustomDataFile: json['isCustomDataFile'] as bool? ?? false,
    );
  }
}

/// Declarative configuration bundle for an entire language community.
class CommunityLanguageConfig {
  final String code;
  final String name;
  final String englishName;
  final String direction; // 'ltr' | 'rtl'
  final bool isExperimental;
  final Map<ProjectType, CommunityProjectConfig> projects;
  final Map<String, CommunityModuleConfig> modules;

  const CommunityLanguageConfig({
    required this.code,
    required this.name,
    required this.englishName,
    this.direction = 'ltr',
    this.isExperimental = true,
    this.projects = const {},
    this.modules = const {},
  });

  CommunityProjectConfig? getProject(ProjectType type) => projects[type];

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': name,
    'englishName': englishName,
    'direction': direction,
    'experimental': isExperimental,
    'projects': projects.map((k, v) => MapEntry(k.name.toLowerCase(), v.toJson())),
    'modules': modules.map((k, v) => MapEntry(k, v.toJson())),
  };

  factory CommunityLanguageConfig.fromJson(Map<String, dynamic> json) {
    final projectsRaw = (json['projects'] is Map)
        ? (json['projects'] as Map)
        : const {};
    final Map<ProjectType, CommunityProjectConfig> projects = {};
    for (final entry in projectsRaw.entries) {
      try {
        final type = ProjectType.values.byName(entry.key.toString().toLowerCase());
        if (entry.value is Map) {
          projects[type] = CommunityProjectConfig.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          );
        }
      } catch (_) {}
    }

    final modulesRaw = (json['modules'] is Map)
        ? (json['modules'] as Map)
        : const {};
    final Map<String, CommunityModuleConfig> modules = {};
    for (final entry in modulesRaw.entries) {
      if (entry.value is Map) {
        modules[entry.key.toString()] = CommunityModuleConfig.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        );
      }
    }

    final explicitExp = json['experimental'] as bool? ?? json['isExperimental'] as bool?;
    const primaryLangs = ['id', 'nia'];
    final codeStr = json['code'] as String? ?? '';
    final isExp = explicitExp ?? (!primaryLangs.contains(codeStr.toLowerCase()));

    return CommunityLanguageConfig(
      code: codeStr,
      name: json['name'] as String? ?? '',
      englishName: json['englishName'] as String? ?? '',
      direction: json['direction'] as String? ?? 'ltr',
      isExperimental: isExp,
      projects: projects,
      modules: modules,
    );
  }
}

/// Top-level manifest container holding all language configurations.
class CommunityManifest {
  final Map<ProjectType, Map<String, dynamic>> globalRules;
  final Map<String, CommunityLanguageConfig> languages;

  const CommunityManifest({
    this.globalRules = const {},
    required this.languages,
  });

  /// Built-in fallback global rules for standard Wikimedia projects
  static Map<ProjectType, Map<String, dynamic>> get defaultGlobalRules => {
    ProjectType.wikipedia: {
      'remove': [
        '.ambox',
        '.catlinks',
        '.hatnote',
        '.metadata',
        '.mw-editsection',
        '.navbox',
        '.nomobile',
        '.noprint',
        'script',
        'style',
      ],
      'hide': [
        '.references',
        '.reflist',
      ],
      'referenceKeywords': [
        'reference',
        'reflist',
        'referensi',
        'umbu',
        'famotokhi ba gahe',
        'catatan kaki',
        'rujukan',
        'sumber',
        'notes',
      ],
    },
    ProjectType.wiktionary: {
      'remove': [
        '.navbox',
        '.metadata',
        '.ambox',
        '.noprint',
        '.mw-editsection',
        'style',
        'script',
      ],
      'hide': [
        '.reflist',
        '.references',
      ],
      'referenceKeywords': [
        'reference',
        'reflist',
        'referensi',
        'catatan kaki',
        'notes',
      ],
    },
    ProjectType.wikibooks: {
      'remove': [
        '.navbox',
        '.metadata',
        '.ambox',
        '.noprint',
        '.mw-editsection',
        'style',
        'script',
      ],
      'hide': [
        '.reflist',
        '.references',
      ],
      'referenceKeywords': [
        'reference',
        'reflist',
        'referensi',
        'catatan kaki',
        'umbu',
        'famotokhi ba gahe',
        'notes',
      ],
    },
  };

  factory CommunityManifest.fromJson(Map<String, dynamic> json) {
    final globalRaw = json['global'] as Map<String, dynamic>? ?? {};
    final Map<ProjectType, Map<String, dynamic>> globalRules =
        Map.from(defaultGlobalRules);
    for (final entry in globalRaw.entries) {
      try {
        final type = ProjectType.values.byName(entry.key.toLowerCase());
        if (entry.value is Map) {
          globalRules[type] = Map<String, dynamic>.from(entry.value as Map);
        }
      } catch (_) {}
    }

    final languagesRaw = json['languages'] as Map<String, dynamic>? ?? json;
    final Map<String, CommunityLanguageConfig> languages = {};

    for (final entry in languagesRaw.entries) {
      if (entry.key == 'global') continue;
      if (entry.value is Map<String, dynamic>) {
        final langConfig = CommunityLanguageConfig.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        );
        languages[entry.key.toLowerCase()] = langConfig;
      }
    }
    return CommunityManifest(
      globalRules: globalRules,
      languages: languages,
    );
  }

  /// Factory to assemble a manifest from individual decoded maps (e.g. modular JSON files)
  factory CommunityManifest.fromMaps({
    Map<String, dynamic>? globalJson,
    required Iterable<Map<String, dynamic>> languageJsons,
  }) {
    final Map<ProjectType, Map<String, dynamic>> globalRules =
        Map.from(defaultGlobalRules);
    if (globalJson != null) {
      final globalRaw =
          globalJson['global'] as Map<String, dynamic>? ?? globalJson;
      for (final entry in globalRaw.entries) {
        try {
          final type = ProjectType.values.byName(entry.key.toLowerCase());
          if (entry.value is Map) {
            globalRules[type] = Map<String, dynamic>.from(entry.value as Map);
          }
        } catch (_) {}
      }
    }

    final Map<String, CommunityLanguageConfig> unordered = {};
    for (final langMap in languageJsons) {
      try {
        final langConfig = CommunityLanguageConfig.fromJson(langMap);
        if (langConfig.code.isNotEmpty) {
          unordered[langConfig.code.toLowerCase()] = langConfig;
        }
      } catch (_) {
        // Fault isolation: malformed language file is skipped without breaking others
      }
    }

    // Keep primary languages at the top in consistent order, then alphabetical
    final Map<String, CommunityLanguageConfig> languages = {};
    const priority = ['id', 'nia', 'en', 'jv'];
    for (final code in priority) {
      if (unordered.containsKey(code)) {
        languages[code] = unordered.remove(code)!;
      }
    }
    final remainingKeys = unordered.keys.toList()..sort();
    for (final code in remainingKeys) {
      languages[code] = unordered[code]!;
    }

    return CommunityManifest(
      globalRules: globalRules,
      languages: languages,
    );
  }

  Map<String, dynamic> toJson() => {
    if (globalRules.isNotEmpty)
      'global': globalRules.map((k, v) => MapEntry(k.name.toLowerCase(), v)),
    'languages': languages.map((k, v) => MapEntry(k, v.toJson())),
  };
}
