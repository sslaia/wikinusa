import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final htmlRulesProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final response = await http.get(
      Uri.parse('https://raw.githubusercontent.com/sslaia/wikinusa/refs/heads/main/assets/data/html_rules.json'),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Failed to load HTML rules');
  } catch (e) {
    // Fallback global rules if fetch fails
    return {
      "global": {
        "remove": [
          ".ambox",
          ".gallery",
          ".gallerybox",
          ".gallerytext"
          ".infobox",
          ".metadata",
          ".mw-editsection",
          ".mw-references-wrap",
          ".navbox",
          "#References",
          ".references",
          "references",
          ".reflist",
          ".sidebar",
          "table",
          ".vertical-navbox",
        ],
        "referenceKeywords": ["reference", "referensi", "umbu"]
      }
    };
  }
});
