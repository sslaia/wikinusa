import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:wikimedia_core/wikimedia_core.dart';
import '../../../providers/app_state.dart';
import '../../../providers/shared_prefs_provider.dart';
import '../config/chat_module_config.dart';
import '../models/chat_message.dart';
import '../models/chat_topic.dart';
import '../services/app_chat_auth_adapter.dart';
import '../services/chat_auth_adapter.dart';
import '../services/wiki_chat_api_service.dart';
import '../services/wiki_event_stream_service.dart';

/// Target configuration for WikiChat based on current language and project.
class ChatTargetInfo {
  final String langCode;
  final ProjectType project;
  final String domain;
  final String pageTitle;
  final bool isCustom;

  const ChatTargetInfo({
    required this.langCode,
    required this.project,
    required this.domain,
    required this.pageTitle,
    required this.isCustom,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatTargetInfo &&
          runtimeType == other.runtimeType &&
          langCode == other.langCode &&
          project == other.project &&
          domain == other.domain &&
          pageTitle == other.pageTitle &&
          isCustom == other.isCustom;

  @override
  int get hashCode =>
      Object.hash(langCode, project, domain, pageTitle, isCustom);
}

/// Provides current target info (language, project, domain, pageTitle) for WikiChat.
final chatTargetProvider = Provider<ChatTargetInfo>((ref) {
  final langCode = ref.watch(languageProvider);
  final project = ref.watch(appStateProvider);
  final prefs = ref.watch(sharedPreferencesProvider);

  final domain = ChatModuleConfig.getDomain(langCode, project);
  final pageTitle = ChatModuleConfig.getPageTitle(prefs, langCode, project);
  final isCustom =
      ChatModuleConfig.hasCustomPageTitle(prefs, langCode, project);

  return ChatTargetInfo(
    langCode: langCode,
    project: project,
    domain: domain,
    pageTitle: pageTitle,
    isCustom: isCustom,
  );
});

/// Auth adapter provider
final chatAuthAdapterProvider = Provider<ChatAuthAdapter>((ref) {
  return AppChatAuthAdapter(ref);
});

/// API service provider
final chatApiServiceProvider = Provider<WikiChatApiService>((ref) {
  final service = WikiChatApiService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Notifier managing topics list and live SSE updates for the active discussion page.
class ChatTopicsNotifier extends AsyncNotifier<List<WikiChatTopic>> {
  WikiEventStreamService? _sseService;
  Timer? _debounceTimer;

  @override
  Future<List<WikiChatTopic>> build() async {
    final target = ref.watch(chatTargetProvider);
    final api = ref.watch(chatApiServiceProvider);
    final auth = ref.watch(chatAuthAdapterProvider);

    // Dispose previous SSE connection
    _sseService?.dispose();
    _sseService = null;

    // Listen for real-time changes
    _sseService = WikiEventStreamService(
      domain: target.domain,
      pageTitle: target.pageTitle,
      onPageUpdated: () {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
          ref.invalidateSelf();
        });
      },
    );
    _sseService!.startListening();

    ref.onDispose(() {
      _debounceTimer?.cancel();
      _sseService?.dispose();
    });

    final token = await auth.getValidAccessToken();

    return await api.fetchTopics(
      domain: target.domain,
      pageTitle: target.pageTitle,
      accessToken: token,
    );
  }

  /// Manually trigger a refresh
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final target = ref.read(chatTargetProvider);
      final api = ref.read(chatApiServiceProvider);
      final auth = ref.read(chatAuthAdapterProvider);
      final token = await auth.getValidAccessToken();
      return await api.fetchTopics(
        domain: target.domain,
        pageTitle: target.pageTitle,
        accessToken: token,
      );
    });
  }

  /// Create a new discussion topic
  Future<bool> createNewTopic({
    required BuildContext context,
    required String topicTitle,
    required String message,
    String? captchaWord,
    String? captchaId,
  }) async {
    final auth = ref.read(chatAuthAdapterProvider);
    final target = ref.read(chatTargetProvider);
    final api = ref.read(chatApiServiceProvider);

    if (!auth.isAuthenticated) {
      final loggedIn = await auth.requireLogin(context);
      if (!loggedIn) {
        throw Exception('chat_login_required'.tr());
      }
    }

    final token = await auth.getValidAccessToken();
    if (token == null) {
      throw Exception('chat_login_required'.tr());
    }

    await api.createNewTopic(
      domain: target.domain,
      pageTitle: target.pageTitle,
      topicTitle: topicTitle,
      wikitext: message,
      accessToken: token,
      captchaWord: captchaWord,
      captchaId: captchaId,
    );

    // Refresh topics
    await refresh();
    return true;
  }
}

