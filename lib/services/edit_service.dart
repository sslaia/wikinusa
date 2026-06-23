import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wikimedia_core/wikimedia_core.dart';

class EditService {
  static String _getFinalTitle(String pageTitle, String languageCode, String projectStr) {
    String apiPrefix = WikiConfig.getApiPrefix(languageCode, projectStr);
    if (apiPrefix.isEmpty) return pageTitle;
    
    if (pageTitle == 'Main Page') {
      return '${apiPrefix}Olayama'; // Wait, let's keep it simple or fallback to original title.
    }
    
    final lowerTitle = pageTitle.toLowerCase();
    if (lowerTitle.startsWith('special:') ||
        lowerTitle.startsWith('spesial:') ||
        lowerTitle.startsWith('mirunggan:') ||
        lowerTitle.startsWith('istimewa:') ||
        lowerTitle.startsWith('istimiwa:') ||
        lowerTitle.startsWith('istimèwa:') ||
        lowerTitle.startsWith('khas:') ||
        lowerTitle.startsWith('husus:')) {
      return pageTitle;
    } else if (lowerTitle.startsWith('category:') ||
               lowerTitle.startsWith('kategori:') ||
               lowerTitle.startsWith('template:') ||
               lowerTitle.startsWith('templat:')) {
      final parts = pageTitle.split(':');
      final namespace = parts[0];
      final rest = parts.sublist(1).join(':');
      return '$namespace:$apiPrefix$rest';
    } else if (!pageTitle.startsWith(apiPrefix)) {
      return '$apiPrefix$pageTitle';
    }
    return pageTitle;
  }

  static Future<String?> fetchWikitext({
    required ProjectType project,
    required String languageCode,
    required String title,
  }) async {
    final projectStr = project.name.toLowerCase();
    final domain = WikiConfig.getDomain(languageCode, projectStr);
    final finalTitle = _getFinalTitle(title, languageCode, projectStr);

    final url = Uri.parse(
        'https://$domain/w/api.php?action=query&prop=revisions&rvprop=content&rvslots=main&titles=${Uri.encodeComponent(finalTitle)}&format=json');

    try {
      final response = await http.get(url, headers: WikiConfig.uaHeaders).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final pages = data['query']?['pages'] as Map<String, dynamic>?;
        if (pages != null && pages.isNotEmpty) {
          final pageData = pages.values.first;
          if (pageData['revisions'] != null && pageData['revisions'].isNotEmpty) {
            final revision = pageData['revisions'][0];
            return revision['slots']?['main']?['*'] ?? revision['*'];
          } else if (pageData['missing'] == "") {
             return ""; // Page doesn't exist yet
          }
        }
      }
    } catch (e) {
      // Ignore error, return null
    }
    return null;
  }

  static Future<String?> fetchCsrfToken({
    required ProjectType project,
    required String languageCode,
    required String accessToken,
  }) async {
    final projectStr = project.name.toLowerCase();
    final domain = WikiConfig.getDomain(languageCode, projectStr);
    
    final url = Uri.parse('https://$domain/w/api.php?action=query&meta=tokens&format=json');
    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $accessToken',
        ...WikiConfig.uaHeaders,
      }).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['query']?['tokens']?['csrftoken'];
      }
    } catch (e) {
      // Ignore
    }
    return null;
  }

  static Future<bool> editPage({
    required ProjectType project,
    required String languageCode,
    required String title,
    required String text,
    required String summary,
    required String accessToken,
    required String csrfToken,
  }) async {
    final projectStr = project.name.toLowerCase();
    final domain = WikiConfig.getDomain(languageCode, projectStr);
    final finalTitle = _getFinalTitle(title, languageCode, projectStr);

    final url = Uri.parse('https://$domain/w/api.php');
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/x-www-form-urlencoded',
          ...WikiConfig.uaHeaders,
        },
        body: {
          'action': 'edit',
          'title': finalTitle,
          'text': text,
          'summary': summary,
          'token': csrfToken,
          'format': 'json',
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['edit'] != null && data['edit']['result'] == 'Success') {
          return true;
        }
      }
    } catch (e) {
      // Ignore
    }
    return false;
  }
}
