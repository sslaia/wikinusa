import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wikinusa/screens/create_book_screen.dart';
import 'package:wikinusa/screens/create_entry_screen.dart';
import 'package:wikinusa/screens/create_page_screen.dart';
import '../data/about_app.dart';
import '../data/about_community.dart';
import '../data/whats_new.dart';
import '../models/project_type.dart';
import '../providers/app_state.dart';
import '../providers/font_size_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/about_screen.dart';
import '../screens/bookmarks_screen.dart';

class DrawerMenu extends ConsumerWidget {
  const DrawerMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final currentProject = ref.watch(appStateProvider);
    final currentLanguage = ref.watch(languageProvider);
    final currentFontSize = ref.watch(fontSizeProvider);

    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Drawer(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      child: Column(
        children: [
          _buildHeader(context, theme, currentProject),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _buildSectionLabel(theme, 'drawer_quick_shortcuts'),
                _buildDrawerItem(
                  theme,
                  icon: Icons.edit_note_rounded,
                  title: 'create_new_page'.tr(),
                  onTap: () {
                    Widget destination;
                    if (currentProject == ProjectType.wikipedia) {
                      destination = const CreatePageScreen();
                    } else if (currentLanguage == 'nia' && currentProject == ProjectType.wiktionary) {
                      destination = const CreateEntryScreen();
                    } else if (currentLanguage == 'nia' && currentProject == ProjectType.wikibooks) {
                      destination = const CreateBookScreen();
                    } else {
                      destination = const CreatePageScreen();
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => destination,
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  theme,
                  icon: Icons.bookmark_rounded,
                  title: 'bookmarks'.tr(),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BookmarksScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildSectionLabel(theme, 'drawer_project'),
                _buildProjectSelector(context, ref, theme, currentProject, currentLanguage),
                const SizedBox(height: 16),
                _buildSectionLabel(theme, 'drawer_language'),
                _buildLanguageSelector(context, ref, theme, currentLanguage),
                const SizedBox(height: 16),
                _buildSectionLabel(theme, 'drawer_appearance'),
                _buildAppearanceToggle(ref, theme, isDark),
                const SizedBox(height: 16),
                _buildSectionLabel(theme, 'drawer_font_size'),
                _buildFontSizeSelector(ref, theme, currentFontSize),
                const SizedBox(height: 16),
                _buildSectionLabel(theme, 'drawer_about'),
                _buildDrawerItem(
                  theme,
                  icon: Icons.groups_2_rounded,
                  title: 'about_community'.tr(),
                  onTap: () => _navigateToAbout(context, 'about_community', aboutCommunity),
                ),
                _buildDrawerItem(
                  theme,
                  icon: Icons.newspaper_rounded,
                  title: 'about_whats_new'.tr(),
                  onTap: () => _navigateToAbout(context, 'about_whats_new', whatsNew),
                ),
                _buildDrawerItem(
                  theme,
                  icon: Icons.info_rounded,
                  title: 'about_app'.tr(),
                  onTap: () => _navigateToAbout(context, 'about_app', aboutApp),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, ProjectType currentProject) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 24, left: 24, right: 24),
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
                image: AssetImage('assets/images/woman_reading_a_book_on_lap.webp'),
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
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8, top: 8),
      child: Container(
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
      ),
    );
  }

  Widget _buildDrawerItem(ThemeData theme, {required IconData icon, required String title, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
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
        child: ListTile(
          leading: Icon(icon, color: theme.colorScheme.onSurface.withValues(alpha: 0.7), size: 22),
          title: Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _buildProjectSelector(BuildContext context, WidgetRef ref, ThemeData theme, ProjectType currentProject, String currentLanguage) {
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButton<ProjectType>(
        value: currentProject,
        isExpanded: true,
        underline: const SizedBox(),
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.primary),
        onChanged: (ProjectType? newValue) {
          if (newValue != null && newValue.isSupported(currentLanguage)) {
            ref.read(appStateProvider.notifier).setProject(newValue, currentLanguage);
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
        items: ProjectType.values.map((project) {
          final isSupported = project.isSupported(currentLanguage);
          return DropdownMenuItem<ProjectType>(
            value: project,
            enabled: isSupported,
            child: Row(
              children: [
                Icon(
                  Icons.circle, 
                  size: 8, 
                  color: isSupported ? project.primaryColor : Colors.grey.withValues(alpha: 0.3)
                ),
                const SizedBox(width: 12),
                Text(
                  project.name.toLowerCase().tr(),
                  style: TextStyle(
                    color: !isSupported 
                        ? Colors.grey.withValues(alpha: 0.5)
                        : (project == currentProject ? project.primaryColor : theme.colorScheme.onSurface),
                    fontWeight: project == currentProject ? FontWeight.bold : FontWeight.normal,
                    decoration: !isSupported ? TextDecoration.lineThrough : null,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context, WidgetRef ref, ThemeData theme, String currentLanguage) {
    final languages = [
      {'code': 'en', 'name': 'english'},
      {'code': 'id', 'name': 'indonesian'},
      {'code': 'nia', 'name': 'nias'},
    ];

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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButton<String>(
        value: currentLanguage,
        isExpanded: true,
        underline: const SizedBox(),
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: theme.colorScheme.primary, size: 20),
        onChanged: (String? newValue) {
          if (newValue != null) {
            ref.read(languageProvider.notifier).setLanguage(newValue);
            context.setLocale(Locale(newValue));
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
        items: languages.map((lang) {
          return DropdownMenuItem(
            value: lang['code'],
            child: Text(
              lang['name']!.tr(),
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontWeight: currentLanguage == lang['code'] ? FontWeight.bold : FontWeight.normal,
              ),
            ),
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
      child: SwitchListTile(
        secondary: Icon(
          isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          color: theme.colorScheme.primary,
          size: 20,
        ),
        title: Text(
          isDark ? 'dark_mode'.tr() : 'light_mode'.tr(),
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        value: isDark,
        onChanged: (val) {
          ref.read(themeModeProvider.notifier).setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildFontSizeSelector(WidgetRef ref, ThemeData theme, AppFontSize currentFontSize) {
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
      child: Row(
        children: AppFontSize.values.map((size) {
          final isSelected = size == currentFontSize;
          return Expanded(
            child: InkWell(
              onTap: () => ref.read(fontSizeProvider.notifier).setFontSize(size),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: isSelected
                    ? BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.3),
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
                    color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _navigateToAbout(BuildContext context, String titleKey, String body) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AboutScreen(title: titleKey, body: body),
      ),
    );
  }
}
