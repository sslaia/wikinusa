import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_state.dart';
import '../providers/shortcuts_provider.dart';
import '../screens/article_screen.dart';

void showShortcutsBottomSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (builderContext) {
      return Consumer(
        builder: (consumerContext, ref, child) {
          final theme = Theme.of(consumerContext);
          final langCode = context.locale.languageCode;
          final currentProject = ref.watch(appStateProvider);
          final shortcutsAsync = ref.watch(shortcutsProvider);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 24.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.2,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      'shortcuts'.tr(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  shortcutsAsync.when(
                    data: (allShortcuts) {
                      final projectKey =
                          currentProject.name.toLowerCase() == 'wikibooks' &&
                              langCode == 'id'
                          ? 'wikibuku'
                          : currentProject.name.toLowerCase();

                      final langShortcuts =
                          allShortcuts[langCode] as Map<String, dynamic>?;
                      final list =
                          (langShortcuts?[projectKey] as List<dynamic>?) ?? [];

                      if (list.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text('no_shortcuts_available'.tr()),
                        );
                      }

                      return Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            children: list.map((item) {
                              final shortcut = item as Map<String, dynamic>;
                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color:
                                        theme.colorScheme.surfaceContainerLow,
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
                                  Navigator.pop(consumerContext);
                                  final url = shortcut['url'] as String;

                                  // Extract title from Wikipedia URL: .../wiki/Title
                                  final uri = Uri.parse(url);
                                  final pathSegments = uri.pathSegments;
                                  String title = '';
                                  if (pathSegments.contains('wiki')) {
                                    final index = pathSegments.indexOf('wiki');
                                    if (index + 1 < pathSegments.length) {
                                      title = Uri.decodeComponent(
                                        pathSegments[index + 1],
                                      ).replaceAll('_', ' ');
                                    }
                                  }

                                  String? extractedTitle;
                                  if (pathSegments.length >= 2 &&
                                      pathSegments[0] == 'wiki') {
                                    extractedTitle = pathSegments[1].replaceAll(
                                      '_',
                                      ' ',
                                    );
                                  }

                                  // Determine if it's a "Special" page
                                  bool isSpecialPage = false;
                                  if (extractedTitle != null) {
                                    final lowerTitle = extractedTitle
                                        .toLowerCase();
                                    isSpecialPage =
                                        lowerTitle.startsWith('special:') ||
                                        lowerTitle.startsWith('spesial:') ||
                                        lowerTitle.startsWith('mirunggan:') ||
                                        lowerTitle.startsWith('istimewa:') ||
                                        lowerTitle.startsWith('istimiwa:') ||
                                        lowerTitle.startsWith('istimèwa:') ||
                                        lowerTitle.startsWith('khas:') ||
                                        lowerTitle.startsWith('husus:');
                                  }

                                  // Routing Logic
                                  if (isSpecialPage && extractedTitle != null) {
                                    await launchUrl(
                                      uri,
                                      mode: LaunchMode.inAppBrowserView,
                                    );
                                    return;
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ArticleScreen(title: title),
                                      ),
                                    );
                                  }
                                },
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, stack) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text('Error loading shortcuts: $err'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
