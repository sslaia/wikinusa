import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:wikimedia_core/wikimedia_core.dart';
import '../screens/article_screen.dart';
import '../services/connectivity_service.dart';
import 'app_state.dart';
import 'database_provider.dart';

class RandomArticleNotifier extends StateNotifier<bool> {
  RandomArticleNotifier() : super(false);

  Future<void> navigateToRandomArticle(BuildContext context, WidgetRef ref) async {
    state = true;
    try {
      final currentProject = ref.read(appStateProvider);
      final langCode = ref.read(languageProvider);
      final projectStr = currentProject.name.toLowerCase();
      final db = ref.read(appDatabaseProvider);

      final isOnline = await ConnectivityService.isOnline();
      String? randomTitle;
      bool isFromOfflineCache = false;

      if (isOnline) {
        try {
          randomTitle = await WikiApiService.fetchRandomArticleTitle(langCode, projectStr);
        } catch (_) {
          // If online fetch fails unexpectedly, fall back to offline
        }
      }

      if (randomTitle == null) {
        // Offline or online fetch returned null/failed: draw from local database
        final cachedArticle = await db.getRandomCachedArticle(
          project: projectStr,
          languageCode: langCode,
        );
        if (cachedArticle != null) {
          randomTitle = cachedArticle.pageTitle;
          isFromOfflineCache = true;
        }
      }

      if (!context.mounted) return;

      if (randomTitle != null) {
        if (isFromOfflineCache) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('random_article_offline'.tr()),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArticleScreen(title: randomTitle!),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('no_offline_articles_found'.tr()),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error_fetching_random_article'.tr())),
        );
      }
    } finally {
      state = false;
    }
  }
}

final randomArticleProvider = StateNotifierProvider<RandomArticleNotifier, bool>((ref) {
  return RandomArticleNotifier();
});
