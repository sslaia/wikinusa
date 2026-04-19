import '../entities/article.dart';
import '../entities/wiki_project.dart';

abstract class ArticleRepository {
  Future<Article> getArticleByTitle(String title, String langCode, WikiProject project);
  Future<String> getHomePage(String langCode, String title, WikiProject project);
}
