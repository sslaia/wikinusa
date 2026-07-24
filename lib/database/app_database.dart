import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

part 'app_database.g.dart';

@DataClassName('ArticleCache')
class ArticleCaches extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get project => text()();
  TextColumn get languageCode => text()();
  TextColumn get pageTitle => text()();
  TextColumn get htmlContent => text()();
  TextColumn get heroImageUrl => text().nullable()();
  BoolColumn get isArticle => boolean().withDefault(const Constant(true))();
  DateTimeColumn get fetchedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {project, languageCode, pageTitle, isArticle},
      ];
}

@DriftDatabase(tables: [ArticleCaches])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<ArticleCache?> getCachedArticle({
    required String project,
    required String languageCode,
    required String pageTitle,
    required bool isArticle,
  }) {
    return (select(articleCaches)
          ..where((t) =>
              t.project.equals(project) &
              t.languageCode.equals(languageCode) &
              t.pageTitle.equals(pageTitle) &
              t.isArticle.equals(isArticle)))
        .getSingleOrNull();
  }

  Future<int> upsertArticle({
    required String project,
    required String languageCode,
    required String pageTitle,
    required String htmlContent,
    String? heroImageUrl,
    required bool isArticle,
  }) {
    return into(articleCaches).insertOnConflictUpdate(
      ArticleCachesCompanion.insert(
        project: project,
        languageCode: languageCode,
        pageTitle: pageTitle,
        htmlContent: htmlContent,
        heroImageUrl: Value(heroImageUrl),
        isArticle: Value(isArticle),
        fetchedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> clearCache({
    required String project,
    required String languageCode,
    String? pageTitle,
  }) {
    if (pageTitle != null && pageTitle.isNotEmpty) {
      return (delete(articleCaches)
            ..where((t) =>
                t.project.equals(project) &
                t.languageCode.equals(languageCode) &
                t.pageTitle.equals(pageTitle)))
          .go();
    } else {
      return (delete(articleCaches)
            ..where((t) =>
                t.project.equals(project) &
                t.languageCode.equals(languageCode)))
          .go();
    }
  }

  Future<int> clearAllCache() {
    return delete(articleCaches).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'wikinusa_offline.sqlite'));

    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    final cachebase = await getTemporaryDirectory();
    sqlite3.tempDirectory = cachebase.path;

    return NativeDatabase.createInBackground(file);
  });
}
