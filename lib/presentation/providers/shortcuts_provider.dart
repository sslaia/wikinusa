import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/wiki_project.dart';
import 'shared_prefs_provider.dart';
import 'language_provider.dart';
import 'project_provider.dart';

final shortcutsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  const remoteUrl = 'https://raw.githubusercontent.com/sslaia/wikinusa/refs/heads/main/assets/data/shortcuts.json';
  final prefs = ref.watch(sharedPreferencesProvider);
  final langCode = ref.watch(languageProvider).code;
  final project = ref.watch(projectProvider);
  
  Map<String, dynamic> shortcutsData;

  try {
    final response = await http.get(Uri.parse(remoteUrl)).timeout(const Duration(seconds: 5));
    
    if (response.statusCode == 200) {
      final remoteJson = response.body;
      final localJson = prefs.getString('cached_shortcuts');
      
      if (remoteJson != localJson) {
        await prefs.setString('cached_shortcuts', remoteJson);
      }
      shortcutsData = json.decode(remoteJson) as Map<String, dynamic>;
    } else {
      shortcutsData = await _getCachedOrAssetShortcuts(prefs);
    }
  } catch (e) {
    debugPrint('ShortcutsProvider: Failed to fetch remote shortcuts: $e');
    shortcutsData = await _getCachedOrAssetShortcuts(prefs);
  }

  // Resolve the list based on langCode and project
  if (shortcutsData.containsKey(langCode)) {
    final langData = shortcutsData[langCode];
    
    // Check if new structure (nested by project)
    if (langData is Map) {
      final projectData = langData[project.name];
      if (projectData is List) {
        return projectData.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } 
    // Fallback for old structure (direct list for Wikipedia)
    else if (langData is List && project == WikiProject.wikipedia) {
      return langData.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
  }

  return [];
});

Future<Map<String, dynamic>> _getCachedOrAssetShortcuts(var prefs) async {
  final cachedJson = prefs.getString('cached_shortcuts');
  if (cachedJson != null) {
    try {
      return json.decode(cachedJson) as Map<String, dynamic>;
    } catch (e) {}
  }
  final assetJson = await rootBundle.loadString('assets/data/shortcuts.json');
  return json.decode(assetJson) as Map<String, dynamic>;
}
