import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

import 'package:wikimedia_core/wikimedia_core.dart';
import '../../../utils/wiki_utils.dart';
import '../../../widgets/wiki_footer.dart';
import '../../../utils/responsive_utils.dart';
import '../../../widgets/adaptive_nav_actions.dart';
import '../../../widgets/drawer_menu.dart';
import '../../../widgets/custom_bottom_app_bar.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/modules_provider.dart';
import '../../../providers/app_state.dart';
import '../../../screens/image_screen.dart';
import '../../../widgets/module_disabled_view.dart';

class _TocChapter {
  final int index;
  final String title;
  final int level;
  final GlobalKey key;

  _TocChapter({
    required this.index,
    required this.title,
    required this.level,
    required this.key,
  });
}

typedef NewsletterParams = ({
  String langCode,
  String pageTitle,
  ProjectType project,
});

// Provider for newsletter page adaptable to currently selected language with offline database caching
final newsletterApiProvider = FutureProvider.autoDispose
    .family<dynamic, NewsletterParams>((ref, params) async {
      final db = ref.watch(appDatabaseProvider);

      return WikiApiService.fetchPageHtml(
        params.project,
        params.langCode,
        params.pageTitle,
        true,
        forceRefresh:
            true, // Always check online for latest changes if internet connection exists
        getCachedPage: (proj, lang, title, isArt) async {
          final cached = await db.getCachedArticle(
            project: proj,
            languageCode: lang,
            pageTitle: title,
            isArticle: isArt,
          );
          if (cached != null) {
            try {
              final decoded = jsonDecode(cached.htmlContent);
              if (decoded is Map<String, dynamic>) {
                return {...decoded, 'isOfflineCache': true};
              }
            } catch (_) {}
          }
          return null;
        },
        saveCachedPage:
            (proj, lang, title, content, heroImageUrl, isArt) async {
              await db.upsertArticle(
                project: proj,
                languageCode: lang,
                pageTitle: title,
                htmlContent: content,
                heroImageUrl: heroImageUrl,
                isArticle: isArt,
              );
            },
      );
    });

class NewsletterScreen extends ConsumerStatefulWidget {
  const NewsletterScreen({super.key});

  @override
  ConsumerState<NewsletterScreen> createState() => _NewsletterScreenState();
}

