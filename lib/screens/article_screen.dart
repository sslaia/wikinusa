import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html/dom.dart' as dom;
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import '../utils/wiki_utils.dart';
import '../utils/responsive_utils.dart';
import 'package:wikimedia_core/wikimedia_core.dart';
import '../providers/history_provider.dart';
import '../providers/bookmarks_provider.dart';
import '../widgets/shortcuts_side_bar.dart';
import '../widgets/wiki_footer.dart';
import '../providers/app_state.dart';
import '../providers/wiki_api_provider.dart';
import '../widgets/article_hero_image.dart';
import '../widgets/custom_bottom_app_bar.dart';
import '../widgets/drawer_menu.dart';
import '../widgets/adaptive_nav_actions.dart';
import '../providers/auth_provider.dart';
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
  String _rawHtml = '';
  String _highlightedHtml = '';
  String? _lastArticleKey;
  late GlobalKey<HtmlWidgetState> _htmlWidgetKey;
  List<GlobalKey> _matchKeys = [];

  @override
  void initState() {
    super.initState();
    _htmlWidgetKey = GlobalKey<HtmlWidgetState>();

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
    setState(() {
      _isSearchActive = false;
      _searchController.clear();
      _totalMatchCount = 0;
      _currentMatchIndex = 0;
      _highlightedHtml = _rawHtml;
      _matchKeys.clear();
    });
    _searchFocusNode.unfocus();
  }

  void _runSearch(String query, {bool updateIndex = true}) {
    if (query.isEmpty) {
      setState(() {
        _highlightedHtml = _rawHtml;
        _totalMatchCount = 0;
        _currentMatchIndex = 0;
        _matchKeys.clear();
      });
      return;
    }

    int count = 0;
    final highlighted = WikiUtils.highlightHtml(_rawHtml, query, _currentMatchIndex, (c) {
      count = c;
    });

    setState(() {
      _highlightedHtml = highlighted;
      _totalMatchCount = count;
      if (_matchKeys.length != count) {
        _matchKeys = List.generate(count, (index) => GlobalKey());
      }
      if (updateIndex) {
        if (count > 0) {
          _currentMatchIndex = 0;
        } else {
          _currentMatchIndex = -1;
        }
      }
    });

    if (count > 0 && updateIndex) {
      _scrollToCurrentMatch();
    }
  }

  void _nextMatch() {
    if (_totalMatchCount <= 1) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex + 1) % _totalMatchCount;
    });
    _runSearch(_searchController.text, updateIndex: false);
    _scrollToCurrentMatch();
  }

  void _prevMatch() {
    if (_totalMatchCount <= 1) return;
    setState(() {
      _currentMatchIndex = (_currentMatchIndex - 1 + _totalMatchCount) % _totalMatchCount;
    });
    _runSearch(_searchController.text, updateIndex: false);
    _scrollToCurrentMatch();
  }

  void _scrollToCurrentMatch() {
    if (_totalMatchCount == 0 || _currentMatchIndex < 0 || _currentMatchIndex >= _matchKeys.length) return;
    final key = _matchKeys[_currentMatchIndex];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = key.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          alignment: 0.5,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentProject = ref.watch(appStateProvider);
    final wikiContent = ref.watch(wikiApiProvider(widget.title));
    final langCode = ref.watch(languageProvider);
    final theme = Theme.of(context);

    /// Fallback fonts for Javanese and other scripts
    final List<String> fontFallbacks = [
      GoogleFonts.notoSansJavanese().fontFamily!,
      'Roboto',
    ];

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
      _htmlWidgetKey = GlobalKey<HtmlWidgetState>();
      _isSearchActive = false;
      _searchController.clear();
      _totalMatchCount = 0;
      _currentMatchIndex = 0;
      _rawHtml = '';
      _highlightedHtml = '';
      _matchKeys.clear();
    }

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyF, control: true): _startSearch,
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true): _startSearch,
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final deviceType = ResponsiveUtils.getDeviceType(context);
          final isLandscape = ResponsiveUtils.isLandscape(context);
          final isCompact = deviceType == DeviceType.compact;
          final isTablet = deviceType != DeviceType.compact;
          final isCompactLandscape = isCompact && isLandscape;
          final isCompactPortrait = isCompact && !isLandscape;
          final isTabletLandscape = isTablet && isLandscape;
          final bool showShortcutsSideBar =
              isTabletLandscape || deviceType == DeviceType.expanded;

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
            drawer: DrawerMenu(),
            body: Row(
              children: [
                if (showShortcutsSideBar) const ShortcutsSidebar(),
                Expanded(
                  child: Stack(
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: wikiContent.when(
                            data: (data) {
                              String htmlContent;
                              String? imageUrl;

                              if (data is Map<String, dynamic>) {
                                htmlContent = data['html'] ?? '';
                                imageUrl = data['imageUrl'];
                              } else if (data is String) {
                                htmlContent = data;
                              } else {
                                htmlContent = '';
                              }

                              if (_rawHtml != htmlContent) {
                                _rawHtml = htmlContent;
                                if (_isSearchActive && _searchController.text.isNotEmpty) {
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    _runSearch(_searchController.text, updateIndex: false);
                                  });
                                }
                              }

                              final displayedHtml = (_isSearchActive && _searchController.text.isNotEmpty)
                                  ? _highlightedHtml
                                  : htmlContent;

                              return SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ArticleHeroImage(
                                      theme: Theme.of(context),
                                      title: widget.title,
                                      imageUrl: imageUrl ?? '',
                                      project: currentProject,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: SelectionArea(
                                        child: HtmlWidget(
                                          displayedHtml,
                                          key: _htmlWidgetKey,
                                          textStyle:
                                              GoogleFonts.notoSerif(
                                                fontSize: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.fontSize,
                                                height: 1.8,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.9),
                                              ).copyWith(
                                                fontFamilyFallback:
                                                    fontFallbacks,
                                              ),
                                          onTapUrl: (url) =>
                                              WikiUtils.handleTapUrl(
                                                context,
                                                url,
                                                htmlContent,
                                                currentProject,
                                                langCode,
                                              ),
                                          customStylesBuilder: (element) =>
                                              WikiUtils.customStyles(
                                                context,
                                                element,
                                              ),
                                          customWidgetBuilder: (element) {
                                            final sharedWidget =
                                                WikiUtils.customWidgetBuilder(
                                                  context,
                                                  element,
                                                );
                                            if (sharedWidget != null) {
                                              return sharedWidget;
                                            }

                                            if (element.localName == 'span' &&
                                                element.classes.contains(
                                                  'search-highlight',
                                                )) {
                                              final indexStr =
                                                  element.attributes[
                                                    'data-index'
                                                  ] ??
                                                  '0';
                                              final index =
                                                  int.tryParse(indexStr) ?? 0;
                                              final text = element.text;
                                              final isActive =
                                                  index == _currentMatchIndex;

                                              if (index >= 0 &&
                                                  index < _matchKeys.length) {
                                                return InlineCustomWidget(
                                                  alignment:
                                                      PlaceholderAlignment
                                                          .baseline,
                                                  baseline:
                                                      TextBaseline.alphabetic,
                                                  child: Container(
                                                    key: _matchKeys[index],
                                                    color: isActive
                                                        ? Colors.orange
                                                        : Colors.yellow,
                                                    padding:
                                                        const EdgeInsets
                                                            .symmetric(
                                                          vertical: 2,
                                                        ),
                                                    child: Text(
                                                      text,
                                                      style: GoogleFonts
                                                          .notoSerif(
                                                            fontSize: Theme.of(
                                                                  context,
                                                                )
                                                                .textTheme
                                                                .bodyMedium
                                                                ?.fontSize,
                                                            height: 1.8,
                                                            color: Theme.of(
                                                                  context,
                                                                )
                                                                .colorScheme
                                                                .onSurface
                                                                .withValues(
                                                                  alpha: 0.9,
                                                                ),
                                                          )
                                                          .copyWith(
                                                            fontFamilyFallback:
                                                                fontFallbacks,
                                                            fontWeight:
                                                                isActive
                                                                    ? FontWeight
                                                                        .bold
                                                                    : FontWeight
                                                                        .normal,
                                                          ),
                                                    ),
                                                  ),
                                                );
                                              }
                                            }

                                            if (element.classes.contains(
                                              'gallery',
                                            )) {
                                              return _buildNativeGallery(
                                                element,
                                              );
                                            }

                                            final isThumb =
                                                element.classes.contains(
                                                  'thumb',
                                                ) ||
                                                (element.localName ==
                                                        'figure' &&
                                                    element.attributes['typeof']
                                                            ?.contains(
                                                              'mw:File/Thumb',
                                                            ) ==
                                                        true);

                                            if (isThumb) {
                                              if (element.classes.contains(
                                                'hidden-hero-container',
                                              )) {
                                                return const SizedBox.shrink();
                                              }

                                              final img =
                                                  element.localName == 'img'
                                                  ? element
                                                  : element.querySelector(
                                                      'img',
                                                    );

                                              if (img != null &&
                                                  img.classes.contains(
                                                    'wiki-inline-icon',
                                                  )) {
                                                return null;
                                              }

                                              if (img != null) {
                                                final caption =
                                                    element
                                                        .querySelector(
                                                          '.caption',
                                                        )
                                                        ?.text ??
                                                    element
                                                        .querySelector(
                                                          '.thumbcaption',
                                                        )
                                                        ?.text ??
                                                    element
                                                        .querySelector(
                                                          'figcaption',
                                                        )
                                                        ?.text;

                                                return _buildFullWidthImage(
                                                  img,
                                                  caption,
                                                );
                                              }
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ),
                                    const WikiFooter(),
                                    const SizedBox(height: 100),
                                  ],
                                ),
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
                if (isCompactLandscape || isTablet)
                  Container(
                    width: 56,
                    color: theme.colorScheme.primary,
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
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
            bottomNavigationBar: isCompactPortrait
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

  Widget _buildNativeGallery(dom.Element galleryElement) {
    final items = galleryElement.querySelectorAll('.gallerybox');
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 280,
      margin: const EdgeInsets.symmetric(vertical: 24),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final box = items[index];
          final img = box.querySelector('img');
          final caption = box.querySelector('.gallerytext')?.text ?? '';

          if (img == null) return const SizedBox.shrink();
          final src = img.attributes['src'] ?? '';
          final fullImageUrl = src.startsWith('http') ? src : 'https:$src';

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ImageScreen(imagePath: fullImageUrl),
                ),
              );
            },
            child: Container(
              width: 300,
              margin: const EdgeInsets.only(right: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Hero(
                      tag: fullImageUrl,
                      child: Image.network(
                        fullImageUrl,
                        fit: BoxFit.cover,
                        headers: WikiConfig.uaHeaders,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                        child: Text(
                          caption,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFullWidthImage(dom.Element img, String? caption) {
    final src = img.attributes['src'] ?? '';
    if (src.isEmpty) return const SizedBox.shrink();
    final fullImageUrl = src.startsWith('http') ? src : 'https:$src';
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ImageScreen(imagePath: fullImageUrl),
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Hero(
                tag: fullImageUrl,
                child: Image.network(
                  fullImageUrl,
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      width: double.infinity,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.05,
                      ),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 100,
                    width: double.infinity,
                    color: theme.colorScheme.errorContainer.withValues(
                      alpha: 0.1,
                    ),
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              ),
            ),
          ),
          if (caption != null && caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Text(
                caption,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
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
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withValues(alpha: 0.5),
        onPressed: history.canGoBack
            ? () {
                ref.read(historyProvider.notifier).goBack();
                Navigator.of(context).pop();
              }
            : null,
      ),
      _buildDivider(theme),
      _buildActionButton(
        theme,
        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
        isBookmarked ? theme.colorScheme.primary : theme.colorScheme.onSurface,
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
      _buildDivider(theme),
      _buildActionButton(
        theme,
        Icons.share_outlined,
        theme.colorScheme.onSurface,
        onPressed: () {
          SharePlus.instance.share(ShareParams(uri: Uri.parse(pageUrl)));
        },
      ),
      _buildDivider(theme),
      _buildActionButton(
        theme,
        Icons.find_in_page_outlined,
        theme.colorScheme.onSurface,
        onPressed: _startSearch,
      ),
      _buildDivider(theme),
      _buildActionButton(
        theme,
        Icons.edit_outlined,
        theme.colorScheme.onSurface,
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
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('page_cant_open').tr()));
            }
          }
        },
      ),
      _buildDivider(theme),
      _buildActionButton(
        theme,
        Icons.arrow_forward_ios,
        history.canGoForward
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
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
          duration: const Duration(seconds: 3),
        ),
      );

      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        await WikiApiService.clearCache(
          currentProject,
          langCode,
          currentTitle,
        );
        ref.invalidate(wikiApiProvider(currentTitle));
      }
    }
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
          padding: const EdgeInsets.all(8.0),
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
      margin: const EdgeInsets.symmetric(horizontal: 6),
    );
  }

  Widget _buildSearchPanel(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
