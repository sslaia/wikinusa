import 'package:flutter/foundation.dart';

/// Represents a single comment/message on a MediaWiki talk page.
@immutable
class WikiChatMessage {
  final String id;
  final String author;
  final DateTime? timestamp;
  final String htmlContent;
  final int level;
  final String? parentId;
  final String? replyingToAuthor;
  final String? replyingToSnippet;
  final bool isPending;
  final bool hasError;

  const WikiChatMessage({
    required this.id,
    required this.author,
    this.timestamp,
    required this.htmlContent,
    this.level = 1,
    this.parentId,
    this.replyingToAuthor,
    this.replyingToSnippet,
    this.isPending = false,
    this.hasError = false,
  });

  /// Extracts the first clean line of text from [htmlContent] to display
  /// as a preview/snippet when quoting or replying, just like in WhatsApp.
  String get firstLineSnippet {
    if (htmlContent.isEmpty) return '';

    // Replace breaks and block boundaries with newlines
    var text = htmlContent
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(
            RegExp(r'</(p|div|h[1-6]|li|dd|dt|tr)>', caseSensitive: false),
            '\n');

    // Remove all remaining HTML tags
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');

    // Decode common HTML entities
    text = text
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&apos;', "'")
        .replaceAll('&#039;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#160;', ' ');

    for (final line in text.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return '';
  }

  /// The DiscussionTools comment or heading ID to use when replying to this message.
  /// If this message was generated from heading othercontent (ending with `_content`),
  /// returns the valid MediaWiki heading ID without `_content`.
  String get replyTargetCommentId {
    if (id.endsWith('_content')) {
      return id.substring(0, id.length - 8);
    }
    return id;
  }

  /// Parse from DiscussionTools JSON item (`type == 'comment'`).
  factory WikiChatMessage.fromDiscussionToolsJson(
    Map<String, dynamic> json, {
    String? parentId,
    String? replyingToAuthor,
    String? replyingToSnippet,
  }) {
    final id = json['id'] as String? ?? '';
    final author = json['author'] as String? ?? 'Anonymous';
    final rawTimestamp = json['timestamp'] as String?;
    DateTime? dt;
    if (rawTimestamp != null && rawTimestamp.isNotEmpty) {
      try {
        dt = DateTime.tryParse(rawTimestamp);
      } catch (_) {}
    }

    final html = json['html'] as String? ?? '';
    final level = (json['level'] as num?)?.toInt() ?? 1;

    return WikiChatMessage(
      id: id,
      author: author,
      timestamp: dt,
      htmlContent: html,
      level: level,
      parentId: parentId,
      replyingToAuthor: replyingToAuthor,
      replyingToSnippet: replyingToSnippet,
    );
  }

  WikiChatMessage copyWith({
    String? id,
    String? author,
    DateTime? timestamp,
    String? htmlContent,
    int? level,
    String? parentId,
    String? replyingToAuthor,
    String? replyingToSnippet,
    bool? isPending,
    bool? hasError,
  }) {
    return WikiChatMessage(
      id: id ?? this.id,
      author: author ?? this.author,
      timestamp: timestamp ?? this.timestamp,
      htmlContent: htmlContent ?? this.htmlContent,
      level: level ?? this.level,
      parentId: parentId ?? this.parentId,
      replyingToAuthor: replyingToAuthor ?? this.replyingToAuthor,
      replyingToSnippet: replyingToSnippet ?? this.replyingToSnippet,
      isPending: isPending ?? this.isPending,
      hasError: hasError ?? this.hasError,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WikiChatMessage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          author == other.author &&
          isPending == other.isPending &&
          hasError == other.hasError;

  @override
  int get hashCode => Object.hash(id, author, isPending, hasError);
}
