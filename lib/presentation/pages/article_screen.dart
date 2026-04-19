import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:wikinusa/presentation/pages/create_page_screen.dart';
import 'package:wikinusa/presentation/pages/gallery_carousel_screen.dart';
import 'package:wikinusa/presentation/pages/image_screen.dart';
import 'package:wikinusa/presentation/widgets/wiki_footer.dart';
import 'package:wikinusa/presentation/widgets/custom_bottom_nav_bar.dart';
import 'package:wikinusa/presentation/widgets/custom_drawer.dart';
import 'package:wikinusa/presentation/providers/article_provider.dart';
import 'package:wikinusa/presentation/providers/language_provider.dart';
import 'package:wikinusa/presentation/providers/project_provider.dart';
import 'package:wikinusa/presentation/providers/html_rules_provider.dart';
import 'package:wikinusa/presentation/providers/bookmarks_provider.dart';
import 'package:wikinusa/domain/entities/article.dart';
import 'package:wikinusa/domain/entities/wiki_project.dart';
import 'package:wikinusa/core/theme_config.dart';

class ArticleImageMetadata {
  final Map<String, String>? hero;
  final List<Map<String, String>> bottomCarousel;
  final List<String> usedInGalleries;

  ArticleImageMetadata({
    this.hero,
    required this.bottomCarousel,
    required this.usedInGalleries,
  });
}

class ArticleScreen extends ConsumerStatefulWidget {
  final String pageTitle;

  const ArticleScreen({super.key, required this.pageTitle});

