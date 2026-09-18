import 'package:flutter/material.dart';
import 'package:wikimedia_core/wikimedia_core.dart';
import '../models/chat_topic.dart';
import '../utils/chat_date_utils.dart';

/// Card item displaying a discussion topic thread in the topics list.
class TopicCard extends StatelessWidget {
  final WikiChatTopic topic;
  final ProjectType project;
  final String langCode;
  final VoidCallback onTap;

  const TopicCard({
    super.key,
    required this.topic,
    required this.project,
    this.langCode = 'id',
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accentColor = project.getThemedColor(isDark);

    String? latestSnippet;
    if (topic.messages.isNotEmpty) {
      latestSnippet = topic.messages.last.htmlContent
          .replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHigh
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and latest activity
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        topic.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (topic.latestReplyTimestamp != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        _formatTimestamp(topic.latestReplyTimestamp!),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),

                if (latestSnippet != null && latestSnippet.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    latestSnippet,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 12),

                // Meta badges (Comment count, Author count)
                Row(
                  children: [
                    _buildMetaChip(
                      theme,
                      icon: Icons.chat_bubble_outline_rounded,
                      label: '${topic.commentCount}',
                      accentColor: accentColor,
                    ),
                    if (topic.authorCount > 0) ...[
                      const SizedBox(width: 8),
                      _buildMetaChip(
                        theme,
                        icon: Icons.people_outline_rounded,
                        label: '${topic.authorCount}',
                        accentColor: accentColor,
                      ),
                    ],
                    const Spacer(),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.6,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaChip(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: accentColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    return ChatDateUtils.formatTimestamp(dt, langCode: langCode);
  }
}
