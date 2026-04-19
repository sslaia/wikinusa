import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/article.dart';
import '../../domain/entities/wiki_project.dart';
import '../../domain/repositories/article_repository.dart';
import '../datasources/remote_article_data_source.dart';

class ArticleRepositoryImpl implements ArticleRepository {
  final RemoteArticleDataSource remoteDataSource;

  ArticleRepositoryImpl(this.remoteDataSource);

  @override
  Future<Article> getArticleByTitle(String title, String langCode, WikiProject project) async {
    return await remoteDataSource.getArticle(title, langCode, project);
  }

  @override
  Future<String> getHomePage(String langCode, String title, WikiProject project) async {
    final prefs = await SharedPreferences.getInstance();
    // Include project name in cache key to avoid collisions between projects for the same title/lang
    final cacheKey = 'home_page_${project.name}_${langCode}_$title';
    final timestampKey = '${cacheKey}_timestamp';

    final cachedHtml = prefs.getString(cacheKey);
    final lastFetch = prefs.getInt(timestampKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Cache valid for 24 hours
    if (cachedHtml != null && (now - lastFetch) < 24 * 60 * 60 * 1000) {
      return cachedHtml;
    }

    try {
      final html = await remoteDataSource.getHomePage(langCode, title, project);

      if (html.isNotEmpty) {
        await prefs.setString(cacheKey, html);
        await prefs.setInt(timestampKey, now);
      }
      return html;
    } catch (e) {
      if (cachedHtml != null) return cachedHtml;
      rethrow;
    }
  }
}
