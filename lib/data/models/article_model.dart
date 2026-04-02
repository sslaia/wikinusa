import '../../domain/entities/article.dart';

class ArticleModel extends Article {
  const ArticleModel({
    required super.pageid,
    required super.title,
    required super.text,
  });

  factory ArticleModel.fromMap(Map<String, dynamic> map) {
    return ArticleModel(
      pageid: map['pageid'] as int,
      title: map['title'] as String,
      text: map['text'] as String,
    );
  }
}
