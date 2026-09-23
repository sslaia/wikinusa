import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wikimedia_core/wikimedia_core.dart';
import 'shared_prefs_provider.dart';

final shortcutsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  if (!CommunityRegistry.isInitialized) {
    try {
      await CommunityRegistry.init();
    } catch (e) {
      debugPrint('ShortcutsProvider: Failed to initialize CommunityRegistry: $e');
    }
  }

  if (CommunityRegistry.languages.isNotEmpty) {
    final Map<String, dynamic> result = {};
    for (final lang in CommunityRegistry.languages) {
      result[lang.code] = <String, dynamic>{};
      for (final project in ProjectType.values) {
        final shortcuts = CommunityRegistry.getShortcuts(lang.code, project);
        result[lang.code][project.name.toLowerCase()] =
            shortcuts.map((s) => s.toJson()).toList();
      }
    }
    return result;
  }

  final prefs = ref.watch(sharedPreferencesProvider);

  // Fallback to cached shortcuts if available
  final cachedJson = prefs.getString('cached_shortcuts');
  if (cachedJson != null) {
    try {
      return json.decode(cachedJson) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('ShortcutsProvider: Failed to decode cached shortcuts: $e');
    }
  }

  // Absolute minimum fallback to prevent app crash
    return {
      "nia": {
        "wikipedia": [
          {
            "icon": "history",
            "title": "Safuria tebulö",
            "pageTitle": "Spesial:Perubahan_terbaru",
          },
          {
            "icon": "pages_outlined",
            "title": "Nga'örö spesial",
            "pageTitle": "Spesial:Halaman_istimewa",
          },
          {
            "icon": "campaign_outlined",
            "title": "Angombakhata",
            "pageTitle": "Wikipedia:Angombakhata",
          },
          {
            "icon": "people_outlined",
            "title": "Bawagöli zato",
            "pageTitle": "Wikipedia:Bawagöli_zato",
          },
          {
            "icon": "chat_bubble_outlined",
            "title": "Monganga afo",
            "pageTitle": "Wikipedia:Monganga_afo",
          },
          {
            "icon": "construction_outlined",
            "title": "Nahia wamakori",
            "pageTitle": "Wikipedia:Nahia_wamakori",
          },
          {
            "icon": "help_outline",
            "title": "Fanolo",
            "pageTitle": "Fanolo:Fanolo",
          },
          {
            "icon": "support_agent_outlined",
            "title": "Sangai halöŵö",
            "pageTitle": "Wikipedia:Sangai_halöŵö",
          },
        ],
        "wiktionary": [
          {
            "icon": "history",
            "title": "Safuria tebulö",
            "pageTitle": "Spesial:Perubahan_terbaru",
          },
          {
            "icon": "pages_outlined",
            "title": "Nga'örö spesial",
            "pageTitle": "Spesial:Halaman_istimewa",
          },
          {
            "icon": "campaign_outlined",
            "title": "Angombakhata",
            "pageTitle": "Wikikamus:Angombakhata",
          },
          {
            "icon": "people_outlined",
            "title": "Bawagöli zato",
            "pageTitle": "Wikikamus:Bawagöli_zato",
          },
          {
            "icon": "chat_bubble_outlined",
            "title": "Monganga afo",
            "pageTitle": "Wikikamus:Monganga_afo",
          },
          {
            "icon": "construction_outlined",
            "title": "Nahia wamakori",
            "pageTitle": "Wikikamus:Nahia_wamakori",
          },
          {
            "icon": "help_outline",
            "title": "Fanolo",
            "pageTitle": "Fanolo:Fanolo",
          },
          {
            "icon": "support_agent_outlined",
            "title": "Sangai halöŵö",
            "pageTitle": "Wikikamus:Sangai_halöŵö",
          },
        ],
        "wikibooks": [
          {
            "icon": "history",
            "title": "Safuria tebulö",
            "pageTitle":
                "Special:RecentChanges?hidebots=1&translations=filter&hidecategorization=1&hideWikibase=1&hideWikifunctions=1&limit=250&days=30&urlversion=2&rc-testwiki-project=b&rc-testwiki-code=nia",
          },
          {
            "icon": "pages_outlined",
            "title": "Nga'örö spesial",
            "pageTitle": "Special:SpecialPages",
          },
          {
            "icon": "campaign_outlined",
            "title": "Angombakhata",
            "pageTitle": "Wikibooks:Angombakhata",
          },
          {
            "icon": "people_outlined",
            "title": "Bawagöli zato",
            "pageTitle": "Wikibooks:Bawagöli_zato",
          },
          {
            "icon": "chat_bubble_outlined",
            "title": "Monganga afo",
            "pageTitle": "Wikibooks:Monganga_afo",
          },
          {
            "icon": "construction_outlined",
            "title": "Nahia wamakori",
            "pageTitle": "Wikibooks:Nahia_wamakori",
          },
          {
            "icon": "help_outline",
            "title": "Fanolo",
            "pageTitle": "Help:Fanolo",
          },
          {
            "icon": "support_agent_outlined",
            "title": "Sangai halöŵö",
            "pageTitle": "Wikibooks:Sangai_halöŵö",
          },
        ],
      },
    };
});
