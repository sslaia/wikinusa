import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/wiki_language.dart';
import '../providers/language_provider.dart';
import '../providers/font_size_provider.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _autoSave = true;
  bool _offlineCache = false;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final currentLanguage = ref.watch(languageProvider);
    final currentFontSize = ref.watch(fontSizeProvider);
    final theme = Theme.of(context);
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      appBar: AppBar(title: Text('settings')),
      // appBar: AppBar(
      //   backgroundColor: theme.colorScheme.surface,
      //   foregroundColor: theme.colorScheme.primary,
      //   elevation: 0,
      //   centerTitle: true,
      //   leading: Builder(
      //     builder: (context) => IconButton(
      //       icon: const Icon(Icons.menu),
      //       onPressed: () => Scaffold.of(context).openDrawer(),
      //     ),
      //   ),
      //   title: Text(
      //     'Wikinusa',
      //     style: theme.textTheme.titleLarge?.copyWith(
      //       fontWeight: FontWeight.w700,
      //       fontSize: 22,
      //       letterSpacing: -0.5,
      //       color: theme.colorScheme.primary,
      //     ),
      //   ),
      //   actions: [IconButton(icon: const Icon(Icons.search), onPressed: () {})],
      // ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
        child: Column(
          children: [
            _buildProfileHeader(theme),
            const SizedBox(height: 32),
            _buildAppearanceCard(theme, isDark, currentFontSize),
            const SizedBox(height: 16),
            _buildLocalizationCard(context, theme, currentLanguage),
            const SizedBox(height: 16),
            _buildArticlePreferencesCard(theme),
            const SizedBox(height: 48),
            _buildSignOutButton(theme),
            const SizedBox(height: 32),
            _buildVersionFooter(theme),
            const SizedBox(height: 32),
          ],
        ),
      ),
      // bottomNavigationBar: const CustomBottomNavBar(),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const CircleAvatar(
                radius: 44,
                backgroundImage: NetworkImage(
                  'https://i.pravatar.cc/150?img=11',
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFC107),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.black,
                  size: 14,
                  weight: 900,
                ),
              ),
            ),
          ],
        ),
        Text(
          'user_profile',
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'contributions',
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.5,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildCardHeader(ThemeData theme, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 22),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceCard(ThemeData theme, bool isDark, AppFontSize currentFontSize) {
    return Container(
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
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(theme, Icons.palette, 'appearance'),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'dark_light_mode_toggle',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Switch between light and dark themes',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isDark,
                onChanged: (val) {
                  ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                },
                activeThumbColor: theme.colorScheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'font_size_selection',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Adjust the readability of knowledge articles',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildSegmentButton(theme, AppFontSize.small, currentFontSize),
                _buildSegmentButton(theme, AppFontSize.normal, currentFontSize),
                _buildSegmentButton(theme, AppFontSize.large, currentFontSize),
                _buildSegmentButton(theme, AppFontSize.extraLarge, currentFontSize),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(ThemeData theme, AppFontSize targetSize, AppFontSize currentSize) {
    final isSelected = targetSize == currentSize;
    return Expanded(
      child: InkWell(
        onTap: () {
          ref.read(fontSizeProvider.notifier).setFontSize(targetSize);
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
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
            targetSize.label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocalizationCard(BuildContext context, ThemeData theme, WikiLanguage currentLanguage) {
    return Container(
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
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(theme, Icons.language, 'localization'),
          const SizedBox(height: 24),
          Text(
            'language_selection',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'choose_wiki_language',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _showLanguageSelector(context, theme, currentLanguage),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currentLanguage.displayName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontSize: 13,
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageSelector(BuildContext context, ThemeData theme, WikiLanguage currentLanguage) {
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
                'select_language',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
                          : null,
                      onTap: () {
                        ref.read(languageProvider.notifier).setLanguage(lang);
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

  Widget _buildArticlePreferencesCard(ThemeData theme) {
    return Container(
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
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(theme, Icons.menu_book, 'Article Preferences'),
          const SizedBox(height: 24),
          _buildPreferenceRow(
            theme,
            icon: Icons.history,
            iconBgColor: const Color(0xFFFFCA28),
            iconColor: Colors.black87,
            title: 'Auto-save reading progress',
            subtitle: 'Continue where you left off',
            value: _autoSave,
            onChanged: (val) => setState(() => _autoSave = val!),
          ),
          const SizedBox(height: 24),
          _buildPreferenceRow(
            theme,
            icon: Icons.download_for_offline_outlined,
            iconBgColor: const Color(0xFFFFAAA5),
            iconColor: Colors.black87,
            title: 'Offline cache',
            subtitle: 'Available for local access',
            value: _offlineCache,
            onChanged: (val) => setState(() => _offlineCache = val!),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceRow(
    ThemeData theme, {
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: theme.colorScheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ],
    );
  }

  Widget _buildSignOutButton(ThemeData theme) {
    return InkWell(
      onTap: () {},
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.logout, color: theme.colorScheme.secondary, size: 18),
          const SizedBox(width: 8),
          Text(
            'SIGN OUT FROM ACCOUNT',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionFooter(ThemeData theme) {
    return Text(
      'NIASPEDIA V2.4.0 • BUILT FOR ARCHIVISTS',
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
        letterSpacing: 2.0,
        fontSize: 10,
      ),
    );
  }
}
