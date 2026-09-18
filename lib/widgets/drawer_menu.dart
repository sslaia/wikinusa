import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wikinusa/modules/crosswords/screens/crosswords_screen.dart';

import '../screens/create_book_screen.dart';
import '../screens/create_entry_screen.dart';
import '../screens/create_page_screen.dart';
import 'package:wikimedia_core/wikimedia_core.dart';
import '../providers/app_state.dart';
import '../providers/font_size_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/shortcuts_provider.dart';
import '../screens/about_screen.dart';
import '../screens/bookmarks_screen.dart';
import '../modules/gallery/screens/gallery_carousel_screen.dart';
import '../modules/course/screens/language_course_screen.dart';
import '../modules/newsletter/screens/newsletter_screen.dart';
import '../modules/chat/screens/chat_topics_screen.dart';
import '../screens/module_settings_screen.dart';
import '../utils/shortcut_utils.dart';
import '../utils/wiki_utils.dart';
import '../providers/modules_provider.dart';
import 'drawer_auth_section.dart';

class DrawerMenu extends ConsumerWidget {
  final bool isPermanent;
  const DrawerMenu({super.key, this.isPermanent = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Drawer(
      elevation: isPermanent ? 0 : null,
      shape: isPermanent
          ? const RoundedRectangleBorder(borderRadius: BorderRadius.zero)
          : null,
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      child: Container(
        decoration: isPermanent
            ? BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.3,
                    ),
                    width: 1,
                  ),
                ),
              )
            : null,
        child: const DrawerContent(),
      ),
    );
  }
}

class DrawerContent extends ConsumerWidget {
  const DrawerContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final currentProject = ref.watch(appStateProvider);
    final currentLanguage = ref.watch(languageProvider);
    final currentFontSize = ref.watch(fontSizeProvider);

    final crosswordsConfig = ref.watch(
      moduleConfigProvider((
        moduleKey: 'crosswords',
        langCode: currentLanguage,
      )),
    );
    final courseConfig = ref.watch(
      moduleConfigProvider((moduleKey: 'course', langCode: currentLanguage)),
    );
    final galleryConfig = ref.watch(
      moduleConfigProvider((moduleKey: 'gallery', langCode: currentLanguage)),
    );
    final newsletterConfig = ref.watch(
      moduleConfigProvider((
        moduleKey: 'newsletter',
        langCode: currentLanguage,
      )),
    );
    final chatConfig = ref.watch(
      moduleConfigProvider((
        moduleKey: 'chat',
        langCode: currentLanguage,
      )),
    );

