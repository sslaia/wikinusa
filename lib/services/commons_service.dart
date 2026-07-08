import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:wikimedia_core/wikimedia_core.dart';

class CommonsService {
  static const String _baseUrl = 'https://commons.wikimedia.org/w/api.php';

  static Future<Map<String, dynamic>?> fetchImageInfo(String fileName) async {
    final url = Uri.parse('$_baseUrl?action=query&titles=$fileName&prop=imageinfo&iiprop=url|extmetadata&format=json&origin=*');

    try {
      final response = await http.get(url, headers: WikiConfig.uaHeaders).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final pages = data['query']?['pages'] as Map<String, dynamic>?;
        if (pages != null && pages.isNotEmpty) {
          final pageId = pages.keys.first;
          final imageInfo = pages[pageId]?['imageinfo'] as List<dynamic>?;
          if (imageInfo != null && imageInfo.isNotEmpty) {
            return imageInfo.first as Map<String, dynamic>;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error fetching image info: $e');
      }
    }
    return null;
  }

  static String getThumbnailUrl(String fileName, {int width = 900}) {
    // MediaWiki thumbnail URL convention is complex. 
    // It's often better to fetch it via API or use a stable thumb generator.
    // For simplicity, we can use the 'iiurl' from fetchImageInfo with 'iiurlwidth'.
    return 'https://commons.wikimedia.org/wiki/Special:FilePath/$fileName?width=$width';
  }

  static String getOriginalUrl(String fileName) {
    return 'https://commons.wikimedia.org/wiki/Special:FilePath/$fileName';
  }

  static Future<List<Map<String, dynamic>>> searchImages(String query) async {
    if (query.trim().isEmpty) return [];

    final url = Uri.parse(
      '$_baseUrl?action=query'
      '&generator=search'
      '&gsrsearch=$query'
      '&gsrnamespace=6'
      '&prop=imageinfo'
      '&iiprop=url'
      '&gsrlimit=30'
      '&format=json'
      '&origin=*'
    );

    try {
      final response = await http.get(url, headers: WikiConfig.uaHeaders).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final pages = data['query']?['pages'] as Map<String, dynamic>?;
        if (pages != null) {
          final List<Map<String, dynamic>> results = [];
          for (final page in pages.values) {
            final title = page['title'] as String?;
            if (title == null) continue;
            
            final imageInfo = page['imageinfo'] as List<dynamic>?;
            final url = (imageInfo != null && imageInfo.isNotEmpty)
                ? imageInfo.first['url'] as String?
                : null;
            
            if (url == null) continue;

            final fileName = title
                .replaceFirst(RegExp(r'^(File|Berkas):', caseSensitive: false), '')
                .trim();

            results.add({
              'title': title,
              'fileName': fileName,
              'url': url,
              'thumbnailUrl': getThumbnailUrl(fileName, width: 300),
            });
          }
          return results;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error searching images on Commons: $e');
      }
    }
    return [];
  }
}
