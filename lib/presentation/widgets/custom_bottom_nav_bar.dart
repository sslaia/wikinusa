import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wikinusa/presentation/pages/create_page_screen.dart';
import 'shortcuts_bottom_sheet.dart';
import '../providers/article_provider.dart';
import '../providers/language_provider.dart';
import '../pages/article_screen.dart';

enum _NavBarAction { drawer, home, createNewPage, refresh, shortcuts, random }

class _NavBarItem {
  final IconData icon;
  final String label;
  final _NavBarAction action;

  _NavBarItem({required this.icon, required this.label, required this.action});
}

class CustomBottomNavBar extends ConsumerWidget {
  final bool isHomeScreen;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const CustomBottomNavBar({
    super.key,
    this.isHomeScreen = false,
    this.scaffoldKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final items = [
      _NavBarItem(
        icon: Icons.menu,
        label: 'settings'.tr(),
        action: _NavBarAction.drawer,
      ),
      if (!isHomeScreen)
        _NavBarItem(
          icon: Icons.home,
          label: 'home'.tr(),
          action: _NavBarAction.home,
        ),
      if (isHomeScreen)
        _NavBarItem(
          icon: Icons.edit_note_outlined,
          label: 'create_new_page'.tr(),
          action: _NavBarAction.createNewPage,
        ),
      _NavBarItem(
        icon: Icons.refresh,
        label: 'refresh'.tr(),
        action: _NavBarAction.refresh,
      ),
      _NavBarItem(
        icon: Icons.switch_access_shortcut_outlined,
        label: 'shortcuts'.tr(),
        action: _NavBarAction.shortcuts,
      ),
      _NavBarItem(
        icon: Icons.shuffle,
        label: 'random'.tr(),
        action: _NavBarAction.random,
      ),
    ];

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: theme.colorScheme.surface,
      currentIndex: 0,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      selectedItemColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      unselectedItemColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      items: items.map((item) {
        return BottomNavigationBarItem(
          icon: Icon(item.icon, size: 24),
          label: item.label,
          tooltip: item.label,
        );
      }).toList(),
      onTap: (index) async {
        final action = items[index].action;
        if (action == _NavBarAction.drawer) {
          if (scaffoldKey != null) {
            scaffoldKey!.currentState?.openDrawer();
          } else {
            Scaffold.of(context).openDrawer();
          }
        } else if (action == _NavBarAction.home) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else if (action == _NavBarAction.createNewPage) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreatePageScreen(),
            ),
          );
        } else if (action == _NavBarAction.refresh) {
          if (isHomeScreen) {
            ref.invalidate(homePageProvider);
          } else {
            final currentTitle = ref
                .read(articleNavigationProvider)
                .currentTitle;
            if (currentTitle != null) {
              ref.invalidate(articleDetailProvider(currentTitle));
            }
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('refreshing_content').tr(),
              duration: Duration(milliseconds: 500),
            ),
          );
        } else if (action == _NavBarAction.shortcuts) {
          showShortcutsBottomSheet(context, ref);
        } else if (action == _NavBarAction.random) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('fetching_random_article').tr(),
              duration: Duration(seconds: 1),
            ),
          );

          try {
            final langCode = ref.read(languageProvider).code;
            final dataSource = ref.read(remoteArticleDataSourceProvider);
            final randomTitle = await dataSource.getRandomTitle(langCode);

            if (context.mounted) {
              if (isHomeScreen) {
                ref.read(articleNavigationProvider.notifier).setArticles([
                  randomTitle,
                ], 0);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ArticleScreen(pageTitle: randomTitle),
                  ),
                );
              } else {
                ref
                    .read(articleNavigationProvider.notifier)
                    .pushArticle(randomTitle);
              }
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${'error'.tr()}: ${e.toString()}')),
              );
            }
          }
        }
      },
    );
  }
}
