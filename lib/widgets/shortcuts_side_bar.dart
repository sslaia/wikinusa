import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/project_type.dart';
import '../providers/app_state.dart';
import '../providers/shortcuts_provider.dart';
import '../screens/article_screen.dart';

class ShortcutsSidebar extends ConsumerWidget {
  const ShortcutsSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentProject = ref.watch(appStateProvider);
    final langCode = context.locale.languageCode;
    final shortcutsAsync = ref.watch(shortcutsProvider);

    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reuse the header style from your drawer or bottom sheet
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
            child: Text(
              'shortcuts'.tr(),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: shortcutsAsync.when(
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

                if (list.isEmpty) return const SizedBox.shrink();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final shortcut = list[index] as Map<String, dynamic>;
                    // Reuse the existing card builder from your bottom sheet file
                    return _buildShortcutCard(
                      context,
                      theme,
                      currentProject,
                      shortcut,
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutCard(
    BuildContext context,
    ThemeData theme,
    ProjectType project,
    Map<String, dynamic> shortcut,
  ) {
    final iconName = shortcut['icon'] as String;
    final title = shortcut['title'] as String;
    final url = shortcut['url'] as String;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: project.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getIconData(iconName),
              size: 20,
              color: project.primaryColor,
            ),
          ),
          title: Text(
            title,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          onTap: () async {
            final uri = Uri.parse(url);
            final pathSegments = uri.pathSegments;

            String articleTitle = '';
            if (pathSegments.contains('wiki')) {
              final index = pathSegments.indexOf('wiki');
              if (index + 1 < pathSegments.length) {
                articleTitle = pathSegments
                    .sublist(index + 1)
                    .join('/')
                    .replaceAll('_', ' ');
                // Remove query parameters if any from the title string
                if (articleTitle.contains('?')) {
                  articleTitle = articleTitle.split('?').first;
                }
              }
            }

            // If it's a special page or we couldn't parse a title, launch externally/in-app browser
            bool isSpecialPage = false;
            if (articleTitle.isNotEmpty) {
              final lowerTitle = articleTitle.toLowerCase();
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

            if (isSpecialPage || articleTitle.isEmpty) {
              try {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
                }
              } catch (e) {
                debugPrint('Could not launch $url: $e');
              }
            } else {
              // TEMP: Strip Nias Wikibooks prefix
              if (articleTitle.startsWith('Wb/nia/')) {
                articleTitle = articleTitle.replaceFirst('Wb/nia/', '');
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ArticleScreen(title: articleTitle),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'campaign_outlined':
        return Icons.campaign_rounded;
      case 'chat_bubble_outlined':
        return Icons.chat_bubble_rounded;
      case 'construction_outlined':
        return Icons.construction_rounded;
      case 'help_outlined':
      case 'help_outline':
        return Icons.help_outline_rounded;
      case 'history':
        return Icons.history_rounded;
      case 'newspaper_outlined':
        return Icons.newspaper_rounded;
      case 'pages_outlined':
        return Icons.pages_rounded;
      case 'people_outlined':
      case 'people_outline':
        return Icons.people_rounded;
      case 'support_agent_outlined':
        return Icons.support_agent_rounded;
      case 'water_drop_outlined':
        return Icons.water_drop_rounded;
      default:
        return Icons.shortcut_rounded;
    }
  }
}
