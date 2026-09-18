import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/chat_message.dart';
import '../services/wiki_chat_api_service.dart';
import '../state/chat_providers.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_composer.dart';
import '../widgets/wiki_captcha_dialog.dart';

/// Conversation screen displaying all messages in a specific discussion topic thread.
class ChatConversationScreen extends ConsumerStatefulWidget {
  final String topicId;

  const ChatConversationScreen({
    super.key,
    required this.topicId,
  });

  @override
  ConsumerState<ChatConversationScreen> createState() =>
      _ChatConversationScreenState();
}

class _ChatConversationScreenState
    extends ConsumerState<ChatConversationScreen> {
  final ScrollController _scrollController = ScrollController();
  WikiChatMessage? _replyingToMessage;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendReply(String messageText) async {
    final conversationState =
        ref.read(topicConversationProvider(widget.topicId));
    final topic = conversationState.topic;

    if (topic == null) return;

    // Target comment ID: If replying to a specific message, use its ID.
    // Otherwise, reply to the last message in the thread or fallback to topic heading id.
    final targetCommentId = _replyingToMessage?.id ??
        (topic.messages.isNotEmpty ? topic.messages.last.id : topic.id);

    final replyingAuthor = _replyingToMessage?.author;

    // Clear replying state
    setState(() {
      _replyingToMessage = null;
    });

    final notifier =
        ref.read(topicConversationProvider(widget.topicId).notifier);

    Future<void> send([String? captchaWord, String? captchaId]) async {
      try {
        final success = await notifier.postReply(
          context: context,
          commentId: targetCommentId,
          wikitext: messageText,
          replyingToAuthor: replyingAuthor,
          captchaWord: captchaWord,
          captchaId: captchaId,
        );

        if (mounted) {
          if (success) {
            _scrollToBottom();
          } else {
            final error = ref
                .read(topicConversationProvider(widget.topicId))
                .errorMessage;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${'chat_send_failed'.tr()}: ${error ?? ""}'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      } on WikiCaptchaException catch (ce) {
        if (!mounted) return;
        final target = ref.read(chatTargetProvider);
        final token = await WikiCaptchaDialog.show(
          context,
          siteKey: ce.siteKey,
          domain: target.domain,
          pageTitle: target.pageTitle,
          captchaId: ce.id,
          captchaUrl: ce.url,
          captchaQuestion: ce.question,
          prefillContent: messageText,
        );
        if (token != null && token.isNotEmpty && mounted) {
          await send(token, ce.id);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('chat_captcha_desc'.tr()),
              action: SnackBarAction(
                label: 'retry'.tr(),
                onPressed: () => send(),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${'chat_send_failed'.tr()}: ${e.toString().replaceFirst("Exception: ", "")}',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }

    await send();
  }

  void _handleRetryFailedMessage(WikiChatMessage failedMsg) {
    final plainText = failedMsg.htmlContent
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();
    if (plainText.isEmpty) return;

    ref
        .read(topicConversationProvider(widget.topicId).notifier)
        .removePendingMessage(failedMsg.id);

    _handleSendReply(plainText);
  }

  void _openInBrowser() async {
    final target = ref.read(chatTargetProvider);
    final cleanPage = target.pageTitle.replaceAll(' ', '_');
    final anchor = widget.topicId.replaceAll(' ', '_');
    final url = 'https://${target.domain}/wiki/$cleanPage#$anchor';
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final target = ref.watch(chatTargetProvider);
    final conversationState =
        ref.watch(topicConversationProvider(widget.topicId));
    final topic = conversationState.topic;
    final auth = ref.watch(chatAuthAdapterProvider);
    final currentUsername = auth.currentUsername;

    final messages = conversationState.allMessages;
    final appBarForeground = theme.appBarTheme.foregroundColor ??
        (isDark ? theme.colorScheme.onSurface : Colors.white);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        foregroundColor: appBarForeground,
        iconTheme: IconThemeData(color: appBarForeground),
        actionsIconTheme: IconThemeData(color: appBarForeground),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              topic?.title ?? '...',
              style: (theme.appBarTheme.titleTextStyle ??
                      theme.textTheme.titleMedium)
                  ?.copyWith(
                color: appBarForeground,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (topic != null)
              Text(
                '${messages.length} ${messages.length == 1 ? "comment" : "comments"}',
                style: (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(
                  fontSize: 10,
                  color: Colors.white,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser_rounded),
            color: appBarForeground,
            tooltip: 'continue_in_browser'.tr(),
            onPressed: _openInBrowser,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Text(
                      'No comments yet.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isCurrentUser = currentUsername != null &&
                          msg.author.toLowerCase() ==
                              currentUsername.toLowerCase();

                      return ChatBubble(
                        message: msg,
                        isCurrentUser: isCurrentUser,
                        project: target.project,
                        langCode: target.langCode,
                        onReply: (repliedMsg) {
                          setState(() {
                            _replyingToMessage = repliedMsg;
                          });
                        },
                        onRetry: _handleRetryFailedMessage,
                      );
                    },
                  ),
          ),
          ChatComposer(
            project: target.project,
            replyingToMessage: _replyingToMessage,
            onCancelReply: () {
              setState(() {
                _replyingToMessage = null;
              });
            },
            onSend: _handleSendReply,
            isSubmitting: conversationState.isSubmitting,
          ),
        ],
      ),
    );
  }
}
