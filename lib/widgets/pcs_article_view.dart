import 'dart:convert';
import 'dart:isolate';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:wikimedia_core/wikimedia_core.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

import '../data/disclaimer.dart';
import '../data/license_notice.dart';

class PcsAssetLoader {
  static String? _cachedBaseCss;
  static String? _cachedPcsCss;
  static String? _cachedPcsJs;
  static String? _cachedSpacerImageBase64;
  static final Map<ProjectType, String> _cachedHeroFallbacks = {};
  static bool _isLoading = false;

  static Future<void> ensureLoaded() async {
    if (_cachedBaseCss != null &&
        _cachedPcsCss != null &&
        _cachedPcsJs != null &&
        _cachedSpacerImageBase64 != null) {
      return;
    }
    if (_isLoading) return;
    _isLoading = true;
    try {
      _cachedBaseCss ??= await rootBundle.loadString('assets/pcs/base.css');
      _cachedPcsCss ??= await rootBundle.loadString('assets/pcs/pcs.css');
      _cachedPcsJs ??= await rootBundle.loadString('assets/pcs/pcs.js');
      if (_cachedSpacerImageBase64 == null) {
        final bytes = await rootBundle.load("assets/images/ni'owewemagai.webp");
        _cachedSpacerImageBase64 = base64Encode(bytes.buffer.asUint8List());
      }
    } catch (e) {
      debugPrint('Error loading bundled PCS assets: $e');
    } finally {
      _isLoading = false;
    }
  }

  static String get baseCss => _cachedBaseCss ?? '';
  static String get pcsCss => _cachedPcsCss ?? '';
  static String get pcsJs => _cachedPcsJs ?? '';
  static String get spacerImageBase64 => _cachedSpacerImageBase64 ?? '';

  static Future<String?> getHeroFallback(ProjectType project) async {
    if (_cachedHeroFallbacks.containsKey(project)) {
      return _cachedHeroFallbacks[project];
    }
    try {
      final bytes = await rootBundle.load(project.articleHeroImagePath);
      final b64 = base64Encode(bytes.buffer.asUint8List());
      _cachedHeroFallbacks[project] = b64;
      return b64;
    } catch (_) {
      return null;
    }
  }
}

class PcsHtmlProcessor {
  /// Asynchronously processes HTML, offloading DOM parsing to [Isolate.run]
  /// for payloads >= 4 KB to prevent UI jank on 2 GB RAM / low-end devices.
  static Future<String> processAsync({
    required String rawHtml,
    required String? heroImageUrl,
    String languageCode = 'id',
    ProjectType project = ProjectType.wikipedia,
    List<String>? referenceKeywords,
  }) async {
    if (rawHtml.isEmpty) return rawHtml;

    final projectStr = project.name.toLowerCase();
    final removeSelectors = WikiConfig.getCombinedRulesList(
      languageCode,
      projectStr,
      'remove',
    );
    final hideSelectors = WikiConfig.getCombinedRulesList(
      languageCode,
      projectStr,
      'hide',
    );
    final removeEmptySections = WikiConfig.hasProcessingFlag(
      languageCode,
      projectStr,
      'removeEmptySections',
    );
    final removeEmptyImageSections = WikiConfig.hasProcessingFlag(
      languageCode,
      projectStr,
      'removeEmptyImageSections',
    );
    final configuredRefKeywords = WikiConfig.getCombinedRulesList(
      languageCode,
      projectStr,
      'referenceKeywords',
    );
    final tableScrollHint = 'table_scroll_hint'.tr();

    // Short strings (< 4 KB) parse faster inline without isolate spawn overhead
    if (rawHtml.length < 4096) {
      return _processWithRules(
        rawHtml: rawHtml,
        heroImageUrl: heroImageUrl,
        removeSelectors: removeSelectors,
        hideSelectors: hideSelectors,
        removeEmptySections: removeEmptySections,
        removeEmptyImageSections: removeEmptyImageSections,
        configuredRefKeywords: configuredRefKeywords,
        referenceKeywords: referenceKeywords,
        tableScrollHint: tableScrollHint,
      );
    }

    return Isolate.run(
      () => _processWithRules(
        rawHtml: rawHtml,
        heroImageUrl: heroImageUrl,
        removeSelectors: removeSelectors,
        hideSelectors: hideSelectors,
        removeEmptySections: removeEmptySections,
        removeEmptyImageSections: removeEmptyImageSections,
        configuredRefKeywords: configuredRefKeywords,
        referenceKeywords: referenceKeywords,
        tableScrollHint: tableScrollHint,
      ),
    );
  }

  /// Synchronous processing fallback for small payloads or legacy calls.
  static String process({
    required String rawHtml,
    required String? heroImageUrl,
    String languageCode = 'id',
    ProjectType project = ProjectType.wikipedia,
    List<String>? referenceKeywords,
  }) {
    if (rawHtml.isEmpty) return rawHtml;

    final projectStr = project.name.toLowerCase();
    return _processWithRules(
      rawHtml: rawHtml,
      heroImageUrl: heroImageUrl,
      removeSelectors: WikiConfig.getCombinedRulesList(
        languageCode,
        projectStr,
        'remove',
      ),
      hideSelectors: WikiConfig.getCombinedRulesList(
        languageCode,
        projectStr,
        'hide',
      ),
      removeEmptySections: WikiConfig.hasProcessingFlag(
        languageCode,
        projectStr,
        'removeEmptySections',
      ),
      removeEmptyImageSections: WikiConfig.hasProcessingFlag(
        languageCode,
        projectStr,
        'removeEmptyImageSections',
      ),
      configuredRefKeywords: WikiConfig.getCombinedRulesList(
        languageCode,
        projectStr,
        'referenceKeywords',
      ),
      referenceKeywords: referenceKeywords,
      tableScrollHint: 'table_scroll_hint'.tr(),
    );
  }

