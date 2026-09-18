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
    this.isPending = false,
    this.hasError = false,
  });

  /// Parse from DiscussionTools JSON item (`type == 'comment'`).
  factory WikiChatMessage.fromDiscussionToolsJson(
    Map<String, dynamic> json, {
    String? parentId,
    String? replyingToAuthor,
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

    String html = json['html'] as String? ?? '';
    // DiscussionTools HTML comments may contain trailing signatures or elements;
    // We clean unnecessary empty paragraphs or break tags if needed.

    final level = (json['level'] as num?)?.toInt() ?? 1;

    return WikiChatMessage(
      id: id,
      author: author,
      timestamp: dt,
      htmlContent: html,
      level: level,
      parentId: parentId,
      replyingToAuthor: replyingToAuthor,
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
