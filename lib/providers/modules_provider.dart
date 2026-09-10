import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wikimedia_core/wikimedia_core.dart';

class ModuleConfig {
  final bool enabled;
  final ProjectType project;
  final String pageTitle;
  final String? dataFile;

  const ModuleConfig({
    required this.enabled,
    required this.project,
    required this.pageTitle,
    this.dataFile,
  });

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
    );
  }
}

final modulesConfigProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final assetJson = await rootBundle.loadString('assets/data/modules.json');
    return json.decode(assetJson) as Map<String, dynamic>;
  } catch (e) {
    debugPrint('Failed to load modules.json: $e');
    return {};
  }
});

final moduleConfigProvider = Provider.family<ModuleConfig?, ({String moduleKey, String langCode})>((ref, arg) {
  final asyncData = ref.watch(modulesConfigProvider);
  final map = asyncData.asData?.value;
  if (map == null) {
    // Default fallback during initial load
    return ModuleConfig(
      enabled: arg.langCode == 'nia',
      project: (arg.moduleKey == 'newsletter' || arg.moduleKey == 'gallery')
          ? ProjectType.wikipedia
          : ProjectType.wiktionary,
      pageTitle: arg.moduleKey == 'newsletter'
          ? 'Wikipedia:Turia'
          : (arg.moduleKey == 'course' ? 'Wikikamus:Sulu' : ''),
    );
  }

  final langMap = map[arg.langCode] as Map<String, dynamic>?;
  final moduleMap = langMap?[arg.moduleKey] as Map<String, dynamic>?;
  if (moduleMap == null) return null;

  return ModuleConfig.fromJson(moduleMap);
});
