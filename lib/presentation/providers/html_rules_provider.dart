import 'dart:convert';
import 'package:flutter/services.dart';
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
    // Fallback to local file if fetch fails
    try {
      final jsonString = await rootBundle.loadString('assets/data/html_rules.json');
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      // Ultimate fallback if local file is inexplicably missing
      return {
        "global": {
          "remove": [
            ".ambox",
            ".gallery",
            ".gallerybox",
            ".gallerytext",
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
  }
});
