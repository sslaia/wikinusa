import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'dart:convert';
import '../../domain/entities/article.dart';

class RemoteArticleDataSource {
  Future<String> getHomePage(String langCode, String title) async {
    final url = Uri.parse(
      'https://$langCode.wikipedia.org/api/rest_v1/page/html/${Uri.encodeComponent(title)}',
    );
    
    final response = await http.get(
      url,
      headers: {
        'User-Agent': 'WikinusaApp/1.0 (slaia@yahoo.com) FlutterApp',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load Wikipedia Main Page via REST API');
    }

    return response.body;
  }

  Future<Article> getArticle(String pageTitle, String langCode) async {
    final url = Uri.parse(
      'https://$langCode.wikipedia.org/api/rest_v1/page/html/${Uri.encodeComponent(pageTitle)}',
    );
    
    final response = await http.get(
      url,
      headers: {
        'User-Agent': 'WikinusaApp/1.0 (slaia@yahoo.com) FlutterApp',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load article via REST API');
    }

    // Note: html REST API doesn't return pageid in the body.
    final document = html_parser.parse(response.body);
    _fixUrls(document.body!, langCode, false);

    return Article(
      pageid: 0, // REST API doesn't provide this directly in the HTML response
      title: pageTitle,
      text: document.body!.innerHtml,
    );
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

  Future<List<Map<String, dynamic>>> searchArticles(String query, String langCode) async {
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
          img.attributes['style'] = 'margin-right: 12px; margin-bottom: 8px; max-width: 150px;';
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
}
