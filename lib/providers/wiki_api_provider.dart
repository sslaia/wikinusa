import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wikimedia_core/wikimedia_core.dart';
import 'app_state.dart';
import 'database_provider.dart';

/// Returns a String/Map for articles, and a `List<HomePageSection>` for the home page.
final wikiApiProvider = FutureProvider.autoDispose.family<dynamic, String?>((ref, pageTitleArg) async {
  final currentProject = ref.watch(appStateProvider);
  final langCode = ref.watch(languageProvider);
  final db = ref.watch(appDatabaseProvider);

  String pageTitle;
  bool isArticle;

  if (pageTitleArg == null || pageTitleArg.isEmpty) {
    pageTitle = 'Main Page';
    isArticle = false;
  } else {
    // ArticleScreen request
    pageTitle = pageTitleArg;
    isArticle = true;
  }

  return WikiApiService.fetchPageHtml(
    currentProject,
    langCode,
    pageTitle,
    isArticle,
    getCachedPage: (project, languageCode, title, isArt) async {
      final cached = await db.getCachedArticle(
        project: project,
        languageCode: languageCode,
        pageTitle: title,
        isArticle: isArt,
      );
      if (cached != null) {
        try {
          final decoded = jsonDecode(cached.htmlContent);
          if (isArt && decoded is Map<String, dynamic>) {
            return {
              ...decoded,
              'isOfflineCache': true,
            };
          } else if (!isArt && decoded is List) {
            return decoded.map((e) => HomePageSection.fromJson(e)).toList();
          }
        } catch (_) {}
      }
      return null;
    },
    saveCachedPage: (project, languageCode, title, content, heroImageUrl, isArt) async {
      await db.upsertArticle(
        project: project,
        languageCode: languageCode,
        pageTitle: title,
        htmlContent: content,
        heroImageUrl: heroImageUrl,
        isArticle: isArt,
      );
    },
  );
});
