import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: theme.colorScheme.surface,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: currentProject.primaryColor,
              image: const DecorationImage(
                image: AssetImage(
                  'assets/images/woman_reading_a_book_on_lap.webp',
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Text(
              'WikiNusa',
              style: GoogleFonts.cinzelDecorative(
                textStyle: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  shadows: const [Shadow(blurRadius: 10, color: Colors.black)],
                ),
              ),
            ),
          ),
          ExpansionTile(
            initiallyExpanded: true,
            title: _buildSectionHeader(theme, 'drawer_quick_shortcuts'),
            children: [
              ListTile(
                leading: const Icon(Icons.edit_note_outlined),
                title: Text('create_new_page').tr(),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CreatePageScreen()),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.bookmark,
                  color: theme.colorScheme.onSurface,
                ),
                title: Text('bookmarks').tr(),
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
            ],
          ),
          ExpansionTile(
            title: _buildSectionHeader(theme, 'drawer_project'),
            children: [
              ListTile(
                leading: Icon(
                  Icons.book_outlined,
                  color: currentProject.primaryColor,
                ),
                title: DropdownButton<ProjectType>(
                  value: currentProject,
                  isExpanded: true,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down),
                  onChanged: (ProjectType? newValue) {
                    if (newValue != null) {
                      ref.read(appStateProvider.notifier).setProject(newValue);
                      // Navigate back to the root (HomeScreen) and close drawer
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                  items: ProjectType.values.map((project) {
                    return DropdownMenuItem<ProjectType>(
                      value: project,
                      child: Text(
                        project.name.toLowerCase().tr(),
                        style: TextStyle(
                          color: project == currentProject
                              ? project.primaryColor
                              : null,
                          fontWeight: project == currentProject
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

          ExpansionTile(
            title: _buildSectionHeader(theme, 'drawer_language'),
            children: [
              ListTile(
                leading: const Icon(Icons.language),
                title: DropdownButton<String>(
                  value: currentLanguage,
                  isExpanded: true,
                  underline: const SizedBox(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      // Update Riverpod state (persists via SharedPreferences)
                      ref.read(languageProvider.notifier).setLanguage(newValue);

                      // Update EasyLocalization locale
                      context.setLocale(Locale(newValue));

                      // Navigate back to the root (HomeScreen) and close drawer
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                  items: [
                    DropdownMenuItem(value: 'en', child: Text('english').tr()),
                    DropdownMenuItem(
                      value: 'id',
                      child: Text('indonesian').tr(),
                    ),
                    DropdownMenuItem(value: 'nia', child: Text('nias').tr()),
                  ],
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: _buildSectionHeader(theme, 'drawer_appearance'),
            children: [
              SwitchListTile(
                secondary: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  color: theme.colorScheme.onSurface,
                ),
                title: isDark
                    ? Text('dark_mode').tr()
                    : Text('light_mode').tr(),
                value: isDark,
                onChanged: (val) {
                  ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                },
              ),
            ],
          ),
          ExpansionTile(
            title: _buildSectionHeader(theme, 'drawer_font_size'),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _buildSegmentButton(
                        ref,
                        theme,
                        AppFontSize.small,
                        currentFontSize,
                      ),
                      _buildSegmentButton(
                        ref,
                        theme,
                        AppFontSize.normal,
                        currentFontSize,
                      ),
                      _buildSegmentButton(
                        ref,
                        theme,
                        AppFontSize.large,
                        currentFontSize,
                      ),
                      _buildSegmentButton(
                        ref,
                        theme,
                        AppFontSize.extraLarge,
                        currentFontSize,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          ExpansionTile(
            title: _buildSectionHeader(theme, 'drawer_about'),
            children: [
              ListTile(
                leading: const Icon(Icons.groups_2_outlined),
                title: Text('about_community').tr(),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AboutScreen(
                        title: 'about_community',
                        body: aboutCommunity,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.newspaper_outlined),
                title: Text('about_whats_new').tr(),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AboutScreen(title: 'about_whats_new', body: whatsNew),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.smartphone_outlined),
                title: Text('about_app').tr(),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          AboutScreen(title: 'about_app', body: aboutApp),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 16, 8),
      child: Text(
        title.tr(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSegmentButton(
    WidgetRef ref,
    ThemeData theme,
    AppFontSize targetSize,
    AppFontSize currentSize,
  ) {
    final isSelected = targetSize == currentSize;
    return Expanded(
      child: InkWell(
        onTap: () {
          ref.read(fontSizeProvider.notifier).setFontSize(targetSize);
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: isSelected
              ? BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                )
              : null,
          alignment: Alignment.center,
          child: Text(
            targetSize.label[0].toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