  static String _processWithRules({
    required String rawHtml,
    required String? heroImageUrl,
    required List<String> removeSelectors,
    required List<String> hideSelectors,
    required bool removeEmptySections,
    required bool removeEmptyImageSections,
    required List<String> configuredRefKeywords,
    List<String>? referenceKeywords,
    required String tableScrollHint,
  }) {
    if (rawHtml.isEmpty) return rawHtml;

    final document = html_parser.parse(rawHtml);

    // Multi-lingual Community Rules: Apply removals
    for (final s in removeSelectors) {
      document.querySelectorAll(s).forEach((el) => el.remove());
    }

    // Multi-lingual Community Rules: Apply hides
    for (final s in hideSelectors) {
      document.querySelectorAll(s).forEach((el) => el.classes.add('wikinusa-hidden'));
    }

    // Multi-lingual Community Rules: Apply empty section cleanups
    if (removeEmptySections) {
      _removeEmptySections(document);
    }
    if (removeEmptyImageSections) {
      _removeEmptyImageSections(document);
    }

    // Data Tables: Wrap with contextual swipe hint container
    _wrapDataTables(document, tableScrollHint);

    // Hide and remove edit pencil icons (links to edit headings, infobox fields, or Wikidata entries)
    final editElements = document.querySelectorAll(
      '.penicon, '
      '.wikidata-edit-link, '
      '.wikidata-link, '
      '.mw-editsection, '
      '.mw-editsection-like, '
      '.mw-editsection-bracket, '
      '.infobox-edit, '
      '[data-bridge-edit-flow], '
      'a[href*="wikidata.org"][title*="Sunting"], '
      'a[href*="wikidata.org"][title*="Edit"], '
      'a[title*="Suntingan nilai di Wikidata"], '
      'a[title*="Edit this at Wikidata"], '
      'a[title*="Edit on Wikidata"], '
      'a[title*="Sunting di Wikidata"]',
    );
    for (final el in editElements) {
      el.remove();
    }

    final editImages = document.querySelectorAll(
      'img[src*="OOjs_UI_icon_edit"], '
      'img[resource*="OOjs_UI_icon_edit"], '
      'img[src*="icon_edit"], '
      'img[resource*="icon_edit"], '
      'img[alt*="Suntingan nilai di Wikidata"], '
      'img[alt*="Edit this at Wikidata"], '
      'img[alt*="Edit on Wikidata"], '
      'img[alt*="Sunting di Wikidata"]',
    );
    for (final img in editImages) {
      dom.Element toRemove = img;
      dom.Element? p = img.parent;
      while (p != null &&
          p.localName != "td" &&
          p.localName != "th" &&
          p.localName != "p" &&
          p.localName != "body" &&
          p.localName != "section" &&
          p.localName != "div") {
        toRemove = p;
        p = p.parent;
      }
      toRemove.remove();
    }

    // 0. Classify and tag infobox main images and maps
    final allInfoboxes =
        document.querySelectorAll('.infobox, table.infobox, .infobox_v2');
    for (final box in allInfoboxes) {
      final rows = box.querySelectorAll('tr');
      bool foundFirstPropertyLabel = false;
      for (final tr in rows) {
        if (tr.querySelector('.infobox-label, th.infobox-label') != null) {
          foundFirstPropertyLabel = true;
        }

        final hasMap = tr.querySelector(
              '.mw-kartographer-map, .locmap, .switcher-container, [data-mw-kartographer], a[href*="map"], a[href*="Map"], a[href*="Peta"]',
            ) != null;
        final hasMulti =
            tr.querySelector('.tmulti, .multiimageinner') != null;
        final isImageCell = tr.querySelector(
              '.infobox-image, td.infobox-image, th.infobox-image',
            ) != null;
        final hasImg = tr.querySelector('img') != null;

        if (isImageCell || hasMap || hasMulti || (!foundFirstPropertyLabel && hasImg)) {
          tr.classes.add('wikinusa-infobox-image-row');
          for (final cell in tr.querySelectorAll('td, th')) {
            cell.classes.add('wikinusa-infobox-image-cell');
          }
        }
      }
    }

    // 0. Classify all images: distinguish standalone pictures/photos/maps from small UI icons
    final allImages = document.querySelectorAll('img');
    for (final img in allImages) {
      final src = img.attributes['src'] ?? '';
      if (src.isNotEmpty) {
        final isIcon = CoreWikiUtils.isIcon(src, img);
        if (isIcon) {
          img.classes.add('wiki-inline-icon');
          dom.Element? p = img.parent;
          while (p != null && p.localName != 'body' && p.localName != 'section') {
            if (p.localName == 'figure' ||
                p.classes.contains('thumb') ||
                p.attributes['typeof']?.contains('mw:File') == true) {
              p.classes.add('wiki-inline-icon-container');
              break;
            }
            p = p.parent;
          }
        } else {
          // Real picture, photo, map, or thumbnail
          dom.Element? p = img.parent;
          bool isStandaloneThumb = false;
          while (p != null && p.localName != 'body' && p.localName != 'section') {
            if (p.classes.contains('thumb') ||
                p.attributes['typeof']?.contains('mw:File/Thumb') == true ||
                p.attributes['typeof']?.contains('mw:File/Frame') == true) {
              isStandaloneThumb = true;
              p.classes.add('wikinusa-fullwidth-image-container');
              break;
            }
            if (p.classes.contains('infobox') || p.classes.contains('navbox')) {
              break;
            }
            p = p.parent;
          }
          if (isStandaloneThumb) {
            img.classes.add('wikinusa-fullwidth-image');
          }
        }
      }
    }

    final sec0 = document.querySelector('section[data-mw-section-id="0"]') ??
        document.getElementById('content') ??
        document.body;

    if (sec0 != null) {
      // 1. Identify first substantive paragraph
      final ps = sec0.querySelectorAll('p');
      dom.Element? firstP;
      for (final p in ps) {
        if (!p.classes.contains('mw-empty-elt') && p.text.trim().length > 20) {
          firstP = p;
          break;
        }
      }

      if (firstP != null) {
        // Collect infoboxes that precede firstP in section 0
        final infoboxes =
            sec0.querySelectorAll('.infobox, table.infobox, .infobox_v2');
        final precedingInfoboxes = <dom.Element>[];
        for (final box in infoboxes) {
          if (_precedes(box, firstP, sec0)) {
            precedingInfoboxes.add(box);
          }
        }

        // Collect ONLY real standalone figures/thumbnails that precede firstP (NEVER relocate icons!)
        final figures =
            sec0.querySelectorAll('figure, .thumb, .thumbinner');
        final precedingFigures = <dom.Element>[];
        for (final fig in figures) {
          if (_precedes(fig, firstP, sec0)) {
            if (fig.classes.contains('wiki-inline-icon-container')) {
              continue; // Leave icons where they are!
            }
            final img = fig.querySelector('img');
            final src = img?.attributes['src'] ?? '';
            if (src.isNotEmpty && CoreWikiUtils.isIcon(src, img)) {
              continue; // Leave icons where they are!
            }
            final isHeroCandidate = heroImageUrl != null &&
                heroImageUrl.isNotEmpty &&
                src.isNotEmpty &&
                (heroImageUrl.contains(src) || src.contains(heroImageUrl));

            if (isHeroCandidate) {
              fig.classes.add('wikinusa-hidden-hero');
            } else if (fig.classes.contains('wikinusa-fullwidth-image-container') ||
                fig.attributes['typeof']?.contains('Thumb') == true ||
                fig.attributes['typeof']?.contains('Frame') == true) {
              precedingFigures.add(fig);
            }
          }
        }

        // Relocate elements after firstP
        var currentTarget = firstP.nextElementSibling;
        final parent = firstP.parent ?? sec0;

        // Place non-hero images first, then infoboxes
        for (final fig in precedingFigures) {
          fig.remove();
          if (currentTarget != null) {
            parent.insertBefore(fig, currentTarget);
          } else {
            parent.append(fig);
          }
          currentTarget = fig.nextElementSibling;
        }

        for (final box in precedingInfoboxes) {
          box.remove();
          if (currentTarget != null) {
            parent.insertBefore(box, currentTarget);
          } else {
            parent.append(box);
          }
          currentTarget = box.nextElementSibling;
        }
      }
    }

    // 2. Hide Reference sections and footnote lists
    final combinedKeywords = {
      'referensi',
      'rujukan',
      'umbu',
      'catatan kaki',
      'catatan',
      'notes',
      'references',
      'reflist',
      'famotokhi ba gahe',
      ...?referenceKeywords?.map((k) => k.toLowerCase().trim()),
      ...configuredRefKeywords.map((k) => k.toLowerCase().trim()),
    };

    // Find headings matching reference keywords
    final headings = document.querySelectorAll('h2, h3, h4');
    for (final h in headings) {
      final text = h.text.toLowerCase().trim();
      final id = (h.attributes['id'] ?? '').toLowerCase().trim();
      final isRefHeading = combinedKeywords.any(
        (kw) => text.contains(kw) || id.contains(kw),
      );

      if (isRefHeading) {
        dom.Element? section = h.parent;
        while (section != null &&
            section.localName != 'section' &&
            section.localName != 'body') {
          section = section.parent;
        }
        if (section != null && section.localName == 'section') {
          section.classes.add('wikinusa-ref-section');
        } else {
          h.classes.add('wikinusa-ref-section');
          var next = h.nextElementSibling;
          while (next != null && !['h1', 'h2', 'h3'].contains(next.localName)) {
            next.classes.add('wikinusa-ref-section');
            next = next.nextElementSibling;
          }
        }
      }
    }

    // Also hide any section wrapping .reflist or ol.mw-references
    final refContainers =
        document.querySelectorAll('.reflist, ol.mw-references, .mw-references-wrap');
    for (final ref in refContainers) {
      dom.Element? section = ref.parent;
      while (section != null &&
          section.localName != 'section' &&
          section.localName != 'body') {
        section = section.parent;
      }
      if (section != null && section.localName == 'section') {
        section.classes.add('wikinusa-ref-section');
      } else {
        ref.classes.add('wikinusa-ref-section');
      }
    }

    return document.body?.innerHtml ?? rawHtml;
  }

  static void _wrapDataTables(dom.Document document, String hintText) {
    final tables = document.querySelectorAll('table');
    for (final table in tables) {
      final isInfobox = table.classes.any((c) =>
          c.contains('infobox') ||
          c.contains('navbox') ||
          c.contains('ambox') ||
          c.contains('metadata') ||
          c.contains('toc'));
      if (isInfobox) continue;
      if (table.parent?.classes.contains('wikinusa-table-scroll-wrapper') == true) {
        continue;
      }

      final cardWrapper = dom.Element.tag('div')..classes.add('wikinusa-table-card');
      final hintBar = dom.Element.tag('div')
        ..classes.add('wikinusa-table-hint')
        ..innerHtml = '<span class="wikinusa-table-hint-icon">↔</span><span>$hintText</span>';
      final scrollWrapper = dom.Element.tag('div')..classes.add('wikinusa-table-scroll-wrapper');

      table.replaceWith(cardWrapper);
      cardWrapper.append(hintBar);
      cardWrapper.append(scrollWrapper);
      scrollWrapper.append(table);
    }
  }

