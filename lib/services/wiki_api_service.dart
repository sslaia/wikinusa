import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/home_page_section.dart';
import '../models/project_type.dart';
import 'home_page_builder.dart';
import 'html_processor.dart';

class WikiApiService {
  static String _getCacheKey(ProjectType project, String languageCode, String pageTitle, bool isArticle) {
    final projectStr = project.name.toLowerCase();
    return isArticle
        ? 'article_${projectStr}_${languageCode}_$pageTitle'
        : 'home_page_${projectStr}_$languageCode';
  }

  static Future<void> clearCache(ProjectType project, String languageCode, String? pageTitle) async {
    final prefs = await SharedPreferences.getInstance();
    final isArticle = pageTitle != null && pageTitle.isNotEmpty;
    final cacheKey = _getCacheKey(project, languageCode, pageTitle ?? 'Main Page', isArticle);
    await prefs.remove(cacheKey);
    await prefs.remove('${cacheKey}_timestamp');
  }

  static Future<dynamic> fetchPageHtml(
    ProjectType project,
    String languageCode,
    String pageTitle,
    bool isArticle, {
    bool forceRefresh = false,
  }) async {
    final projectStr = project.name.toLowerCase();
    final cacheKey = _getCacheKey(project, languageCode, pageTitle, isArticle);
    final cacheTimestampKey = '${cacheKey}_timestamp';

    final prefs = await SharedPreferences.getInstance();

    // Only use cache for Home Page (isArticle == false) and if not forcing refresh.
    // Articles themselves are always fetched fresh as per user request.
    if (!forceRefresh && !isArticle) {
      final cachedTimestampStr = prefs.getString(cacheTimestampKey);
      if (cachedTimestampStr != null) {
        final cachedTimestamp = DateTime.parse(cachedTimestampStr);
        final difference = DateTime.now().difference(cachedTimestamp);
        // Cache valid for 24 hours
        if (difference.inHours < 24) {
          final cachedData = prefs.getString(cacheKey);
          if (cachedData != null && cachedData.isNotEmpty) {
            try {
              final List<dynamic> jsonList = jsonDecode(cachedData);
              return jsonList.map((e) => HomePageSection.fromJson(e)).toList();
            } catch (e) {
              await prefs.remove(cacheKey);
              await prefs.remove(cacheTimestampKey);
            }
          }
        }
      }
    }

    String url;
    if (isArticle) {
      url = 'https://$languageCode.$projectStr.org/w/api.php?action=parse&page=${Uri.encodeComponent(pageTitle)}&format=json&prop=text|images&mobileformat=1&redirects=1';
    } else {
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
          
          final processedResult = await HtmlProcessor.processArticleHtml(
            htmlContent,
            languageCode,
            project,
          );

          // Still save to cache for potential future use (e.g. offline mode), but we don't read it above
          await prefs.setString(cacheKey, jsonEncode(processedResult));
          await prefs.setString(cacheTimestampKey, DateTime.now().toIso8601String());
          return processedResult;
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
    if (response.statusCode != 200) throw Exception('Failed to search Wikipedia');
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
