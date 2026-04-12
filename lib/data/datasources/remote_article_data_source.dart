import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'dart:convert';
import '../../domain/entities/article.dart';

class RemoteArticleDataSource {
  Future<String> getHomePage(String langCode, String title) async {
    try {
      final url = Uri.parse(
        'https://$langCode.wikipedia.org/api/rest_v1/page/html/${Uri.encodeComponent(title)}',
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

    // Fallback to Action API
    return await _fetchFromActionApi(langCode, title);
  }

  Future<Article> getArticle(String pageTitle, String langCode) async {
    String htmlContent;
    int pageId = 0;

    try {
      final url = Uri.parse(
        'https://$langCode.wikipedia.org/api/rest_v1/page/html/${Uri.encodeComponent(pageTitle)}',
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
        htmlContent = await _fetchFromActionApi(langCode, pageTitle);
      }
    } catch (e) {
      htmlContent = await _fetchFromActionApi(langCode, pageTitle);
    }

    final document = html_parser.parse(htmlContent);
    _fixUrls(document.body!, langCode, false);

    return Article(
      pageid: pageId,
      title: pageTitle,
      text: document.body!.innerHtml,
    );
  }

  Future<String> _fetchFromActionApi(String langCode, String title) async {
    final url = Uri.parse(
      'https://$langCode.wikipedia.org/w/api.php?action=parse&page=${Uri.encodeComponent(title)}&format=json&prop=text|images&mobileformat=1&redirects=1',
    );

    final response = await http.get(
      url,
      headers: {
        'User-Agent': 'WikinusaApp/1.0 (slaia@yahoo.com) FlutterApp',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load Wikipedia content via Action API');
    }

    final data = json.decode(response.body);
    if (data['error'] != null) {
      throw Exception('Wikipedia API Error: ${data['error']['info']}');
    }

    return data['parse']['text']['*'] ?? '';
  }

  Future<String> getRandomTitle(String langCode) async {
    final url = Uri.parse(
      'https://$langCode.wikipedia.org/w/api.php?action=query&list=random&rnnamespace=0&rnlimit=1&format=json',
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

    return randomList[0]['title'] as String;
  }

  Future<List<Map<String, dynamic>>> searchArticles(
    String query,
    String langCode,
  ) async {
    final url = Uri.parse(
      'https://$langCode.wikipedia.org/w/api.php?action=query&list=search&srsearch=${Uri.encodeComponent(query)}&format=json&utf8=1',
    );

    final response = await http.get(
      url,
      headers: {
        'User-Agent': 'WikinusaApp/1.0 (slaia@yahoo.com) FlutterApp',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to search Wikipedia');
    }

    final data = json.decode(response.body);
    return List<Map<String, dynamic>>.from(data['query']['search']);
  }

  void _fixUrls(dom.Element element, String langCode, bool isFeaturedArticle) {
    element.querySelectorAll('img').forEach((img) {
      String? src = img.attributes['src'];
      if (src != null) {
        if (src.startsWith('//')) {
          src = 'https:$src';
        } else if (src.startsWith('/')) {
          src = 'https://$langCode.wikipedia.org$src';
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
    element.querySelectorAll('a').forEach((a) {
      final href = a.attributes['href'];
      if (href != null && href.startsWith('/')) {
        a.attributes['href'] = 'https://$langCode.wikipedia.org$href';
      }
    });
  }

  // Helper for debug logging
  void debugPrint(String message) {
    debugPrint('RemoteArticleDataSource: $message');
  }
}
