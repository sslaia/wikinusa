import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'shared_prefs_provider.dart';

final shortcutsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  const remoteUrl = 'https://raw.githubusercontent.com/sslaia/wikinusa/refs/heads/main/assets/data/shortcuts.json';
  final prefs = ref.watch(sharedPreferencesProvider);
  
  // Fetch remote shortcuts
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
    debugPrint('ShortcutsProvider: Failed to fetch remote shortcuts: $e');
  }

  // Fallback to cached shortcuts if available
  final cachedJson = prefs.getString('cached_shortcuts');
  if (cachedJson != null) {
    try {
      return json.decode(cachedJson) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('ShortcutsProvider: Failed to decode cached shortcuts: $e');
    }
  }

  // Final fallback: Load from local assets
  try {
    final assetJson = await rootBundle.loadString('assets/data/shortcuts.json');
    return json.decode(assetJson) as Map<String, dynamic>;
  } catch (e) {
    debugPrint('ShortcutsProvider: Failed to load shortcuts from assets: $e');
    // Absolute minimum fallback to prevent app crash
    return {
      "id": [
        {"icon": "history", "title": "Perubahan terbaru", "url": "https://id.wikipedia.org/wiki/Istimewa:Perubahan_terbaru"},
        {"icon": "pages_outlined", "title": "Halaman istimewa", "url": "https://id.wikipedia.org/wiki/Istimewa:Halaman_istimewa"},
        {"icon": "people_outlined", "title": "Portal komunitas", "url": "https://id.wikipedia.org/wiki/Portal:Komunitas"},
        {"icon": "chat_bubble_outline", "title": "Warung kopi", "url": "https://id.wikipedia.org/wiki/Wikipedia:Warung_Kopi"},
        {"icon": "construction_outlined", "title": "Bak pasir", "url": "https://id.wikipedia.org/wiki/Wikipedia:Bak_pasir"},
        {"icon": "help_outlined", "title": "Bantuan", "url": "https://id.wikipedia.org/wiki/Bantuan:Isi"}
      ],
    };
  }
});
