import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wikimedia_core/wikimedia_core.dart';
import '../screens/article_screen.dart';
import '../services/connectivity_service.dart';
import 'app_state.dart';
import 'database_provider.dart';

class RandomArticleNotifier extends StateNotifier<bool> {
  RandomArticleNotifier() : super(false);

  static final Map<String, List<String>> _inMemoryCatalogCache = {};

  Future<String?> _getRandomTitleFromCatalog(
    String langCode,
    String projectStr,
  ) async {
    final catalogKey = '${langCode}_$projectStr';
    if (_inMemoryCatalogCache.containsKey(catalogKey) &&
        _inMemoryCatalogCache[catalogKey]!.isNotEmpty) {
      final list = _inMemoryCatalogCache[catalogKey]!;
      return list[Random().nextInt(list.length)];
    }

    final configuredPath = WikiConfig.getRandomPagesFile(langCode, projectStr);
    final candidates = [
      if (configuredPath != null && configuredPath.isNotEmpty) configuredPath,
      'assets/data/${langCode}_${projectStr}_pages.json',
    ];

    for (final relPath in candidates) {
      try {
        String? jsonStr;
        // 1. Try local documents directory (OTA synced)
        try {
          final docDir = await getApplicationDocumentsDirectory();
          final localFile = File('${docDir.path}/$relPath');
          if (await localFile.exists()) {
            jsonStr = await localFile.readAsString();
          }
        } catch (_) {}

        // 2. Try bundled asset
        if (jsonStr == null || jsonStr.isEmpty) {
          try {
            jsonStr = await rootBundle.loadString(relPath);
          } catch (_) {}
        }

        if (jsonStr != null && jsonStr.isNotEmpty) {
          final decoded = jsonDecode(jsonStr);
          if (decoded is List) {
            final titles = decoded
                .map((e) => e.toString().trim())
                .where((t) => t.isNotEmpty)
                .toList();
            if (titles.isNotEmpty) {
              _inMemoryCatalogCache[catalogKey] = titles;
              return titles[Random().nextInt(titles.length)];
            }
          }
        }
      } catch (_) {}
    }
    return null;
  }

  Future<void> navigateToRandomArticle(
    BuildContext context,
    WidgetRef ref,
  ) async {
    state = true;
    try {
      final currentProject = ref.read(appStateProvider);
      final langCode = ref.read(languageProvider);
      final projectStr = currentProject.name.toLowerCase();
      final db = ref.read(appDatabaseProvider);

      final isOnline = await ConnectivityService.isOnline();
      ref.read(isOnlineProvider.notifier).setOnline(isOnline);
      String? randomTitle;
      bool isFromOfflineCache = false;

      // 1. Check if a pre-generated page catalog exists (e.g. Nias Wikibooks)
      randomTitle = await _getRandomTitleFromCatalog(langCode, projectStr);

      // 2. If not found in catalog, query online API
      if (randomTitle == null && isOnline) {
        try {
          randomTitle = await WikiApiService.fetchRandomArticleTitle(
            langCode,
            projectStr,
          );
          if (randomTitle != null) {
            ref.read(isOnlineProvider.notifier).setOnline(true);
          }
        } catch (_) {
          // Fall back to offline database
        }
      }

      // 3. If still null, draw from local cached database
      if (randomTitle == null) {
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

final randomArticleProvider =
    StateNotifierProvider<RandomArticleNotifier, bool>((ref) {
      return RandomArticleNotifier();
    });
