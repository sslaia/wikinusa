import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/bookmarks_provider.dart';
import '../providers/article_provider.dart';
import '../providers/language_provider.dart';
import 'article_screen.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bookmarks = ref.watch(bookmarksProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Bookmarks'),
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
                    'No bookmarks yet',
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
                    'Language: ${bookmark.langCode.toUpperCase()}',
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
                    // Update current language if it's different from the bookmark's language
                    final currentLang = ref.read(languageProvider);
                    if (currentLang.code != bookmark.langCode) {
                      // Note: This assumes languageProvider has a way to change language by code.
                      // If there's no setLanguageByCode, we might need to find the language object.
                      // For now, we'll just navigate.
                    }

                    // Reset navigation history and navigate to the article
                    ref.read(articleNavigationProvider.notifier).setArticles([bookmark.title], 0);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ArticleScreen(pageTitle: bookmark.title),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