  static void _removeEmptySections(dom.Document document) {
    final potentialMarkers = [
      ...document.querySelectorAll('dd'),
      ...document.querySelectorAll('li'),
    ];
    final emptyMarkers = potentialMarkers.where(
      (element) => element.text.trim() == 'Lö hadöi',
    );
    for (final marker in emptyMarkers) {
      dom.Element? listContainer = marker.parent;
      if (listContainer == null) continue;
      if (!['dl', 'ul', 'ol'].contains(listContainer.localName)) continue;

      dom.Element? headingContainer = listContainer.previousElementSibling;
      if (headingContainer != null &&
          (headingContainer.classes.contains('mw-heading') ||
           ['h2', 'h3', 'h4'].contains(headingContainer.localName))) {
        headingContainer.remove();
        listContainer.remove();
      }
    }
  }

  static void _removeEmptyImageSections(dom.Document document) {
    final imageHeadings = document.querySelectorAll('h3#Gambara, h3[id="Gambara"]');
    for (final h3 in imageHeadings) {
      dom.Element headingContainer = h3;
      if (h3.parent?.classes.contains('mw-heading') == true) {
        headingContainer = h3.parent!;
      }
      final nextElement = headingContainer.nextElementSibling;
      if (nextElement == null || nextElement.localName != 'figure') {
        headingContainer.remove();
      }
    }
  }

  static bool _precedes(dom.Element a, dom.Element b, dom.Element container) {
    if (a == b) return false;
    final all = container.querySelectorAll('*');
    final idxA = all.indexOf(a);
    final idxB = all.indexOf(b);
    if (idxA != -1 && idxB != -1) {
      return idxA < idxB;
    }
    return false;
  }
}

class PcsArticleController {
  _PcsArticleWebViewState? _state;

  void _attach(_PcsArticleWebViewState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  Future<void> setTheme(String theme) async {
    await _state?.setTheme(theme);
  }

  Future<void> setTextSize(int percent) async {
    await _state?.setTextSize(percent);
  }

  Future<int> search(String query) async {
    return (await _state?.search(query)) ?? 0;
  }

  Future<int> nextMatch() async {
    return (await _state?.nextMatch()) ?? -1;
  }

  Future<int> previousMatch() async {
    return (await _state?.previousMatch()) ?? -1;
  }

  Future<void> clearSearch() async {
    await _state?.clearSearch();
  }

  Future<void> expandOrCollapseTables(bool expand) async {
    await _state?.expandOrCollapseTables(expand);
  }

  Future<String> getTableOfContents() async {
    return (await _state?.getTableOfContents()) ?? '[]';
  }
}

class PcsArticleWebView extends StatefulWidget {
  final String htmlContent;
  final String baseUrl;
  final String title;
  final String? heroImageUrl;
  final ProjectType project;
  final String theme; // 'light', 'dark', 'sepia', 'black'
  final String fontFamily;
  final String languageCode;
  final double fontSizeScale;
  final PcsArticleController? controller;
  final Function(String href, String? title) onLinkClicked;
  final Function(String referenceId, String html) onReferenceClicked;
  final Function(String imageUrl, String? title) onImageClicked;
  final VoidCallback? onSetupFinished;

  const PcsArticleWebView({
    super.key,
    required this.htmlContent,
    required this.baseUrl,
    required this.title,
    this.heroImageUrl,
    required this.project,
    required this.theme,
    this.fontFamily = 'Plus Jakarta Sans',
    this.languageCode = 'id',
    this.fontSizeScale = 1.15,
    this.controller,
    required this.onLinkClicked,
    required this.onReferenceClicked,
    required this.onImageClicked,
    this.onSetupFinished,
  });

  @override
  State<PcsArticleWebView> createState() => _PcsArticleWebViewState();
}

class _PcsArticleWebViewState extends State<PcsArticleWebView> {
  late final WebViewController _webViewController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    _initController();
    _loadPcsContent();
  }

  @override
  void didUpdateWidget(covariant PcsArticleWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(this);
    }
    if (widget.theme != oldWidget.theme) {
      setTheme(widget.theme);
    }
    if (widget.fontSizeScale != oldWidget.fontSizeScale) {
      setTextSize((widget.fontSizeScale * 100).round());
    }
    if (widget.htmlContent != oldWidget.htmlContent ||
        widget.title != oldWidget.title ||
        widget.heroImageUrl != oldWidget.heroImageUrl ||
        widget.languageCode != oldWidget.languageCode) {
      _loadPcsContent();
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();
    super.dispose();
  }

