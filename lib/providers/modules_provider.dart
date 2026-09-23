import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:wikimedia_core/wikimedia_core.dart';
import 'shared_prefs_provider.dart';

class ModuleConfig {
  final bool enabled;
  final ProjectType project;
  final String pageTitle;
  final String? dataFile;
  final bool isCustomDataFile;

  const ModuleConfig({
    required this.enabled,
    required this.project,
    required this.pageTitle,
    this.dataFile,
    this.isCustomDataFile = false,
  });

  ModuleConfig copyWith({
    bool? enabled,
    ProjectType? project,
    String? pageTitle,
    String? dataFile,
    bool? isCustomDataFile,
  }) {
    return ModuleConfig(
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

  factory ModuleConfig.fromJson(Map<String, dynamic> json) {
    ProjectType projectType = ProjectType.wikipedia;
    final projStr = json['project'] as String?;
    if (projStr != null) {
      try {
        projectType = ProjectType.values.byName(projStr.toLowerCase());
      } catch (_) {}
    }

    return ModuleConfig(
      enabled: json['enabled'] as bool? ?? false,
      project: projectType,
      pageTitle: json['pageTitle'] as String? ?? '',
      dataFile: json['dataFile'] as String?,
      isCustomDataFile: json['isCustomDataFile'] as bool? ?? false,
    );
  }
}

class ModulesConfigNotifier
    extends StateNotifier<Map<String, Map<String, ModuleConfig>>> {
  final Ref ref;
  late final Future<void> initFuture;

  ModulesConfigNotifier(this.ref) : super({}) {
    initFuture = _loadConfig();
  }

  Future<void> _loadConfig() async {
    final Map<String, Map<String, ModuleConfig>> result = {};

    if (!CommunityRegistry.isInitialized) {
      try {
        await CommunityRegistry.init();
      } catch (e) {
        debugPrint('ModulesProvider: Failed to initialize CommunityRegistry: $e');
      }
    }

    if (CommunityRegistry.languages.isNotEmpty) {
      for (final lang in CommunityRegistry.languages) {
        result[lang.code] = {};
        for (final entry in lang.modules.entries) {
          result[lang.code]![entry.key] = ModuleConfig(
            enabled: entry.value.enabled,
            project: entry.value.project,
            pageTitle: entry.value.pageTitle,
            dataFile: entry.value.dataFile,
            isCustomDataFile: entry.value.isCustomDataFile,
          );
        }
      }
    }

    // Load user overrides from SharedPreferences
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final overridesStr = prefs.getString('custom_modules_config');
      if (overridesStr != null) {
        final Map<String, dynamic> overrides = json.decode(overridesStr);
        for (final langEntry in overrides.entries) {
          final langCode = langEntry.key;
          final modulesMap = langEntry.value as Map<String, dynamic>? ?? {};
          result.putIfAbsent(langCode, () => {});
          for (final modEntry in modulesMap.entries) {
            result[langCode]![modEntry.key] = ModuleConfig.fromJson(
              modEntry.value as Map<String, dynamic>,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to load custom_modules_config from prefs: $e');
    }

    state = result;
  }

  Future<void> updateModuleConfig({
    required String langCode,
    required String moduleKey,
    required ModuleConfig config,
  }) async {
    final newState = <String, Map<String, ModuleConfig>>{
      for (final e in state.entries)
        e.key: <String, ModuleConfig>{...e.value},
    };
    newState.putIfAbsent(langCode, () => <String, ModuleConfig>{});
    newState[langCode]![moduleKey] = config;
    state = newState;

    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final overridesStr = prefs.getString('custom_modules_config');
      Map<String, dynamic> overrides = {};
      if (overridesStr != null) {
        try {
          overrides = json.decode(overridesStr) as Map<String, dynamic>;
        } catch (_) {}
      }
      overrides.putIfAbsent(langCode, () => <String, dynamic>{});
      overrides[langCode][moduleKey] = config.toJson();
      await prefs.setString('custom_modules_config', json.encode(overrides));
    } catch (e) {
      debugPrint('Failed to save custom_modules_config: $e');
    }
  }

  Future<void> resetToDefaults({String? langCode}) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      if (langCode != null) {
        final overridesStr = prefs.getString('custom_modules_config');
        if (overridesStr != null) {
          final Map<String, dynamic> overrides = json.decode(overridesStr);
          overrides.remove(langCode);
          await prefs.setString('custom_modules_config', json.encode(overrides));
        }
      } else {
        await prefs.remove('custom_modules_config');
      }
    } catch (e) {
      debugPrint('Failed to reset custom_modules_config: $e');
    }
    await _loadConfig();
  }
}

final modulesConfigNotifierProvider = StateNotifierProvider<
    ModulesConfigNotifier,
    Map<String, Map<String, ModuleConfig>>>((ref) {
  return ModulesConfigNotifier(ref);
});

final moduleConfigProvider = Provider.family<
    ModuleConfig?,
    ({String moduleKey, String langCode})>((ref, arg) {
  final allConfigs = ref.watch(modulesConfigNotifierProvider);
  final config = allConfigs[arg.langCode]?[arg.moduleKey];
  if (config != null) return config;

  return ModuleConfig(
    enabled: arg.langCode == 'nia' || arg.moduleKey == 'chat',
    project: (arg.moduleKey == 'newsletter' ||
            arg.moduleKey == 'gallery' ||
            arg.moduleKey == 'chat')
        ? ProjectType.wikipedia
        : ProjectType.wiktionary,
    pageTitle: arg.moduleKey == 'newsletter'
        ? 'Wikipedia:Turia'
        : (arg.moduleKey == 'course' ? 'Wikikamus:Sulu' : ''),
  );
});
