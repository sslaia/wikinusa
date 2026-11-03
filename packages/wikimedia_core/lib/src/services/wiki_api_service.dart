import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/home_page_section.dart';
import '../models/project_type.dart';
import 'home_page_builder.dart';
import '../core/wiki_config.dart';
import '../core/community_registry.dart';

class WikiApiService {
  static final Set<String> _forceRefreshKeys = {};
  static final Map<String, int> _editedRevisions = {};

  static String _getCacheKey(
    ProjectType project,
    String languageCode,
    String pageTitle,
    bool isArticle,
  ) {
    final projectStr = project.name.toLowerCase();
    return isArticle
        ? 'article_${projectStr}_${languageCode}_$pageTitle'
        : 'home_page_${projectStr}_$languageCode';
  }

  static void recordEditedRevision(
    ProjectType project,
    String languageCode,
    String pageTitle,
    int revisionId,
  ) {
    final cacheKey = _getCacheKey(project, languageCode, pageTitle, true);
    _editedRevisions[cacheKey] = revisionId;
    _forceRefreshKeys.add(cacheKey);
  }

  static Future<void> clearCache(
    ProjectType project,
    String languageCode,
    String? pageTitle,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final isArticle = pageTitle != null && pageTitle.isNotEmpty;
    final cacheKey = _getCacheKey(
      project,
      languageCode,
      pageTitle ?? 'Main Page',
      isArticle,
    );
    _forceRefreshKeys.add(cacheKey);
    await prefs.remove(cacheKey);
    await prefs.remove('${cacheKey}_timestamp');
  }