class _NewsletterScreenState extends ConsumerState<NewsletterScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final ScrollController _scrollController;
  bool _isTocExpanded = false;
  final Map<int, GlobalKey> _chapterKeys = {};
  List<_TocChapter> _tocChapters = [];
  String? _lastParsedHtml;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Proactively check for latest changes online when entering screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(newsletterApiProvider);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _extractHeadingText(dom.Element el) {
    final clone = el.clone(true);
    for (final removeEl in clone.querySelectorAll(
      '.mw-editsection, .mw-editsection-bracket, .mw-headline-number, meta, style, script',
    )) {
      removeEl.remove();
    }
    return clone.text
        .replaceAll(
          RegExp(r'\[\s*(edit|bulö’ö kode|sunting)\s*\]', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> _refreshNewsletter() async {
    final currentLanguage = ref.read(languageProvider);
    final moduleConfig = ref.read(
      moduleConfigProvider((
        moduleKey: 'newsletter',
        langCode: currentLanguage,
      )),
    );
    final pageTitle = (moduleConfig?.pageTitle.isNotEmpty ?? false)
        ? moduleConfig!.pageTitle
        : 'Wikipedia:Turia';
    final project = moduleConfig?.project ?? ProjectType.wikipedia;

    final db = ref.read(appDatabaseProvider);
    await db.clearCache(
      project: project.name.toLowerCase(),
      languageCode: currentLanguage,
      pageTitle: pageTitle,
    );
    await WikiApiService.clearCache(project, currentLanguage, pageTitle);

    ref.invalidate(newsletterApiProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('refreshing_content'.tr()),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLanguage = ref.watch(languageProvider);
    final moduleConfig = ref.watch(
      moduleConfigProvider((
        moduleKey: 'newsletter',
        langCode: currentLanguage,
      )),
    );

    final isEnabled = moduleConfig?.enabled ?? false;
    final pageTitle = (moduleConfig?.pageTitle.isNotEmpty ?? false)
        ? moduleConfig!.pageTitle
        : 'Wikipedia:Turia';
    final project = moduleConfig?.project ?? ProjectType.wikipedia;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final headerColor = project.primaryColor;
    final accentColor = project.getThemedColor(isDark);

    final newsletterContent = isEnabled
        ? ref.watch(
            newsletterApiProvider((
              langCode: currentLanguage,
              pageTitle: pageTitle,
              project: project,
            )),
          )
        : null;

    final domain = WikiConfig.getDomain(
      currentLanguage,
      project.name.toLowerCase(),
    );
    final String pageUrl =
        'https://$domain/wiki/${pageTitle.replaceAll(' ', '_')}';

    return PopScope(
      canPop: !_isTocExpanded,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isTocExpanded) {
          setState(() {
            _isTocExpanded = false;
          });
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = ResponsiveUtils.isLandscape(context);

          final bool showBottomNavBar = !isLandscape;
          final bool showNavigationRail = isLandscape;
          final bool showPermanentDrawer = ResponsiveUtils.isTabletLandscape(
            context,
          );
          final bool showMenuButtonInRail =
              showNavigationRail && !showPermanentDrawer;

          if (!isEnabled) {
            return Scaffold(
              key: _scaffoldKey,
              drawer: showPermanentDrawer ? null : const DrawerMenu(),
              appBar: AppBar(title: Text('newsletter'.tr())),
              bottomNavigationBar: showBottomNavBar
                  ? CustomBottomAppBar(
                      scaffoldKey: _scaffoldKey,
                      currentProject: project,
                      pageTitle: pageTitle,
                      onRefresh: _refreshNewsletter,
                    )
                  : null,
              body: ModuleDisabledView(
                moduleTitle: 'newsletter'.tr(),
                icon: Icons.feed_rounded,
                color: accentColor,
              ),
            );
          }

          return Scaffold(
            key: _scaffoldKey,
            drawer: showPermanentDrawer ? null : const DrawerMenu(),
            bottomNavigationBar: showBottomNavBar
                ? CustomBottomAppBar(
                    scaffoldKey: _scaffoldKey,
                    currentProject: project,
                    pageTitle: pageTitle,
                    onRefresh: _refreshNewsletter,
                  )
                : null,
            body: Row(
              children: [
                if (showPermanentDrawer)
                  const SizedBox(
                    width: 304,
                    child: DrawerMenu(isPermanent: true),
                  ),
                Expanded(
                  child: Stack(
                    children: [
                      CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          SliverAppBar(
                            automaticallyImplyLeading: false,
                            expandedHeight: 200.0,
                            floating: true,
                            pinned: false,
                            snap: true,
                            backgroundColor: headerColor,
                            actions: [
                              IconButton(
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  color: Colors.white,
                                ),
                                tooltip: 'refresh'.tr(),
                                onPressed: _refreshNewsletter,
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.share_rounded,
                                  color: Colors.white,
                                ),
                                tooltip: 'share'.tr(),
                                onPressed: () {
                                  SharePlus.instance.share(
                                    ShareParams(uri: Uri.parse(pageUrl)),
                                  );
                                },
                              ),
                              // IconButton(
                              //   icon: const Icon(
                              //     Icons.open_in_browser_rounded,
                              //     color: Colors.white,
                              //   ),
                              //   tooltip: 'open_in_browser'.tr(),
                              //   onPressed: () async {
                              //     final uri = Uri.parse(pageUrl);
                              //     if (await canLaunchUrl(uri)) {
                              //       await launchUrl(
                              //         uri,
                              //         mode: LaunchMode.externalApplication,
                              //       );
                              //     }
                              //   },
                              // ),
                            ],
                            flexibleSpace: FlexibleSpaceBar(
                              centerTitle: true,
                              title: Text(
                                'newsletter_title'.tr(),
                                style: GoogleFonts.cinzelDecorative(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                              background: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      headerColor,
                                      headerColor.withValues(alpha: 0.85),
                                      const Color(0xFF1E3A8A),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.feed_rounded,
                                        size: 56,
                                        color: Colors.white.withValues(
                                          alpha: 0.35,
                                        ),
                                      ),
                                      const SizedBox(height: 36),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                        ),
                                        child: Text(
                                          'newsletter_subtitle'.tr(),
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.merriweather(
                                            fontSize: 13,
                                            color: Colors.white.withValues(
                                              alpha: 0.9,
                                            ),
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (newsletterContent != null)
                            newsletterContent.when(
                              data: (data) {
                                String htmlContent;

                                final bool isOfflineCache =
                                    data is Map<String, dynamic> &&
                                    data['isOfflineCache'] == true;

                                if (data is Map<String, dynamic>) {
                                  htmlContent = data['html'] ?? '';
                                } else if (data is String) {
                                  htmlContent = data;
                                } else {
                                  htmlContent = '';
                                }

                                if (htmlContent.isEmpty ||
                                    htmlContent.contains(
                                      'Error: Could not parse',
                                    )) {
                                  return SliverFillRemaining(
                                    child: Center(
                                      child: Text(
                                        'error_loading_contents'.tr(),
                                      ),
                                    ),
                                  );
                                }

                                // Clean inline styles
                                final cleanHtml = htmlContent.replaceAll(
                                  RegExp(r'style="[^"]*"'),
                                  '',
                                );

                                final doc = html_parser.parse(cleanHtml);
                                final mainContent =
                                    doc.querySelector('.mw-parser-output') ??
                                    doc.body;

                                final headingElements =
                                    mainContent?.querySelectorAll('h2, h3') ??
                                    [];
                                if (htmlContent != _lastParsedHtml) {
                                  _lastParsedHtml = htmlContent;
                                  _chapterKeys.clear();
                                  _tocChapters = [];
                                  for (
                                    int i = 0;
                                    i < headingElements.length;
                                    i++
                                  ) {
                                    final el = headingElements[i];
                                    el.attributes['data-toc-index'] = '$i';
                                    final title = _extractHeadingText(el);
                                    if (title.isNotEmpty) {
                                      final key = _chapterKeys.putIfAbsent(
                                        i,
                                        () => GlobalKey(),
                                      );
                                      _tocChapters.add(
                                        _TocChapter(
                                          index: i,
                                          title: title,
                                          level: el.localName == 'h2' ? 2 : 3,
                                          key: key,
                                        ),
                                      );
                                    }
                                  }
                                } else {
                                  for (
                                    int i = 0;
                                    i < headingElements.length;
                                    i++
                                  ) {
                                    headingElements[i]
                                            .attributes['data-toc-index'] =
                                        '$i';
                                  }
                                }

                                final cleanBody =
                                    mainContent?.innerHtml.trim() ??
                                    cleanHtml.trim();

                                final langCode = context.locale.languageCode;

                                return SliverPadding(
                                  padding: const EdgeInsets.all(16.0),
                                  sliver: SliverList(
                                    delegate: SliverChildListDelegate([
                                      if (isOfflineCache)
                                        Container(
                                          width: double.infinity,
                                          margin: const EdgeInsets.only(
                                            bottom: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme
                                                .colorScheme
                                                .surfaceContainerHigh,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                            horizontal: 16,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.offline_pin_outlined,
                                                size: 18,
                                                color: accentColor,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'offline_saved_version'.tr(),
                                                  style: theme
                                                      .textTheme
                                                      .labelMedium
                                                      ?.copyWith(
                                                        color: theme
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      HtmlWidget(
                                        cleanBody,
                                        textStyle: GoogleFonts.notoSerif(
                                          height: 1.8,
                                          fontSize: 16,
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.9),
                                        ),
                                        onTapUrl: (url) =>
                                            WikiUtils.handleTapUrl(
                                              context,
                                              url,
                                              htmlContent,
                                              project,
                                              langCode,
                                            ),
                                        customWidgetBuilder: (element) {
                                          if (element.id == 'toc' ||
                                              element.classes.contains('toc')) {
                                            return const SizedBox.shrink();
                                          }
                                          if (element.localName == 'h2' ||
                                              element.localName == 'h3') {
                                            final isH2 =
                                                element.localName == 'h2';
                                            final idxStr = element
                                                .attributes['data-toc-index'];
                                            final key = idxStr != null
                                                ? _chapterKeys[int.tryParse(
                                                    idxStr,
                                                  )]
                                                : null;

                                            return Container(
                                              key: key,
                                              padding: EdgeInsets.only(
                                                top: isH2 ? 20.0 : 14.0,
                                                bottom: 8.0,
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    _extractHeadingText(
                                                      element,
                                                    ),
                                                    style:
                                                        GoogleFonts.cinzelDecorative(
                                                          fontSize: isH2
                                                              ? 16
                                                              : 14,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: accentColor,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Container(
                                                    width: isH2 ? 36 : 24,
                                                    height: 2.5,
                                                    decoration: BoxDecoration(
                                                      color: accentColor,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            2,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
                                          if (element.localName == 'img') {
                                            final src =
                                                element.attributes['src'];
                                            if (src != null && src.isNotEmpty) {
                                              final fullUrl =
                                                  src.startsWith('//')
                                                  ? 'https:$src'
                                                  : src;
                                              return Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12.0,
                                                    ),
                                                child: _buildImageWidget(
                                                  fullUrl,
                                                  accentColor,
                                                ),
                                              );
                                            }
                                          }
                                          return null;
                                        },
                                        customStylesBuilder: (element) {
                                          if (element.localName ==
                                              'blockquote') {
                                            return {
                                              'border-left':
                                                  '4px solid ${accentColor.toHtmlRgba()}',
                                              'padding-left': '12px',
                                              'margin-left': '0',
                                              'font-style': 'italic',
                                            };
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 32),
                                      const WikiFooter(),
                                      const SizedBox(height: 80),
                                    ]),
                                  ),
                                );
                              },
                              loading: () => const SliverFillRemaining(
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              error: (err, stack) => SliverFillRemaining(
                                child: Center(
                                  child: Text('${'error'.tr()}: $err'),
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (_isTocExpanded)
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              setState(() {
                                _isTocExpanded = false;
                              });
                            },
                            child: const ColoredBox(color: Colors.transparent),
                          ),
                        ),
                      if (_tocChapters.isNotEmpty)
                        _buildTocPill(theme, accentColor, isDark),
                    ],
                  ),
                ),
                if (showNavigationRail)
                  Container(
                    width: 56,
                    color: headerColor,
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        if (showMenuButtonInRail)
                          IconButton(
                            icon: const Icon(Icons.menu),
                            color: theme.colorScheme.onPrimary,
                            tooltip: 'open_navigation_menu'.tr(),
                            onPressed: () =>
                                _scaffoldKey.currentState?.openDrawer(),
                          ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children:
                                    AdaptiveNavActions.buildActions(
                                          context,
                                          ref,
                                          currentProject: project,
                                          isHomeScreen: false,
                                          showHome: true,
                                          pageTitle: pageTitle,
                                          color: theme.colorScheme.onPrimary,
                                          onRefresh: _refreshNewsletter,
                                        )
                                        .map(
                                          (w) => Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 4,
                                            ),
                                            child: w,
                                          ),
                                        )
                                        .toList(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTocPill(ThemeData theme, Color accentColor, bool isDark) {
    final bottomPadding = 24.0 + MediaQuery.paddingOf(context).bottom;

    if (!_isTocExpanded) {
      return Positioned(
        bottom: bottomPadding,
        right: 24,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () {
              setState(() {
                _isTocExpanded = true;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? theme.colorScheme.surfaceContainerHigh.withValues(
                        alpha: 0.95,
                      )
                    : theme.colorScheme.surface.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: accentColor.withValues(alpha: isDark ? 0.5 : 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: isDark ? 0.25 : 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.toc_rounded, size: 22, color: accentColor),
                  const SizedBox(width: 8),
                  Text(
                    'table_of_contents'.tr(),
                    style: GoogleFonts.cinzelDecorative(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.keyboard_arrow_up_rounded,
                    size: 20,
                    color: accentColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxWidth = (screenWidth - 48).clamp(280.0, 360.0);
    final maxHeight = (screenHeight * 0.55).clamp(240.0, 420.0);

    return Positioned(
      bottom: bottomPadding,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.98)
                : theme.colorScheme.surface.withValues(alpha: 0.98),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: accentColor.withValues(alpha: isDark ? 0.5 : 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: isDark ? 0.3 : 0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                InkWell(
                  onTap: () {
                    setState(() {
                      _isTocExpanded = false;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 10, 10),
                    child: Row(
                      children: [
                        Icon(Icons.toc_rounded, size: 22, color: accentColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'table_of_contents'.tr(),
                            style: GoogleFonts.cinzelDecorative(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(
                              alpha: isDark ? 0.2 : 0.1,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: accentColor.withValues(alpha: isDark ? 0.25 : 0.15),
                ),
                // Chapter list
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 8,
                    ),
                    itemCount: _tocChapters.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 2),
                    itemBuilder: (context, index) {
                      final chapter = _tocChapters[index];
                      final isH2 = chapter.level == 2;
                      return InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          setState(() {
                            _isTocExpanded = false;
                          });
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            final targetContext = chapter.key.currentContext;
                            if (targetContext != null) {
                              Scrollable.ensureVisible(
                                targetContext,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOutCubic,
                                alignment: 0.06,
                              );
                            }
                          });
                        },
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: isH2 ? 10.0 : 26.0,
                            right: 12.0,
                            top: 8.0,
                            bottom: 8.0,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (isH2)
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    shape: BoxShape.circle,
                                  ),
                                )
                              else
                                Icon(
                                  Icons.subdirectory_arrow_right_rounded,
                                  size: 15,
                                  color: accentColor.withValues(
                                    alpha: isDark ? 0.9 : 0.7,
                                  ),
                                ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  chapter.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.merriweather(
                                    fontSize: isH2 ? 13 : 12,
                                    fontWeight: isH2
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: isH2 ? 0.95 : 0.8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget(String url, Color themeColor) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ImageScreen(imagePath: url)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: themeColor.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(url, fit: BoxFit.cover, width: double.infinity),
        ),
      ),
    );
  }
}

extension on Color {
  String toHtmlRgba() {
    return 'rgba($r, $g, $b, $a)';
  }
}