  static Future<void> handleWikipediaLink(
    BuildContext context,
    WidgetRef ref,
    String? url,
    String langCode,
  ) async {
    if (url == null || url.isEmpty) return;

    try {
      String absoluteUrl = url;
      if (url.startsWith('./')) {
        absoluteUrl = 'https://$langCode.wikipedia.org/wiki/${url.substring(2)}';
      } else if (url.startsWith('/')) {
        absoluteUrl = 'https://$langCode.wikipedia.org$url';
      } else if (url.startsWith('//')) {
        absoluteUrl = 'https:$url';
      }

      final uri = Uri.parse(Uri.encodeFull(absoluteUrl));
      final isMainWiki = uri.host == '$langCode.wikipedia.org' || uri.host.isEmpty;
      final isRedLink = uri.queryParameters['action'] == 'edit';

      String? extractedTitle;
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 2 && pathSegments[0] == 'wiki') {
        extractedTitle = pathSegments[1].replaceAll('_', ' ');
      }

      if (isRedLink && extractedTitle != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CreatePageScreen(initialTitle: extractedTitle)),
        );
        return;
      }

      bool isSpecialPage = false;
      if (extractedTitle != null) {
        final lowerTitle = extractedTitle.toLowerCase();
        isSpecialPage = lowerTitle.startsWith('special:') ||
            lowerTitle.startsWith('spesial:') ||
            lowerTitle.startsWith('mirunggan:') ||
            lowerTitle.startsWith('istimewa:') ||
            lowerTitle.startsWith('istimiwa:') ||
            lowerTitle.startsWith('istimèwa:') ||
            lowerTitle.startsWith('khas:') ||
            lowerTitle.startsWith('husus:');
      }

      if (isSpecialPage && extractedTitle != null) {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        return;
      }

      if (extractedTitle != null && isMainWiki && !isRedLink && !isSpecialPage) {
        ref.read(articleNavigationProvider.notifier).pushArticle(extractedTitle);
        final currentRoute = ModalRoute.of(context);
        final isAlreadyOnArticleScreen = currentRoute?.settings.name == 'ArticleScreen' ||
            (currentRoute is MaterialPageRoute && currentRoute.builder(context) is ArticleScreen);

        if (!isAlreadyOnArticleScreen) {
          Navigator.push(
            context,
            MaterialPageRoute(
              settings: const RouteSettings(name: 'ArticleScreen'),
              builder: (_) => ArticleScreen(pageTitle: extractedTitle!),
            ),
          );
        }
      } else {
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      }
    } catch (e) {
      debugPrint('${'link_handling_error'.tr()}: $e');
      try {
        final fallbackUri = Uri.parse(Uri.encodeFull(url));
        await launchUrl(fallbackUri, mode: LaunchMode.inAppBrowserView);
      } catch (_) {}
    }
  }

  @override
  ConsumerState<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends ConsumerState<ArticleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = ref.read(articleNavigationProvider);
      if (nav.pageTitles.isEmpty) {
        ref.read(articleNavigationProvider.notifier).setArticles([widget.pageTitle], 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentProject = ref.watch(projectProvider);
    
    // Dynamically update the theme based on the current project
    final projectTheme = Theme.of(context).copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: currentProject.seedColor,
        brightness: Theme.of(context).brightness,
      ),
    );

    final navState = ref.watch(articleNavigationProvider);
    final currentTitle = navState.currentTitle ?? widget.pageTitle;
    final rulesAsync = ref.watch(htmlRulesProvider);
    final langCode = ref.watch(languageProvider).code;

    final String pageUrl = 'https://$langCode.${currentProject.domain}/wiki/${currentTitle.replaceAll(' ', '_')}';

    return Theme(
      data: projectTheme,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;
          if (navState.canGoBack) {
            ref.read(articleNavigationProvider.notifier).previous();
            return;
          }
          bool movedBack = false;
          Navigator.popUntil(context, (route) {
            if (route.settings.name == 'SearchResultsScreen') {
              movedBack = true;
              return true;
            }
            if (route.isFirst) return true;
            return false;
          });
          if (!movedBack) Navigator.of(context).pop();
        },
        child: Scaffold(
          backgroundColor: projectTheme.colorScheme.surface,
          drawer: const CustomDrawer(),
          body: ref.watch(articleDetailProvider(currentTitle)).when(
                data: (article) => rulesAsync.when(
                  data: (rules) {
                    final metadata = _extractMetadata(article.text, langCode, rules);
                    return Stack(
                      children: [
                        SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeroImage(projectTheme, article, metadata.hero, currentProject),
                              _buildArticleContent(projectTheme, article, langCode, rules),
                              if (metadata.bottomCarousel.isNotEmpty) ...[
                                const SizedBox(height: 32),
                                _buildImageCarousel(projectTheme, metadata.bottomCarousel),
                              ],
                              const WikiFooter(),
                              const SizedBox(height: 70),
                            ],
                          ),
                        ),
                        _buildFloatingActionBar(projectTheme, navState, pageUrl, currentTitle, langCode),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => _buildErrorContent(projectTheme, article, navState, pageUrl, currentTitle, langCode, rulesAsync.value ?? {}, currentProject),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('${'error'.tr()}: $err')),
              ),
          bottomNavigationBar: const CustomBottomNavBar(),
        ),
      ),
    );
  }

  Widget _buildErrorContent(
    ThemeData theme,
    Article article,
    ArticleNavigationState navState,
    String pageUrl,
    String title,
    String langCode,
    Map<String, dynamic> rules,
    WikiProject project,
  ) {
    final metadata = _extractMetadata(article.text, langCode, rules);
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroImage(theme, article, metadata.hero, project),
              _buildArticleContent(theme, article, '', {}),
              const SizedBox(height: 100),
            ],
          ),
        ),
        _buildFloatingActionBar(theme, navState, pageUrl, title, langCode),
      ],
    );
  }

  ArticleImageMetadata _extractMetadata(String html, String langCode, Map<String, dynamic> rules) {
    final doc = html_parser.parse(html);
    final List<Map<String, String>> allImages = [];
    final List<String> usedInGalleries = [];
    final galleries = doc.querySelectorAll('.gallery');
    for (var gallery in galleries) {
      final galleryImages = _extractImagesFromElement(gallery);
      usedInGalleries.addAll(galleryImages.map((e) => e['url']!));
    }
    doc.querySelectorAll('figure, .thumb, .mw-file-description, img').forEach((element) {
      final images = _extractImagesFromElement(element);
      for (var img in images) {
        final url = img['url'] ?? '';
        final isMap = url.contains('maps.wikimedia.org');
        final isDuplicate = allImages.any((existing) => existing['url'] == url);
        if (!isMap && !isDuplicate) allImages.add(img);
      }
    });
    Map<String, String>? hero;
    if (galleries.isNotEmpty) {
      final firstGalleryImages = _extractImagesFromElement(galleries.first);
      if (firstGalleryImages.isNotEmpty) hero = firstGalleryImages.first;
    }
    if (hero == null) {
      for (var img in allImages) {
        final url = img['url'] ?? '';
        final isIcon = url.contains('/icon/') || url.contains('/Symbol_') || url.contains('.svg') || url.contains('maps') || url.contains('/favicon');
        if (!isIcon) {
          hero = img;
          break;
        }
      }
    }
    final bottomCarousel = allImages.where((img) {
      final isHero = img['url'] == hero?['url'];
      final isInGallery = usedInGalleries.contains(img['url']);
      return !isHero && !isInGallery;
    }).toList();
    return ArticleImageMetadata(hero: hero, bottomCarousel: bottomCarousel, usedInGalleries: usedInGalleries);
  }

  List<Map<String, String>> _extractImagesFromElement(dom.Element element) {
    final List<Map<String, String>> found = [];
    final imgElements = element.localName == 'img' ? [element] : element.querySelectorAll('img');
    for (var img in imgElements) {
      String? src = img.attributes['src'] ?? img.attributes['data-src'];
      if (src != null && src.isNotEmpty) {
        if (src.startsWith('//')) src = 'https:$src';
        final widthStr = img.attributes['width'];
        if (widthStr != null) {
          final width = int.tryParse(widthStr);
          if (width != null && width < 100) continue;
        }
        dom.Element container = element;
        dom.Element? parent = img.parent;
        while (parent != null && parent != element.parent) {
          if (parent.classes.contains('thumbinner') || parent.classes.contains('gallerybox')) {
            container = parent;
            break;
          }
          parent = parent.parent;
        }
        final captionElement = container.querySelector('.thumbcaption') ?? container.querySelector('.gallerytext') ?? container.querySelector('figcaption');
        found.add({'url': src, 'caption': captionElement?.text.trim() ?? ''});
      }
    }
    return found;
  }

  Widget _buildImageCarousel(ThemeData theme, List<Map<String, String>> images) {
    final List<String> galleryUrls = images.map((img) => img['url'] ?? '').where((url) => url.isNotEmpty).toList();
    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          final imageUrl = images[index]['url'] ?? '';
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => GalleryCarouselScreen(galleryImages: galleryUrls))),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              width: 300,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroImage(ThemeData theme, Article article, Map<String, String>? heroData, WikiProject project) {
    final imageUrl = heroData?['url'];
    
    // Project-specific fallback images
    String fallbackAsset;
    switch (project) {
      case WikiProject.wiktionary:
        fallbackAsset = 'assets/images/sappho-fresco.webp';
        break;
      case WikiProject.wikibooks:
        fallbackAsset = 'assets/images/wajah-nias.webp';
        break;
      default:
        fallbackAsset = 'assets/images/woman_reading_a_book_on_lap.webp';
    }

    return Stack(
      children: [
        Container(
          height: 350,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: imageUrl != null ? NetworkImage(imageUrl) : AssetImage(fallbackAsset) as ImageProvider,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, theme.colorScheme.surface.withValues(alpha: 0.7), theme.colorScheme.surface],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.4, 0.85, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 24,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                article.title,
                style: theme.textTheme.displayLarge?.copyWith(fontSize: 32, fontWeight: FontWeight.w800, height: 1.1, color: theme.colorScheme.primary, letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.colorScheme.secondary, borderRadius: BorderRadius.circular(2))),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Consumer(
              builder: (context, ref, child) {
                final navState = ref.watch(articleNavigationProvider);
                return CircleAvatar(
                  backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.5),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: theme.colorScheme.primary),
                    onPressed: () {
                      if (navState.canGoBack) {
                        ref.read(articleNavigationProvider.notifier).previous();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showReferencePopup(BuildContext context, String referenceId, String htmlContent, String langCode) {
    final theme = Theme.of(context);
    final document = html_parser.parse(htmlContent);
    final decodedId = Uri.decodeComponent(referenceId);
    final refElement = document.getElementById(decodedId) ?? document.getElementById(referenceId);
    if (refElement == null) return;
    refElement.querySelectorAll('.mw-cite-backlink').forEach((e) => e.remove());
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
            Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: theme.colorScheme.secondary),
                const SizedBox(width: 8),
                Text('reference'.tr(), style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.secondary, letterSpacing: 1.1)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            Flexible(
              child: SingleChildScrollView(
                child: HtmlWidget(
                  refElement.innerHtml,
                  onTapUrl: (url) {
                    ArticleScreen.handleWikipediaLink(context, ref, url, langCode);
                    return true;
                  },
                  textStyle: theme.textTheme.bodyMedium?.copyWith(fontSize: 14, height: 1.6, color: theme.colorScheme.onSurface),
                  customStylesBuilder: (element) {
                    if (element.localName == 'sup' || element.classes.contains('reference')) return {'display': 'inline', 'font-size': '0.75em', 'vertical-align': 'super', 'line-height': '0'};
                    if (element.localName == 'a') return {'color': '#${theme.colorScheme.primary.toARGB32().toRadixString(16).substring(2)}', 'text-decoration': 'none'};
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleContent(ThemeData theme, Article article, String langCode, Map<String, dynamic> rules) {
    final langRules = rules[langCode] ?? {};
    final globalRules = rules['global'] ?? {};
    final List<String> toRemoveSelectors = [...(globalRules['remove'] as List<dynamic>? ?? []), ...(langRules['remove'] as List<dynamic>? ?? []), '.reflist', '.references', '.mw-references-wrap', '.navbox', 'table', '.sidebar'].map((e) => e.toString()).toList();
    final List<String> toHideSelectors = [...(globalRules['hide'] as List<dynamic>? ?? []), ...(langRules['hide'] as List<dynamic>? ?? []), 'img', 'figure', '.thumb'].map((e) => e.toString()).toList();
    final List<String> referenceKeywords = [...(globalRules['referenceKeywords'] as List<dynamic>? ?? []), ...(langRules['referenceKeywords'] as List<dynamic>? ?? []), 'reference', 'catatan kaki', 'rujukan'].map((e) => e.toString()).toList();
    final doc = html_parser.parse(article.text);
    if (toRemoveSelectors.isNotEmpty) doc.querySelectorAll(toRemoveSelectors.join(', ')).forEach((e) => e.remove());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: HtmlWidget(
            doc.body?.innerHtml ?? article.text,
            onTapUrl: (url) {
              if (url.contains('cite_note')) {
                final refId = url.split('#').last;
                _showReferencePopup(context, refId, article.text, langCode);
                return true;
              }
              ArticleScreen.handleWikipediaLink(context, ref, url, langCode);
              return true;
            },
            textStyle: theme.textTheme.bodyLarge?.copyWith(
              fontFamily: (langCode == 'jv') ? GoogleFonts.notoSansJavanese().fontFamily : GoogleFonts.notoSerif().fontFamily,
              height: 1.8,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
            ),
            customStylesBuilder: (element) {
              final lowerText = element.text.toLowerCase();
              if (element.localName == 'sup' || element.classes.contains('reference')) return {'display': 'inline', 'font-size': '0.75em', 'vertical-align': 'super', 'line-height': '0'};
              if (element.localName == 'a') {
                final href = element.attributes['href'] ?? '';
                if (href.contains('action=edit') || element.classes.contains('new')) return {'color': '#a77364', 'text-decoration': 'none'};
              }
              if (element.localName?.startsWith('h') == true && referenceKeywords.any((k) => lowerText.contains(k.toLowerCase()))) return {'display': 'none'};
              if (toHideSelectors.any((s) => element.classes.contains(s.replaceFirst('.', '')) || element.localName == s)) return {'display': 'none'};
              if (element.localName == 'a') return {'color': '#${theme.colorScheme.primary.toARGB32().toRadixString(16).substring(2)}', 'text-decoration': 'none', 'font-weight': '600'};
              final langAttr = element.attributes['lang'];
              if (langAttr == 'jv') return {'font-family': 'Noto Sans Javanese'};
              if (langAttr == 'ar') return {'font-family': 'Noto Sans Arabic', 'direction': 'rtl'};
              if (element.classes.contains('new')) return {'color': '#${WikinusaThemeConfig.getLinkRed(theme.brightness).toARGB32().toRadixString(16).substring(2)}'};
              return null;
            },
            customWidgetBuilder: (element) {
              if (element.classes.contains('gallery')) {
                final images = _extractImagesFromElement(element);
                if (images.isNotEmpty) return Padding(padding: const EdgeInsets.symmetric(vertical: 24.0), child: _buildImageCarousel(theme, images));
              }
              if (element.localName?.startsWith('h') == true) {
                final text = element.text;
                final lowerText = text.toLowerCase();
                if (referenceKeywords.any((k) => lowerText.contains(k.toLowerCase()))) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(text, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: theme.textTheme.bodyLarge?.fontFamily)),
                      const SizedBox(height: 4),
                      Container(width: 30, height: 2, decoration: BoxDecoration(color: theme.colorScheme.secondary, borderRadius: BorderRadius.circular(1))),
                    ],
                  ),
                );
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionBar(ThemeData theme, ArticleNavigationState navState, String pageUrl, String currentTitle, String langCode) {
    final isBookmarked = ref.watch(bookmarksProvider).any((b) => b.title == currentTitle && b.langCode == langCode);
    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(color: theme.colorScheme.surface, borderRadius: BorderRadius.circular(32), border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 8))]),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionButton(theme, Icons.arrow_back_ios_new, navState.canGoBack ? theme.colorScheme.primary : Colors.grey.withValues(alpha: 0.5), onPressed: navState.canGoBack ? () => ref.read(articleNavigationProvider.notifier).previous() : null),
              _buildDivider(theme),
              _buildActionButton(theme, isBookmarked ? Icons.bookmark : Icons.bookmark_border, isBookmarked ? theme.colorScheme.primary : theme.colorScheme.onSurface, onPressed: () {
                ref.read(bookmarksProvider.notifier).toggleBookmark(currentTitle, langCode);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isBookmarked ? 'bookmarks_removed'.tr() : 'bookmarks_added'.tr()), duration: const Duration(seconds: 1)));
              }),
              _buildDivider(theme),
              _buildActionButton(theme, Icons.share_outlined, theme.colorScheme.onSurface, onPressed: () => SharePlus.instance.share(ShareParams(uri: Uri.parse(pageUrl)))),
              _buildDivider(theme),
              _buildActionButton(theme, Icons.edit_outlined, theme.colorScheme.onSurface, onPressed: () async {
                final uri = Uri.parse('$pageUrl?action=edit&section=all');
                try { await launchUrl(uri, mode: LaunchMode.inAppBrowserView); } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('editor_cant_open').tr())); }
              }),
              _buildDivider(theme),
              _buildActionButton(theme, Icons.visibility_outlined, theme.colorScheme.onSurface, onPressed: () async {
                final uri = Uri.parse(pageUrl);
                try { await launchUrl(uri, mode: LaunchMode.inAppBrowserView); } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('page_cant_open').tr())); }
              }),
              _buildDivider(theme),
              _buildActionButton(theme, Icons.arrow_forward_ios, navState.canGoForward ? theme.colorScheme.primary : Colors.grey.withValues(alpha: 0.5), onPressed: navState.canGoForward ? () => ref.read(articleNavigationProvider.notifier).next() : null),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(ThemeData theme, IconData icon, Color color, {VoidCallback? onPressed}) {
    return Material(color: Colors.transparent, child: InkWell(onTap: onPressed, borderRadius: BorderRadius.circular(24), child: Padding(padding: const EdgeInsets.all(10.0), child: Icon(icon, color: color, size: 18))));
  }

  Widget _buildDivider(ThemeData theme) {
    return Container(height: 20, width: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5), margin: const EdgeInsets.symmetric(horizontal: 4));
  }
}
