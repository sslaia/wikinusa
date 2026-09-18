import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wikimedia_core/wikimedia_core.dart';
import '../models/chat_message.dart';
import '../utils/chat_date_utils.dart';

/// Renders an individual talk page comment as a modern chat message bubble.
class ChatBubble extends StatelessWidget {
  final WikiChatMessage message;
  final bool isCurrentUser;
  final ProjectType project;
  final String langCode;
  final void Function(WikiChatMessage message)? onReply;
  final void Function(WikiChatMessage message)? onRetry;

  const ChatBubble({
    super.key,
    required this.message,
    this.isCurrentUser = false,
    required this.project,
    this.langCode = 'id',
    this.onReply,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = project.getThemedColor(isDark);

    // Limit indent to max 2 levels to prevent horizontal clipping on mobile
    final indentPadding = (message.level > 1 ? 16.0 : 0.0);

    return Padding(
      padding: EdgeInsets.only(
        left: isCurrentUser ? 40 : (12 + indentPadding),
        right: isCurrentUser ? 12 : 40,
        top: 4,
        bottom: 4,
      ),
      child: Column(
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Author & Timestamp Row
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isCurrentUser) ...[
                  _buildAvatar(theme, message.author, accentColor),
                  const SizedBox(width: 6),
                ],
                Text(
                  message.author,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isCurrentUser
                        ? accentColor
                        : theme.colorScheme.onSurface,
                  ),
                ),
                if (message.timestamp != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    _formatTimestamp(message.timestamp!),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
                if (message.isPending) ...[
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 10,
                    height: 10,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: accentColor,
                    ),
                  ),
                ],
                if (message.hasError) ...[
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: onRetry != null ? () => onRetry!(message) : null,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 14,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'retry'.tr(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.error,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Message Card / Bubble
          Container(
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? (isDark
                      ? theme.colorScheme.primaryContainer.withValues(alpha: 0.6)
                      : accentColor.withValues(alpha: 0.12))
                  : (isDark
                      ? theme.colorScheme.surfaceContainerHigh
                      : theme.colorScheme.surfaceContainerLow),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
                bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
              ),
              border: Border.all(
                color: isCurrentUser
                    ? accentColor.withValues(alpha: isDark ? 0.4 : 0.25)
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Replying to quote header if present
                if (message.replyingToAuthor != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(6),
                      border: Border(
                        left: BorderSide(color: accentColor, width: 3),
                      ),
                    ),
                    child: Text(
                      '${'chat_replying_to'.tr()}: @${message.replyingToAuthor}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],

                // Comment HTML Content
                HtmlWidget(
                  message.htmlContent,
                  textStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    height: 1.4,
                  ),
                  onTapUrl: (url) async {
                    final uri = Uri.tryParse(url);
                    if (uri != null) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                    return true;
                  },
                ),

                // Reply action button
                if (onReply != null && !message.isPending) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: () => onReply!(message),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.reply_rounded,
                              size: 14,
                              color: accentColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'chat_reply'.tr(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: accentColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme, String author, Color accent) {
    final initial = author.isNotEmpty ? author[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 9,
      backgroundColor: accent.withValues(alpha: 0.2),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: accent,
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    return ChatDateUtils.formatTimestamp(
      dt,
      includeYear: true,
      langCode: langCode,
    );
  }
}