final chatTopicsProvider =
    AsyncNotifierProvider<ChatTopicsNotifier, List<WikiChatTopic>>(() {
  return ChatTopicsNotifier();
});

/// Optimistic message posting state for a specific topic conversation.
class TopicConversationState {
  final WikiChatTopic? topic;
  final List<WikiChatMessage> pendingMessages;
  final bool isSubmitting;
  final String? errorMessage;

  const TopicConversationState({
    this.topic,
    this.pendingMessages = const [],
    this.isSubmitting = false,
    this.errorMessage,
  });

  List<WikiChatMessage> get allMessages {
    if (topic == null) return pendingMessages;
    return [...topic!.messages, ...pendingMessages];
  }

  TopicConversationState copyWith({
    WikiChatTopic? topic,
    List<WikiChatMessage>? pendingMessages,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return TopicConversationState(
      topic: topic ?? this.topic,
      pendingMessages: pendingMessages ?? this.pendingMessages,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage,
    );
  }
}

class TopicConversationNotifier
    extends StateNotifier<TopicConversationState> {
  final Ref ref;
  final String topicId;

  TopicConversationNotifier(this.ref, this.topicId)
      : super(const TopicConversationState()) {
    _syncTopic();
  }

  void updateTopicFromList(List<WikiChatTopic> topics) {
    try {
      final found = topics.firstWhere((t) => t.id == topicId);
      state = state.copyWith(topic: found);
    } catch (_) {}
  }

  void _syncTopic() {
    final topics = ref.read(chatTopicsProvider).value;
    if (topics != null) {
      updateTopicFromList(topics);
    }
  }

  /// Post a reply comment to a topic or specific comment
  Future<bool> postReply({
    required BuildContext context,
    required String commentId,
    required String wikitext,
    String? replyingToAuthor,
    String? captchaWord,
    String? captchaId,
  }) async {
    final auth = ref.read(chatAuthAdapterProvider);
    final target = ref.read(chatTargetProvider);
    final api = ref.read(chatApiServiceProvider);

    if (!auth.isAuthenticated) {
      final loggedIn = await auth.requireLogin(context);
      if (!loggedIn) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: 'chat_login_required'.tr(),
        );
        return false;
      }
    }

