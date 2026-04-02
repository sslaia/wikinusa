import '../entities/article.dart';

abstract class ArticleRepository {
  Future<Article> getArticleByTitle(String title, String langCode);
  Future<String> getHomePage(String langCode, String title);
}
