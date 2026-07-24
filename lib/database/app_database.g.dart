// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ArticleCachesTable extends ArticleCaches
    with TableInfo<$ArticleCachesTable, ArticleCache> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArticleCachesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _projectMeta = const VerificationMeta(
    'project',
  );
  @override
  late final GeneratedColumn<String> project = GeneratedColumn<String>(
    'project',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageCodeMeta = const VerificationMeta(
    'languageCode',
  );
  @override
  late final GeneratedColumn<String> languageCode = GeneratedColumn<String>(
    'language_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageTitleMeta = const VerificationMeta(
    'pageTitle',
  );
  @override
  late final GeneratedColumn<String> pageTitle = GeneratedColumn<String>(
    'page_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _htmlContentMeta = const VerificationMeta(
    'htmlContent',
  );
  @override
  late final GeneratedColumn<String> htmlContent = GeneratedColumn<String>(
    'html_content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heroImageUrlMeta = const VerificationMeta(
    'heroImageUrl',
  );
  @override
  late final GeneratedColumn<String> heroImageUrl = GeneratedColumn<String>(
    'hero_image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isArticleMeta = const VerificationMeta(
    'isArticle',
  );
  @override
  late final GeneratedColumn<bool> isArticle = GeneratedColumn<bool>(
    'is_article',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_article" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
  late final GeneratedColumn<DateTime> fetchedAt = GeneratedColumn<DateTime>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    project,
    languageCode,
    pageTitle,
    htmlContent,
    heroImageUrl,
    isArticle,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'article_caches';
  @override
  VerificationContext validateIntegrity(
    Insertable<ArticleCache> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('project')) {
      context.handle(
        _projectMeta,
        project.isAcceptableOrUnknown(data['project']!, _projectMeta),
      );
    } else if (isInserting) {
      context.missing(_projectMeta);
    }
    if (data.containsKey('language_code')) {
      context.handle(
        _languageCodeMeta,
        languageCode.isAcceptableOrUnknown(
          data['language_code']!,
          _languageCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_languageCodeMeta);
    }
    if (data.containsKey('page_title')) {
      context.handle(
        _pageTitleMeta,
        pageTitle.isAcceptableOrUnknown(data['page_title']!, _pageTitleMeta),
      );
    } else if (isInserting) {
      context.missing(_pageTitleMeta);
    }
    if (data.containsKey('html_content')) {
      context.handle(
        _htmlContentMeta,
        htmlContent.isAcceptableOrUnknown(
          data['html_content']!,
          _htmlContentMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_htmlContentMeta);
    }
    if (data.containsKey('hero_image_url')) {
      context.handle(
        _heroImageUrlMeta,
        heroImageUrl.isAcceptableOrUnknown(
          data['hero_image_url']!,
          _heroImageUrlMeta,
        ),
      );
    }
    if (data.containsKey('is_article')) {
      context.handle(
        _isArticleMeta,
        isArticle.isAcceptableOrUnknown(data['is_article']!, _isArticleMeta),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {project, languageCode, pageTitle, isArticle},
  ];
  @override
  ArticleCache map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ArticleCache(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      project: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project'],
      )!,
      languageCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language_code'],
      )!,
      pageTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}page_title'],
      )!,
      htmlContent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}html_content'],
      )!,
      heroImageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hero_image_url'],
      ),
      isArticle: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_article'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $ArticleCachesTable createAlias(String alias) {
    return $ArticleCachesTable(attachedDatabase, alias);
  }
}

