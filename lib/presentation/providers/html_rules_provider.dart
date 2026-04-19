import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'project_provider.dart';

final htmlRulesProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final project = ref.watch(projectProvider);
  Map<String, dynamic> allRules;

  try {
    final response = await http.get(
      Uri.parse('https://raw.githubusercontent.com/sslaia/wikinusa/refs/heads/main/assets/data/html_rules.json'),
    );
    if (response.statusCode == 200) {
      allRules = json.decode(response.body) as Map<String, dynamic>;
    } else {
      allRules = await _loadLocalRules();
    }
  } catch (e) {
    allRules = await _loadLocalRules();
  }

  // If the new structure is detected (nested by language and project), 
  // we filter it here so consumers don't have to worry about the nesting.
  // Note: Since html_rules.json contains both "global" and language-specific keys,
  // we return the whole map, but you'll need to update your Home Page Builders 
  // to look under nia -> wikipedia instead of just nia.
  
  return allRules;
});

Future<Map<String, dynamic>> _loadLocalRules() async {
  try {
    final jsonString = await rootBundle.loadString('assets/data/html_rules.json');
    return json.decode(jsonString) as Map<String, dynamic>;
  } catch (_) {
    return {
      "global": {
        "remove": [".ambox", ".gallery", ".navbox", "table"],
        "referenceKeywords": ["reference", "referensi", "umbu"]
      }
    };
  }
}
