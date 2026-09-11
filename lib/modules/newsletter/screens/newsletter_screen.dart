import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:html/parser.dart' as html_parser;

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

typedef NewsletterParams = ({
  bool forceRefresh,
  String langCode,
  String pageTitle,
  ProjectType project,
});

// Provider for newsletter page adaptable to currently selected language with offline database caching
final newsletterApiProvider =
    FutureProvider.autoDispose.family<dynamic, NewsletterParams>((ref, params) async {
  final db = ref.watch(appDatabaseProvider);

  return WikiApiService.fetchPageHtml(
    params.project,
    params.langCode,
    params.pageTitle,
    true,
    forceRefresh: params.forceRefresh,
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
            return {
              ...decoded,
              'isOfflineCache': true,
            };
          }
        } catch (_) {}
      }
      return null;
    },
    saveCachedPage: (proj, lang, title, content, heroImageUrl, isArt) async {
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
  bool _forceRefresh = false;

  @override
  Widget build(BuildContext context) {
    final currentLanguage = ref.watch(languageProvider);
    final moduleConfig = ref.watch(
      moduleConfigProvider((moduleKey: 'newsletter', langCode: currentLanguage)),
    );

    final pageTitle = (moduleConfig?.pageTitle.isNotEmpty ?? false)
        ? moduleConfig!.pageTitle
        : 'Wikipedia:Turia';
    final project = moduleConfig?.project ?? ProjectType.wikipedia;
    final wikiColor = project.primaryColor;
    final theme = Theme.of(context);

    final newsletterContent = ref.watch(
      newsletterApiProvider((
        forceRefresh: _forceRefresh,
        langCode: currentLanguage,
        pageTitle: pageTitle,
        project: project,
      )),
    );

    final domain = WikiConfig.getDomain(
      currentLanguage,
      project.name.toLowerCase(),
    );
    final String pageUrl =
        'https://$domain/wiki/${pageTitle.replaceAll(' ', '_')}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = ResponsiveUtils.isLandscape(context);

        final bool showBottomNavBar = !isLandscape;
        final bool showNavigationRail = isLandscape;
        final bool showPermanentDrawer =
            ResponsiveUtils.isTabletLandscape(context);
        final bool showMenuButtonInRail =
            showNavigationRail && !showPermanentDrawer;

        return Scaffold(
          key: _scaffoldKey,
          drawer: showPermanentDrawer ? null : const DrawerMenu(),
          bottomNavigationBar: showBottomNavBar
              ? CustomBottomAppBar(
                  scaffoldKey: _scaffoldKey,
                  currentProject: project,
                  pageTitle: pageTitle,
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
                      slivers: [
                        SliverAppBar(
                          automaticallyImplyLeading: false,
                          expandedHeight: 200.0,
                          floating: true,
                          pinned: false,
                          snap: true,
                          backgroundColor: wikiColor,
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
                                    wikiColor,
                                    wikiColor.withValues(alpha: 0.85),
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
                                      color: Colors.white.withValues(alpha: 0.35),
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
                                          color: Colors.white.withValues(alpha: 0.9),
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
                        newsletterContent.when(
                          data: (data) {
                            String htmlContent;

                            if (data is Map<String, dynamic>) {
                              htmlContent = data['html'] ?? '';
                            } else if (data is String) {
                              htmlContent = data;
                            } else {
                              htmlContent = '';
                            }

                            if (htmlContent.isEmpty ||
                                htmlContent.contains('Error: Could not parse')) {
                              return SliverFillRemaining(
                                child: Center(
                                  child: Text('error_loading_contents'.tr()),
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
                            final cleanBody =
                                mainContent?.innerHtml.trim() ??
                                cleanHtml.trim();

                            final langCode = context.locale.languageCode;

                            return SliverPadding(
                              padding: const EdgeInsets.all(16.0),
                              sliver: SliverList(
                                delegate: SliverChildListDelegate([
                                  HtmlWidget(
                                    cleanBody,
                                    textStyle: GoogleFonts.notoSerif(
                                      height: 1.8,
                                      fontSize: 16,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.9),
                                    ),
                                    onTapUrl: (url) => WikiUtils.handleTapUrl(
                                      context,
                                      url,
                                      htmlContent,
                                      project,
                                      langCode,
                                    ),
                                    customWidgetBuilder: (element) {
                                      if (element.localName == 'h2' ||
                                          element.localName == 'h3') {
                                        final isH2 = element.localName == 'h2';
                                        return Padding(
                                          padding: EdgeInsets.only(
                                            top: isH2 ? 20.0 : 14.0,
                                            bottom: 8.0,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                element.text.trim(),
                                                style:
                                                    GoogleFonts.cinzelDecorative(
                                                  fontSize: isH2 ? 16 : 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: wikiColor,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Container(
                                                width: isH2 ? 36 : 24,
                                                height: 2.5,
                                                decoration: BoxDecoration(
                                                  color: wikiColor,
                                                  borderRadius:
                                                      BorderRadius.circular(2),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                      if (element.localName == 'img') {
                                        final src = element.attributes['src'];
                                        if (src != null && src.isNotEmpty) {
                                          final fullUrl = src.startsWith('//')
                                              ? 'https:$src'
                                              : src;
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12.0,
                                            ),
                                            child: _buildImageWidget(
                                              fullUrl,
                                              wikiColor,
                                            ),
                                          );
                                        }
                                      }
                                      return null;
                                    },
                                    customStylesBuilder: (element) {
                                      if (element.localName == 'blockquote') {
                                        return {
                                          'border-left':
                                              '4px solid ${wikiColor.toHtmlRgba()}',
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
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (err, stack) => SliverFillRemaining(
                            child: Center(child: Text('${'error'.tr()}: $err')),
                          ),
                        ),
                      ],
                    ),
                    _buildFloatingActionBar(theme, pageUrl, wikiColor),
                  ],
                ),
              ),
              if (showNavigationRail)
                Container(
                  width: 56,
                  color: wikiColor,
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
    );
  }

  Widget _buildFloatingActionBar(
    ThemeData theme,
    String pageUrl,
    Color wikiColor,
  ) {
    return Positioned(
      bottom: 24 + MediaQuery.paddingOf(context).bottom,
      right: 24,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: wikiColor.withValues(alpha: 0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: wikiColor.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.refresh_rounded, size: 20, color: wikiColor),
              tooltip: 'refresh'.tr(),
              onPressed: () {
                setState(() {
                  _forceRefresh = true;
                });
                ref.invalidate(newsletterApiProvider);
              },
            ),
            IconButton(
              icon: Icon(Icons.share_rounded, size: 20, color: wikiColor),
              tooltip: 'share'.tr(),
              onPressed: () {
                SharePlus.instance.share(
                  ShareParams(uri: Uri.parse(pageUrl)),
                );
              },
            ),
            IconButton(
              icon: Icon(
                Icons.open_in_browser_rounded,
                size: 20,
                color: wikiColor,
              ),
              tooltip: 'open_in_browser'.tr(),
              onPressed: () async {
                final uri = Uri.parse(pageUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String url, Color themeColor) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageScreen(imagePath: url),
          ),
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
          child: Image.network(
            url,
            fit: BoxFit.cover,
            width: double.infinity,
          ),
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