    final isCrosswordsEnabled =
        crosswordsConfig?.enabled ?? (currentLanguage == 'nia');
    final isCourseEnabled = courseConfig?.enabled ?? (currentLanguage == 'nia');
    final isGalleryEnabled =
        galleryConfig?.enabled ?? (currentLanguage == 'nia');
    final isNewsletterEnabled =
        newsletterConfig?.enabled ?? (currentLanguage == 'nia');
    final isChatEnabled = chatConfig?.enabled ?? true;

    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildHeader(context, theme, currentProject),
        _buildExpansionSection(
          theme,
          titleKey: 'drawer_quick_shortcuts',
          children: [
            _buildDrawerItem(
              theme,
              icon: Icons.edit_note_rounded,
              title: 'create_new_page'.tr(),
              onTap: () {
                _closeDrawer(context);
                Widget destination;
                if (currentProject == ProjectType.wikipedia) {
                  destination = const CreatePageScreen();
                } else if (currentLanguage == 'nia' &&
                    currentProject == ProjectType.wiktionary) {
                  destination = const CreateEntryScreen();
                } else if (currentLanguage == 'nia' &&
                    currentProject == ProjectType.wikibooks) {
                  destination = const CreateBookScreen();
                } else {
                  destination = const CreatePageScreen();
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => destination),
                );
              },
            ),
            _buildDrawerItem(
              theme,
              icon: Icons.bookmark_rounded,
              title: 'bookmarks'.tr(),
              onTap: () {
                _closeDrawer(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BookmarksScreen()),
                );
              },
            ),
          ],
        ),
        _buildProjectShortcutsSection(
          context,
          ref,
          theme,
          currentProject,
          currentLanguage,
        ),
        _buildExpansionSection(
          theme,
          titleKey: 'drawer_project',
          initiallyExpanded: true,
          children: [
            _buildProjectSelector(
              context,
              ref,
              theme,
              currentProject,
              currentLanguage,
            ),
          ],
        ),
        // Modules are visible across all languages, greyed out when not available in the active language
        _buildExpansionSection(
          theme,
          titleKey: 'drawer_modules',
          initiallyExpanded: true,
          children: [
            _buildDrawerItem(
              theme,
              icon: Icons.grid_on_rounded,
              title: 'crosswords'.tr(),
              enabled: isCrosswordsEnabled,
              onTap: () {
                _closeDrawer(context);
                final project =
                    crosswordsConfig?.project ?? ProjectType.wiktionary;
                ref
                    .read(appStateProvider.notifier)
                    .setProject(project, currentLanguage);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CrosswordsScreen()),
                );
              },
            ),
            _buildDrawerItem(
              theme,
              icon: Icons.school_rounded,
              title: 'language_course'.tr(),
              enabled: isCourseEnabled,
              onTap: () {
                _closeDrawer(context);
                final project = courseConfig?.project ?? ProjectType.wiktionary;
                ref
                    .read(appStateProvider.notifier)
                    .setProject(project, currentLanguage);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LanguageCourseScreen(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              theme,
              icon: Icons.photo_library_rounded,
              title: 'gallery'.tr(),
              enabled: isGalleryEnabled,
              onTap: () {
                _closeDrawer(context);
                final project = galleryConfig?.project ?? ProjectType.wikipedia;
                ref
                    .read(appStateProvider.notifier)
                    .setProject(project, currentLanguage);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GalleryCarouselScreen(),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              theme,
              icon: Icons.feed_rounded,
              title: 'newsletter'.tr(),
              enabled: isNewsletterEnabled,
              onTap: () {
                _closeDrawer(context);
                final project =
                    newsletterConfig?.project ?? ProjectType.wikipedia;
                ref
                    .read(appStateProvider.notifier)
                    .setProject(project, currentLanguage);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewsletterScreen()),
                );
              },
            ),
            _buildDrawerItem(
              theme,
              icon: Icons.chat_bubble_outline_rounded,
              title: 'chat'.tr(),
              enabled: isChatEnabled,
              onTap: () {
                _closeDrawer(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatTopicsScreen()),
                );
              },
            ),
            _buildDrawerItem(
              theme,
              icon: Icons.tune_rounded,
              title: 'module_settings'.tr(),
              onTap: () {
                _closeDrawer(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ModuleSettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        _buildExpansionSection(
          theme,
          titleKey: 'drawer_language',
          initiallyExpanded: false,
          children: [
            _buildLanguageSelector(context, ref, theme, currentLanguage),
          ],
        ),
        _buildExpansionSection(
          theme,
          titleKey: 'drawer_appearance',
          initiallyExpanded: false,
          children: [_buildAppearanceToggle(ref, theme, isDark)],
        ),
        _buildExpansionSection(
          theme,
          titleKey: 'drawer_font_size',
          initiallyExpanded: false,
          children: [_buildFontSizeSelector(ref, theme, currentFontSize)],
        ),
        _buildExpansionSection(
          theme,
          titleKey: 'drawer_about',
          initiallyExpanded: false,
          children: [
            _buildDrawerItem(
              theme,
              icon: Icons.groups_2_rounded,
              title: 'about_community'.tr(),
              onTap: () => _navigateToAbout(
                context,
                'about_community',
                'about_community_content'.tr(),
              ),
            ),
            _buildDrawerItem(
              theme,
              icon: Icons.newspaper_rounded,
              title: 'about_whats_new'.tr(),
              onTap: () => _navigateToAbout(
                context,
                'about_whats_new',
                'whats_new_content'.tr(),
              ),
            ),
            _buildDrawerItem(
              theme,
              icon: Icons.info_rounded,
              title: 'about_app'.tr(),
              onTap: () => _navigateToAbout(
                context,
                'about_app',
                'about_app_content'.tr(),
              ),
            ),
          ],
        ),
        const DrawerAuthSection(),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildExpansionSection(
    ThemeData theme, {
    required String titleKey,
    required List<Widget> children,
    bool initiallyExpanded = true,
  }) {
    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: _buildSectionLabel(theme, titleKey),
        initiallyExpanded: initiallyExpanded,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
        shape: const Border(),
        collapsedShape: const Border(),
        children: children,
      ),
    );
  }

  Widget _buildProjectShortcutsSection(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ProjectType currentProject,
    String currentLanguage,
  ) {
    final shortcutsAsync = ref.watch(shortcutsProvider);
    final projectKey = currentProject.name.toLowerCase();

    return shortcutsAsync.when(
      data: (data) {
        final shortcuts =
            data[currentLanguage]?[projectKey] as List<dynamic>? ?? [];
        if (shortcuts.isEmpty) return const SizedBox.shrink();

        return _buildExpansionSection(
          theme,
          titleKey: 'drawer_project_shortcuts',
          initiallyExpanded: false,
          children: shortcuts.map((s) {
            final title = s['title'] as String;
            final iconName = s['icon'] as String;
            final pageTitle = s['pageTitle'] as String;
            return _buildDrawerItem(
              theme,
              icon: ShortcutUtils.getIconData(iconName),
              title: title,
              onTap: () {
                _closeDrawer(context);
                ShortcutUtils.handleShortcutTap(
                  context,
                  pageTitle,
                  currentLanguage,
                  currentProject,
                );
              },
            );
          }).toList(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    ProjectType currentProject,
  ) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: topPadding + 24,
        bottom: 24,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: const DecorationImage(
                image: AssetImage('assets/images/rai.webp'),
                fit: BoxFit.cover,
              ),
              boxShadow: [
                BoxShadow(
                  color: currentProject.primaryColor.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'WikiNusa',
            style: GoogleFonts.cinzelDecorative(
              textStyle: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
          ),
          Text(
            'motto'.tr(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(ThemeData theme, String labelKey) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        labelKey.tr().toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary.withValues(alpha: 0.7),
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            leading: Icon(
              icon,
              color: enabled
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.7)
                  : Colors.grey.withValues(alpha: 0.4),
              size: 22,
            ),
            title: Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: enabled
                    ? theme.colorScheme.onSurface
                    : Colors.grey.withValues(alpha: 0.5),
                decoration: !enabled ? TextDecoration.lineThrough : null,
              ),
            ),
            onTap: onTap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProjectSelector(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ProjectType currentProject,
    String currentLanguage,
  ) {
    return RadioGroup<ProjectType>(
      groupValue: currentProject,
      onChanged: (ProjectType? newValue) {
        if (newValue != null) {
          ref
              .read(appStateProvider.notifier)
              .setProject(newValue, currentLanguage);
          _closeDrawer(context);
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Column(
        children: ProjectType.values.map((project) {
          final isSupported = project.isSupported(currentLanguage);
          return RadioListTile<ProjectType>(
            value: project,
            enabled: isSupported,
            title: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 8,
                  color: isSupported
                      ? project.primaryColor
                      : Colors.grey.withValues(alpha: 0.3),
                ),
                const SizedBox(width: 8),
                Text(
                  project.getLocalizedDisplayName(currentLanguage),
                  style: TextStyle(
                    color: !isSupported
                        ? Colors.grey.withValues(alpha: 0.5)
                        : (project == currentProject
                              ? project.primaryColor
                              : theme.colorScheme.onSurface),
                    fontWeight: project == currentProject
                        ? FontWeight.bold
                        : FontWeight.normal,
                    decoration: !isSupported
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
              ],
            ),
            activeColor: project.primaryColor,
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLanguageSelector(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    String currentLanguage,
  ) {
    final languages = [
      {'code': 'en', 'name': 'english'},
      {'code': 'id', 'name': 'indonesian'},
      {'code': 'nia', 'name': 'nias'},
      {'code': 'jv', 'name': 'javanese'},
    ];

    return RadioGroup<String>(
      groupValue: currentLanguage,
      onChanged: (String? newValue) {
        if (newValue != null) {
          ref.read(languageProvider.notifier).setLanguage(newValue);
          context.setLocale(Locale(newValue));
          _closeDrawer(context);
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      child: Column(
        children: languages.map((lang) {
          final code = lang['code']!;
          return RadioListTile<String>(
            value: code,
            title: Text(
              lang['name']!.tr(),
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: currentLanguage == code
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
            activeColor: theme.colorScheme.primary,
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAppearanceToggle(WidgetRef ref, ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: SwitchListTile(
          secondary: Icon(
            isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          title: Text(
            isDark ? 'dark_mode'.tr() : 'light_mode'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          value: isDark,
          onChanged: (val) {
            ref
                .read(themeModeProvider.notifier)
                .setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
          },
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildFontSizeSelector(
    WidgetRef ref,
    ThemeData theme,
    AppFontSize currentFontSize,
  ) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Row(
          children: AppFontSize.values.map((size) {
            final isSelected = size == currentFontSize;
            return Expanded(
              child: InkWell(
                onTap: () =>
                    ref.read(fontSizeProvider.notifier).setFontSize(size),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: isSelected
                      ? BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        )
                      : null,
                  alignment: Alignment.center,
                  child: Text(
                    size.label[0].toUpperCase(),
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _closeDrawer(BuildContext context) {
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold?.isDrawerOpen ?? false) {
      scaffold?.closeDrawer();
    }
  }

  void _navigateToAbout(BuildContext context, String titleKey, String body) {
    _closeDrawer(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AboutScreen(title: titleKey, body: body),
      ),
    );
  }
}
