import 'dart:convert';
import 'package:html/dom.dart' as dom;
import 'package:http/http.dart' as http;
import '../core/wiki_config.dart';
import '../models/project_type.dart';
import 'wiki_link_intent.dart';

class CoreWikiUtils {
  /// Simple in-memory cache for optimized image URLs
  static final Map<String, String> _imageOptimizerCache = {};

  static bool isIcon(String src, [dom.Element? element]) {
    final lowerSrc = src.toLowerCase();

    // 1. Static or internal Wikimedia UI asset paths
    if (lowerSrc.contains('/static/images/') ||
        lowerSrc.contains('/static/resources/') ||
        lowerSrc.contains('/w/resources/') ||
        lowerSrc.contains('/resources/assets/')) {
      return true;
    }

    // 2. Vector SVGs (almost always logos, icons, diagrams, or UI symbols)
    if (lowerSrc.contains('.svg')) {
      return true;
    }

    // 3. Known UI icon / symbol / utility keywords in filename or path
    if (lowerSrc.contains('px-gnome-') ||
        lowerSrc.contains('px-icon-') ||
        lowerSrc.contains('icon-') ||
        lowerSrc.contains('-icon') ||
        lowerSrc.contains('/icon/') ||
        lowerSrc.contains('_icon') ||
        lowerSrc.contains('icon.') ||
        lowerSrc.contains('px-symbol_') ||
        lowerSrc.contains('symbol-') ||
        lowerSrc.contains('symbol_') ||
        lowerSrc.contains('/symbol/') ||
        lowerSrc.contains('symbol.') ||
        lowerSrc.contains('px-help-') ||
        lowerSrc.contains('px-information_') ||
        lowerSrc.contains('px-ambox_') ||
        lowerSrc.contains('px-question_mark') ||
        lowerSrc.contains('px-edit-clear') ||
        lowerSrc.contains('px-magnifying_glass') ||
        lowerSrc.contains('px-search_icon') ||
        lowerSrc.contains('px-crystal_clear') ||
        lowerSrc.contains('crystal_clear') ||
        lowerSrc.contains('crystal-clear') ||
        lowerSrc.contains('px-c_icon') ||
        lowerSrc.contains('px-system-') ||
        lowerSrc.contains('px-padlock-') ||
        lowerSrc.contains('badge') ||
        lowerSrc.contains('bullet') ||
        lowerSrc.contains('button') ||
        lowerSrc.contains('favicon') ||
        lowerSrc.contains('disambig') ||
        lowerSrc.contains('centralautologin')) {
      return true;
    }

    // 4. Project and Foundation Logos (e.g. Wikimedia, Wikipedia, Wiktionary, etc.)
    final uri = Uri.tryParse(src);
    final path = (uri != null && uri.hasAuthority ? uri.path : src).toLowerCase();

    if (path.contains('wikimedia-logo') ||
        path.contains('wikimedia_logo') ||
        path.contains('wikimedia_community_logo') ||
        path.contains('wikimedia-button') ||
        path.contains('wikipedia-logo') ||
        path.contains('wiktionary-logo') ||
        path.contains('wikibooks-logo') ||
        path.contains('wikisource-logo') ||
        path.contains('wikiquote-logo') ||
        path.contains('wikidata-logo') ||
        path.contains('wikispecies-logo') ||
        path.contains('wikinews-logo') ||
        path.contains('wikiversity-logo') ||
        path.contains('wikivoyage-logo') ||
        path.contains('meta-wiki_logo') ||
        path.contains('commons-logo') ||
        path.contains('mediawiki-') ||
        path.contains('mediawiki_') ||
        path.contains('poweredby_mediawiki') ||
        path.contains('-logo.') ||
        path.contains('_logo.') ||
        path.contains('-logo-') ||
        path.contains('_logo_') ||
        path.contains('/logo.') ||
        path.contains('/logo-') ||
        path.contains('/logo_') ||
        path.contains('px-logo') ||
        path.endsWith('logo.png') ||
        path.endsWith('logo.jpg') ||
        path.endsWith('logo.jpeg')) {
      return true;
    }

    // 5. MediaWiki small thumbnail sizes in URL (e.g. /20px-, /40px-, /50px-)
    final thumbMatch = RegExp(r'/(\d+)px-').firstMatch(lowerSrc);
    if (thumbMatch != null) {
      final width = int.tryParse(thumbMatch.group(1)!);
      if (width != null && width <= 60) {
        return true;
      }
    }

    // 6. Inspect DOM element attributes and context if provided
    if (element != null) {
      final widthAttr = int.tryParse(element.attributes['width'] ?? '');
      final heightAttr = int.tryParse(element.attributes['height'] ?? '');
      if ((widthAttr != null && widthAttr <= 60) &&
          (heightAttr != null && heightAttr <= 60)) {
        return true;
      }

      final alt = (element.attributes['alt'] ?? '').toLowerCase();
      if (alt.contains('logo') ||
          alt.contains('icon') ||
          alt.contains('lambang') ||
          alt.contains('simbol') ||
          alt.contains('tanda')) {
        return true;
      }

      if (element.classes.contains('wiki-inline-icon') ||
          element.classes.contains('noviewer')) {
        return true;
      }

      dom.Element? parent = element.parent;
      int depth = 0;
      while (parent != null && depth < 3) {
        if (parent.classes.contains('noviewer') ||
            parent.classes.contains('metadata') ||
            parent.classes.contains('navbox')) {
          return true;
        }
        parent = parent.parent;
        depth++;
      }
    }

    return false;
  }

