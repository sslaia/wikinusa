import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/bookmarks_provider.dart';
import '../providers/article_provider.dart';
import '../providers/language_provider.dart';
import 'article_screen.dart';
import 'webview_screen.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bookmarks = ref.watch(bookmarksProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('bookmarks').tr(),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.primary,
        elevation: 0,
      ),
      body: bookmarks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: theme.colorScheme.onSurface.withOpacity(0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'bookmarks_empty'.tr(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bookmarks.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final bookmark = bookmarks[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    bookmark.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    '${'language'.tr()}: ${bookmark.langCode.toUpperCase()}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: theme.colorScheme.error,
                    onPressed: () {
                      ref.read(bookmarksProvider.notifier).toggleBookmark(
                        bookmark.title,
                        bookmark.langCode,
                      );
                    },
                  ),
                  onTap: () {
                    final currentLangCode = ref.read(languageProvider).code;

                    if (currentLangCode == bookmark.langCode) {
                      // Update current language if it's different from the bookmark's language
                      // (Kept for future logic if needed)
                      /*
                      final currentLang = ref.read(languageProvider);
                      if (currentLang.code != bookmark.langCode) {
                        // Note: This assumes languageProvider has a way to change language by code.
                      }
                      */

                      // Reset navigation history and navigate to the native article screen
                      ref.read(articleNavigationProvider.notifier).setArticles([bookmark.title], 0);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ArticleScreen(pageTitle: bookmark.title),
                        ),
                      );
                    } else {
                      // Navigate to WebViewScreen for articles in different languages
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WebViewScreen(
                            langCode: bookmark.langCode,
                            pageTitle: bookmark.title,
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
    );
  }
}
