import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;

import '../models/project_type.dart';
import '../providers/history_provider.dart';
import '../screens/article_screen.dart';
import '../screens/create_page_screen.dart';
import '../screens/create_entry_screen.dart';
import '../screens/create_book_screen.dart';
import '../theme/app_theme.dart';

class WikiUtils {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  
  /// Simple in-memory cache for optimized image URLs
  static final Map<String, String> _imageOptimizerCache = {};

  /// Wikimedia requires a descriptive User-Agent
  static const Map<String, String> uaHeaders = {
    'User-Agent': 'WikiNusa/1.1.0 (https://sslaia.github.io/wikinusa; slaia@yahoo.com) Generic/1.0',
  };

  static bool isIcon(String src) {
    final lowerSrc = src.toLowerCase();
    return lowerSrc.contains('/static/images/mobile/copyright/') ||
        lowerSrc.contains('/static/images/footer/') ||
        lowerSrc.contains('.svg') ||
        lowerSrc.contains('px-gnome-') ||
        lowerSrc.contains('px-icon-') ||
        lowerSrc.contains('px-symbol_') ||
        lowerSrc.contains('px-help-') ||
        lowerSrc.contains('px-information_') ||
        lowerSrc.contains('px-ambox_') ||
        lowerSrc.contains('px-question_mark') ||
        lowerSrc.contains('px-edit-clear') ||
        lowerSrc.contains('px-magnifying_glass') ||
        lowerSrc.contains('px-search_icon') ||
        lowerSrc.contains('px-crystal_clear') ||
        lowerSrc.contains('px-c_icon') ||
        lowerSrc.contains('px-system-') ||
        lowerSrc.contains('px-padlock-');
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
        final apiUrl = 'https://www.mediawiki.org/w/api.php?action=query&titles=${Uri.encodeComponent(fileName)}&prop=imageinfo&iiprop=url&iiurlwidth=$width&format=json';
        final response = await http.get(Uri.parse(apiUrl), headers: uaHeaders);

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
        debugPrint('WikiUtils: Error fetching optimized image: $e');
      }
    }
    return normalized;
  }

  static Future<bool> handleTapUrl(BuildContext context, String url, String? htmlContent, ProjectType currentProject, String languageCode) async {
    if (url.startsWith('#') || url.contains('cite_note')) {
      if (htmlContent != null) {
        final refId = url.split('#').last;
        _showReferencePopup(context, refId, htmlContent);
      }
      return true;
    }

    final lowerUrl = url.toLowerCase();
    final mediaExtensions = ['.mp3', '.ogg', '.wav', '.m4a', '.mp4', '.webm', '.ogv'];
    bool isMediaLink = mediaExtensions.any((ext) => lowerUrl.endsWith(ext) || lowerUrl.contains('$ext?') || lowerUrl.contains('$ext#')) ||
        (lowerUrl.contains('upload.wikimedia.org') && mediaExtensions.any((ext) => lowerUrl.contains(ext))) ||
        lowerUrl.contains('/wiki/file:') ||
        lowerUrl.contains('/wiki/berkas:');

    if (isMediaLink) {
      if (lowerUrl.endsWith('.mp4') || lowerUrl.endsWith('.webm') || lowerUrl.endsWith('.ogv')) {
        _launchExternalUrl(url);
      } else {
        await _playAudio(context, url, languageCode, currentProject);
      }
      return true;
    }

    String? title;
    bool isRedLink = url.contains('action=edit') || url.contains('redlink=1');

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

      if (decodedTitle.contains('Wb/nia/')) decodedTitle = decodedTitle.replaceFirst('Wb/nia/', '');

      if (decodedTitle.isNotEmpty) {
        final container = ProviderScope.containerOf(context);
        container.read(historyProvider.notifier).push(decodedTitle);

        if (isRedLink) {
          Widget screen;
          switch (currentProject) {
            case ProjectType.wiktionary: screen = CreateEntryScreen(title: decodedTitle); break;
            case ProjectType.wikibooks: screen = CreateBookScreen(title: decodedTitle); break;
            case ProjectType.wikipedia: screen = CreatePageScreen(initialTitle: decodedTitle); break;
          }
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ArticleScreen(title: decodedTitle)));
        }
        return true;
      }
    }

    if (url.startsWith('http')) {
      _launchExternalUrl(url);
      return true;
    }
    return false;
  }

  static Future<void> _launchExternalUrl(String urlString) async {
    final url = Uri.parse(urlString.startsWith('//') ? 'https:$urlString' : urlString);
    if (await canLaunchUrl(url)) await launchUrl(url, mode: LaunchMode.inAppBrowserView);
  }

  static Future<void> _playAudio(BuildContext context, String url, String languageCode, ProjectType project) async {
    String audioUrl = url;
    if (audioUrl.startsWith('//')) audioUrl = 'https:$audioUrl';

    bool isWikiFilePage = audioUrl.contains('/wiki/File:') || audioUrl.contains('/wiki/Berkas:') || audioUrl.startsWith('/wiki/') || audioUrl.startsWith('./');
    if (isWikiFilePage && !audioUrl.contains('upload.wikimedia.org')) {
      try {
        String fileName = audioUrl.split(':').last.split('?').first.split('#').first;
        if (!fileName.startsWith('File:')) fileName = 'File:$fileName';
        final domain = '$languageCode.${project.name.toLowerCase()}.org';
        final apiUrl = 'https://$domain/w/api.php?action=query&titles=${Uri.encodeComponent(fileName)}&prop=imageinfo&iiprop=url&format=json';
        final response = await http.get(Uri.parse(apiUrl), headers: uaHeaders);
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
        debugPrint('WikiUtils: Error resolving audio URL: $e');
      }
    }

    if (!audioUrl.startsWith('http')) {
      final domain = '$languageCode.${project.name.toLowerCase()}.org';
      audioUrl = audioUrl.startsWith('/') ? 'https://$domain$audioUrl' : 'https://$domain/wiki/$audioUrl';
    }
    if (audioUrl.startsWith('http://')) audioUrl = audioUrl.replaceFirst('http://', 'https://');

    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)), const SizedBox(width: 12), const Text('Playing audio...')]), duration: const Duration(seconds: 2)));
      }
      await _audioPlayer.stop();
      try {
        await _audioPlayer.setUrl(audioUrl, headers: uaHeaders);
      } catch (e) {
        await _audioPlayer.setUrl(audioUrl);
      }
      await _audioPlayer.play();
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not play audio')));
    }
  }

  static bool _isHidden(dom.Element element) {
    dom.Element? current = element;
    while (current != null) {
      if (current.classes.contains('wikinusa-hidden')) return true;
      current = current.parent;
    }
    return false;
  }

  static Map<String, String>? customStyles(BuildContext context, dom.Element element) {
    if (_isHidden(element)) return {'display': 'none'};
    final styles = <String, String>{};
    if (element.localName == 'sup' || element.classes.contains('reference')) return {'display': 'inline-block', 'padding': '0 2px', 'font-size': '0.75em', 'vertical-align': 'super'};
    if (element.localName == 'a') {
      final href = element.attributes['href'] ?? '';
      final color = AppTheme.getLinkColor(context, isRedLink: href.contains('action=edit') || href.contains('redlink=1'));
      styles['color'] = '#${color.toARGB32().toRadixString(16).substring(2)}';
      styles['text-decoration'] = 'none';
      styles['font-weight'] = '600';
    }
    return styles.isEmpty ? null : styles;
  }

  static Widget? customWidgetBuilder(BuildContext context, dom.Element element) {
    // Check if current element or any parent is marked as hidden
    if (_isHidden(element)) return const SizedBox.shrink();

    if (element.localName == 'h2') {
      final theme = Theme.of(context);
      return Padding(
        padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(element.text, style: GoogleFonts.notoSerif(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
            const SizedBox(height: 4),
            Container(width: 40, height: 3, decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(2))),
          ],
        ),
      );
    }
    return null;
  }

  static void _showReferencePopup(BuildContext context, String referenceId, String htmlContent) {
    final theme = Theme.of(context);
    final document = html_parser.parse(htmlContent);
    final decodedId = Uri.decodeComponent(referenceId);
    
    // Robust search: getElementById or suffix match (for Wikibooks/Incubator IDs)
    dom.Element? refElement = document.getElementById(decodedId) ?? document.getElementById(referenceId);
    
    if (refElement == null) {
      final allWithId = document.querySelectorAll('[id]');
      for (var el in allWithId) {
        final id = el.attributes['id'] ?? '';
        if (id.endsWith(decodedId) || id.endsWith(referenceId)) {
          refElement = el;
          break;
        }
      }
    }

    if (refElement == null) return;
    
    final refClone = refElement.clone(true);
    refClone.querySelectorAll('.mw-cite-backlink').forEach((e) => e.remove());

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.info_outline, size: 18, color: theme.colorScheme.secondary),
              const SizedBox(width: 8),
              Text('reference'.tr(), style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
            ]),
            const Divider(),
            Flexible(child: SingleChildScrollView(child: HtmlWidget(refClone.innerHtml, textStyle: theme.textTheme.bodyMedium?.copyWith(fontSize: 14, height: 1.6)))),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
