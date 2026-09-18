import 'package:flutter/foundation.dart';
import 'chat_message.dart';

/// Represents a talk page discussion topic / section (`type == 'heading'`).
@immutable
class WikiChatTopic {
  final String id;
  final String title;
  final String? placeholderHeading;
  final int commentCount;
  final int authorCount;
  final DateTime? latestReplyTimestamp;
  final List<WikiChatMessage> messages;

  const WikiChatTopic({
    required this.id,
    required this.title,
    this.placeholderHeading,
    this.commentCount = 0,
    this.authorCount = 0,
    this.latestReplyTimestamp,
    this.messages = const [],
  });

  /// The target comment ID to use when replying to the topic as a whole.
  /// If there are real comments (not ending with `_content`), targets the last real comment.
  /// Otherwise, targets the section heading ID (`id`).
  String get replyTargetCommentId {
    for (int i = messages.length - 1; i >= 0; i--) {
      final msg = messages[i];
      if (!msg.id.endsWith('_content') && !msg.isPending) {
        return msg.id;
      }
    }
    return id;
  }

  /// Parse a heading item from DiscussionTools API JSON and recursively flatten
  /// nested `.replies` and subheadings into a chronological chat message list.
  factory WikiChatTopic.fromDiscussionToolsJson(
    Map<String, dynamic> json, {
    Map<String, Map<String, dynamic>>? allItemsById,
  }) {
    final id = json['id'] as String? ?? '';

    // In DiscussionTools, headings may provide 'html', 'line', or 'name'.
    // HTML often includes fallback <span> anchor elements (e.g. <span id="..."></span>Title).
    final rawTitle = (json['line'] as String?) ??
        (json['html'] as String?) ??
        (json['name'] as String?) ??
        '';

    String cleanTopicTitle = _cleanTitle(rawTitle);

    // Fallback to name or id if title was not in html or was empty
    if (cleanTopicTitle.isEmpty || cleanTopicTitle == 'h-') {
      final fallbackId =
          (json['name'] as String?) ?? (json['id'] as String?) ?? '';
      if (fallbackId.startsWith('h-') && fallbackId.length > 2) {
        var s = fallbackId.substring(2);
        // Remove trailing timestamp if present (e.g. -20260814083500)
        s = s.replaceFirst(RegExp(r'-\d{14}$'), '');
        cleanTopicTitle = s.replaceAll('_', ' ').trim();
      }
    }

    final commentCount = (json['commentCount'] as num?)?.toInt() ?? 0;
    final authorCount = (json['authorCount'] as num?)?.toInt() ?? 0;

    final rawLatest = json['latestReplyTimestamp'] as String?;
    DateTime? latestDt;
    if (rawLatest != null && rawLatest.isNotEmpty) {
      try {
        latestDt = DateTime.tryParse(rawLatest);
      } catch (_) {}
    }

    // Flatten recursive replies and incorporate subheading contents
    final flattenedMessages = <WikiChatMessage>[];
    final replies = json['replies'] as List<dynamic>? ?? [];

    final pendingSubheadings = <String>[];
    // Include othercontent from the top-level topic if present (e.g. archive list)
    final rootOtherContent = json['othercontent'] as String?;
    if (rootOtherContent != null && rootOtherContent.isNotEmpty) {
      pendingSubheadings.add(rootOtherContent);
    }

    void processItem(
      Map<String, dynamic> item, {
      String? parentId,
      String? replyingToAuthor,
    }) {
      final type = item['type'] as String?;
      final headingLevel = (item['headingLevel'] as num?)?.toInt() ??
          (item['headinglevel'] as num?)?.toInt();

      if (type == 'comment') {
        var html = item['html'] as String? ?? '';
        if (pendingSubheadings.isNotEmpty) {
          html = pendingSubheadings.join('') + html;
          pendingSubheadings.clear();
        }

        final msg = WikiChatMessage.fromDiscussionToolsJson(
          {
            ...item,
            'html': html,
          },
          parentId: parentId,
          replyingToAuthor: replyingToAuthor,
        );
        flattenedMessages.add(msg);

        // Child replies
        final children = item['replies'] as List<dynamic>? ?? [];
        for (final child in children) {
          if (child is Map<String, dynamic>) {
            processItem(
              child,
              parentId: msg.id,
              replyingToAuthor: msg.author,
            );
          }
        }
      } else if (type == 'heading' || headingLevel != null) {
        // Sub-heading item (level 3, 4, etc.)
        final itemId = item['id'] as String?;
        final fullItem = (itemId != null && allItemsById != null)
            ? (allItemsById[itemId] ?? item)
            : item;

        final rawSubTitle = (fullItem['line'] as String?) ??
            (fullItem['html'] as String?) ??
            (fullItem['name'] as String?) ??
            '';
        final cleanSubTitle = _cleanTitle(rawSubTitle);
        final otherContent = (fullItem['othercontent'] as String?) ?? '';

        if (cleanSubTitle.isNotEmpty) {
          pendingSubheadings.add('<h4><b>$cleanSubTitle</b></h4>');
        }
        if (otherContent.isNotEmpty) {
          pendingSubheadings.add(otherContent);
        }

        final children = item['replies'] as List<dynamic>? ?? [];
        for (final child in children) {
          if (child is Map<String, dynamic>) {
            processItem(
              child,
              parentId: parentId,
              replyingToAuthor: replyingToAuthor,
            );
          }
        }
      } else {
        // Other container
        final children = item['replies'] as List<dynamic>? ?? [];
        for (final child in children) {
          if (child is Map<String, dynamic>) {
            processItem(
              child,
              parentId: parentId,
              replyingToAuthor: replyingToAuthor,
            );
          }
        }
      }
    }

    for (final reply in replies) {
      if (reply is Map<String, dynamic>) {
        processItem(reply);
      }
    }

    // If there were subheadings or othercontent without any subsequent signed comment:
    if (pendingSubheadings.isNotEmpty) {
      var fallbackAuthor = 'Wiki';
      final topicName = json['name'] as String? ?? '';
      if (topicName.startsWith('h-') && topicName.length > 2) {
        final parts = topicName.substring(2).split('-');
        if (parts.isNotEmpty && parts[0].isNotEmpty) {
          fallbackAuthor = parts[0];
        }
      }

      flattenedMessages.add(
        WikiChatMessage(
          id: '${id}_content',
          author: fallbackAuthor,
          timestamp: latestDt,
          htmlContent: pendingSubheadings.join(''),
        ),
      );
      pendingSubheadings.clear();
    }

    // Sort messages chronologically by timestamp if timestamps exist
    flattenedMessages.sort((a, b) {
      if (a.timestamp == null && b.timestamp == null) return 0;
      if (a.timestamp == null) return -1;
      if (b.timestamp == null) return 1;
      return a.timestamp!.compareTo(b.timestamp!);
    });

    return WikiChatTopic(
      id: id,
      title: cleanTopicTitle.isEmpty ? 'Untitled Topic' : cleanTopicTitle,
      placeholderHeading: json['placeholderheading'] as String?,
      commentCount: commentCount > 0 ? commentCount : flattenedMessages.length,
      authorCount: authorCount > 0
          ? authorCount
          : (flattenedMessages.isNotEmpty ? 1 : 0),
      latestReplyTimestamp: latestDt ??
          (flattenedMessages.isNotEmpty
              ? flattenedMessages.last.timestamp
              : null),
      messages: flattenedMessages,
    );
  }

  static String _cleanTitle(String rawTitle) {
    String cleanTitle = rawTitle.replaceAll(RegExp(r'<[^>]*>'), '');
    cleanTitle = cleanTitle
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'&[^;]+;'), '')
        .trim();
    return cleanTitle;
  }

  WikiChatTopic copyWith({
    String? id,
    String? title,
    String? placeholderHeading,
    int? commentCount,
    int? authorCount,
    DateTime? latestReplyTimestamp,
    List<WikiChatMessage>? messages,
  }) {
    return WikiChatTopic(
      id: id ?? this.id,
      title: title ?? this.title,
      placeholderHeading: placeholderHeading ?? this.placeholderHeading,
      commentCount: commentCount ?? this.commentCount,
      authorCount: authorCount ?? this.authorCount,
      latestReplyTimestamp:
          latestReplyTimestamp ?? this.latestReplyTimestamp,
      messages: messages ?? this.messages,
    );
  }
}
