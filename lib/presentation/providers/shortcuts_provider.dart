import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'shared_prefs_provider.dart';

final shortcutsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  const remoteUrl = 'https://raw.githubusercontent.com/sslaia/wikinusa/refs/heads/main/assets/data/shortcuts.json';
  final prefs = ref.watch(sharedPreferencesProvider);
  
  // 1. Try to fetch remote shortcuts
  try {
    final response = await http.get(Uri.parse(remoteUrl)).timeout(const Duration(seconds: 5));
    
    if (response.statusCode == 200) {
      final remoteJson = response.body;
      final localJson = prefs.getString('cached_shortcuts');
      
      // If different from what we have cached, update cache
      if (remoteJson != localJson) {
        await prefs.setString('cached_shortcuts', remoteJson);
      }
      return json.decode(remoteJson) as Map<String, dynamic>;
    }
  } catch (e) {
    // Silently fail and fallback to cache or assets
    print('Failed to fetch remote shortcuts: $e');
  }

  // 2. Fallback to cached shortcuts if available
  final cachedJson = prefs.getString('cached_shortcuts');
  if (cachedJson != null) {
    try {
      return json.decode(cachedJson) as Map<String, dynamic>;
    } catch (e) {
      print('Failed to decode cached shortcuts: $e');
    }
  }

  // 3. Final fallback: Load from local assets
  try {
    final assetJson = await rootBundle.loadString('assets/data/shortcuts.json');
    return json.decode(assetJson) as Map<String, dynamic>;
  } catch (e) {
    print('Failed to load shortcuts from assets: $e');
    // Absolute minimum fallback to prevent app crash
    return {
      "nia": [
        {"icon": "history", "title": "recent_changes", "url": "https://nia.wikipedia.org/wiki/Spesial:Perubahan_terbaru"},
        {"icon": "campaign_outlined", "title": "announcement", "url": "https://nia.wikipedia.org/wiki/Wikipedia:Angombakhata"},
        {"icon": "people_outlined", "title": "community_portal", "url": "https://nia.wikipedia.org/wiki/Wikipedia:Bawagöli_zato"},
        {"icon": "water_drop_outlined", "title": "village_pump", "url": "https://nia.wikipedia.org/wiki/Wikipedia:Monganga_afo"},
        {"icon": "construction_outlined", "title": "sandbox", "url": "https://nia.wikipedia.org/wiki/Wikipedia:Nahia_wamakori"},
        {"icon": "help_outlined", "title": "help", "url": "https://nia.wikipedia.org/wiki/Fanolo:Fanolo"},
        {"icon": "support_agent_outlined", "title": "helpers", "url": "https://nia.wikipedia.org/wiki/Wikipedia:Sangai_halöŵö"}
      ]
    };
  }
});
