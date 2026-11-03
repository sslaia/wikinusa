import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import '../utils/wiki_utils.dart';
import '../utils/responsive_utils.dart';
import 'package:wikimedia_core/wikimedia_core.dart';
import '../providers/history_provider.dart';
import '../providers/bookmarks_provider.dart';
import '../providers/app_state.dart';
import '../providers/wiki_api_provider.dart';
import '../providers/custom_hero_image_provider.dart';
import '../providers/font_size_provider.dart';
import '../widgets/custom_bottom_app_bar.dart';
import '../widgets/drawer_menu.dart';
import '../widgets/adaptive_nav_actions.dart';
import '../widgets/pcs_article_view.dart';
import '../providers/auth_provider.dart';
import '../providers/database_provider.dart';
import 'edit_page_screen.dart';
import 'image_screen.dart';

class ArticleScreen extends ConsumerStatefulWidget {
  final String title;

  const ArticleScreen({super.key, required this.title});

  @override
  ConsumerState<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends ConsumerState<ArticleScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isSearchActive = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  int _currentMatchIndex = 0;
  int _totalMatchCount = 0;
  String? _lastArticleKey;
  final PcsArticleController _pcsController = PcsArticleController();

  @override
  void initState() {
    super.initState();

    /// Register this article in history when opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(historyProvider.notifier).push(widget.title);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearchActive = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
      _searchController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _searchController.text.length,
      );
    });
  }

  void _closeSearch() {
    _pcsController.clearSearch();
    setState(() {
      _isSearchActive = false;
      _searchController.clear();
      _totalMatchCount = 0;
      _currentMatchIndex = 0;
    });
    _searchFocusNode.unfocus();
  }

  void _runSearch(String query) async {
    if (query.isEmpty) {
      await _pcsController.clearSearch();
      if (mounted) {
        setState(() {
          _totalMatchCount = 0;
          _currentMatchIndex = 0;
        });
      }
      return;
    }

    final count = await _pcsController.search(query);
    if (mounted) {
      setState(() {
        _totalMatchCount = count;
        _currentMatchIndex = count > 0 ? 0 : -1;
      });
    }
  }

  void _nextMatch() async {
    if (_totalMatchCount <= 1) return;
    final idx = await _pcsController.nextMatch();
    if (mounted && idx >= 0) {
      setState(() {
        _currentMatchIndex = idx;
      });
    }
  }

  void _prevMatch() async {
    if (_totalMatchCount <= 1) return;
    final idx = await _pcsController.previousMatch();
    if (mounted && idx >= 0) {
      setState(() {
        _currentMatchIndex = idx;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentProject = ref.watch(appStateProvider);
    final wikiContent = ref.watch(wikiApiProvider(widget.title));
    final langCode = ref.watch(languageProvider);
    final fontSize = ref.watch(fontSizeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final projectColor = currentProject.getThemedColor(isDark);

    /// Temporary solution while Nias Wikibooks is still in the Incubator
    String pageUrl;
    if (langCode == 'nia' && currentProject == ProjectType.wikibooks) {
      String incubatorTitle = widget.title;
      if (!incubatorTitle.contains('Wb/nia/')) {
        final lowerTitle = incubatorTitle.toLowerCase();
        if (lowerTitle.startsWith('special:') ||
            lowerTitle.startsWith('spesial:') ||
            lowerTitle.startsWith('mirunggan:') ||
            lowerTitle.startsWith('istimewa:') ||
            lowerTitle.startsWith('istimiwa:') ||
            lowerTitle.startsWith('istimèwa:') ||
            lowerTitle.startsWith('khas:') ||
            lowerTitle.startsWith('husus:')) {
          // Special pages don't need prefix
        } else if (lowerTitle.startsWith('category:') ||
            lowerTitle.startsWith('kategori:') ||
            lowerTitle.startsWith('template:') ||
            lowerTitle.startsWith('templat:')) {
          final parts = incubatorTitle.split(':');
          final namespace = parts[0];
          final rest = parts.sublist(1).join(':');
          incubatorTitle = '$namespace:Wb/nia/$rest';
        } else {
          incubatorTitle = 'Wb/nia/$incubatorTitle';
        }
      }
      pageUrl =
          'https://incubator.wikimedia.org/wiki/${incubatorTitle.replaceAll(' ', '_')}';
    } else {
      pageUrl =
          'https://$langCode.${currentProject.name.toLowerCase()}.org/wiki/${widget.title.replaceAll(' ', '_')}';
    }

    final articleKey = 'html_${widget.title}_${currentProject.name}_$langCode';
    if (_lastArticleKey != articleKey) {
      _lastArticleKey = articleKey;
      _isSearchActive = false;
      _searchController.clear();
      _totalMatchCount = 0;
      _currentMatchIndex = 0;
    }

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): _startSearch,
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true): _startSearch,
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = ResponsiveUtils.isLandscape(context);

          final bool showBottomNavBar = !isLandscape;
          final bool showNavigationRail = isLandscape;
          final bool showPermanentDrawer =
              ResponsiveUtils.isTabletLandscape(context);
          final bool showMenuButtonInRail =
              showNavigationRail && !showPermanentDrawer;

          return PopScope(
            canPop: !_isSearchActive,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              if (_isSearchActive) {
                _closeSearch();
              }
            },
            child: Scaffold(
            key: _scaffoldKey,
            drawer: showPermanentDrawer ? null : const DrawerMenu(),
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
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: wikiContent.when(
                            skipLoadingOnRefresh: false,
                            data: (data) {
                              String htmlContent = '';
                              String? imageUrl;
                              bool isOfflineCache = false;

                              if (data is Map<String, dynamic>) {
                                htmlContent = data['html'] ?? '';
                                imageUrl = data['imageUrl'];
                                if (imageUrl != null &&
                                    CoreWikiUtils.isIcon(imageUrl)) {
                                  imageUrl = null;
                                }
                                isOfflineCache = data['isOfflineCache'] == true;
                              } else if (data is String) {
                                htmlContent = data;
                              }

                              final customHero = ref.watch(customHeroImageProvider)[currentProject];
                              final effectiveHeroUrl = (imageUrl != null && imageUrl.isNotEmpty)
                                  ? imageUrl
                                  : customHero;

                              final pcsTheme = isDark ? 'dark' : 'light';
                              final domain = WikiConfig.getDomain(langCode, currentProject.name.toLowerCase());
                              final baseUrl = 'https://$domain/wiki/';

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (isOfflineCache)
                                    Container(
                                      width: double.infinity,
                                      color: Theme.of(context).colorScheme.surfaceContainerHigh,
                                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.offline_pin_outlined,
                                            size: 16,
                                            color: Theme.of(context).colorScheme.primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'offline_saved_version'.tr(),
                                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Expanded(
                                    child: PcsArticleWebView(
                                      key: ValueKey('pcs_${widget.title}_${currentProject.name}_${langCode}_${htmlContent.hashCode}'),
                                      htmlContent: htmlContent,
                                      baseUrl: baseUrl,
                                      title: widget.title,
                                      heroImageUrl: effectiveHeroUrl,
                                      project: currentProject,
                                      theme: pcsTheme,
                                      languageCode: langCode,
                                      fontSizeScale: fontSize.scale,
                                      controller: _pcsController,
                                      onLinkClicked: (href, linkTitle) {
                                        WikiUtils.handleTapUrl(
                                          context,
                                          href,
                                          htmlContent,
                                          currentProject,
                                          langCode,
                                        );
                                      },
                                      onReferenceClicked: (refId, refHtml) {
                                        WikiUtils.showReferencePopup(
                                          context,
                                          refId,
                                          refHtml.isNotEmpty ? refHtml : htmlContent,
                                        );
                                      },
                                      onImageClicked: (src, imgTitle) {
                                        final fullSrc = src.startsWith('//')
                                            ? 'https:$src'
                                            : (src.startsWith('/') ? 'https://$domain$src' : src);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ImageScreen(imagePath: fullSrc),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (error, stack) => Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  '${'error_loading_contents'.tr()}: $error',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (!_isSearchActive)
                        Positioned(
                          top: 10 + MediaQuery.paddingOf(context).top,
                          left: 12,
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? theme.colorScheme.surfaceContainerHigh
                                        .withValues(alpha: 0.92)
                                    : theme.colorScheme.surface
                                        .withValues(alpha: 0.92),
                                border: Border.all(
                                  color: projectColor.withValues(alpha: isDark ? 0.5 : 0.25),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: projectColor.withValues(alpha: isDark ? 0.25 : 0.15),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: Icon(Icons.arrow_back, color: projectColor),
                                tooltip: 'back'.tr(),
                                onPressed: () {
                                  ref.read(historyProvider.notifier).goBack();
                                  Navigator.of(context).pop();
                                },
                              ),
                            ),
                          ),
                        ),
                      if (_isSearchActive)
                        Positioned(
                          top: 16 + MediaQuery.paddingOf(context).top,
                          left: 16,
                          right: 16,
                          child: _buildSearchPanel(theme),
                        ),
                      if (!_isSearchActive)
                        _buildFloatingActionBar(
                          theme,
                          pageUrl,
                          widget.title,
                          langCode,
                          currentProject.name,
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
                                          currentProject: currentProject,
                                          isHomeScreen: false,
                                          showHome: true,
                                          pageTitle: widget.title,
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
            bottomNavigationBar: showBottomNavBar
                ? CustomBottomAppBar(
                    scaffoldKey: _scaffoldKey,
                    currentProject: currentProject,
                    pageTitle: widget.title,
                  )
                : null,
          ),
        );
      },
    ),
    );
  }

  Widget _buildFloatingActionBar(
    ThemeData theme,
    String pageUrl,
    String currentTitle,
    String langCode,
    String projectName,
  ) {
    final bookmarks = ref.watch(bookmarksProvider);
    final history = ref.watch(historyProvider);
    final currentProject = ref.watch(appStateProvider);
    final isDark = theme.brightness == Brightness.dark;
    final project = ProjectType.values.firstWhere(
      (p) => p.name == projectName,
      orElse: () => currentProject,
    );
    final projectColor = project.getThemedColor(isDark);

    final isBookmarked = bookmarks.any(
      (b) =>
          b.title == currentTitle &&
          b.langCode == langCode &&
          b.projectName == projectName,
    );

    final List<Widget> children = [
      _buildActionButton(
        theme,
        Icons.arrow_back_ios_new,
        history.canGoBack
            ? projectColor
            : projectColor.withValues(alpha: 0.38),
        tooltip: 'back'.tr(),
        onPressed: history.canGoBack
            ? () {
                ref.read(historyProvider.notifier).goBack();
                Navigator.of(context).pop();
              }
            : null,
      ),
      _buildDivider(theme, projectColor),
      _buildActionButton(
        theme,
        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
        projectColor,
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
      _buildDivider(theme, projectColor),
      _buildActionButton(
        theme,
        Icons.share_outlined,
        projectColor,
        tooltip: 'share'.tr(),
        onPressed: () {
          SharePlus.instance.share(ShareParams(uri: Uri.parse(pageUrl)));
        },
      ),
      _buildDivider(theme, projectColor),
      _buildActionButton(
        theme,
        Icons.find_in_page_outlined,
        projectColor,
        tooltip: 'find_in_page'.tr(),
        onPressed: _startSearch,
      ),
      _buildDivider(theme, projectColor),
      _buildActionButton(
        theme,
        Icons.edit_outlined,
        projectColor,
        tooltip: 'edit'.tr(),
        onPressed: () async {
          var authState = ref.read(authProvider);
          if (authState.isLoading) {
            final completer = Completer<AuthState>();
            final listener = ref.listenManual<AuthState>(
              authProvider,
              (previous, next) {
                if (!next.isLoading && !completer.isCompleted) {
                  completer.complete(next);
                }
              },
              fireImmediately: true,
            );
            authState = await completer.future;
            listener.close();
          }

          if (!mounted) return;

          if (authState.isLoggedIn) {
            await _handleEdit(currentTitle, langCode);
          } else {
            final bool? shouldLogin = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                constraints: const BoxConstraints(maxWidth: 400),
                title: Text('login_required'.tr()),
                content: Text('login_to_edit_message'.tr()),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('continue_in_browser'.tr()),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('login'.tr()),
                  ),
                ],
              ),
            );

            if (!mounted) return;

            if (shouldLogin == true) {
              await ref.read(authProvider.notifier).login(context);
              if (!mounted) return;
              final newAuthState = ref.read(authProvider);
              if (newAuthState.isLoggedIn) {
                await _handleEdit(currentTitle, langCode);
              }
            } else if (shouldLogin == false) {
              final uri = Uri.parse('$pageUrl?action=edit&section=all');
              try {
                await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('editor_cant_open').tr()));
                }
              }
            }
          }
        },
      ),
      _buildDivider(theme, projectColor),
      _buildActionButton(
        theme,
        Icons.visibility_outlined,
        projectColor,
        tooltip: 'open_in_browser'.tr(),
        onPressed: () async {
          final uri = Uri.parse(pageUrl);
          try {
            await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('page_cant_open').tr()));
            }
          }
        },
      ),
      _buildDivider(theme, projectColor),
      _buildActionButton(
        theme,
        Icons.arrow_forward_ios,
        history.canGoForward
            ? projectColor
            : projectColor.withValues(alpha: 0.38),
        tooltip: 'forward'.tr(),
        onPressed: history.canGoForward
            ? () {
                final nextTitle = ref
                    .read(historyProvider.notifier)
                    .goForward();
                if (nextTitle != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArticleScreen(title: nextTitle),
                    ),
                  );
                }
              }
            : null,
      ),
    ];

    return Positioned(
      bottom: 24 + MediaQuery.paddingOf(context).bottom,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.95)
                : theme.colorScheme.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: projectColor.withValues(alpha: isDark ? 0.5 : 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: projectColor.withValues(alpha: isDark ? 0.25 : 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ),
      ),
    );
  }

  Future<void> _handleEdit(
    String currentTitle,
    String langCode,
  ) async {
    final currentProject = ref.read(appStateProvider);
    final didEdit = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditPageScreen(title: currentTitle),
      ),
    );

    if (didEdit == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('refreshing_content').tr(),
          duration: const Duration(seconds: 1),
        ),
      );

      final db = ref.read(appDatabaseProvider);
      await db.clearCache(
        project: currentProject.name.toLowerCase(),
        languageCode: langCode,
        pageTitle: currentTitle,
      );
      await WikiApiService.clearCache(
        currentProject,
        langCode,
        currentTitle,
      );
      ref.invalidate(wikiApiProvider(currentTitle));
    }
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
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
    if (tooltip != null && tooltip.isNotEmpty) {
      return Tooltip(message: tooltip, child: widget);
    }
    return widget;
  }

  Widget _buildDivider(ThemeData theme, Color projectColor) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      height: 20,
      width: 1,
      color: projectColor.withValues(alpha: isDark ? 0.35 : 0.2),
      margin: const EdgeInsets.symmetric(horizontal: 6),
    );
  }

  Widget _buildSearchPanel(ThemeData theme) {
    final currentProject = ref.watch(appStateProvider);
    final isDark = theme.brightness == Brightness.dark;
    final projectColor = currentProject.getThemedColor(isDark);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.95)
            : theme.colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: projectColor.withValues(alpha: isDark ? 0.5 : 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: projectColor.withValues(alpha: isDark ? 0.25 : 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Icon(
            Icons.search,
            color: theme.colorScheme.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'find_in_page'.tr(),
                border: InputBorder.none,
                isDense: true,
                hintStyle: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
              textInputAction: TextInputAction.search,
              onChanged: (val) => _runSearch(val),
              onSubmitted: (val) => _nextMatch(),
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 15,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _totalMatchCount > 0
                    ? '${_currentMatchIndex + 1}/$_totalMatchCount'
                    : '0/0',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.clear, size: 18),
              onPressed: () {
                _searchController.clear();
                _runSearch('');
              },
              tooltip: 'clear'.tr(),
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_up, size: 22),
              onPressed: _totalMatchCount > 0 ? _prevMatch : null,
              tooltip: 'previous'.tr(),
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, size: 22),
              onPressed: _totalMatchCount > 0 ? _nextMatch : null,
              tooltip: 'next'.tr(),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: _closeSearch,
            tooltip: 'close'.tr(),
          ),
        ],
      ),
    );
  }
}
