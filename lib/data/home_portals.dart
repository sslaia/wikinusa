import 'package:flutter/material.dart';
import 'package:wikimedia_core/wikimedia_core.dart';

class HomePortals {
  static Map<String, Map<String, List<Map<String, dynamic>>>> getPortals(
    BuildContext context,
  ) {
    if (CommunityRegistry.isInitialized && CommunityRegistry.languages.isNotEmpty) {
      final Map<String, Map<String, List<Map<String, dynamic>>>> result = {};
      for (final lang in CommunityRegistry.languages) {
        result[lang.code] = {};
        for (final project in ProjectType.values) {
          final portals = CommunityRegistry.getPortals(lang.code, project);
          result[lang.code]![project.name.toLowerCase()] =
              portals.map((p) => {'label': p.label, 'title': p.title}).toList();
        }
      }
      return result;
    }
    return const {};
  }
}