  static Future<dynamic> fetchPageHtml(
    ProjectType project,
    String languageCode,
    String pageTitle,
    bool isArticle, {
    bool forceRefresh = false,
    Future<dynamic> Function(
      String project,
      String languageCode,
      String pageTitle,
      bool isArticle,
    )? getCachedPage,
    Future<void> Function(
      String project,
      String languageCode,
      String pageTitle,
      String content,
      String? heroImageUrl,
      bool isArticle,
    )? saveCachedPage,
  }) async {
    final cacheKey = _getCacheKey(project, languageCode, pageTitle, isArticle);
    final cacheTimestampKey = '${cacheKey}_timestamp';
    if (_forceRefreshKeys.remove(cacheKey)) {
      forceRefresh = true;
    }

    final prefs = await SharedPreferences.getInstance();

    if (!forceRefresh && !isArticle) {
      final cachedTimestampStr = prefs.getString(cacheTimestampKey);
      if (cachedTimestampStr != null) {
        final cachedTimestamp = DateTime.parse(cachedTimestampStr);
        final difference = DateTime.now().difference(cachedTimestamp);
        if (difference.inHours < 24) {
          final cachedData = prefs.getString(cacheKey);
          if (cachedData != null && cachedData.isNotEmpty) {
            try {
              final List<dynamic> jsonList = jsonDecode(cachedData);
              final sections =
                  jsonList.map((e) => HomePageSection.fromJson(e)).toList();
              final isFallback =
                  sections.length == 1 &&
                  (sections.first.titleKey == 'mainContent' ||
                      sections.first.titleKey == 'main_content' ||
                      sections.first.titleKey == 'no_content');
              final hasNoImages = sections.length > 1 &&
                  sections.every((s) => s.imageUrl == null || s.imageUrl!.isEmpty);
              if (!isFallback && !hasNoImages) {
                return sections;
              }
            } catch (e) {
              await prefs.remove(cacheKey);
              await prefs.remove(cacheTimestampKey);
            }
          }
        }
      }
    }

    String domain = WikiConfig.getDomain(languageCode, project.name.toLowerCase());
    String finalTitle = pageTitle;
    
    final rules = WikiConfig.getRules(languageCode, project.name.toLowerCase());
    final mainPageTitle = rules?['mainPageTitle'] as String? ??
        _getDefaultMainPageTitle(languageCode, project);
    if (pageTitle == 'Main Page') {
      finalTitle = mainPageTitle;
    }

    bool useActionApiForHome = false;
    String apiPrefix = WikiConfig.getApiPrefix(languageCode, project.name.toLowerCase());

    if (apiPrefix.isNotEmpty) {
      if (!isArticle) {
        useActionApiForHome = true;
        finalTitle = '$apiPrefix$finalTitle';
      }
    }

    if (apiPrefix.isNotEmpty && isArticle) {
        if (pageTitle == 'Main Page') {
          finalTitle = '$apiPrefix$mainPageTitle';
        } else if (!pageTitle.contains(apiPrefix)) {
          final lowerTitle = pageTitle.toLowerCase();
          if (lowerTitle.startsWith('special:') ||
              lowerTitle.startsWith('spesial:') ||
              lowerTitle.startsWith('mirunggan:') ||
              lowerTitle.startsWith('istimewa:') ||
              lowerTitle.startsWith('istimiwa:') ||
              lowerTitle.startsWith('istimèwa:') ||
              lowerTitle.startsWith('khas:') ||
              lowerTitle.startsWith('husus:')) {
            finalTitle = pageTitle;
          } else if (lowerTitle.startsWith('category:') ||
                     lowerTitle.startsWith('kategori:') ||
                     lowerTitle.startsWith('template:') ||
                     lowerTitle.startsWith('templat:')) {
            final parts = pageTitle.split(':');
            final namespace = parts[0];
            final rest = parts.sublist(1).join(':');
            finalTitle = '$namespace:$apiPrefix$rest';
          } else {
            finalTitle = '$apiPrefix$pageTitle';
          }
        }
    }

    final requestHeaders = {
      ...WikiConfig.uaHeaders,
      if (forceRefresh || isArticle) ...{
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
      },
    };

    String url;
    final formattedTitle = finalTitle.replaceAll(' ', '_');
    int? targetRevId = forceRefresh ? _editedRevisions[cacheKey] : null;

    if (isArticle && forceRefresh && targetRevId == null) {
      try {
        final revQueryUrl =
            'https://$domain/w/api.php?action=query&prop=revisions&titles=${Uri.encodeComponent(finalTitle)}&rvprop=ids&format=json&redirects=1&smaxage=0&maxage=0&requestid=${DateTime.now().millisecondsSinceEpoch}';
        final revResp = await http
            .get(Uri.parse(revQueryUrl), headers: requestHeaders)
            .timeout(const Duration(seconds: 6));
        if (revResp.statusCode == 200) {
          final revData = jsonDecode(utf8.decode(revResp.bodyBytes));
          final pages = revData['query']?['pages'] as Map<String, dynamic>?;
          if (pages != null && pages.isNotEmpty) {
            final pageObj = pages.values.first;
            final revisions = pageObj['revisions'] as List?;
            if (revisions != null && revisions.isNotEmpty) {
              final revId = revisions.first['revid'];
              if (revId is int) {
                targetRevId = revId;
              }
            }
          }
        }
      } catch (_) {}
    }

    if (isArticle) {
      if (targetRevId != null) {
        url =
            'https://$domain/w/rest.php/v1/revision/$targetRevId/html?_t=${DateTime.now().millisecondsSinceEpoch}';
      } else {
        url =
            'https://$domain/w/rest.php/v1/page/${Uri.encodeComponent(formattedTitle)}/html?_t=${DateTime.now().millisecondsSinceEpoch}';
      }
    } else if (useActionApiForHome) {
      url =
          'https://$domain/w/api.php?action=parse&page=${Uri.encodeComponent(finalTitle)}&format=json&prop=text|images&mobileformat=1&redirects=1';
      if (forceRefresh) {
        url += '&smaxage=0&maxage=0&nocache=1&_t=${DateTime.now().millisecondsSinceEpoch}';
      }
    } else {
      url =
          'https://$domain/w/rest.php/v1/page/${Uri.encodeComponent(formattedTitle)}/html';
      if (forceRefresh) {
        url += '?_t=${DateTime.now().millisecondsSinceEpoch}';
      }
    }

    try {
      var response = await http
          .get(Uri.parse(url), headers: requestHeaders)
          .timeout(const Duration(seconds: 15));

      if (isArticle && response.statusCode != 200 && targetRevId != null) {
        final fallbackUrl =
            'https://$domain/w/rest.php/v1/page/${Uri.encodeComponent(formattedTitle)}/html?_t=${DateTime.now().millisecondsSinceEpoch}';
        response = await http
            .get(Uri.parse(fallbackUrl), headers: requestHeaders)
            .timeout(const Duration(seconds: 15));
      } else if (isArticle &&
          response.statusCode == 200 &&
          targetRevId == null &&
          _editedRevisions.containsKey(cacheKey)) {
        final minRevId = _editedRevisions[cacheKey]!;
        final returnedRevId =
            int.tryParse(response.headers['content-revision-id'] ?? '');
        if (returnedRevId != null && returnedRevId < minRevId) {
          final revUrl =
              'https://$domain/w/rest.php/v1/revision/$minRevId/html?_t=${DateTime.now().millisecondsSinceEpoch}';
          final revResponse = await http
              .get(Uri.parse(revUrl), headers: requestHeaders)
              .timeout(const Duration(seconds: 15));
          if (revResponse.statusCode == 200) {
            response = revResponse;
          }
        } else if (returnedRevId != null && returnedRevId >= minRevId) {
          _editedRevisions.remove(cacheKey);
        }
      }

      if (response.statusCode == 200) {
        if (isArticle) {
          final parsoidHtml = utf8.decode(response.bodyBytes);

          // Extract candidate hero image from Wikimedia summary API or Parsoid HTML
          String? heroImageUrl;
          try {
            final summaryUrl =
                'https://$domain/api/rest_v1/page/summary/${Uri.encodeComponent(formattedTitle)}';
            final summaryResp = await http
                .get(Uri.parse(summaryUrl), headers: WikiConfig.uaHeaders)
                .timeout(const Duration(seconds: 4));
            if (summaryResp.statusCode == 200) {
              final summaryData =
                  jsonDecode(utf8.decode(summaryResp.bodyBytes));
              heroImageUrl = summaryData['thumbnail']?['source'] ??
                  summaryData['originalimage']?['source'];
            }
          } catch (_) {}

          if (heroImageUrl == null || heroImageUrl.isEmpty) {
            final imgMatch = RegExp(r'<img[^>]+src="([^">]+)"', caseSensitive: false)
                .firstMatch(parsoidHtml);
            if (imgMatch != null) {
              final rawSrc = imgMatch.group(1) ?? '';
              if (!rawSrc.contains('icon') &&
                  !rawSrc.contains('.svg') &&
                  !rawSrc.contains('Red_Pencil') &&
                  !rawSrc.contains('Disambig')) {
                heroImageUrl = rawSrc.startsWith('//') ? 'https:$rawSrc' : rawSrc;
              }
            }
          }

          String processedHtml = parsoidHtml;

          /// Fetch and append category members if it's a category page
          final bool isCategory =
              finalTitle.contains('Category:') ||
              finalTitle.contains('Kategori:');
          if (isCategory) {
            final categoryHtml = await _fetchCategoryContent(
              domain,
              finalTitle,
              languageCode,
            );
            processedHtml += categoryHtml;
          }

          final processedResult = {
            'html': processedHtml,
            'imageUrl': heroImageUrl,
            'title': finalTitle,
            'domain': domain,
          };

          await prefs.setString(cacheKey, jsonEncode(processedResult));
          await prefs.setString(
            cacheTimestampKey,
            DateTime.now().toIso8601String(),
          );

          if (saveCachedPage != null) {
            await saveCachedPage(
              project.name.toLowerCase(),
              languageCode,
              pageTitle,
              jsonEncode(processedResult),
              heroImageUrl,
              isArticle,
            );
          }

          return processedResult;
        } else {
          List<int> htmlBytes;
          if (useActionApiForHome) {
            final bodyStr = utf8.decode(response.bodyBytes);
            final decoded = jsonDecode(bodyStr);
            final htmlContent = decoded['parse']?['text']?['*'] ?? '';
            /// Convert the extracted HTML string back to bytes for HomePageBuilder
            htmlBytes = utf8.encode(htmlContent);
          } else {
            htmlBytes = response.bodyBytes;
          }

          final List<HomePageSection> sections = await HomePageBuilder.build(
            htmlBytes,
            languageCode,
            project,
          );

          await prefs.setString(
            cacheKey,
            jsonEncode(sections.map((e) => e.toJson()).toList()),
          );
          await prefs.setString(
            cacheTimestampKey,
            DateTime.now().toIso8601String(),
          );

          if (saveCachedPage != null) {
            await saveCachedPage(
              project.name.toLowerCase(),
              languageCode,
              pageTitle,
              jsonEncode(sections.map((e) => e.toJson()).toList()),
              null,
              isArticle,
            );
          }

          return sections;
        }
      } else {
        throw Exception('Failed to load page: ${response.statusCode}');
      }
    } catch (e) {
      if (getCachedPage != null) {
        final cachedData = await getCachedPage(
          project.name.toLowerCase(),
          languageCode,
          pageTitle,
          isArticle,
        );
        if (cachedData != null) {
          return cachedData;
        }
      }
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> searchArticles(
    String query,
    String langCode,
    String projectStr, {
    int offset = 0,
    int limit = 20,
  }) async {
    String domain = WikiConfig.getDomain(langCode, projectStr);
    String searchQuery = query;
    String apiPrefix = WikiConfig.getApiPrefix(langCode, projectStr);

    if (apiPrefix.isNotEmpty) {
      searchQuery = '$apiPrefix$query';
    }

    final url = Uri.parse(
      'https://$domain/w/api.php?action=query&list=search&srsearch=${Uri.encodeComponent(searchQuery)}&srlimit=$limit&sroffset=$offset&format=json&utf8=1',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) throw Exception('Failed to search Wiki');

      /// Fixed: Use utf8.decode for correct character encoding
      final data = json.decode(utf8.decode(response.bodyBytes));

      final List<Map<String, dynamic>> results =
          List<Map<String, dynamic>>.from(data['query']?['search'] ?? []);
          
      final int? nextOffset = data['continue']?['sroffset'];

      if (apiPrefix.isNotEmpty) {
        for (var result in results) {
          String title = result['title'] as String;
          if (title.startsWith(apiPrefix)) {
            result['title'] = title.replaceFirst(apiPrefix, '');
          }
        }
      }

      return {
        'results': results,
        'nextOffset': nextOffset,
      };
    } catch (e) {
      throw Exception('Search error: $e');
    }
  }

  static Future<String> _fetchCategoryContent(
    String domain,
    String categoryTitle,
    String languageCode,
  ) async {
    final url =
        'https://$domain/w/api.php?action=query&list=categorymembers&cmtitle=${Uri.encodeComponent(categoryTitle)}&cmlimit=500&cmprop=title|type|ns&format=json';
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final members = data['query']?['categorymembers'] as List?;
        if (members == null || members.isEmpty) {
          return '<p><i>This category currently contains no pages or media.</i></p>';
        }

        final subcats = members.where((m) => m['ns'] == 14).toList();
        final pages = members.where((m) => m['ns'] != 14).toList();

        StringBuffer html = StringBuffer(
          '<div class="category-container" style="margin-top: 24px; border-top: 1px solid #eee; padding-top: 16px;">',
        );

        if (subcats.isNotEmpty) {
          String subTitle = 'Subcategories';
          if (languageCode == 'id') subTitle = 'Subkategori';
          if (languageCode == 'nia') subTitle = 'Subkategori';

          html.write(
            '<h3 style="color: #666; font-size: 1.1em;">$subTitle</h3><ul style="list-style-type: none; padding-left: 0;">',
          );
          for (var sub in subcats) {
            final title = sub['title'] as String;
            html.write(
              '<li style="margin-bottom: 8px; font-weight: 500;">📂 <a href="./$title">$title</a></li>',
            );
          }
          html.write('</ul>');
        }

        if (pages.isNotEmpty) {
          String pagesTitle = 'Pages';
          if (languageCode == 'id') pagesTitle = 'Halaman';
          if (languageCode == 'nia') pagesTitle = 'Nga\'örö';

          html.write(
            '<h3 style="color: #666; font-size: 1.1em; margin-top: 24px;">$pagesTitle</h3><ul style="list-style-type: none; padding-left: 0;">',
          );
          for (var page in pages) {
            final title = page['title'] as String;
            html.write(
              '<li style="margin-bottom: 8px;">📄 <a href="./$title">$title</a></li>',
            );
          }
          html.write('</ul>');
        }

        html.write('</div>');
        return html.toString();
      }
    } catch (_) {}
    return '';
  }

  static Future<String?> fetchRandomArticleTitle(
    String langCode,
    String projectStr,
  ) async {
    String domain = WikiConfig.getDomain(langCode, projectStr);
    String apiPrefix = WikiConfig.getApiPrefix(langCode, projectStr);

    if (apiPrefix.isNotEmpty) {
      try {
        const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
        final randomLetter = letters[DateTime.now().millisecondsSinceEpoch % letters.length];
        final url = Uri.parse(
          'https://$domain/w/api.php?action=query&list=allpages&apprefix=$apiPrefix&apfrom=$apiPrefix$randomLetter&aplimit=30&format=json',
        );
        final response = await http
            .get(url, headers: {'User-Agent': 'WikiNusa/1.5.8 (info@wikinusa.org)'})
            .timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final data = json.decode(utf8.decode(response.bodyBytes));
          final pages = data['query']?['allpages'] as List?;
          if (pages != null && pages.isNotEmpty) {
            final validTitles = pages
                .map((p) => p['title'] as String)
                .where((t) {
                  final clean = t.startsWith(apiPrefix) ? t.substring(apiPrefix.length) : t;
                  return !clean.startsWith('Wikibooks:') &&
                      !clean.startsWith('Help:') &&
                      !clean.startsWith('Fanolo:') &&
                      !clean.startsWith('Category:') &&
                      !clean.startsWith('Kategori:') &&
                      clean != 'Olayama';
                })
                .toList();
            if (validTitles.isNotEmpty) {
              final randomIndex = DateTime.now().millisecondsSinceEpoch % validTitles.length;
              var title = validTitles[randomIndex];
              if (title.startsWith(apiPrefix)) {
                title = title.substring(apiPrefix.length);
              }
              return title;
            }
          }
        }
      } catch (_) {}

      try {
        final url = Uri.parse(
          'https://$domain/w/api.php?action=query&list=allpages&apprefix=$apiPrefix&aplimit=50&format=json',
        );
        final response = await http
            .get(url, headers: {'User-Agent': 'WikiNusa/1.5.8 (info@wikinusa.org)'})
            .timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final data = json.decode(utf8.decode(response.bodyBytes));
          final pages = data['query']?['allpages'] as List?;
          if (pages != null && pages.isNotEmpty) {
            final validTitles = pages
                .map((p) => p['title'] as String)
                .where((t) {
                  final clean = t.startsWith(apiPrefix) ? t.substring(apiPrefix.length) : t;
                  return !clean.startsWith('Wikibooks:') &&
                      !clean.startsWith('Help:') &&
                      !clean.startsWith('Fanolo:') &&
                      !clean.startsWith('Category:') &&
                      clean != 'Olayama';
                })
                .toList();
            if (validTitles.isNotEmpty) {
              final randomIndex = DateTime.now().millisecondsSinceEpoch % validTitles.length;
              var title = validTitles[randomIndex];
              if (title.startsWith(apiPrefix)) {
                title = title.substring(apiPrefix.length);
              }
              return title;
            }
          }
        }
      } catch (_) {}
      return null;
    }

    final url = Uri.parse(
      'https://$domain/w/api.php?action=query&list=random&rnnamespace=0&rnlimit=1&format=json',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final randomList = data['query']?['random'] as List?;
        if (randomList != null && randomList.isNotEmpty) {
          return randomList[0]['title'] as String;
        }
      }
    } catch (_) {}
    return null;
  }

  static String _getDefaultMainPageTitle(
    String languageCode,
    ProjectType project,
  ) {
    if (CommunityRegistry.isInitialized) {
      return CommunityRegistry.getMainPageTitle(languageCode, project);
    }
    switch (languageCode) {
      case 'id':
        if (project == ProjectType.wiktionary) return 'Wikikamus:Halaman_Utama';
        return 'Halaman_Utama';
      case 'nia':
        if (project == ProjectType.wikipedia) return 'Wikipedia:Olayama';
        if (project == ProjectType.wiktionary) return 'Wikikamus:Olayama';
        return 'Olayama';
      case 'jv':
        if (project == ProjectType.wiktionary) return 'Wikisastra:Pendhapa';
        return 'Wikipédia:Pendhapa';
      case 'en':
        if (project == ProjectType.wiktionary) return 'Wiktionary:Main_Page';
        return 'Main_Page';
      default:
        return 'Main_Page';
    }
  }
}