    final token = await auth.getValidAccessToken();
    if (token == null) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'chat_login_required'.tr(),
      );
      return false;
    }

    final tempId = 'pending_${DateTime.now().millisecondsSinceEpoch}';
    final currentUsername = auth.currentUsername ??
        (await auth.fetchCurrentUsername(target.domain)) ??
        'You';

    final pendingMsg = WikiChatMessage(
      id: tempId,
      author: currentUsername,
      timestamp: DateTime.now(),
      htmlContent: '<p>${_escapeHtml(wikitext)}</p>',
      isPending: true,
      parentId: commentId,
      replyingToAuthor: replyingToAuthor,
    );

    // Add optimistic message
    state = state.copyWith(
      pendingMessages: [...state.pendingMessages, pendingMsg],
      isSubmitting: true,
      errorMessage: null,
    );

    try {
      await api.postReply(
        domain: target.domain,
        pageTitle: target.pageTitle,
        commentId: commentId,
        wikitext: wikitext,
        accessToken: token,
        captchaWord: captchaWord,
        captchaId: captchaId,
      );

      // Successfully posted on wiki; trigger global topic refresh
      await ref.read(chatTopicsProvider.notifier).refresh();

      // Clear pending message once refresh is done
      state = state.copyWith(
        pendingMessages:
            state.pendingMessages.where((m) => m.id != tempId).toList(),
        isSubmitting: false,
      );
      return true;
    } on WikiCaptchaException {
      // Remove temporary pending message and reset isSubmitting before rethrowing
      // so the UI can prompt the user to solve the CAPTCHA and retry without duplicate ghost messages
      state = state.copyWith(
        pendingMessages:
            state.pendingMessages.where((m) => m.id != tempId).toList(),
        isSubmitting: false,
      );
      rethrow;
    } catch (e) {
      // Mark pending message with error
      final updatedPending = state.pendingMessages.map((m) {
        if (m.id == tempId) {
          return m.copyWith(isPending: false, hasError: true);
        }
        return m;
      }).toList();

      state = state.copyWith(
        pendingMessages: updatedPending,
        isSubmitting: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  /// Remove a pending message by ID (used e.g. when retrying a failed message).
  void removePendingMessage(String messageId) {
    state = state.copyWith(
      pendingMessages:
          state.pendingMessages.where((m) => m.id != messageId).toList(),
    );
  }

  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}

final topicConversationProvider = StateNotifierProvider.autoDispose
    .family<TopicConversationNotifier, TopicConversationState, String>((
  ref,
  topicId,
) {
  final notifier = TopicConversationNotifier(ref, topicId);
  // Listen for changes in topics to update this topic in real time
  ref.listen(chatTopicsProvider, (prev, next) {
    if (next.hasValue && next.value != null) {
      notifier.updateTopicFromList(next.value!);
    }
  });
  return notifier;
});

/// Represents unread discussion status for the active target page.
class ChatUnreadState {
  final bool hasUnread;
  final int? latestRevId;
  final int? lastSeenRevId;

  const ChatUnreadState({
    this.hasUnread = false,
    this.latestRevId,
    this.lastSeenRevId,
  });

  ChatUnreadState copyWith({
    bool? hasUnread,
    int? latestRevId,
    int? lastSeenRevId,
  }) {
    return ChatUnreadState(
      hasUnread: hasUnread ?? this.hasUnread,
      latestRevId: latestRevId ?? this.latestRevId,
      lastSeenRevId: lastSeenRevId ?? this.lastSeenRevId,
    );
  }
}

class ChatUnreadNotifier extends StateNotifier<ChatUnreadState> {
  final Ref ref;

  ChatUnreadNotifier(this.ref) : super(const ChatUnreadState()) {
    checkUnread();
  }

  String _storageKey(ChatTargetInfo target) {
    return 'wikichat_last_seen_revid_${target.langCode.toLowerCase()}_${target.project.name.toLowerCase()}';
  }

  /// Check whether the target discussion page has new revisions since last seen.
  Future<void> checkUnread() async {
    try {
      final target = ref.read(chatTargetProvider);
      final prefs = ref.read(sharedPreferencesProvider);
      final api = ref.read(chatApiServiceProvider);
      final auth = ref.read(chatAuthAdapterProvider);
      final token = await auth.getValidAccessToken();

      final key = _storageKey(target);
      final lastSeen = prefs.getInt(key);

      final latestRevId = await api.fetchLatestRevisionId(
        domain: target.domain,
        pageTitle: target.pageTitle,
        accessToken: token,
      );

      if (latestRevId == null) {
        state = state.copyWith(
          hasUnread: false,
          lastSeenRevId: lastSeen,
        );
        return;
      }

      if (lastSeen == null) {
        // First time initialization: record current revid so user starts clean,
        // but any future edits will trigger the unread badge.
        await prefs.setInt(key, latestRevId);
        state = ChatUnreadState(
          hasUnread: false,
          latestRevId: latestRevId,
          lastSeenRevId: latestRevId,
        );
      } else {
        final hasUnread = latestRevId > lastSeen;
        state = ChatUnreadState(
          hasUnread: hasUnread,
          latestRevId: latestRevId,
          lastSeenRevId: lastSeen,
        );
      }
    } catch (_) {
      // Ignore network/service errors gracefully
    }
  }

  /// Mark the current target page discussions as read/seen.
  Future<void> markAsSeen() async {
    try {
      final target = ref.read(chatTargetProvider);
      final prefs = ref.read(sharedPreferencesProvider);
      int? latest = state.latestRevId;

      if (latest == null) {
        final api = ref.read(chatApiServiceProvider);
        final auth = ref.read(chatAuthAdapterProvider);
        final token = await auth.getValidAccessToken();
        latest = await api.fetchLatestRevisionId(
          domain: target.domain,
          pageTitle: target.pageTitle,
          accessToken: token,
        );
      }

      if (latest != null && latest > 0) {
        final key = _storageKey(target);
        await prefs.setInt(key, latest);
        state = ChatUnreadState(
          hasUnread: false,
          latestRevId: latest,
          lastSeenRevId: latest,
        );
      } else {
        state = state.copyWith(hasUnread: false);
      }
    } catch (_) {}
  }
}

final chatUnreadProvider =
    StateNotifierProvider<ChatUnreadNotifier, ChatUnreadState>((ref) {
  final notifier = ChatUnreadNotifier(ref);
  ref.listen(chatTargetProvider, (prev, next) {
    if (prev != next) {
      notifier.checkUnread();
    }
  });
  return notifier;
});
