import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'dart:convert';
import '../../domain/entities/article.dart';
import '../../domain/entities/wiki_project.dart';
import '../../domain/entities/wiki_language.dart';

class RemoteArticleDataSource {
  String _getBaseUrl(String langCode, WikiProject project) {
    final language = WikiLanguage.fromCode(langCode);
    return 'https://${language.getFullDomain(project)}';
  }

  String _getPageTitle(String title, String langCode, WikiProject project) {
    final language = WikiLanguage.fromCode(langCode);
    final prefix = language.getPagePrefix(project);
    if (prefix.isNotEmpty && !title.startsWith(prefix)) {
      return '$prefix$title';
    }
    return title;
  }

  Future<String> getHomePage(String langCode, String title, WikiProject project) async {
    final baseUrl = _getBaseUrl(langCode, project);
    final fullTitle = _getPageTitle(title, langCode, project);
    
    try {
      final url = Uri.parse(
        '$baseUrl/api/rest_v1/page/html/${Uri.encodeComponent(fullTitle)}',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'WikinusaApp/1.0 (slaia@yahoo.com) FlutterApp',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return response.body;
      }
    } catch (e) {
      debugPrint('REST API failed for home page: $e. Trying Action API...');
    }

    return await _fetchFromActionApi(langCode, fullTitle, project);
  }

  Future<Article> getArticle(String pageTitle, String langCode, WikiProject project) async {
    String htmlContent;
    final baseUrl = _getBaseUrl(langCode, project);
    final fullTitle = _getPageTitle(pageTitle, langCode, project);

    try {
      final url = Uri.parse(
        '$baseUrl/api/rest_v1/page/html/${Uri.encodeComponent(fullTitle)}',
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'WikinusaApp/1.0 (slaia@yahoo.com) FlutterApp',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        htmlContent = response.body;
      } else {
        htmlContent = await _fetchFromActionApi(langCode, fullTitle, project);
      }
    } catch (e) {
      htmlContent = await _fetchFromActionApi(langCode, fullTitle, project);
    }

    final document = html_parser.parse(htmlContent);
    _processHtml(document.body!, langCode, project, false);

    return Article(
      pageid: 0,
      title: pageTitle,
      text: document.body!.innerHtml,
    );
  }

  Future<String> _fetchFromActionApi(String langCode, String title, WikiProject project) async {
    final baseUrl = _getBaseUrl(langCode, project);
    final url = Uri.parse(
      '$baseUrl/w/api.php?action=parse&page=${Uri.encodeComponent(title)}&format=json&prop=text|images&mobileformat=1&redirects=1',
    );

    final response = await http.get(
      url,
      headers: {
        'User-Agent': 'WikinusaApp/1.0 (slaia@yahoo.com) FlutterApp',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load ${project.displayName} content via Action API');
    }

    final data = json.decode(response.body);
    if (data['error'] != null) {
      throw Exception('${project.displayName} API Error: ${data['error']['info']}');
    }

    return data['parse']['text']['*'] ?? '';
  }

  Future<String> getRandomTitle(String langCode, WikiProject project) async {
    final baseUrl = _getBaseUrl(langCode, project);
    final language = WikiLanguage.fromCode(langCode);
    final prefix = language.getPagePrefix(project);
    
    final url = Uri.parse(
      '$baseUrl/w/api.php?action=query&list=random&rnnamespace=0&rnlimit=1&format=json',
    );
    final response = await http.get(
      url,
      headers: {
        'User-Agent': 'WikinusaApp/1.0 (slaia@yahoo.com) FlutterApp',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch random title');
    }

    final data = json.decode(response.body);
    final randomList = data['query']['random'] as List;
    if (randomList.isEmpty) {
      throw Exception('No random title found');
    }

    String title = randomList[0]['title'] as String;
    // Strip prefix if it exists to keep UI clean
    if (prefix.isNotEmpty && title.startsWith(prefix)) {
      title = title.replaceFirst(prefix, '');
    }
    
    return title;
  }

  Future<List<Map<String, dynamic>>> searchArticles(
    String query,
    String langCode,
    WikiProject project,
  ) async {
    final baseUrl = _getBaseUrl(langCode, project);
    final language = WikiLanguage.fromCode(langCode);
    final prefix = language.getPagePrefix(project);
    
    // If there's a prefix (like Incubator), we should include it in the search or handle it via namespace
    final fullQuery = prefix.isNotEmpty ? '$prefix$query' : query;

    final url = Uri.parse(
      '$baseUrl/w/api.php?action=query&list=search&srsearch=${Uri.encodeComponent(fullQuery)}&format=json&utf8=1',
    );

    final response = await http.get(
      url,
      headers: {
        'User-Agent': 'WikinusaApp/1.0 (slaia@yahoo.com) FlutterApp',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to search ${project.displayName}');
    }

    final data = json.decode(response.body);
    final List<Map<String, dynamic>> results = List<Map<String, dynamic>>.from(data['query']['search']);
    
    // Clean up results for Incubator
    if (prefix.isNotEmpty) {
      for (var result in results) {
        if (result['title'].toString().startsWith(prefix)) {
          result['title'] = result['title'].toString().replaceFirst(prefix, '');
        }
      }
    }
    
    return results;
  }

  void _processHtml(dom.Element element, String langCode, WikiProject project, bool isFeaturedArticle) {
    final baseUrl = _getBaseUrl(langCode, project);

    // Fix Image URLs
    element.querySelectorAll('img').forEach((img) {
      String? src = img.attributes['src'];
      if (src != null) {
        if (src.startsWith('//')) {
          src = 'https:$src';
        } else if (src.startsWith('/')) {
          src = '$baseUrl$src';
        }
        img.attributes['src'] = src;

        if (isFeaturedArticle) {
          img.attributes['align'] = 'left';
          img.attributes['style'] =
              'margin-right: 12px; margin-bottom: 8px; max-width: 150px;';
        }
      }
      img.attributes.remove('srcset');
    });

    // Fix Links
    element.querySelectorAll('a').forEach((a) {
      final href = a.attributes['href'];
      if (href != null && href.startsWith('/')) {
        a.attributes['href'] = '$baseUrl$href';
      }
    });

    // Project-specific cleaning
    switch (project) {
      case WikiProject.wiktionary:
        _cleanWiktionaryHtml(element);
        break;
      case WikiProject.wikibooks:
        _cleanWikibooksHtml(element);
        break;
      case WikiProject.wikipedia:
      default:
        // Already handled general fixes
        break;
    }
  }

  void _cleanWiktionaryHtml(dom.Element element) {
    element.querySelectorAll('.mw-editsection').forEach((e) => e.remove());
    element.querySelectorAll('.navbox').forEach((e) => e.remove());
  }

  void _cleanWikibooksHtml(dom.Element element) {
    element.querySelectorAll('.sisterproject').forEach((e) => e.remove());
  }

  void debugPrint(String message) {
    print('RemoteArticleDataSource: $message');
  }
}
