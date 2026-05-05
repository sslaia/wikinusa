import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/history_provider.dart';
import '../providers/bookmarks_provider.dart';
import '../screens/article_screen.dart';

class ArticleSidebar extends ConsumerWidget {
  const ArticleSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider).stack.reversed.toList();
    final bookmarks = ref.watch(bookmarksProvider);
    final theme = Theme.of(context);

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              indicatorColor: theme.colorScheme.primary,
              tabs: [
                Tab(text: 'bookmarks'.tr()),
                Tab(text: 'history'.tr()),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildBookmarksList(context, bookmarks, theme),
                  _buildHistoryList(context, history, theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarksList(BuildContext context, List bookmarks, ThemeData theme) {
    if (bookmarks.isEmpty) {
      return Center(
        child: Text(
          'bookmarks_empty'.tr(),
          style: theme.textTheme.bodySmall,
        ),
      );
    }

    return ListView.builder(
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final bookmark = bookmarks[index];
        return ListTile(
          leading: const Icon(Icons.bookmark_outline, size: 20),
          title: Text(
            bookmark.title,
            style: const TextStyle(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            bookmark.projectName,
            style: theme.textTheme.labelSmall,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ArticleScreen(title: bookmark.title),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryList(BuildContext context, List<String> history, ThemeData theme) {
    if (history.isEmpty) {
      return Center(
        child: Text(
          'history_empty'.tr(), // Assuming this key exists or just use a string
          style: theme.textTheme.bodySmall,
        ),
      );
    }

    return ListView.builder(
      itemCount: history.length,
      itemBuilder: (context, index) {
        final title = history[index];
        return ListTile(
          leading: const Icon(Icons.history, size: 20),
          title: Text(
            title,
            style: const TextStyle(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ArticleScreen(title: title),
              ),
            );
          },
        );
      },
    );
  }
}
