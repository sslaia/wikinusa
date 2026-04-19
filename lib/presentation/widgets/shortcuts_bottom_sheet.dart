import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wikinusa/presentation/pages/article_screen.dart';
import '../providers/shortcuts_provider.dart';
import '../providers/language_provider.dart';

void showShortcutsBottomSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (builderContext) {
      return DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.2,
        maxChildSize: 0.75,
        expand: false,
        builder: (context, scrollController) {
          return Consumer(
            builder: (consumerContext, ref, child) {
              final theme = Theme.of(consumerContext);
              final langCode = ref.watch(languageProvider).code;
              final shortcutsAsync = ref.watch(shortcutsProvider);

              return Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      children: [
                        Text(
                          'shortcuts'.tr(),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: shortcutsAsync.when(
                      data: (list) {
                        if (list.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text('no_shortcuts_available'.tr()),
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final shortcut = list[index];
                            return ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getIconData(shortcut['icon'] as String),
                                  size: 20,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.8),
                                ),
                              ),
                              title: Text(
                                shortcut['title'] as String,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onTap: () async {
                                Navigator.pop(builderContext);
                                final url = shortcut['url'] as String;
                                ArticleScreen.handleWikipediaLink(
                                  context,
                                  ref,
                                  url,
                                  langCode,
                                );
                              },
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (err, stack) => Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text('Error: $err'),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    },
  );
}

IconData _getIconData(String name) {
  switch (name) {
    case 'campaign_outlined':
      return Icons.campaign_outlined;
    case 'chat_bubble_outlined':
    case 'chat_bubble_outline':
      return Icons.chat_bubble_outlined;
    case 'construction_outlined':
      return Icons.construction_outlined;
    case 'help_outlined':
    case 'help_outline':
      return Icons.help_outline;
    case 'history':
      return Icons.history;
    case 'newspaper_outlined':
      return Icons.newspaper_outlined;
    case 'pages_outlined':
      return Icons.pages_outlined;
    case 'people_outlined':
    case 'people_outline':
      return Icons.people_outlined;
    case 'support_agent_outlined':
      return Icons.support_agent_outlined;
    case 'water_drop_outlined':
      return Icons.water_drop_outlined;
    default:
      return Icons.content_copy;
  }
}
