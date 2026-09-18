import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:wikimedia_core/wikimedia_core.dart';
import '../models/chat_message.dart';
import 'quote_reply_preview.dart';

/// Bottom message composer with text input, send action, and quote preview.
class ChatComposer extends StatefulWidget {
  final ProjectType project;
  final WikiChatMessage? replyingToMessage;
  final VoidCallback onCancelReply;
  final Future<void> Function(String message) onSend;
  final bool isSubmitting;

  const ChatComposer({
    super.key,
    required this.project,
    this.replyingToMessage,
    required this.onCancelReply,
    required this.onSend,
    this.isSubmitting = false,
  });

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _canSend = false;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final canSend = _textController.text.trim().isNotEmpty;
    if (canSend != _canSend) {
      setState(() => _canSend = canSend);
    }
  }

  @override
  void didUpdateWidget(covariant ChatComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If a new reply was triggered, autofocus composer
    if (widget.replyingToMessage != null &&
        oldWidget.replyingToMessage?.id != widget.replyingToMessage?.id) {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _textController.text.trim();
    if (text.isEmpty || widget.isSubmitting) return;

    _textController.clear();
    await widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = widget.project.getThemedColor(isDark);

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainer
            : theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.replyingToMessage != null)
              QuoteReplyPreview(
                message: widget.replyingToMessage!,
                project: widget.project,
                onCancel: widget.onCancelReply,
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? theme.colorScheme.surfaceContainerHigh
                            : theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.25),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        enabled: !widget.isSubmitting,
                        minLines: 1,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        style: theme.textTheme.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'chat_reply_hint'.tr(),
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: _canSend && !widget.isSubmitting
                            ? accentColor
                            : theme.colorScheme.surfaceContainerHighest,
                        foregroundColor: _canSend && !widget.isSubmitting
                            ? (isDark
                                ? theme.colorScheme.onPrimaryContainer
                                : Colors.white)
                            : theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                        minimumSize: const Size(44, 44),
                        shape: const CircleBorder(),
                      ),
                      onPressed:
                          (_canSend && !widget.isSubmitting) ? _handleSend : null,
                      icon: widget.isSubmitting
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDark
                                    ? theme.colorScheme.onPrimaryContainer
                                    : Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
