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
import '../../../providers/bookmarks_provider.dart';
import '../../../providers/modules_provider.dart';
import '../../../providers/app_state.dart';
import '../../../screens/image_screen.dart';

class NiasCourseScreen extends ConsumerStatefulWidget {
  const NiasCourseScreen({super.key});

  @override
  ConsumerState<NiasCourseScreen> createState() => _NiasCourseScreenState();
}

class _NiasCourseScreenState extends ConsumerState<NiasCourseScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final currentLanguage = ref.watch(languageProvider);
    final courseConfig = ref.watch(
      moduleConfigProvider((moduleKey: 'course', langCode: currentLanguage)),
    );

    final courseTitle = (courseConfig?.pageTitle.isNotEmpty ?? false)
        ? courseConfig!.pageTitle
        : 'Wikikamus:Sulu';
    final project = courseConfig?.project ?? ProjectType.wiktionary;

    final courseContent = ref.watch(
      courseApiProvider((
        pageTitle: courseTitle,
        langCode: currentLanguage,
        project: project,
      )),
    );
    final theme = Theme.of(context);

    // Mix of project colors
    final mixedColor = Color.lerp(
      ProjectType.wikipedia.primaryColor,
      Color.lerp(
        ProjectType.wiktionary.primaryColor,
        ProjectType.wikibooks.primaryColor,
        0.5,
      ),
      0.5,
    )!;

    final domain = WikiConfig.getDomain(
      currentLanguage,
      project.name.toLowerCase(),
    );
    final String pageUrl =
        'https://$domain/wiki/${courseTitle.replaceAll(' ', '_')}';

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
                  pageTitle: courseTitle,
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
                          backgroundColor: mixedColor,
                          flexibleSpace: FlexibleSpaceBar(
                            centerTitle: true,
                            title: Text(
                              'nias_course_title'.tr(),
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
                                    ProjectType.wikipedia.primaryColor,
                                    ProjectType.wiktionary.primaryColor,
                                    ProjectType.wikibooks.primaryColor,
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.auto_stories_rounded,
                                      size: 60,
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 40,
                                    ), // Spacer for title
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                      child: Text(
                                        'nias_course_subtitle'.tr(),
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.merriweather(
                                          fontSize: 14,
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
                        courseContent.when(
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
                                htmlContent.contains(
                                  'Error: Could not parse',
                                )) {
                              return SliverFillRemaining(
                                child: Center(
                                  child: Text('error_loading_contents'.tr()),
                                ),
                              );
                            }

                            // Strip all inline styles to use app fonts and styles
                            final cleanHtml = htmlContent.replaceAll(
                              RegExp(r'style="[^"]*"'),
                              '',
                            );

                            // Parse and extract specific Sulu lesson components
                            final doc = html_parser.parse(cleanHtml);

                            final titleElement = doc.querySelector(
                              '.lesson-title',
                            );
                            final contentElement = doc.querySelector(
                              '.lesson-content',
                            );

                            final lessonTitle = titleElement?.text.trim() ?? '';

                            // Remove title from the document to prevent duplicate rendering and spacing issues
                            titleElement?.remove();

                            // Surgical content extraction: prefer .lesson-content, then .mw-parser-output, then body.
                            String cleanBody;
                            if (contentElement != null) {
                              cleanBody = contentElement.innerHtml.trim();
                            } else {
                              final mainContent =
                                  doc.querySelector('.mw-parser-output') ??
                                  doc.body;
                              cleanBody =
                                  mainContent?.innerHtml.trim() ??
                                  cleanHtml.trim();
                            }

                            var currentProject = ProjectType.wiktionary;
                            final langCode = context.locale.languageCode;

                            return SliverPadding(
                              padding: const EdgeInsets.all(16.0),
                              sliver: SliverList(
                                delegate: SliverChildListDelegate([
                                  if (lessonTitle.isNotEmpty) ...[
                                    Text(
                                      lessonTitle,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.montserratAlternates(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: mixedColor,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
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
                                      currentProject,
                                      langCode,
                                    ),
                                    customStylesBuilder: (element) {
                                      if (element.localName == 'blockquote') {
                                        return {
                                          'border-left':
                                              '4px solid ${mixedColor.toHtmlRgba()}',
                                          'background-color': mixedColor
                                              .withValues(alpha: 0.05)
                                              .toHtmlRgba(),
                                          'padding': '16px',
                                          'margin': '16px 0',
                                          'font-style': 'italic',
                                          'border-radius': '0 12px 12px 0',
                                        };
                                      }
                                      return WikiUtils.customStyles(
                                        context,
                                        element,
                                      );
                                    },
                                    customWidgetBuilder: (element) {
                                      // Handle images: animate them and make them clickable
                                      if (element.localName == 'img' ||
                                          element.localName == 'figure' ||
                                          element.classes.contains('thumb')) {
                                        final img = element.localName == 'img'
                                            ? element
                                            : element.querySelector('img');

                                        if (img != null) {
                                          final src =
                                              img.attributes['src'] ?? '';
                                          if (src.isNotEmpty &&
                                              !CoreWikiUtils.isIcon(src)) {
                                            final fullUrl =
                                                src.startsWith('http')
                                                ? src
                                                : 'https:$src';
                                            return _buildAnimatedHeroImage(
                                              fullUrl,
                                              mixedColor,
                                            );
                                          }
                                        }
                                      }

                                      return WikiUtils.customWidgetBuilder(
                                        context,
                                        element,
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 32),
                                  const WikiFooter(),
                                  const SizedBox(height: 120),
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
                    _buildFloatingActionBar(
                      theme,
                      pageUrl,
                      courseTitle,
                      project,
                      currentLanguage,
                    ),
                  ],
                ),
              ),
              if (showNavigationRail)
                Container(
                  width: 56,
                  color: theme.colorScheme.primary,
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
                                        pageTitle: courseTitle,
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
    String currentTitle,
    ProjectType project,
    String langCode,
  ) {
    final bookmarks = ref.watch(bookmarksProvider);
    final projectName = project.name;
    final wikiColor = project.primaryColor;

    final isBookmarked = bookmarks.any(
      (b) =>
          b.title == currentTitle &&
          b.langCode == langCode &&
          b.projectName == projectName,
    );

    return Positioned(
      bottom: 24 + MediaQuery.paddingOf(context).bottom,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(32),
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
              _buildActionButton(
                theme,
                isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                wikiColor,
                tooltip: isBookmarked
                    ? 'bookmarks_removed'.tr()
                    : 'bookmarks_added'.tr(),
                onPressed: () {
                  ref
                      .read(bookmarksProvider.notifier)
                      .toggleBookmark(currentTitle, langCode, projectName);

                  ScaffoldMessenger.of(context).clearSnackBars();
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
                },
              ),
              _buildDivider(theme, wikiColor),
              _buildActionButton(
                theme,
                Icons.share_outlined,
                wikiColor,
                tooltip: 'share'.tr(),
                onPressed: () {
                  SharePlus.instance.share(
                    ShareParams(uri: Uri.parse(pageUrl)),
                  );
                },
              ),
              _buildDivider(theme, wikiColor),
              _buildActionButton(
                theme,
                Icons.visibility_outlined,
                wikiColor,
                tooltip: 'open_in_browser'.tr(),
                onPressed: () async {
                  final uri = Uri.parse(pageUrl);
                  try {
                    await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('page_cant_open').tr()),
                      );
                    }
                  }
                },
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
    String? tooltip,
    VoidCallback? onPressed,
  }) {
    final widget = Material(
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
    if (tooltip != null && tooltip.isNotEmpty) {
      return Tooltip(message: tooltip, child: widget);
    }
    return widget;
  }

  Widget _buildDivider(ThemeData theme, Color wikiColor) {
    return Container(
      height: 20,
      width: 1,
      color: wikiColor.withValues(alpha: 0.2),
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildAnimatedHeroImage(String url, Color themeColor) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: GestureDetector(
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
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: themeColor.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
        ),
      ),
    );
  }
}

extension ColorToHtml on Color {
  String toHtmlRgba() {
    return 'rgba($r, $g, $b, $a)';
  }
}

// Special provider for course data dynamically configured per language
final courseApiProvider = FutureProvider.autoDispose
    .family<dynamic, ({String pageTitle, String langCode, ProjectType project})>((
  ref,
  params,
) async {
  return WikiApiService.fetchPageHtml(
    params.project,
    params.langCode,
    params.pageTitle,
    true,
  );
});