class ArticleCache extends DataClass implements Insertable<ArticleCache> {
  final int id;
  final String project;
  final String languageCode;
  final String pageTitle;
  final String htmlContent;
  final String? heroImageUrl;
  final bool isArticle;
  final DateTime fetchedAt;
  const ArticleCache({
    required this.id,
    required this.project,
    required this.languageCode,
    required this.pageTitle,
    required this.htmlContent,
    this.heroImageUrl,
    required this.isArticle,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['project'] = Variable<String>(project);
    map['language_code'] = Variable<String>(languageCode);
    map['page_title'] = Variable<String>(pageTitle);
    map['html_content'] = Variable<String>(htmlContent);
    if (!nullToAbsent || heroImageUrl != null) {
      map['hero_image_url'] = Variable<String>(heroImageUrl);
    }
    map['is_article'] = Variable<bool>(isArticle);
    map['fetched_at'] = Variable<DateTime>(fetchedAt);
    return map;
  }

  ArticleCachesCompanion toCompanion(bool nullToAbsent) {
    return ArticleCachesCompanion(
      id: Value(id),
      project: Value(project),
      languageCode: Value(languageCode),
      pageTitle: Value(pageTitle),
      htmlContent: Value(htmlContent),
      heroImageUrl: heroImageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(heroImageUrl),
      isArticle: Value(isArticle),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory ArticleCache.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ArticleCache(
      id: serializer.fromJson<int>(json['id']),
      project: serializer.fromJson<String>(json['project']),
      languageCode: serializer.fromJson<String>(json['languageCode']),
      pageTitle: serializer.fromJson<String>(json['pageTitle']),
      htmlContent: serializer.fromJson<String>(json['htmlContent']),
      heroImageUrl: serializer.fromJson<String?>(json['heroImageUrl']),
      isArticle: serializer.fromJson<bool>(json['isArticle']),
      fetchedAt: serializer.fromJson<DateTime>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'project': serializer.toJson<String>(project),
      'languageCode': serializer.toJson<String>(languageCode),
      'pageTitle': serializer.toJson<String>(pageTitle),
      'htmlContent': serializer.toJson<String>(htmlContent),
      'heroImageUrl': serializer.toJson<String?>(heroImageUrl),
      'isArticle': serializer.toJson<bool>(isArticle),
      'fetchedAt': serializer.toJson<DateTime>(fetchedAt),
    };
  }

  ArticleCache copyWith({
    int? id,
    String? project,
    String? languageCode,
    String? pageTitle,
    String? htmlContent,
    Value<String?> heroImageUrl = const Value.absent(),
    bool? isArticle,
    DateTime? fetchedAt,
  }) => ArticleCache(
    id: id ?? this.id,
    project: project ?? this.project,
    languageCode: languageCode ?? this.languageCode,
    pageTitle: pageTitle ?? this.pageTitle,
    htmlContent: htmlContent ?? this.htmlContent,
    heroImageUrl: heroImageUrl.present ? heroImageUrl.value : this.heroImageUrl,
    isArticle: isArticle ?? this.isArticle,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  ArticleCache copyWithCompanion(ArticleCachesCompanion data) {
    return ArticleCache(
      id: data.id.present ? data.id.value : this.id,
      project: data.project.present ? data.project.value : this.project,
      languageCode: data.languageCode.present
          ? data.languageCode.value
          : this.languageCode,
      pageTitle: data.pageTitle.present ? data.pageTitle.value : this.pageTitle,
      htmlContent: data.htmlContent.present
          ? data.htmlContent.value
          : this.htmlContent,
      heroImageUrl: data.heroImageUrl.present
          ? data.heroImageUrl.value
          : this.heroImageUrl,
      isArticle: data.isArticle.present ? data.isArticle.value : this.isArticle,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ArticleCache(')
          ..write('id: $id, ')
          ..write('project: $project, ')
          ..write('languageCode: $languageCode, ')
          ..write('pageTitle: $pageTitle, ')
          ..write('htmlContent: $htmlContent, ')
          ..write('heroImageUrl: $heroImageUrl, ')
          ..write('isArticle: $isArticle, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    project,
    languageCode,
    pageTitle,
    htmlContent,
    heroImageUrl,
    isArticle,
    fetchedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArticleCache &&
          other.id == this.id &&
          other.project == this.project &&
          other.languageCode == this.languageCode &&
          other.pageTitle == this.pageTitle &&
          other.htmlContent == this.htmlContent &&
          other.heroImageUrl == this.heroImageUrl &&
          other.isArticle == this.isArticle &&
          other.fetchedAt == this.fetchedAt);
}

class ArticleCachesCompanion extends UpdateCompanion<ArticleCache> {
  final Value<int> id;
  final Value<String> project;
  final Value<String> languageCode;
  final Value<String> pageTitle;
  final Value<String> htmlContent;
  final Value<String?> heroImageUrl;
  final Value<bool> isArticle;
  final Value<DateTime> fetchedAt;
  const ArticleCachesCompanion({
    this.id = const Value.absent(),
    this.project = const Value.absent(),
    this.languageCode = const Value.absent(),
    this.pageTitle = const Value.absent(),
    this.htmlContent = const Value.absent(),
    this.heroImageUrl = const Value.absent(),
    this.isArticle = const Value.absent(),
    this.fetchedAt = const Value.absent(),
  });
  ArticleCachesCompanion.insert({
    this.id = const Value.absent(),
    required String project,
    required String languageCode,
    required String pageTitle,
    required String htmlContent,
    this.heroImageUrl = const Value.absent(),
    this.isArticle = const Value.absent(),
    this.fetchedAt = const Value.absent(),
  }) : project = Value(project),
       languageCode = Value(languageCode),
       pageTitle = Value(pageTitle),
       htmlContent = Value(htmlContent);
  static Insertable<ArticleCache> custom({
    Expression<int>? id,
    Expression<String>? project,
    Expression<String>? languageCode,
    Expression<String>? pageTitle,
    Expression<String>? htmlContent,
    Expression<String>? heroImageUrl,
    Expression<bool>? isArticle,
    Expression<DateTime>? fetchedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (project != null) 'project': project,
      if (languageCode != null) 'language_code': languageCode,
      if (pageTitle != null) 'page_title': pageTitle,
      if (htmlContent != null) 'html_content': htmlContent,
      if (heroImageUrl != null) 'hero_image_url': heroImageUrl,
      if (isArticle != null) 'is_article': isArticle,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
    });
  }

  ArticleCachesCompanion copyWith({
    Value<int>? id,
    Value<String>? project,
    Value<String>? languageCode,
    Value<String>? pageTitle,
    Value<String>? htmlContent,
    Value<String?>? heroImageUrl,
    Value<bool>? isArticle,
    Value<DateTime>? fetchedAt,
  }) {
    return ArticleCachesCompanion(
      id: id ?? this.id,
      project: project ?? this.project,
      languageCode: languageCode ?? this.languageCode,
      pageTitle: pageTitle ?? this.pageTitle,
      htmlContent: htmlContent ?? this.htmlContent,
      heroImageUrl: heroImageUrl ?? this.heroImageUrl,
      isArticle: isArticle ?? this.isArticle,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (project.present) {
      map['project'] = Variable<String>(project.value);
    }
    if (languageCode.present) {
      map['language_code'] = Variable<String>(languageCode.value);
    }
    if (pageTitle.present) {
      map['page_title'] = Variable<String>(pageTitle.value);
    }
    if (htmlContent.present) {
      map['html_content'] = Variable<String>(htmlContent.value);
    }
    if (heroImageUrl.present) {
      map['hero_image_url'] = Variable<String>(heroImageUrl.value);
    }
    if (isArticle.present) {
      map['is_article'] = Variable<bool>(isArticle.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<DateTime>(fetchedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArticleCachesCompanion(')
          ..write('id: $id, ')
          ..write('project: $project, ')
          ..write('languageCode: $languageCode, ')
          ..write('pageTitle: $pageTitle, ')
          ..write('htmlContent: $htmlContent, ')
          ..write('heroImageUrl: $heroImageUrl, ')
          ..write('isArticle: $isArticle, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ArticleCachesTable articleCaches = $ArticleCachesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [articleCaches];
}

typedef $$ArticleCachesTableCreateCompanionBuilder =
    ArticleCachesCompanion Function({
      Value<int> id,
      required String project,
      required String languageCode,
      required String pageTitle,
      required String htmlContent,
      Value<String?> heroImageUrl,
      Value<bool> isArticle,
      Value<DateTime> fetchedAt,
    });
typedef $$ArticleCachesTableUpdateCompanionBuilder =
    ArticleCachesCompanion Function({
      Value<int> id,
      Value<String> project,
      Value<String> languageCode,
      Value<String> pageTitle,
      Value<String> htmlContent,
      Value<String?> heroImageUrl,
      Value<bool> isArticle,
      Value<DateTime> fetchedAt,
    });

class $$ArticleCachesTableFilterComposer
    extends Composer<_$AppDatabase, $ArticleCachesTable> {
  $$ArticleCachesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get project => $composableBuilder(
    column: $table.project,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pageTitle => $composableBuilder(
    column: $table.pageTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get htmlContent => $composableBuilder(
    column: $table.htmlContent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get heroImageUrl => $composableBuilder(
    column: $table.heroImageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArticle => $composableBuilder(
    column: $table.isArticle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ArticleCachesTableOrderingComposer
    extends Composer<_$AppDatabase, $ArticleCachesTable> {
  $$ArticleCachesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get project => $composableBuilder(
    column: $table.project,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pageTitle => $composableBuilder(
    column: $table.pageTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get htmlContent => $composableBuilder(
    column: $table.htmlContent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get heroImageUrl => $composableBuilder(
    column: $table.heroImageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArticle => $composableBuilder(
    column: $table.isArticle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ArticleCachesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ArticleCachesTable> {
  $$ArticleCachesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get project =>
      $composableBuilder(column: $table.project, builder: (column) => column);

  GeneratedColumn<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pageTitle =>
      $composableBuilder(column: $table.pageTitle, builder: (column) => column);

  GeneratedColumn<String> get htmlContent => $composableBuilder(
    column: $table.htmlContent,
    builder: (column) => column,
  );

  GeneratedColumn<String> get heroImageUrl => $composableBuilder(
    column: $table.heroImageUrl,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isArticle =>
      $composableBuilder(column: $table.isArticle, builder: (column) => column);

  GeneratedColumn<DateTime> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$ArticleCachesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ArticleCachesTable,
          ArticleCache,
          $$ArticleCachesTableFilterComposer,
          $$ArticleCachesTableOrderingComposer,
          $$ArticleCachesTableAnnotationComposer,
          $$ArticleCachesTableCreateCompanionBuilder,
          $$ArticleCachesTableUpdateCompanionBuilder,
          (
            ArticleCache,
            BaseReferences<_$AppDatabase, $ArticleCachesTable, ArticleCache>,
          ),
          ArticleCache,
          PrefetchHooks Function()
        > {
  $$ArticleCachesTableTableManager(_$AppDatabase db, $ArticleCachesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArticleCachesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArticleCachesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArticleCachesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> project = const Value.absent(),
                Value<String> languageCode = const Value.absent(),
                Value<String> pageTitle = const Value.absent(),
                Value<String> htmlContent = const Value.absent(),
                Value<String?> heroImageUrl = const Value.absent(),
                Value<bool> isArticle = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
              }) => ArticleCachesCompanion(
                id: id,
                project: project,
                languageCode: languageCode,
                pageTitle: pageTitle,
                htmlContent: htmlContent,
                heroImageUrl: heroImageUrl,
                isArticle: isArticle,
                fetchedAt: fetchedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String project,
                required String languageCode,
                required String pageTitle,
                required String htmlContent,
                Value<String?> heroImageUrl = const Value.absent(),
                Value<bool> isArticle = const Value.absent(),
                Value<DateTime> fetchedAt = const Value.absent(),
              }) => ArticleCachesCompanion.insert(
                id: id,
                project: project,
                languageCode: languageCode,
                pageTitle: pageTitle,
                htmlContent: htmlContent,
                heroImageUrl: heroImageUrl,
                isArticle: isArticle,
                fetchedAt: fetchedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ArticleCachesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ArticleCachesTable,
      ArticleCache,
      $$ArticleCachesTableFilterComposer,
      $$ArticleCachesTableOrderingComposer,
      $$ArticleCachesTableAnnotationComposer,
      $$ArticleCachesTableCreateCompanionBuilder,
      $$ArticleCachesTableUpdateCompanionBuilder,
      (
        ArticleCache,
        BaseReferences<_$AppDatabase, $ArticleCachesTable, ArticleCache>,
      ),
      ArticleCache,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ArticleCachesTableTableManager get articleCaches =>
      $$ArticleCachesTableTableManager(_db, _db.articleCaches);
}
