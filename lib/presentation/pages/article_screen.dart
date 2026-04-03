import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wikinusa/presentation/pages/create_page_screen.dart';
import 'package:wikinusa/presentation/widgets/wikinusa_footer.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/custom_drawer.dart';
import '../providers/article_provider.dart';
import '../providers/language_provider.dart';
import '../providers/html_rules_provider.dart';
import '../providers/bookmarks_provider.dart';
import '../../domain/entities/article.dart';
import '../../core/theme_config.dart';

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
      // Normalize the URL structure
      String absoluteUrl = url;
      if (url.startsWith('./')) {
        absoluteUrl =
            'https://$langCode.wikipedia.org/wiki/${url.substring(2)}';
      } else if (url.startsWith('/')) {
        absoluteUrl = 'https://$langCode.wikipedia.org$url';
      } else if (url.startsWith('//')) {
        absoluteUrl = 'https:$url';
      }

      // Safely encode the URL to handle non-ASCII chars (ö, ŵ)
      final uri = Uri.parse(Uri.encodeFull(absoluteUrl));

      final isMainWiki =
          uri.host == '$langCode.wikipedia.org' || uri.host.isEmpty;
      final isRedLink = uri.queryParameters['action'] == 'edit';

      String? extractedTitle;
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 2 && pathSegments[0] == 'wiki') {
        extractedTitle = pathSegments[1].replaceAll('_', ' ');
      }

      if (isRedLink && extractedTitle != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreatePageScreen(initialTitle: extractedTitle),
          ),
        );
        return;
      }

      // Determine if it's a "Special" page
      bool isSpecialPage = false;
      if (extractedTitle != null) {
        final lowerTitle = extractedTitle.toLowerCase();
        isSpecialPage =
            lowerTitle.startsWith('special:') ||
            lowerTitle.startsWith('spesial:') ||
            lowerTitle.startsWith('istimewa:');
      }

      // 5. Routing Logic
      if (extractedTitle != null &&
          isMainWiki &&
          !isRedLink &&
          !isSpecialPage) {
        // Internal Nav: Open natively in ArticleScreen
        ref
            .read(articleNavigationProvider.notifier)
            .pushArticle(extractedTitle);

        final currentRoute = ModalRoute.of(context);
        final isAlreadyOnArticleScreen =
            currentRoute?.settings.name == 'ArticleScreen' ||
            (currentRoute is MaterialPageRoute &&
                currentRoute.builder(context) is ArticleScreen);

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
        // Everything else: Open in in-app browser
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      }
    } catch (e) {
      debugPrint('Link handling error: $e');
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
        ref.read(articleNavigationProvider.notifier).setArticles([
          widget.pageTitle,
        ], 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navState = ref.watch(articleNavigationProvider);
    final currentTitle = navState.currentTitle ?? widget.pageTitle;
    final rulesAsync = ref.watch(htmlRulesProvider);
    final langCode = ref.watch(languageProvider).code;

    final String pageUrl =
        'https://$langCode.wikipedia.org/wiki/${currentTitle.replaceAll(' ', '_')}';

    return PopScope(
      canPop: !navState.canGoBack,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (navState.canGoBack) {
          ref.read(articleNavigationProvider.notifier).previous();
        }
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        drawer: const CustomDrawer(),
        body: ref
            .watch(articleDetailProvider(currentTitle))
            .when(
              data: (article) => rulesAsync.when(
                data: (rules) {
                  final images = _extractImages(article.text, langCode, rules);
                  return Stack(
                    children: [
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeroImage(
                              theme,
                              article,
                              langCode,
                              rules,
                              navState,
                            ),
                            _buildArticleContent(
                              theme,
                              article,
                              langCode,
                              rules,
                            ),
                            if (images.isNotEmpty) ...[
                              const SizedBox(height: 32),
                              _buildImageCarousel(theme, images),
                            ],
                            const WikinusaFooter(),
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                      _buildFloatingActionBar(
                        theme,
                        navState,
                        pageUrl,
                        currentTitle,
                        langCode,
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => _buildErrorContent(
                  theme,
                  article,
                  navState,
                  pageUrl,
                  currentTitle,
                  langCode,
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('${'error'.tr()}: $err')),
            ),
        bottomNavigationBar: const CustomBottomNavBar(),
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
  ) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroImage(theme, article, '', {}, navState),
              _buildArticleContent(theme, article, '', {}),
              const SizedBox(height: 100),
            ],
          ),
        ),
        _buildFloatingActionBar(theme, navState, pageUrl, title, langCode),
      ],
    );
  }

  List<Map<String, String>> _extractImages(
    String html,
    String langCode,
    Map<String, dynamic> rules,
  ) {
    final doc = html_parser.parse(html);

    final langRules = rules[langCode] ?? {};
    final globalRules = rules['global'] ?? {};

    final List<String> toRemoveSelectors = [
      ...(globalRules['remove'] as List<dynamic>? ?? []),
      ...(langRules['remove'] as List<dynamic>? ?? []),
      'table',
      '.sidebar',
      '.vertical-navbox',
    ].map((e) => e.toString()).toList();

    if (toRemoveSelectors.isNotEmpty) {
      doc
          .querySelectorAll(toRemoveSelectors.join(', '))
          .forEach((e) => e.remove());
    }

    final List<Map<String, String>> images = [];

    doc
        .querySelectorAll(
          'figure, .thumb, .thumbinner, .gallerybox, .mw-file-description',
        )
        .forEach((element) {
          final img = element.querySelector('img');
          final caption =
              element.querySelector('figcaption') ??
              element.querySelector('.thumbcaption') ??
              element.querySelector('.gallerytext');

          if (img != null) {
            String? src = img.attributes['src'];
            if (src != null && src.isNotEmpty) {
              if (src.startsWith('//')) src = 'https:$src';

              if (!images.any((item) => item['url'] == src)) {
                images.add({'url': src, 'caption': caption?.text.trim() ?? ''});
              }
            }
          }
        });

    return images;
  }

  Widget _buildImageCarousel(
    ThemeData theme,
    List<Map<String, String>> images,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'gallery'.tr(),
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: images.length,
            itemBuilder: (context, index) {
              final image = images[index];
              return Container(
                width: 300,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          image['url']!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (ctx, err, stack) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                    ),
                    if (image['caption']!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 8,
                          left: 4,
                          right: 4,
                        ),
                        child: Text(
                          image['caption']!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            fontSize: 10,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeroImage(
    ThemeData theme,
    Article article,
    String langCode,
    Map<String, dynamic> rules,
    ArticleNavigationState navState,
  ) {
    final doc = html_parser.parse(article.text);
    final tempBody = doc.body;

    final langRules = rules[langCode] ?? {};
    final globalRules = rules['global'] ?? {};

    final List<String> toRemoveSelectors = [
      ...(globalRules['remove'] as List<dynamic>? ?? []),
      ...(langRules['remove'] as List<dynamic>? ?? []),
    ].map((e) => e.toString()).toList();

    if (toRemoveSelectors.isNotEmpty) {
      tempBody
          ?.querySelectorAll(toRemoveSelectors.join(', '))
          .forEach((e) => e.remove());
    }

    final imgElement = tempBody?.querySelector('img');
    String? imageUrl =
        imgElement?.attributes['src'] ??
        doc.querySelector('img')?.attributes['src'];

    if (imageUrl != null && imageUrl.startsWith('//')) {
      imageUrl = 'https:$imageUrl';
    }

    return Stack(
      children: [
        Container(
          height: 350,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: imageUrl != null
                  ? NetworkImage(imageUrl)
                  : const AssetImage(
                      'assets/images/woman_reading_a_book_on_lap.webp',
                    ),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  theme.colorScheme.surface.withValues(alpha: 0.7),
                  theme.colorScheme.surface,
                ],
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
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  color: theme.colorScheme.primary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
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
            ),
          ),
        ),
      ],
    );
  }

  void _showReferencePopup(
    BuildContext context,
    String referenceId,
    String htmlContent,
    String langCode,
  ) {
    final theme = Theme.of(context);
    final document = html_parser.parse(htmlContent);

    // Wikipedia reference IDs might be URI encoded
    final decodedId = Uri.decodeComponent(referenceId);
    final refElement =
        document.getElementById(decodedId) ??
        document.getElementById(referenceId);

    if (refElement == null) {
      debugPrint('Reference element not found: $referenceId');
      return;
    }

    // Remove backlink arrows commonly found in Wikipedia references
    refElement.querySelectorAll('.mw-cite-backlink').forEach((e) => e.remove());

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'reference'.tr(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                    letterSpacing: 1.1,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Flexible(
              child: SingleChildScrollView(
                child: HtmlWidget(
                  refElement.innerHtml,
                  onTapUrl: (url) {
                    ArticleScreen.handleWikipediaLink(
                      context,
                      ref,
                      url,
                      langCode,
                    );
                    return true;
                  },
                  textStyle: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    height: 1.6,
                    color: theme.colorScheme.onSurface,
                  ),
                  customStylesBuilder: (element) {
                    if (element.localName == 'a') {
                      return {
                        'color':
                            '#${theme.colorScheme.primary.toARGB32().toRadixString(16).substring(2)}',
                        'text-decoration': 'none',
                      };
                    }
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

  Widget _buildArticleContent(
    ThemeData theme,
    Article article,
    String langCode,
    Map<String, dynamic> rules,
  ) {
    final langRules = rules[langCode] ?? {};
    final globalRules = rules['global'] ?? {};

    final List<String> toRemoveSelectors = [
      ...(globalRules['remove'] as List<dynamic>? ?? []),
      ...(langRules['remove'] as List<dynamic>? ?? []),
    ].map((e) => e.toString()).toList();

    final List<String> toHideSelectors = [
      ...(globalRules['hide'] as List<dynamic>? ?? []),
      ...(langRules['hide'] as List<dynamic>? ?? []),
      'img',
      'figure',
      '.thumb',
    ].map((e) => e.toString()).toList();

    final List<String> referenceKeywords = [
      ...(globalRules['referenceKeywords'] as List<dynamic>? ?? []),
      ...(langRules['referenceKeywords'] as List<dynamic>? ?? []),
      'reference',
      'catatan kaki',
      'rujukan',
    ].map((e) => e.toString()).toList();

    final doc = html_parser.parse(article.text);
    if (toRemoveSelectors.isNotEmpty) {
      doc
          .querySelectorAll(toRemoveSelectors.join(', '))
          .forEach((e) => e.remove());
    }

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
              fontSize: 16,
              height: 1.8,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
            ),
            customStylesBuilder: (element) {
              final lowerText = element.text.toLowerCase();
              if (element.localName?.startsWith('h') == true &&
                  referenceKeywords.any(
                    (k) => lowerText.contains(k.toLowerCase()),
                  )) {
                return {'display': 'none'};
              }

              if (toHideSelectors.any(
                (s) =>
                    element.classes.contains(s.replaceFirst('.', '')) ||
                    element.localName == s,
              )) {
                return {'display': 'none'};
              }

              if (element.localName == 'a') {
                return {
                  'color':
                      '#${theme.colorScheme.primary.toARGB32().toRadixString(16).substring(2)}',
                  'text-decoration': 'none',
                  'font-weight': '600',
                };
              }
              if (element.classes.contains('new')) {
                return {
                  'color':
                      '#${WikinusaThemeConfig.getLinkRed(theme.brightness).toARGB32().toRadixString(16).substring(2)}',
                };
              }
              if (element.localName == 'p') {
                return {'margin-bottom': '16px'};
              }
              if (element.localName == 'sup') {
                return {'font-size': '0.75em', 'vertical-align': 'super'};
              }
              return null;
            },
            customWidgetBuilder: (element) {
              if (element.localName == 'sup') {
                final isRef =
                    element.classes.contains('reference') ||
                    element.classes.contains('mw-ref') ||
                    element.attributes['role'] == 'doc-noteref';

                if (isRef) {
                  final link = element.querySelector('a');
                  final href = link?.attributes['href'];
                  if (href != null && href.contains('cite_note')) {
                    final refId = href.split('#').last;
                    return GestureDetector(
                      onTap: () => _showReferencePopup(
                        context,
                        refId,
                        article.text,
                        langCode,
                      ),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: Text(
                          element.text,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }
                }
              }

              if (element.localName?.startsWith('h') == true) {
                final text = element.text;
                final lowerText = text.toLowerCase();

                if (referenceKeywords.any(
                  (k) => lowerText.contains(k.toLowerCase()),
                )) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        text,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          fontFamily: theme.textTheme.bodyLarge?.fontFamily,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 30,
                        height: 2,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
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

  Widget _buildFloatingActionBar(
    ThemeData theme,
    ArticleNavigationState navState,
    String pageUrl,
    String currentTitle,
    String langCode,
  ) {
    final isBookmarked = ref
        .watch(bookmarksProvider)
        .any((b) => b.title == currentTitle && b.langCode == langCode);

    return Positioned(
      bottom: 24,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionButton(
                theme,
                Icons.arrow_back_ios_new,
                navState.canGoBack
                    ? theme.colorScheme.primary
                    : Colors.grey.withValues(alpha: 0.5),
                onPressed: navState.canGoBack
                    ? () => ref
                          .read(articleNavigationProvider.notifier)
                          .previous()
                    : null,
              ),
              _buildDivider(theme),
              _buildActionButton(
                theme,
                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                isBookmarked
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
                onPressed: () {
                  ref
                      .read(bookmarksProvider.notifier)
                      .toggleBookmark(currentTitle, langCode);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isBookmarked
                              ? 'bookmarks_removed'.tr()
                              : 'bookmarks_added'.tr(),
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
              ),
              _buildDivider(theme),
              _buildActionButton(
                theme,
                Icons.share_outlined,
                theme.colorScheme.onSurface,
                onPressed: () {
                  SharePlus.instance.share(
                    ShareParams(uri: Uri.parse(pageUrl)),
                  );
                },
              ),
              _buildDivider(theme),
              _buildActionButton(
                theme,
                Icons.edit_outlined,
                theme.colorScheme.onSurface,
                onPressed: () async {
                  final uri = Uri.parse('$pageUrl?action=edit&section=all');
                  try {
                    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('editor_cant_open').tr()),
                      );
                    }
                  }
                },
              ),
              _buildDivider(theme),
              _buildActionButton(
                theme,
                Icons.visibility_outlined,
                theme.colorScheme.onSurface,
                onPressed: () async {
                  final uri = Uri.parse(pageUrl);
                  try {
                    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('page_cant_open').tr()),
                      );
                    }
                  }
                },
              ),
              _buildDivider(theme),
              _buildActionButton(
                theme,
                Icons.arrow_forward_ios,
                navState.canGoForward
                    ? theme.colorScheme.primary
                    : Colors.grey.withValues(alpha: 0.5),
                onPressed: navState.canGoForward
                    ? () => ref.read(articleNavigationProvider.notifier).next()
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    ThemeData theme,
    IconData icon,
    Color color, {
    VoidCallback? onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Container(
      height: 20,
      width: 1,
      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