  static Future<String> optimizeImageUrl(
    String url, {
    String? htmlString,
    int width = 500,
  }) async {
    String normalized = url;
    if (url.startsWith('//')) {
      normalized = 'https:$url';
    } else if (url.startsWith('/')) {
      normalized = 'https://upload.wikimedia.org$url';
    }

    String? fileName;
    if (htmlString != null && htmlString.contains('resource=')) {
      final resourceMatch = RegExp(r'resource="([^"]+)"').firstMatch(htmlString);
      if (resourceMatch != null) {
        String resource = resourceMatch.group(1)!;
        fileName = resource.replaceFirst('./Berkas:', '').replaceFirst('./File:', '');
        if (!fileName.startsWith('File:')) fileName = "File:$fileName";
      }
    }
    
    if (fileName == null && normalized.contains('/thumb/')) {
      try {
        final uri = Uri.parse(normalized);
        final segments = uri.pathSegments;
        for (var segment in segments) {
          if (segment.contains('.') && !segment.contains('px-')) {
            fileName = "File:$segment";
            break;
          }
        }
      } catch (_) {}
    }

    if (fileName != null) {
      final cacheKey = '${fileName}_$width';
      if (_imageOptimizerCache.containsKey(cacheKey)) return _imageOptimizerCache[cacheKey]!;

      try {
        final apiUrl = 'https://commons.wikimedia.org/w/api.php?action=query&titles=${Uri.encodeComponent(fileName)}&prop=imageinfo&iiprop=url&iiurlwidth=$width&format=json';
        final response = await http.get(Uri.parse(apiUrl), headers: WikiConfig.uaHeaders);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final pages = data['query']?['pages'];
          if (pages != null && pages.isNotEmpty) {
            final page = pages['-1'] ?? pages.values.first;
            final imageInfo = page['imageinfo'];
            if (imageInfo != null && imageInfo is List && imageInfo.isNotEmpty) {
              String? thumbUrl = imageInfo[0]['thumburl'];
              if (thumbUrl != null) {
                final result = thumbUrl.split('?').first;
                _imageOptimizerCache[cacheKey] = result;
                return result;
              }
            }
          }
        }
      } catch (e) {
        // Ignore optimization errors
      }
    }
    return normalized;
  }

  static Future<String> resolveMediaUrl(String url, String languageCode, ProjectType project) async {
    String audioUrl = url;
    if (audioUrl.startsWith('//')) audioUrl = 'https:$audioUrl';

    bool isWikiFilePage = audioUrl.contains('/wiki/File:') || audioUrl.contains('/wiki/Berkas:') || audioUrl.startsWith('/wiki/') || audioUrl.startsWith('./');
    if (isWikiFilePage && !audioUrl.contains('upload.wikimedia.org')) {
      try {
        String fileName = audioUrl.split(':').last.split('?').first.split('#').first;
        if (!fileName.startsWith('File:')) fileName = 'File:$fileName';
        final domain = WikiConfig.getDomain(languageCode, project.name.toLowerCase());
        final apiUrl = 'https://$domain/w/api.php?action=query&titles=${Uri.encodeComponent(fileName)}&prop=imageinfo&iiprop=url&format=json';
        final response = await http.get(Uri.parse(apiUrl), headers: WikiConfig.uaHeaders);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final pages = data['query']?['pages'];
          if (pages != null && pages.isNotEmpty) {
            final page = pages.values.first;
            final imageInfo = page['imageinfo'];
            if (imageInfo != null && imageInfo is List && imageInfo.isNotEmpty) audioUrl = imageInfo[0]['url'] ?? audioUrl;
          }
        }
      } catch (e) {
        // Ignore resolve errors
      }
    }

    if (!audioUrl.startsWith('http')) {
      final domain = WikiConfig.getDomain(languageCode, project.name.toLowerCase());
      audioUrl = audioUrl.startsWith('/') ? 'https://$domain$audioUrl' : 'https://$domain/wiki/$audioUrl';
    }
    if (audioUrl.startsWith('http://')) audioUrl = audioUrl.replaceFirst('http://', 'https://');
    
    return audioUrl;
  }

  static Future<WikiLinkIntent> handleTapUrl(String url, String languageCode, ProjectType currentProject) async {
    if (url.startsWith('#') || url.contains('cite_note')) {
      final refId = url.split('#').last;
      return ShowReferenceIntent(refId);
    }

    final lowerUrl = url.toLowerCase();
    final mediaExtensions = ['.mp3', '.ogg', '.wav', '.m4a', '.mp4', '.webm', '.ogv'];
    bool isMediaLink = mediaExtensions.any((ext) => lowerUrl.endsWith(ext) || lowerUrl.contains('$ext?') || lowerUrl.contains('$ext#')) ||
        (lowerUrl.contains('upload.wikimedia.org') && mediaExtensions.any((ext) => lowerUrl.contains(ext))) ||
        lowerUrl.contains('/wiki/file:') ||
        lowerUrl.contains('/wiki/berkas:');

    if (isMediaLink) {
      if (lowerUrl.endsWith('.mp4') || lowerUrl.endsWith('.webm') || lowerUrl.endsWith('.ogv')) {
        return OpenExternalUrlIntent(url);
      } else {
        final audioUrl = await resolveMediaUrl(url, languageCode, currentProject);
        return PlayAudioIntent(audioUrl);
      }
    }

    String? title;
    bool isRedLink = url.contains('action=edit') || url.contains('redlink=1');

    if (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('//')) {
      return OpenExternalUrlIntent(url);
    }

    if (url.contains('/wiki/')) {
      title = url.split('/wiki/').last.split('?').first.split('#').first;
    } else if (url.startsWith('./')) {
      title = url.substring(2).split('?').first.split('#').first;
    } else if (url.contains('title=') && url.contains('/w/index.php')) {
      try {
        final uri = Uri.parse(url);
        title = uri.queryParameters['title'];
      } catch (_) {
        final match = RegExp(r'title=([^&]+)').firstMatch(url);
        title = match?.group(1);
      }
    } else if (!url.contains(':') && !url.contains('/') && url.isNotEmpty && !url.startsWith('http')) {
      title = url.split('?').first.split('#').first;
    }

    if (title != null) {
      String decodedTitle;
      try {
        decodedTitle = Uri.decodeComponent(title).replaceAll('_', ' ');
      } catch (e) {
        decodedTitle = title.replaceAll('_', ' ');
      }

      final apiPrefix = WikiConfig.getApiPrefix(languageCode, currentProject.name.toLowerCase());
      if (apiPrefix.isNotEmpty && decodedTitle.contains(apiPrefix)) {
          decodedTitle = decodedTitle.replaceFirst(apiPrefix, '');
      }

      if (decodedTitle.isNotEmpty) {
        return NavigateToArticleIntent(decodedTitle, isRedLink: isRedLink);
      }
    }

    return IgnoreLinkIntent();
  }
}
