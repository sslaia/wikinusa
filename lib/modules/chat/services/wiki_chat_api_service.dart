import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/chat_module_config.dart';
import '../models/chat_topic.dart';

/// Service for communicating with MediaWiki's DiscussionTools Action API.
class WikiChatApiService {
  final http.Client _client;

  WikiChatApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetch discussion topics and their comments from the specified talk page.
  Future<List<WikiChatTopic>> fetchTopics({
    required String domain,
    required String pageTitle,
    String? accessToken,
  }) async {
    final uri = Uri.https(domain, '/w/api.php', {
      'action': 'discussiontoolspageinfo',
      'page': pageTitle,
      'prop': 'threaditemshtml',
      'format': 'json',
      'formatversion': '2',
    });

    final headers = <String, String>{
      'User-Agent': ChatModuleConfig.userAgent,
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };

    final response = await _client.get(uri, headers: headers).timeout(
          const Duration(seconds: 15),
        );

    if (response.statusCode != 200) {
      throw Exception('Failed to load discussions (HTTP ${response.statusCode})');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;

    if (data.containsKey('error')) {
      final code = data['error']?['code'] as String?;
      final info = data['error']?['info'] as String?;
      if (code == 'missingtitle' || code == 'nosuchpage') {
        // Page does not exist yet; return empty list
        return [];
      }
      throw Exception(info ?? 'DiscussionTools API error ($code)');
    }

    final pageInfo = data['discussiontoolspageinfo'] as Map<String, dynamic>?;
    if (pageInfo == null) return [];

    final threadItems = pageInfo['threaditemshtml'] as List<dynamic>? ?? [];
    final topics = <WikiChatTopic>[];

    // Build lookup map of all items by ID to resolve subheadings and their othercontent
    final allItemsById = <String, Map<String, dynamic>>{};
    for (final it in threadItems) {
      if (it is Map<String, dynamic>) {
        final id = it['id'] as String?;
        if (id != null && id.isNotEmpty) {
          allItemsById[id] = it;
        }
      }
    }

    for (final item in threadItems) {
      if (item is Map<String, dynamic>) {
        final type = item['type'] as String?;
        final headingLevel = (item['headingLevel'] as num?)?.toInt() ??
            (item['headinglevel'] as num?)?.toInt();

        // In MediaWiki talk pages, discussion topics are strictly Level 2 headings (== Section ==).
        // Level 3+ headings (=== Subheading ===) are subsections within the message/topic.
        if (type == 'heading' && headingLevel == 2) {
          final topic = WikiChatTopic.fromDiscussionToolsJson(
            item,
            allItemsById: allItemsById,
          );
          // Omit empty lead section placeholder (id == 'h-' with 0 comments)
          if (topic.id == 'h-' &&
              topic.messages.isEmpty &&
              topic.commentCount == 0) {
            continue;
          }
          topics.add(topic);
        }
      }
    }

    return topics;
  }

  /// Fetch the latest revision ID for the specified page.
  /// Returns null if the page does not exist, has no revisions, or on network error.
  Future<int?> fetchLatestRevisionId({
    required String domain,
    required String pageTitle,
    String? accessToken,
  }) async {
    final uri = Uri.https(domain, '/w/api.php', {
      'action': 'query',
      'prop': 'revisions',
      'titles': pageTitle,
      'rvprop': 'ids',
      'format': 'json',
      'formatversion': '2',
    });

    final headers = <String, String>{
      'User-Agent': ChatModuleConfig.userAgent,
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };

    try {
      final response = await _client.get(uri, headers: headers).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode != 200) return null;

      final data = json.decode(response.body) as Map<String, dynamic>;
      final pages = data['query']?['pages'] as List<dynamic>?;
      if (pages == null || pages.isEmpty) return null;

      final page = pages.first as Map<String, dynamic>;
      if (page['missing'] == true) return null;

      final revisions = page['revisions'] as List<dynamic>?;
      if (revisions == null || revisions.isEmpty) return null;

      final rev = revisions.first as Map<String, dynamic>;
      return (rev['revid'] as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  /// Retrieve a CSRF token from MediaWiki API.
  Future<String> fetchCsrfToken({
    required String domain,
    required String accessToken,
  }) async {
    final uri = Uri.https(domain, '/w/api.php', {
      'action': 'query',
      'meta': 'tokens',
      'type': 'csrf',
      'format': 'json',
      'formatversion': '2',
    });

    final headers = {
      'User-Agent': ChatModuleConfig.userAgent,
      'Authorization': 'Bearer $accessToken',
    };

    final response = await _client.get(uri, headers: headers).timeout(
          const Duration(seconds: 15),
        );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch CSRF token (HTTP ${response.statusCode})');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final token = data['query']?['tokens']?['csrftoken'] as String?;

    if (token == null || token.isEmpty || token == '+\\') {
      throw Exception('Invalid CSRF token received. User might not be logged in.');
    }

    return token;
  }

  /// Post a reply comment to an existing comment or topic via `paction=addcomment`.
  Future<Map<String, dynamic>> postReply({
    required String domain,
    required String pageTitle,
    required String commentId,
    required String wikitext,
    required String accessToken,
    String? captchaWord,
    String? captchaId,
  }) async {
    final csrfToken = await fetchCsrfToken(
      domain: domain,
      accessToken: accessToken,
    );

    final uri = Uri.https(domain, '/w/api.php');
    final headers = {
      'User-Agent': ChatModuleConfig.userAgent,
      'Authorization': 'Bearer $accessToken',
    };

    // Defense-in-depth: Ensure commentId never contains synthetic '_content' suffix
    final sanitizedCommentId = commentId.endsWith('_content')
        ? commentId.substring(0, commentId.length - 8)
        : commentId;

    final body = {
      'action': 'discussiontoolsedit',
      'paction': 'addcomment',
      'page': pageTitle,
      'commentid': sanitizedCommentId,
      'wikitext': wikitext,
      'token': csrfToken,
      'format': 'json',
      'formatversion': '2',
      if (captchaWord != null && captchaWord.isNotEmpty) 'captchaword': captchaWord,
      if (captchaId != null && captchaId.isNotEmpty) 'captchaid': captchaId,
    };

    final response = await _client
        .post(uri, headers: headers, body: body)
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Failed to post reply (HTTP ${response.statusCode})');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;

    if (data.containsKey('error')) {
      final info = data['error']?['info'] as String?;
      throw Exception(info ?? 'Failed to post reply');
    }

    final dtEdit = data['discussiontoolsedit'] as Map<String, dynamic>?;
    if (dtEdit != null) {
      final editData = dtEdit['edit'] as Map<String, dynamic>?;
      if (editData != null && editData.containsKey('captcha')) {
        final captcha = editData['captcha'] as Map<String, dynamic>? ?? {};
        final siteKey = (captcha['key'] as String?) ?? '';
        final type = (captcha['type'] as String?) ?? 'hcaptcha';
        final captchaId = (captcha['id']?.toString());
        final url = (captcha['url'] as String?);
        final question = (captcha['question'] as String?);
        throw WikiCaptchaException(
          type: type,
          siteKey: siteKey,
          id: captchaId,
          url: url,
          question: question,
          message: 'MediaWiki requires CAPTCHA verification.',
        );
      }

      if (dtEdit['result'] != 'success') {
        throw Exception(dtEdit['message'] ?? 'Edit was not successful');
      }

      return dtEdit;
    }

    throw Exception('Unexpected response from server');
  }

  /// Create a new discussion topic using DiscussionTools API.
  Future<Map<String, dynamic>> createNewTopic({
    required String domain,
    required String pageTitle,
    required String topicTitle,
    required String wikitext,
    required String accessToken,
    String? captchaWord,
    String? captchaId,
  }) async {
    final csrfToken = await fetchCsrfToken(
      domain: domain,
      accessToken: accessToken,
    );

    final uri = Uri.https(domain, '/w/api.php');
    final headers = {
      'User-Agent': ChatModuleConfig.userAgent,
      'Authorization': 'Bearer $accessToken',
    };

    final body = {
      'action': 'discussiontoolsedit',
      'paction': 'addtopic',
      'page': pageTitle,
      'sectiontitle': topicTitle,
      'wikitext': wikitext,
      'token': csrfToken,
      'format': 'json',
      'formatversion': '2',
      if (captchaWord != null && captchaWord.isNotEmpty) 'captchaword': captchaWord,
      if (captchaId != null && captchaId.isNotEmpty) 'captchaid': captchaId,
    };

    final response = await _client
        .post(uri, headers: headers, body: body)
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception('Failed to create topic (HTTP ${response.statusCode})');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;

    if (data.containsKey('error')) {
      final info = data['error']?['info'] as String?;
      throw Exception(info ?? 'Failed to create topic');
    }

    final dtEdit = data['discussiontoolsedit'] as Map<String, dynamic>?;
    if (dtEdit != null) {
      final editData = dtEdit['edit'] as Map<String, dynamic>?;
      if (editData != null && editData.containsKey('captcha')) {
        final captcha = editData['captcha'] as Map<String, dynamic>? ?? {};
        final siteKey = (captcha['key'] as String?) ?? '';
        final type = (captcha['type'] as String?) ?? 'hcaptcha';
        final captchaId = (captcha['id']?.toString());
        final url = (captcha['url'] as String?);
        final question = (captcha['question'] as String?);
        throw WikiCaptchaException(
          type: type,
          siteKey: siteKey,
          id: captchaId,
          url: url,
          question: question,
          message: 'MediaWiki requires CAPTCHA verification.',
        );
      }

      if (dtEdit['result'] != 'success') {
        throw Exception(dtEdit['message'] ?? 'Topic creation was not successful');
      }

      return dtEdit;
    }

    throw Exception('Unexpected response from server');
  }

  void dispose() {
    _client.close();
  }
}

/// Thrown when MediaWiki anti-abuse (ConfirmEdit) returns a CAPTCHA challenge.
class WikiCaptchaException implements Exception {
  final String type;
  final String siteKey;
  final String? id;
  final String? url;
  final String? question;
  final String message;

  WikiCaptchaException({
    required this.type,
    this.siteKey = '',
    this.id,
    this.url,
    this.question,
    required this.message,
  });

  @override
  String toString() => message;
}
