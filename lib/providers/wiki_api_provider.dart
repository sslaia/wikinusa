import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_state.dart';
import '../services/wiki_api_service.dart';

/// Provider for fetching Wiki content.
/// Returns a String for articles, and a List<HomePageSection> for the home page.
final wikiApiProvider = FutureProvider.autoDispose.family<dynamic, String?>((ref, pageTitleArg) async {
  final currentProject = ref.watch(appStateProvider);
  final langCode = ref.watch(languageProvider);

  String pageTitle;
  bool isArticle;

  if (pageTitleArg == null || pageTitleArg.isEmpty) {
    // HomeScreen request: Use "Main Page" as default title for REST API v1
    pageTitle = 'Main Page';
    isArticle = false;
  } else {
    // ArticleScreen request
    pageTitle = pageTitleArg;
    isArticle = true;
  }

  return WikiApiService.fetchPageHtml(currentProject, langCode, pageTitle, isArticle);
});