  void _initController() {
    final isDark = widget.theme == 'dark' || widget.theme == 'black';
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(bgColor)
      ..addJavaScriptChannel(
        'pcsBridge',
        onMessageReceived: (JavaScriptMessage msg) {
          _handlePcsMessage(msg.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _isLoading = false);
              widget.onSetupFinished?.call();
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url != widget.baseUrl &&
                !request.url.startsWith('about:blank') &&
                !request.url.startsWith('data:')) {
              widget.onLinkClicked(request.url, null);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
  }

  Future<void> _loadPcsContent() async {
    if (mounted && !_isLoading) {
      setState(() => _isLoading = true);
    }
    await PcsAssetLoader.ensureLoaded();
    if (!mounted) return;

    final theme = Theme.of(context);
    final isDark = widget.theme == 'dark' || widget.theme == 'black';
    final primaryColor = widget.project.getThemedColor(isDark);
    final secondaryColor = theme.colorScheme.secondary;
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.white;

    final heroFallbackBase64 =
        await PcsAssetLoader.getHeroFallback(widget.project);
    if (!mounted) return;

    final processedHtml = await PcsHtmlProcessor.processAsync(
      rawHtml: widget.htmlContent,
      heroImageUrl: widget.heroImageUrl,
      languageCode: widget.languageCode,
      project: widget.project,
    );
    if (!mounted) return;

    final documentHtml = _buildDocument(
      parsoidHtml: processedHtml,
      theme: widget.theme,
      fontFamily: widget.fontFamily,
      title: widget.title,
      heroImageUrl: widget.heroImageUrl,
      heroFallbackBase64: heroFallbackBase64,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      backgroundColor: backgroundColor,
      languageCode: widget.languageCode,
      fontSizeScale: widget.fontSizeScale,
    );

    _webViewController.loadHtmlString(documentHtml, baseUrl: widget.baseUrl);
  }

  String _buildFooterHtml(String langCode) {
    final activeDisclaimer = langCode == 'en' ? disclaimerEn : disclaimerId;
    final activeLicenseNotice =
        langCode == 'en' ? licenseNoticeEn : licenseNoticeId;
    final spacerBase64 = PcsAssetLoader.spacerImageBase64;
    final spacerHtml = spacerBase64.isNotEmpty
        ? '<img src="data:image/webp;base64,$spacerBase64" class="wikinusa-footer-spacer" alt="Spacer" />'
        : '<div style="height:20px;"></div>';

    final disclaimerLabel = 'disclaimer_label'.tr();
    final privacyLabel = 'privacy_policy'.tr();

    return '''
<footer class="wikinusa-footer">
  $spacerHtml
  <div class="wikinusa-footer-title">WIKINUSA</div>
  <div class="wikinusa-footer-text">$activeDisclaimer</div>
  <div class="wikinusa-footer-text">$activeLicenseNotice</div>
  <div class="wikinusa-footer-links">
    <a href="https://sslaia.github.io/wikinusa/disclaimer.html" class="wikinusa-footer-link">$disclaimerLabel</a>
    <a href="https://sslaia.github.io/wikinusa/privacy-policy.html" class="wikinusa-footer-link">$privacyLabel</a>
  </div>
</footer>
''';
  }

  String _buildDocument({
    required String parsoidHtml,
    required String theme,
    required String fontFamily,
    required String title,
    String? heroImageUrl,
    String? heroFallbackBase64,
    required Color primaryColor,
    required Color secondaryColor,
    required Color backgroundColor,
    required String languageCode,
    double fontSizeScale = 1.15,
  }) {
    final hasOnlineHero = heroImageUrl != null &&
        heroImageUrl.isNotEmpty &&
        !CoreWikiUtils.isIcon(heroImageUrl);

    String? heroSrc;
    if (hasOnlineHero) {
      heroSrc = heroImageUrl;
    } else if (heroFallbackBase64 != null && heroFallbackBase64.isNotEmpty) {
      heroSrc = 'data:image/webp;base64,$heroFallbackBase64';
    }

    final isNight = theme == 'dark' || theme == 'black';
    final primaryHex =
        '#${primaryColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
    final secondaryHex =
        '#${secondaryColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
    final bgHex =
        '#${backgroundColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
    final textColor = isNight ? '#f1f5f9' : '#0f172a';
    final textSecondaryColor = isNight ? '#94a3b8' : '#475569';
    final linkColor = isNight ? '#c0bcfc' : '#0645ad';
    final linkRedColor = isNight ? '#a0482f' : '#ba0000';
    final quoteColor = isNight ? '#a8be20' : '#889c0b';
    final surfaceHex = isNight ? '#1e1e1e' : '#f8fafc';
    final borderHex =
        isNight ? 'rgba(255, 255, 255, 0.12)' : 'rgba(0, 0, 0, 0.1)';
    final bgRgb = isNight
        ? '18, 18, 18'
        : (theme == 'sepia' ? '248, 241, 233' : '255, 255, 255');

    final heroHeaderHtml = heroSrc != null
        ? '''
<header class="wikinusa-hero-header">
  <div class="wikinusa-hero-image-wrapper">
    <img src="$heroSrc" class="wikinusa-hero-img" alt="${htmlEscape.convert(title)}" />
    <div class="wikinusa-hero-gradient"></div>
  </div>
  <div class="wikinusa-hero-title-container">
    <h1 class="wikinusa-hero-title">${htmlEscape.convert(title)}</h1>
    <div class="wikinusa-hero-accent-bar"></div>
  </div>
</header>
'''
        : '''
<header class="wikinusa-hero-header">
  <div class="wikinusa-hero-title-container">
    <h1 class="wikinusa-hero-title">${htmlEscape.convert(title)}</h1>
    <div class="wikinusa-hero-accent-bar"></div>
  </div>
</header>
''';

    final footerHtml = _buildFooterHtml(languageCode);
    final baseCssContent = PcsAssetLoader.baseCss;
    final pcsCssContent = PcsAssetLoader.pcsCss;
    final pcsJsContent = PcsAssetLoader.pcsJs;

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes">
  <base href="${widget.baseUrl}">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Cinzel+Decorative:wght@700&family=Noto+Sans+Balinese:wght@400;700&family=Noto+Sans+Javanese:wght@400;700&family=Noto+Sans+Sundanese:wght@400;700&family=Plus+Jakarta+Sans:ital,wght@0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet">
  ${baseCssContent.isNotEmpty ? '<style id="pcs-base-css">$baseCssContent</style>' : '<link rel="stylesheet" href="https://meta.wikimedia.org/api/rest_v1/data/css/mobile/base">'}
  ${pcsCssContent.isNotEmpty ? '<style id="pcs-theme-css">$pcsCssContent</style>' : '<link rel="stylesheet" href="https://meta.wikimedia.org/api/rest_v1/data/css/mobile/pcs">'}
  <style>
    :root {
      --wikinusa-primary: $primaryHex;
      --wikinusa-secondary: $secondaryHex;
      --wikinusa-bg: $bgHex;
      --wikinusa-bg-rgb: $bgRgb;
      --wikinusa-text: $textColor;
      --wikinusa-text-secondary: $textSecondaryColor;
      --wikinusa-link: $linkColor;
      --wikinusa-link-red: $linkRedColor;
      --wikinusa-quote-color: $quoteColor;
      --wikinusa-surface: $surfaceHex;
      --wikinusa-border: $borderHex;
    }
    body {
      margin: 0 !important;
      padding: 0 !important;
      font-family: "Plus Jakarta Sans", "Noto Sans Javanese", "Noto Sans Balinese", "Noto Sans Sundanese", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif !important;
      background-color: var(--wikinusa-bg) !important;
      color: var(--wikinusa-text) !important;
      font-size: ${(16.0 * (fontSizeScale / 1.15)).toStringAsFixed(1)}px !important;
      line-height: 1.8 !important;
      letter-spacing: -0.01em !important;
      -webkit-font-smoothing: antialiased;
    }
    p {
      margin: 14px 0 !important;
      line-height: 1.8 !important;
    }

    /* Hero Header */
    .wikinusa-hero-header {
      position: relative;
      width: 100%;
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    .wikinusa-hero-image-wrapper {
      position: relative;
      width: 100%;
      height: 280px;
      overflow: hidden;
      background-color: var(--wikinusa-surface);
    }
    .wikinusa-hero-img {
      width: 100%;
      height: 100%;
      object-fit: cover;
      display: block;
    }
    .wikinusa-hero-gradient {
      position: absolute;
      top: 0; left: 0; right: 0; bottom: 0;
      background: linear-gradient(
        to bottom,
        transparent 0%,
        transparent 35%,
        rgba($bgRgb, 0.7) 80%,
        var(--wikinusa-bg) 100%
      );
    }
    .wikinusa-hero-title-container {
      padding: 16px 20px 10px 20px;
    }
    .wikinusa-hero-title {
      font-family: "Plus Jakarta Sans", -apple-system, BlinkMacSystemFont, sans-serif;
      font-size: 26px;
      font-weight: 700;
      line-height: 1.25;
      margin: 0 0 10px 0;
      color: var(--wikinusa-primary);
      font-variant: small-caps;
    }
    .wikinusa-hero-accent-bar {
      width: 44px;
      height: 4px;
      border-radius: 2px;
      background-color: var(--wikinusa-secondary);
    }

    /* Content Area */
    #content.pcs-content {
      padding: 0 16px 20px 16px !important;
      box-sizing: border-box;
    }

    /* Headings & Signature Underline */
    h2 {
      font-family: "Plus Jakarta Sans", -apple-system, BlinkMacSystemFont, sans-serif !important;
      font-size: 1.35rem !important;
      font-weight: 700 !important;
      color: var(--wikinusa-primary) !important;
      margin-top: 32px !important;
      margin-bottom: 12px !important;
      padding-bottom: 6px !important;
      border-bottom: none !important;
      position: relative !important;
      line-height: 1.3 !important;
    }
    h2::after {
      content: "";
      display: block;
      width: 42px;
      height: 3.5px;
      background-color: var(--wikinusa-primary);
      border-radius: 2px;
      margin-top: 6px;
    }
    h3 {
      font-family: "Plus Jakarta Sans", -apple-system, BlinkMacSystemFont, sans-serif !important;
      font-size: 1.15rem !important;
      font-weight: 700 !important;
      color: var(--wikinusa-text) !important;
      margin-top: 24px !important;
      margin-bottom: 8px !important;
    }
    h4, h5, h6 {
      font-family: "Plus Jakarta Sans", -apple-system, BlinkMacSystemFont, sans-serif !important;
      font-size: 1rem !important;
      font-weight: 600 !important;
      color: var(--wikinusa-text-secondary) !important;
      margin-top: 18px !important;
      margin-bottom: 6px !important;
    }

    /* Links */
    a {
      color: var(--wikinusa-link) !important;
      font-weight: 600 !important;
      text-decoration: none !important;
    }
    a:hover, a:active {
      text-decoration: underline !important;
    }
    a.new,
    a[href*="action=edit"],
    a[href*="redlink=1"] {
      color: var(--wikinusa-link-red) !important;
    }

    /* Full-width Responsive Infoboxes */
    .infobox,
    table.infobox,
    .infobox_v2,
    .pcs-collapse-table-container {
      float: none !important;
      width: 100% !important;
      max-width: 100% !important;
      margin: 16px 0 !important;
      box-sizing: border-box !important;
      display: table !important;
      border-radius: 12px !important;
      border: 1px solid var(--wikinusa-border) !important;
      background-color: var(--wikinusa-surface) !important;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04) !important;
    }
    .pcs-collapse-table-container {
      display: block !important;
    }
    .pcs-collapse-table-container table.infobox {
      border: none !important;
      box-shadow: none !important;
      margin: 0 !important;
    }
    .infobox td, .infobox th {
      box-sizing: border-box !important;
      padding: 8px 12px !important;
    }
    .infobox img {
      max-width: 100% !important;
      height: auto !important;
    }

    /* Hide edit pencil icons and Wikidata edit links in infoboxes, headings, and page content */
    .penicon,
    .wikidata-edit-link,
    .wikidata-link,
    .infobox-edit,
    .mw-editsection,
    .mw-editsection-like,
    .mw-editsection-bracket,
    [data-bridge-edit-flow],
    .infobox .penicon,
    .infobox .wikidata-edit-link,
    .infobox a[href*="wikidata.org"][title*="Sunting"],
    .infobox a[href*="wikidata.org"][title*="Edit"],
    .infobox a[title*="Suntingan nilai di Wikidata"],
    .infobox a[title*="Edit this at Wikidata"],
    .infobox a[title*="Edit on Wikidata"],
    .infobox a[title*="Sunting di Wikidata"],
    .infobox img[src*="OOjs_UI_icon_edit"],
    .infobox img[resource*="OOjs_UI_icon_edit"],
    .infobox img[src*="icon_edit"],
    .infobox img[resource*="icon_edit"],
    .infobox img[alt*="Suntingan nilai di Wikidata"],
    .infobox img[alt*="Edit this at Wikidata"],
    .infobox img[alt*="Edit on Wikidata"],
    .infobox img[alt*="Sunting di Wikidata"],
    img[src*="OOjs_UI_icon_edit"],
    img[resource*="OOjs_UI_icon_edit"] {
      display: none !important;
    }

    /* Standalone Full-Width Images, Photos, Pictures, and Maps */
    figure[typeof*="mw:File/Thumb"]:not(.wiki-inline-icon-container),
    figure[typeof*="mw:File/Frame"]:not(.wiki-inline-icon-container),
    .thumb:not(.wiki-inline-icon-container),
    .thumbinner:not(.wiki-inline-icon-container),
    .wikinusa-fullwidth-image-container {
      float: none !important;
      width: 100% !important;
      max-width: 100% !important;
      margin: 20px 0 !important;
      box-sizing: border-box !important;
      background-color: transparent !important;
      border: none !important;
      display: block !important;
      clear: both !important;
    }
    figure[typeof*="mw:File/Thumb"]:not(.wiki-inline-icon-container) img,
    figure[typeof*="mw:File/Frame"]:not(.wiki-inline-icon-container) img,
    .thumb:not(.wiki-inline-icon-container) > a > img,
    .thumb:not(.wiki-inline-icon-container) > img,
    .thumbinner:not(.wiki-inline-icon-container) img,
    img.wikinusa-fullwidth-image {
      width: 100% !important;
      max-width: 100% !important;
      height: auto !important;
      border-radius: 12px !important;
      box-shadow: 0 4px 14px rgba(0, 0, 0, 0.08) !important;
      box-sizing: border-box !important;
      display: block !important;
      margin: 0 auto !important;
    }
    figcaption,
    .thumbcaption {
      display: block !important;
      width: 100% !important;
      max-width: 100% !important;
      box-sizing: border-box !important;
      font-size: 0.85rem !important;
      font-style: italic !important;
      line-height: 1.5 !important;
      color: var(--wikinusa-text-secondary) !important;
      padding: 8px 4px 4px 4px !important;
      text-align: left !important;
    }
    .wikinusa-hidden-hero {
      display: none !important;
    }

    /* ==========================================================================
       Centering and Full-Width Presentation for Infobox Main Images and Maps
       ========================================================================== */
    .center,
    .content .center,
    .pcs-content .center {
      width: 100% !important;
      text-align: center !important;
      display: block !important;
      margin-left: auto !important;
      margin-right: auto !important;
    }

    /* Infobox Image and Map Cells */
    .infobox td.infobox-image,
    .infobox th.infobox-image,
    .infobox .infobox-image,
    .infobox .wikinusa-infobox-image-cell,
    .infobox td.maptable {
      text-align: center !important;
      padding: 8px 10px !important;
    }

    /* Captions for Infobox Images & Maps */
    .infobox td.infobox-image div,
    .infobox .wikinusa-infobox-image-cell div.infobox-caption,
    .infobox .wikinusa-infobox-image-cell div.ib-settlement-caption,
    .infobox .infobox-caption,
    .infobox .ib-settlement-caption,
    .infobox .wikinusa-infobox-image-cell figcaption,
    .infobox figcaption {
      text-align: center !important;
      margin: 6px auto 4px auto !important;
      font-size: 0.88rem !important;
      font-style: italic !important;
      color: var(--wikinusa-text-secondary) !important;
    }

    /* Main image & map container wrappers inside infobox */
    .infobox td.infobox-image > span,
    .infobox td.infobox-image > a,
    .infobox td.infobox-image span[typeof*="mw:File"],
    .infobox td.infobox-image figure,
    .infobox .wikinusa-infobox-image-cell > span,
    .infobox .wikinusa-infobox-image-cell > a,
    .infobox .wikinusa-infobox-image-cell span[typeof*="mw:File"]:not(.locmap span),
    .infobox .wikinusa-infobox-image-cell a.mw-file-description:not(.locmap a),
    .infobox .wikinusa-infobox-image-cell figure {
      display: block !important;
      width: 100% !important;
      max-width: 100% !important;
      margin: 0 auto !important;
      padding: 0 !important;
      text-align: center !important;
    }

    /* Main Images and Full-Width Maps in Infobox: Fill available space or center */
    .infobox td.infobox-image img:not(.locmap div img),
    .infobox .infobox-image img:not(.locmap div img),
    .infobox .wikinusa-infobox-image-cell img:not(.locmap div img),
    .infobox .mw-kartographer-map img,
    .infobox .switcher-container img:not(.locmap div img) {
      width: 100% !important;
      max-width: 100% !important;
      height: auto !important;
      border-radius: 8px !important;
      display: block !important;
      margin: 0 auto !important;
      box-sizing: border-box !important;
    }

    /* Kartographer interactive & static mapframes */
    .infobox .mw-kartographer-map,
    .infobox .mw-kartographer-container {
      display: block !important;
      width: 100% !important;
      max-width: 100% !important;
      margin: 8px auto !important;
      text-align: center !important;
      float: none !important;
      clear: both !important;
    }

    /* Location Maps (.locmap) with absolute pin overlays */
    .infobox .locmap,
    .infobox .locmap-container {
      display: block !important;
      margin: 8px auto !important;
      float: none !important;
      clear: both !important;
      text-align: center !important;
    }
    .infobox .locmap > div {
      margin: 0 auto !important;
    }
    .infobox .locmap img {
      border-radius: 6px !important;
      max-width: 100% !important;
    }
    .infobox .locmap .od,
    .infobox .locmap .id,
    .infobox .locmap div[style*="position:absolute"],
    .infobox .locmap div[style*="position: absolute"],
    .infobox .locmap div[style*="top"] {
      position: absolute !important;
    }
    .infobox .locmap .od img,
    .infobox .locmap .id img,
    .infobox .locmap div[style*="position:absolute"] img,
    .infobox .locmap div[style*="position: absolute"] img,
    .infobox .locmap div[style*="top"] img {
      width: auto !important;
      max-width: initial !important;
      height: auto !important;
      display: inline-block !important;
      border-radius: 0 !important;
      margin: 0 !important;
      box-shadow: none !important;
    }

    /* Switcher container (country/region map switchers) */
    .infobox .switcher-container {
      display: block !important;
      width: 100% !important;
      max-width: 100% !important;
      margin: 0 auto !important;
      text-align: center !important;
    }
    .infobox .switcher-container > div {
      width: 100% !important;
      display: block !important;
      margin: 0 auto !important;
      text-align: center !important;
    }

    /* Multiple Image Montage in Infoboxes (.tmulti) */
    .infobox .tmulti {
      width: 100% !important;
      max-width: 100% !important;
      margin: 6px auto !important;
      float: none !important;
      clear: both !important;
      text-align: center !important;
    }
    .infobox .tmulti .multiimageinner {
      width: 100% !important;
      max-width: 100% !important;
      margin: 0 auto !important;
      align-items: center !important;
    }
    .infobox .tmulti .trow {
      justify-content: center !important;
      width: 100% !important;
    }
    .infobox .tmulti .tsingle {
      float: none !important;
      margin: 2px auto !important;
      text-align: center !important;
    }

    /* Icons, Inline Symbols, Infobox Icons, UI Elements: Keep natural icon size */
    .wiki-inline-icon,
    .wiki-inline-icon-container,
    .wiki-inline-icon-container img,
    figure.wiki-inline-icon-container,
    figure.mw-halign-left:not([typeof*="Thumb"]):not([typeof*="Frame"]):not(.wikinusa-fullwidth-image-container),
    figure.mw-halign-right:not([typeof*="Thumb"]):not([typeof*="Frame"]):not(.wikinusa-fullwidth-image-container),
    figure:not([typeof*="Thumb"]):not([typeof*="Frame"]):not(.wikinusa-fullwidth-image-container),
    figure:not([typeof*="Thumb"]):not([typeof*="Frame"]):not(.wikinusa-fullwidth-image-container) img,
    span[typeof*="mw:File"],
    span[typeof*="mw:File"] img,
    .infobox td img:not(.infobox-image img):not(.wikinusa-infobox-image-cell img):not(.mw-kartographer-map img):not(.switcher-container img),
    .infobox th img,
    .infobox .mw-halign-left img,
    .infobox-below img,
    .navbox img,
    .ambox img,
    .hatnote img,
    .mw-valign-text-top img,
    .noprint img {
      float: none !important;
      width: auto !important;
      max-width: initial !important;
      height: auto !important;
      box-shadow: none !important;
      border-radius: 0 !important;
      display: inline-block !important;
      vertical-align: middle !important;
    }
    figure.wiki-inline-icon-container,
    figure:not([typeof*="Thumb"]):not([typeof*="Frame"]):not(.wikinusa-fullwidth-image-container),
    span[typeof*="mw:File"] {
      width: auto !important;
      max-width: initial !important;
      margin: 0 2px !important;
      padding: 0 !important;
      display: inline-block !important;
      vertical-align: middle !important;
    }

    /* Quotes and Blockquotes */
    blockquote {
      position: relative !important;
      margin: 18px 0 !important;
      padding: 10px 18px 10px 40px !important;
      font-family: Georgia, "Noto Serif", serif !important;
      font-style: italic !important;
      font-size: 1.02rem !important;
      line-height: 1.65 !important;
      border-left: 3.5px solid var(--wikinusa-quote-color) !important;
      background-color: rgba(128, 128, 128, 0.04) !important;
      border-radius: 0 10px 10px 0 !important;
    }
    blockquote::before {
      content: "“";
      position: absolute;
      left: 10px;
      top: -8px;
      font-size: 46px;
      font-family: Georgia, serif;
      font-weight: bold;
      color: var(--wikinusa-quote-color);
      line-height: 1;
    }

    /* ==========================================================================
       Horizontal Swipeable Gallery Carousel
       ========================================================================== */
    ul.gallery,
    .gallery {
      display: flex !important;
      flex-direction: row !important;
      overflow-x: auto !important;
      overflow-y: hidden !important;
      scroll-snap-type: x mandatory !important;
      gap: 16px !important;
      padding: 12px 16px 22px 16px !important;
      margin: 18px -16px 24px -16px !important;
      list-style: none !important;
      -webkit-overflow-scrolling: touch !important;
      scrollbar-width: thin !important;
      scrollbar-color: var(--wikinusa-primary) transparent !important;
      box-sizing: border-box !important;
    }
    ul.gallery::-webkit-scrollbar,
    .gallery::-webkit-scrollbar {
      height: 4px !important;
    }
    ul.gallery::-webkit-scrollbar-thumb,
    .gallery::-webkit-scrollbar-thumb {
      background: var(--wikinusa-primary) !important;
      border-radius: 4px !important;
    }
    li.gallerybox {
      flex: 0 0 280px !important;
      width: 280px !important;
      min-width: 280px !important;
      max-width: 280px !important;
      height: 250px !important;
      margin: 0 !important;
      border-radius: 16px !important;
      overflow: hidden !important;
      position: relative !important;
      scroll-snap-align: start !important;
      background-color: var(--wikinusa-surface) !important;
      box-shadow: 0 4px 14px rgba(0, 0, 0, 0.08) !important;
      border: 1px solid var(--wikinusa-border) !important;
      box-sizing: border-box !important;
      display: block !important;
      cursor: pointer !important;
    }
    li.gallerybox div.thumb {
      width: 100% !important;
      height: 100% !important;
      margin: 0 !important;
      padding: 0 !important;
      border: none !important;
      background: transparent !important;
      display: block !important;
    }
    li.gallerybox div.thumb > div,
    li.gallerybox div.thumb a,
    li.gallerybox a.mw-file-description {
      width: 100% !important;
      height: 100% !important;
      display: block !important;
      margin: 0 !important;
    }
    li.gallerybox img {
      width: 100% !important;
      height: 100% !important;
      object-fit: cover !important;
      display: block !important;
      border-radius: 0 !important;
      box-shadow: none !important;
      margin: 0 auto !important;
    }
    li.gallerybox div.gallerytext,
    li.gallerybox .gallerytext {
      position: absolute !important;
      bottom: 0 !important;
      left: 0 !important;
      right: 0 !important;
      background: linear-gradient(to bottom, transparent, rgba(0, 0, 0, 0.75) 35%, rgba(0, 0, 0, 0.92)) !important;
      color: #ffffff !important;
      font-size: 11.5px !important;
      font-style: italic !important;
      line-height: 1.4 !important;
      padding: 22px 12px 10px 12px !important;
      margin: 0 !important;
      text-align: center !important;
      max-height: 72px !important;
      overflow: hidden !important;
      text-overflow: ellipsis !important;
      box-sizing: border-box !important;
      pointer-events: none !important;
    }
    li.gallerybox div.gallerytext p,
    li.gallerybox .gallerytext p {
      color: #ffffff !important;
      margin: 0 !important;
      line-height: 1.4 !important;
      display: -webkit-box !important;
      -webkit-line-clamp: 2 !important;
      -webkit-box-orient: vertical !important;
      overflow: hidden !important;
    }
    li.gallerybox div.gallerytext a,
    li.gallerybox .gallerytext a {
      color: #ffffff !important;
      text-decoration: underline !important;
      pointer-events: auto !important;
    }

    /* ==========================================================================
       Data Table Card Presentation & Horizontal Scroll Wrapper
       ========================================================================== */
    .wikinusa-table-card {
      margin: 20px 0 !important;
      border-radius: 14px !important;
      border: 1px solid var(--wikinusa-border) !important;
      background-color: var(--wikinusa-surface) !important;
      box-shadow: 0 3px 10px rgba(0, 0, 0, 0.04) !important;
      overflow: hidden !important;
      box-sizing: border-box !important;
    }
    .wikinusa-table-hint {
      display: flex !important;
      align-items: center !important;
      gap: 8px !important;
      padding: 8px 14px !important;
      background-color: rgba(128, 128, 128, 0.08) !important;
      border-bottom: 1px solid var(--wikinusa-border) !important;
      font-size: 11.5px !important;
      font-weight: 600 !important;
      color: var(--wikinusa-text-secondary) !important;
    }
    .wikinusa-table-hint-icon {
      color: var(--wikinusa-primary) !important;
      font-size: 14px !important;
      font-weight: bold !important;
    }
    .wikinusa-table-scroll-wrapper {
      overflow-x: auto !important;
      -webkit-overflow-scrolling: touch !important;
      padding: 6px !important;
      box-sizing: border-box !important;
    }
    .wikinusa-table-scroll-wrapper table,
    table:not(.infobox):not(.navbox):not(.ambox) {
      border-collapse: collapse !important;
      margin: 0 !important;
      border: none !important;
      box-shadow: none !important;
      border-radius: 0 !important;
      display: table !important;
      width: 100% !important;
      max-width: 100% !important;
      box-sizing: border-box !important;
      background-color: transparent !important;
    }
    .content caption,
    .content table caption,
    .wikinusa-table-scroll-wrapper table caption,
    table:not(.infobox):not(.navbox):not(.ambox) caption {
      display: table-caption !important;
      caption-side: top !important;
      width: 100% !important;
      padding: 10px 14px !important;
      font-weight: 700 !important;
      text-align: center !important;
      color: var(--wikinusa-text) !important;
      background-color: transparent !important;
      box-sizing: border-box !important;
    }
    .infobox caption,
    table.infobox caption {
      display: table-caption !important;
      caption-side: top !important;
      width: 100% !important;
      padding: 10px 12px 6px 12px !important;
      font-weight: 700 !important;
      text-align: center !important;
      box-sizing: border-box !important;
    }
    table:not(.infobox):not(.navbox):not(.ambox) th {
      padding: 10px 14px !important;
      font-weight: 700 !important;
      text-align: left !important;
      background-color: rgba(128, 128, 128, 0.08) !important;
      border: 1px solid var(--wikinusa-border) !important;
    }
    table:not(.infobox):not(.navbox):not(.ambox) td {
      padding: 8px 12px !important;
      border: 1px solid var(--wikinusa-border) !important;
    }

    /* References and Footnotes */
    sup.reference,
    .mw-ref {
      font-size: 0.78em !important;
      vertical-align: super !important;
      padding: 0 2px !important;
    }
    sup.reference a,
    .mw-ref a {
      color: var(--wikinusa-primary) !important;
      font-weight: bold !important;
      padding: 1px 3px !important;
      border-radius: 3px !important;
    }
    /* Hide reference sections and full footnote lists from page scroll */
    .wikinusa-ref-section,
    .reflist,
    .mw-references-wrap,
    ol.references,
    ol.mw-references {
      display: none !important;
    }

    /* Footer */
    .wikinusa-footer {
      margin-top: 48px;
      padding: 32px 16px 120px 16px;
      text-align: center;
      border-top: 1px solid var(--wikinusa-border);
      box-sizing: border-box;
    }
    .wikinusa-footer-spacer {
      max-height: 28px;
      margin: 0 auto 16px auto;
      display: block;
    }
    .wikinusa-footer-title {
      font-family: "Cinzel Decorative", serif;
      font-size: 15px;
      font-weight: 700;
      letter-spacing: 2px;
      color: var(--wikinusa-text-secondary);
      margin-bottom: 16px;
    }
    .wikinusa-footer-text {
      font-size: 11px;
      line-height: 1.6;
      color: var(--wikinusa-text-secondary);
      max-width: 600px;
      margin: 0 auto 16px auto;
    }
    .wikinusa-footer-links {
      display: flex;
      justify-content: center;
      gap: 20px;
      margin-top: 12px;
    }
    .wikinusa-footer-link {
      font-size: 11px;
      font-weight: 700;
      color: var(--wikinusa-primary);
      text-decoration: none;
    }

    /* Search Highlights */
    .wikinusa-search-highlight {
      background-color: #ffe082 !important;
      color: #000000 !important;
      border-radius: 2px;
      padding: 0 2px;
    }
    .wikinusa-search-active {
      background-color: #ff9800 !important;
      color: #ffffff !important;
      font-weight: bold;
    }
  </style>
  <script>
    window.pcsClient = {
      getSetupSettings: function() {
        return JSON.stringify({
          platform: "android",
          theme: "$theme",
          bodyFont: "Plus Jakarta Sans",
          dimImages: true,
          margins: { top: "8px", bottom: "80px" },
          areTablesInitiallyExpanded: false,
          textSizeAdjustmentPercentage: "${(fontSizeScale * 100).round()}%",
          loadImages: true,
          isEditable: false
        });
      },
      onReceiveMessage: function(msg) {
        if (window.pcsBridge) {
          window.pcsBridge.postMessage(msg);
        }
      }
    };

    document.addEventListener('click', function(e) {
      // 1. Gallery box tap: dispatch image event to Flutter ImageScreen
      var galleryBox = e.target.closest('li.gallerybox');
      if (galleryBox) {
        var img = galleryBox.querySelector('img');
        if (img && (e.target.tagName === 'IMG' || e.target.closest('.thumb') || e.target.closest('a'))) {
          e.preventDefault();
          e.stopPropagation();
          var src = img.currentSrc || img.src || img.getAttribute('src') || '';
          var captionEl = galleryBox.querySelector('.gallerytext');
          var caption = captionEl ? captionEl.innerText : '';
          if (window.pcsBridge) {
            window.pcsBridge.postMessage(JSON.stringify({
              action: 'image',
              data: { href: src, title: caption }
            }));
          }
          return;
        }
      }

      // 2. Audio pronunciation links
      var audioTarget = e.target.closest('a[href\$=".ogg"], a[href\$=".mp3"], a[href\$=".wav"], a[href\$=".flac"], .ext-phonos, .audioplayer');
      if (audioTarget) {
        var href = audioTarget.getAttribute('href') || audioTarget.dataset.url || '';
        if (href) {
          e.preventDefault();
          e.stopPropagation();
          if (window.pcsBridge) {
            window.pcsBridge.postMessage(JSON.stringify({
              action: 'audio',
              data: { url: href }
            }));
          }
          return;
        }
      }

      // 3. Footnote / Reference links
      var refAnchor = e.target.closest('sup.reference a, .mw-ref a, a[href*="#cite_note"], a[href*="#cite_ref"]');
      if (refAnchor) {
        var refHref = refAnchor.getAttribute('href') || '';
        if (refHref.indexOf('#') !== -1) {
          e.preventDefault();
          e.stopPropagation();
          var refId = refHref.split('#').pop() || '';
          var decodedRefId = refId;
          try { decodedRefId = decodeURIComponent(refId); } catch (_) {}
          var noteId = decodedRefId.replace('cite_ref-', 'cite_note-');
          var refEl = document.getElementById(decodedRefId) ||
                      document.getElementById(refId) ||
                      document.getElementById(noteId);
          var refHtml = refEl ? refEl.innerHTML : '';
          if (window.pcsBridge) {
            window.pcsBridge.postMessage(JSON.stringify({
              action: 'reference',
              data: { id: decodedRefId || refId, text: refHtml, href: refHref }
            }));
          }
          return;
        }
      }

      // 4. Content image tap (standalone figures, thumbnails, infobox images)
      var tappedImg = e.target.tagName === 'IMG' ? e.target : null;
      var fileLink = e.target.closest('a.mw-file-description, a.image');
      if (!tappedImg && fileLink) {
        tappedImg = fileLink.querySelector('img');
      }
      if (tappedImg &&
          !tappedImg.classList.contains('wiki-inline-icon') &&
          !tappedImg.classList.contains('wikinusa-hero-img') &&
          !tappedImg.classList.contains('wikinusa-footer-spacer')) {
        var inFigureOrInfobox = tappedImg.closest('figure, .thumb, .infobox-image, .wikinusa-infobox-image-cell, .wikinusa-fullwidth-image-container');
        if (inFigureOrInfobox || fileLink) {
          e.preventDefault();
          e.stopPropagation();
          var imgSrc = tappedImg.currentSrc || tappedImg.src || tappedImg.getAttribute('src') || '';
          var figCaption = inFigureOrInfobox ? inFigureOrInfobox.querySelector('figcaption, .thumbcaption, .infobox-caption') : null;
          var imgTitle = figCaption ? figCaption.innerText : (tappedImg.getAttribute('alt') || '');
          if (imgSrc && window.pcsBridge) {
            window.pcsBridge.postMessage(JSON.stringify({
              action: 'image',
              data: { href: imgSrc, title: imgTitle }
            }));
          }
          return;
        }
      }

      // 5. General anchor links (internal wiki links, red links, same-page anchors, external links)
      var link = e.target.closest('a, area');
      if (link) {
        var rawHref = link.getAttribute('href') || '';
        if (!rawHref) return;
        if (rawHref.charAt(0) === '#') {
          e.preventDefault();
          e.stopPropagation();
          var anchorId = rawHref.slice(1);
          var decodedAnchorId = anchorId;
          try { decodedAnchorId = decodeURIComponent(anchorId); } catch (_) {}
          var targetEl = document.getElementById(decodedAnchorId) || document.getElementById(anchorId);
          if (targetEl) {
            targetEl.scrollIntoView({ behavior: 'smooth', block: 'start' });
          }
          return;
        }
        e.preventDefault();
        e.stopPropagation();
        if (window.pcsBridge) {
          window.pcsBridge.postMessage(JSON.stringify({
            action: 'link',
            data: {
              href: rawHref,
              title: link.getAttribute('title') || ''
            }
          }));
        }
      }
    }, true);

    window.WikiNusaSearch = {
      matches: [],
      currentIndex: -1,
      clear: function() {
        var highlights = document.querySelectorAll('.wikinusa-search-highlight');
        for (var i = 0; i < highlights.length; i++) {
          var el = highlights[i];
          var parent = el.parentNode;
          if (parent) {
            parent.replaceChild(document.createTextNode(el.textContent), el);
            parent.normalize();
          }
        }
        this.matches = [];
        this.currentIndex = -1;
      },
      find: function(query) {
        this.clear();
        if (!query || query.trim() === '') return 0;
        var cleanQuery = query.toLowerCase();
        var content = document.getElementById('content') || document.body;
        var walker = document.createTreeWalker(content, NodeFilter.SHOW_TEXT, null, false);
        var nodesToReplace = [];
        var node;
        while (node = walker.nextNode()) {
          if (node.parentElement && (
              node.parentElement.tagName === 'SCRIPT' || 
              node.parentElement.tagName === 'STYLE' ||
              node.parentElement.classList.contains('wikinusa-search-highlight'))) {
            continue;
          }
          if (node.nodeValue.toLowerCase().indexOf(cleanQuery) !== -1) {
            nodesToReplace.push(node);
          }
        }

        for (var n = 0; n < nodesToReplace.length; n++) {
          var textNode = nodesToReplace[n];
          var parent = textNode.parentNode;
          if (!parent) continue;
          var text = textNode.nodeValue;
          var frag = document.createDocumentFragment();
          var lastIdx = 0;
          var lowerText = text.toLowerCase();
          var idx = lowerText.indexOf(cleanQuery);

          while (idx !== -1) {
            if (idx > lastIdx) {
              frag.appendChild(document.createTextNode(text.substring(lastIdx, idx)));
            }
            var span = document.createElement('span');
            span.className = 'wikinusa-search-highlight';
            span.textContent = text.substring(idx, idx + cleanQuery.length);
            this.matches.push(span);
            frag.appendChild(span);
            lastIdx = idx + cleanQuery.length;
            idx = lowerText.indexOf(cleanQuery, lastIdx);
          }
          if (lastIdx < text.length) {
            frag.appendChild(document.createTextNode(text.substring(lastIdx)));
          }
          parent.replaceChild(frag, textNode);
        }

        if (this.matches.length > 0) {
          this.jump(0);
        }
        return this.matches.length;
      },
      jump: function(index) {
        if (this.matches.length === 0) return -1;
        if (this.currentIndex >= 0 && this.currentIndex < this.matches.length) {
          this.matches[this.currentIndex].classList.remove('wikinusa-search-active');
        }
        this.currentIndex = (index + this.matches.length) % this.matches.length;
        var current = this.matches[this.currentIndex];
        current.classList.add('wikinusa-search-active');
        current.scrollIntoView({ behavior: 'smooth', block: 'center' });
        return this.currentIndex;
      },
      next: function() {
        return this.jump(this.currentIndex + 1);
      },
      prev: function() {
        return this.jump(this.currentIndex - 1);
      }
    };
  </script>
  ${pcsJsContent.isNotEmpty ? '<script id="pcs-js">$pcsJsContent</script>' : '<script src="https://meta.wikimedia.org/api/rest_v1/data/javascript/mobile/pcs"></script>'}
</head>
<body class="pcs-theme-$theme">
  $heroHeaderHtml
  <div id="content" class="pcs-content content">
    $parsoidHtml
    $footerHtml
  </div>
</body>
</html>
''';
  }

  void _handlePcsMessage(String rawJson) {
    try {
      final Map<String, dynamic> payload = jsonDecode(rawJson);
      final String action = payload['action'] ?? '';
      final Map<String, dynamic>? data =
          payload['data'] is Map ? payload['data'] : null;

      switch (action) {
        case 'final_setup':
          if (mounted) setState(() => _isLoading = false);
          widget.onSetupFinished?.call();
          break;
        case 'link':
          final href = data?['href']?.toString() ?? '';
          final title = data?['title']?.toString();
          if (href.contains('#cite_note') || href.contains('#cite_ref')) {
            final refId = href.split('#').last;
            widget.onReferenceClicked(refId, '');
            break;
          }
          widget.onLinkClicked(href, title);
          break;
        case 'reference':
          String refId = data?['id']?.toString() ?? '';
          String refHtml = data?['text']?.toString() ?? '';
          final group = data?['referencesGroup'];
          if (group is List && group.isNotEmpty) {
            final idx = (data?['selectedIndex'] as num?)?.toInt() ?? 0;
            final item =
                (idx >= 0 && idx < group.length) ? group[idx] : group.first;
            if (item is Map) {
              if (item['id'] != null) refId = item['id'].toString();
              if (item['html'] != null &&
                  item['html'].toString().isNotEmpty) {
                refHtml = item['html'].toString();
              } else if (item['text'] != null) {
                refHtml = item['text'].toString();
              }
            }
          }
          if (refId.isEmpty && data?['href'] != null) {
            final href = data!['href'].toString();
            if (href.contains('#')) {
              refId = href.split('#').last;
            }
          }
          widget.onReferenceClicked(refId, refHtml);
          break;
        case 'image':
        case 'media':
          final src = data?['href']?.toString() ?? '';
          final title = data?['title']?.toString();
          widget.onImageClicked(src, title);
          break;
        case 'pronunciation':
        case 'audio':
          final audioUrl = data?['url']?.toString() ??
              data?['href']?.toString() ??
              data?['src']?.toString() ??
              '';
          if (audioUrl.isNotEmpty) {
            widget.onLinkClicked(audioUrl, null);
          }
          break;
      }
    } catch (e) {
      debugPrint('PCS message parse error: $e');
    }
  }

  Future<void> setTheme(String theme) async {
    final isDark = theme == 'dark' || theme == 'black';
    _webViewController.setBackgroundColor(
      isDark ? const Color(0xFF121212) : Colors.white,
    );
    await _webViewController.runJavaScript(
      "if (window.pcs && pcs.c1 && pcs.c1.Page) { pcs.c1.Page.setTheme('$theme'); } document.body.className = 'pcs-theme-$theme';",
    );
  }

  Future<void> setTextSize(int percent) async {
    final scale = percent / 100.0;
    final px = (16.0 * (scale / 1.15)).toStringAsFixed(1);
    await _webViewController.runJavaScript(
      "if (window.pcs && pcs.c1 && pcs.c1.Page) { pcs.c1.Page.setTextSizeAdjustment('$percent%'); } document.body.style.fontSize = '${px}px';",
    );
  }

  Future<int> search(String query) async {
    final escapedQuery = jsonEncode(query);
    final result = await _webViewController.runJavaScriptReturningResult(
      'window.WikiNusaSearch ? window.WikiNusaSearch.find($escapedQuery) : 0;',
    );
    if (result is num) return result.toInt();
    if (result is String) return int.tryParse(result) ?? 0;
    return 0;
  }

  Future<int> nextMatch() async {
    final result = await _webViewController.runJavaScriptReturningResult(
      'window.WikiNusaSearch ? window.WikiNusaSearch.next() : -1;',
    );
    if (result is num) return result.toInt();
    if (result is String) return int.tryParse(result) ?? -1;
    return -1;
  }

  Future<int> previousMatch() async {
    final result = await _webViewController.runJavaScriptReturningResult(
      'window.WikiNusaSearch ? window.WikiNusaSearch.prev() : -1;',
    );
    if (result is num) return result.toInt();
    if (result is String) return int.tryParse(result) ?? -1;
    return -1;
  }

  Future<void> clearSearch() async {
    await _webViewController.runJavaScript(
      'if (window.WikiNusaSearch) { window.WikiNusaSearch.clear(); }',
    );
  }

  Future<void> expandOrCollapseTables(bool expand) async {
    await _webViewController.runJavaScript(
      'if (window.pcs && pcs.c1 && pcs.c1.Page) { pcs.c1.Page.expandOrCollapseTables($expand); }',
    );
  }

  Future<String> getTableOfContents() async {
    final result = await _webViewController.runJavaScriptReturningResult(
      'if (window.pcs && pcs.c1 && pcs.c1.Page) { JSON.stringify(pcs.c1.Page.getTableOfContents()); } else { "[]"; }',
    );
    return result.toString();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: [
          WebViewWidget(controller: _webViewController),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
