import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart'; // Required for StateNotifier in this project version
import '../../data/datasources/remote_article_data_source.dart';
import '../../data/repositories/article_repository_impl.dart';
import '../../domain/entities/article.dart';
import '../../domain/repositories/article_repository.dart';
import '../pages/home_page_builders/home_page_processor.dart';
import 'language_provider.dart';

final remoteArticleDataSourceProvider = Provider((ref) => RemoteArticleDataSource());

final pageTitlesProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final String response = await rootBundle.loadString('assets/data/page_titles.json');
  return json.decode(response);
});

final articleRepositoryProvider = Provider<ArticleRepository>((ref) {
  final remoteDataSource = ref.watch(remoteArticleDataSourceProvider);
  return ArticleRepositoryImpl(remoteDataSource);
});

final homePageProvider = FutureProvider<String>((ref) async {
  final langCode = ref.watch(languageProvider).code;
  
  // Wait for page titles to be loaded
  final titlesData = await ref.watch(pageTitlesProvider.future);
  
  String mainPageTitle = 'Main_Page';
  if (titlesData.containsKey(langCode)) {
    final langTitles = titlesData[langCode] as List;
    final mainPageEntry = langTitles.firstWhere(
      (entry) => entry.containsKey('main_page'),
      orElse: () => {'main_page': 'Main_Page'},
    );
    mainPageTitle = mainPageEntry['main_page'];
  }

  final repository = ref.watch(articleRepositoryProvider);
  
  try {
    final rawHtml = await repository.getHomePage(langCode, mainPageTitle);
    // Pre-process the HTML before handing it to the UI
    return HomePageProcessor.process(rawHtml, langCode);
  } catch (e) {
    // If the localized main page fails, try fallback to generic 'Main_Page'
    if (mainPageTitle != 'Main_Page') {
      final fallbackHtml = await repository.getHomePage(langCode, 'Main_Page');
      return HomePageProcessor.process(fallbackHtml, langCode);
    }
    rethrow;
  }
});

final articleDetailProvider = FutureProvider.family<Article, String>((
  ref,
  pageTitle,
) async {
  final repository = ref.watch(articleRepositoryProvider);
  final langCode = ref.watch(languageProvider).code;
  return await repository.getArticleByTitle(pageTitle, langCode);
});

// --- Navigation Logic ---

class ArticleNavigationState {
  final List<String> pageTitles;
  final int currentIndex;

  ArticleNavigationState({
    this.pageTitles = const [],
    this.currentIndex = 0,
  });

  String? get currentTitle => pageTitles.isNotEmpty ? pageTitles[currentIndex] : null;
  bool get canGoBack => currentIndex > 0;
  bool get canGoForward => currentIndex < pageTitles.length - 1;

  ArticleNavigationState copyWith({
    List<String>? pageTitles,
    int? currentIndex,
  }) {
    return ArticleNavigationState(
      pageTitles: pageTitles ?? this.pageTitles,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

class ArticleNavigationNotifier extends StateNotifier<ArticleNavigationState> {
  ArticleNavigationNotifier() : super(ArticleNavigationState());

  void setArticles(List<String> titles, int initialIndex) {
    state = ArticleNavigationState(pageTitles: titles, currentIndex: initialIndex);
  }

  void pushArticle(String title) {
    final List<String> currentTitles = List.from(state.pageTitles);
    final int nextIndex = state.currentIndex + 1;
    
    if (nextIndex < currentTitles.length) {
      currentTitles.removeRange(nextIndex, currentTitles.length);
    }
    
    currentTitles.add(title);
    state = state.copyWith(
      pageTitles: currentTitles,
      currentIndex: currentTitles.length - 1,
    );
  }

  void next() {
    if (state.canGoForward) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  void previous() {
    if (state.canGoBack) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }
}

final articleNavigationProvider =
    StateNotifierProvider<ArticleNavigationNotifier, ArticleNavigationState>((ref) {
  return ArticleNavigationNotifier();
});
