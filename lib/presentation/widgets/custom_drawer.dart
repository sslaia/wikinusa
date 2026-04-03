import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wikinusa/data/about_app.dart';
import 'package:wikinusa/data/about_community.dart';
import 'package:wikinusa/data/whats_new.dart';
import 'package:wikinusa/presentation/pages/about_screen.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/font_size_provider.dart';
import '../../domain/entities/wiki_language.dart';
import '../pages/bookmarks_screen.dart';
import '../pages/create_page_screen.dart';

class CustomDrawer extends ConsumerWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final currentLanguage = ref.watch(languageProvider);
    final currentFontSize = ref.watch(fontSizeProvider);

    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              image: const DecorationImage(
                image: AssetImage(
                  'assets/images/woman_reading_a_book_on_lap.webp',
                ),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: Text(
                'WikiNusa',
                style: GoogleFonts.cinzelDecorative(
                  textStyle: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      const Shadow(blurRadius: 10, color: Colors.black),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildSectionHeader(theme, 'drawer_quick_shortcuts'),
                ListTile(
                  leading: Icon(Icons.add, color: theme.colorScheme.onSurface),
                  title: const Text('create_new_page').tr(),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreatePageScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.bookmark,
                    color: theme.colorScheme.onSurface,
                  ),
                  title: const Text('bookmarks').tr(),
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
                const Divider(),
                _buildSectionHeader(theme, 'drawer_language'),
                ListTile(
                  leading: Icon(
                    Icons.language,
                    color: theme.colorScheme.onSurface,
                  ),
                  title: Text(currentLanguage.displayName),
                  trailing: const Icon(Icons.keyboard_arrow_right, size: 20),
                  onTap: () => _showLanguageSelector(
                    context,
                    ref,
                    theme,
                    currentLanguage,
                  ),
                ),
                const Divider(),
                _buildSectionHeader(theme, 'drawer_appearance'),
                SwitchListTile(
                  secondary: Icon(
                    isDark ? Icons.dark_mode : Icons.light_mode,
                    color: theme.colorScheme.onSurface,
                  ),
                  title: const Text('dark_mode').tr(),
                  value: isDark,
                  onChanged: (val) {
                    ref
                        .read(themeModeProvider.notifier)
                        .setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                  },
                ),
                const Divider(),
                _buildSectionHeader(theme, 'drawer_font_size'),
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
                const Divider(),
                _buildSectionHeader(theme, 'drawer_about'),
                ListTile(
                  leading: Icon(Icons.groups_2_outlined),
                  title: Text('about_community').tr(),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AboutScreen(title: 'about_community', body: aboutCommunity),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.newspaper_outlined),
                  title: Text('about_whats_new').tr(),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AboutScreen(title: 'about_whats_new', body: whatsNew),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.smartphone_outlined),
                  title: Text('about_app').tr(),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AboutScreen(title: 'about_app', body: aboutApp),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                )
              : null,
          alignment: Alignment.center,
          child: Text(
            targetSize.label[0].toUpperCase(), // Single letter label for space
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

  void _showLanguageSelector(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    WikiLanguage currentLanguage,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'select_language'.tr(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: WikiLanguage.values.length,
                  itemBuilder: (context, index) {
                    final lang = WikiLanguage.values[index];
                    final isSelected = lang == currentLanguage;
                    return ListTile(
                      title: Text(
                        lang.displayName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: theme.colorScheme.primary,
                            )
                          : null,
                      onTap: () {
                        ref.read(languageProvider.notifier).setLanguage(lang);
                        
                        context.setLocale(Locale(lang.code));
                        
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
