import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/article.dart';
import '../../domain/repositories/article_repository.dart';
import '../datasources/remote_article_data_source.dart';

class ArticleRepositoryImpl implements ArticleRepository {
  final RemoteArticleDataSource remoteDataSource;

  ArticleRepositoryImpl(this.remoteDataSource);

  @override
  Future<Article> getArticleByTitle(String title, String langCode) async {
    return await remoteDataSource.getArticle(title, langCode);
  }

  @override
  Future<String> getHomePage(String langCode, String title) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'home_page_${langCode}_$title';
    final timestampKey = '${cacheKey}_timestamp';

    final cachedHtml = prefs.getString(cacheKey);
    final lastFetch = prefs.getInt(timestampKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Cache valid for 24 hours (86,400,000 milliseconds)
    if (cachedHtml != null && (now - lastFetch) < 24 * 60 * 60 * 1000) {
      return cachedHtml;
    }

    try {
      // Fetch new data from remote
      final html = await remoteDataSource.getHomePage(langCode, title);

      // Update cache
      if (html.isNotEmpty) {
        await prefs.setString(cacheKey, html);
        await prefs.setInt(timestampKey, now);
      }
      return html;
    } catch (e) {
      // If remote fails, return cached data if available, even if expired
      if (cachedHtml != null) return cachedHtml;
      rethrow;
    }
  }
}
