import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import '../models/home_page_section.dart';
import '../models/project_type.dart';
import 'home_page_builder.dart';

class WikiApiService {
  static Future<dynamic> fetchPageHtml(
    ProjectType project,
    String languageCode,
    String pageTitle,
    bool isArticle,
  ) async {
    final projectStr = project.name.toLowerCase();

    final cacheKey = isArticle
        ? 'article_${projectStr}_${languageCode}_$pageTitle'
        : 'home_page_${projectStr}_$languageCode';
    final cacheTimestampKey = '${cacheKey}_timestamp';

    final prefs = await SharedPreferences.getInstance();

    final cachedTimestampStr = prefs.getString(cacheTimestampKey);
    if (cachedTimestampStr != null) {
      final cachedTimestamp = DateTime.parse(cachedTimestampStr);
      final difference = DateTime.now().difference(cachedTimestamp);
      // Cache valid for 24 hours
      if (difference.inHours < 24) {
        final cachedData = prefs.getString(cacheKey);
        if (cachedData != null && cachedData.isNotEmpty) {
          if (!isArticle) {
            try {
              final List<dynamic> jsonList = jsonDecode(cachedData);
              return jsonList.map((e) => HomePageSection.fromJson(e)).toList();
            } catch (e) {
              await prefs.remove(cacheKey);
              await prefs.remove(cacheTimestampKey);
            }
          } else {
            return jsonDecode(cachedData);
          }
        }
      }
    }

    String url;
    if (isArticle) {
      // Keep using action API for articles as it provides easier parsing of specific properties if needed
      url = 'https://$languageCode.$projectStr.org/w/api.php?action=parse&page=${Uri.encodeComponent(pageTitle)}&format=json&prop=text|images&mobileformat=1&redirects=1';
    } else {
      // New REST API endpoint for home page content
      url = 'https://$languageCode.$projectStr.org/w/rest.php/v1/page/${Uri.encodeComponent(pageTitle)}/html';
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      if (isArticle) {
        final bodyStr = utf8.decode(response.bodyBytes);
        final decoded = jsonDecode(bodyStr);
        String htmlContent = '';
        if (decoded['parse'] != null && decoded['parse']['text'] != null) {
          htmlContent = decoded['parse']['text']['*'] ?? '';
          
          final document = html_parser.parse(htmlContent);
          String? imageUrl;
          
          // Find first image that is not an icon
          final images = document.querySelectorAll('img');
          for (var img in images) {
             final src = img.attributes['src'] ?? '';
             final isIcon = src.contains('/static/images/mobile/copyright/') || 
                          src.contains('/static/images/footer/') ||
                          src.contains('.svg'); // Simple check to skip icons/logos
             
             if (!isIcon) {
                imageUrl = src;
                if (!imageUrl.startsWith('http')) {
                   imageUrl = 'https:$imageUrl';
                }
                // Try to get higher res version if it's a thumbnail
                if (imageUrl.contains('/thumb/')) {
                  final regExp = RegExp(r'\/(\d+)px-');
                  if (regExp.hasMatch(imageUrl)) {
                    imageUrl = imageUrl.replaceFirst(regExp, '/500px-');
                  }
                }

                // Identify container to remove the caption as well
                dom.Element? containerToRemove = img;
                
                // Traverse up to find the standard Wikipedia image container
                // This ensures captions (usually in <figcaption> or .thumbcaption) are removed too.
                var parent = img.parent;
                while (parent != null && parent.localName != 'body') {
                  if (parent.localName == 'figure' || 
                      parent.classes.contains('thumb') || 
                      parent.classes.contains('infobox-image')) {
                    containerToRemove = parent;
                    break;
                  }
                  parent = parent.parent;
                }
                
                containerToRemove?.remove(); 
                break;
             }
          }
          
          final result = {
            'html': document.body?.innerHtml ?? '',
            'imageUrl': imageUrl,
          };

          await prefs.setString(cacheKey, jsonEncode(result));
          await prefs.setString(cacheTimestampKey, DateTime.now().toIso8601String());
          return result;
        }
        return {'html': '<i>Error: Could not parse article content.</i>', 'imageUrl': null};
      } else {
        final List<HomePageSection> sections = await HomePageBuilder.build(
          response.bodyBytes,
          languageCode,
          project,
        );
        
        await prefs.setString(cacheKey, jsonEncode(sections.map((e) => e.toJson()).toList()));
        await prefs.setString(cacheTimestampKey, DateTime.now().toIso8601String());
        return sections;
      }
    } else {
      throw Exception('Failed to load page: ${response.statusCode}');
    }
  }

  static Future<List<Map<String, dynamic>>> searchArticles(
    String query,
    String langCode,
    String projectStr,
  ) async {
    final url = Uri.parse(
      'https://$langCode.$projectStr.org/w/api.php?action=query&list=search&srsearch=${Uri.encodeComponent(query)}&format=json&utf8=1',
    );

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to search Wikipedia');
    }

    final data = json.decode(response.body);
    return List<Map<String, dynamic>>.from(data['query']['search']);
  }

  static Future<String?> fetchRandomArticleTitle(
    String langCode,
    String projectStr,
  ) async {
    final url = Uri.parse(
      'https://$langCode.$projectStr.org/w/api.php?action=query&list=random&rnnamespace=0&rnlimit=1&format=json',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final randomList = data['query']?['random'] as List?;
      if (randomList != null && randomList.isNotEmpty) {
        return randomList[0]['title'] as String?;
      }
    }
    return null;
  }
}
