import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/wiki_language.dart';
import '../providers/language_provider.dart';
import '../providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 9) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildSlide(
                    theme,
                    title: 'onboarding_greeting'.tr(),
                    description: 'onboarding_greeting_description'.tr(),
                      imagePath: 'assets/images/greeting.webp'
                  ),
                  _buildSlide(
                    theme,
                    title: 'onboarding_language'.tr(),
                    description: 'onboarding_language_description'.tr(),
                      imagePath: 'assets/images/language.webp',
                  ),
                  _buildSlide(
                    theme,
                    title: 'onboarding_bookmark'.tr(),
                    description: 'onboarding_bookmark_description'.tr(),
                      imagePath: 'assets/images/bookmark.webp',
                  ),
                  _buildSlide(
                    theme,
                    title: 'onboarding_share'.tr(),
                    description: 'onboarding_share_description'.tr(),
                    imagePath: 'assets/images/share-edit.webp',
                  ),
                  _buildSlide(
                    theme,
                    title: 'onboarding_search'.tr(),
                    description: 'onboarding_search_description'.tr(),
                      imagePath: 'assets/images/search.webp',
                  ),
                  _buildSlide(
                    theme,
                    title: 'onboarding_shortcuts'.tr(),
                    description: 'onboarding_shortcuts_description'.tr(),
                      imagePath: 'assets/images/shortcuts.webp',
                  ),
                  _buildSlide(
                    theme,
                    title: 'onboarding_reference'.tr(),
                    description: 'onboarding_reference_description'.tr(),
                      imagePath: 'assets/images/reference.webp',
                  ),
                  _buildSlide(
                    theme,
                    title: 'onboarding_setting'.tr(),
                    description: 'onboarding_setting_description'.tr(),
                      imagePath: 'assets/images/setting.webp',
                  ),
                  _buildLanguageSelectionSlide(theme),
                ],
              ),
            ),
            _buildBottomControls(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(
    ThemeData theme, {
    required String title,
    required String description,
    required String imagePath,
  }) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain, // Keeps aspect ratio within constraints
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelectionSlide(ThemeData theme) {
    final currentLanguage = ref.watch(languageProvider);

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.language, size: 80, color: theme.colorScheme.primary),
          const SizedBox(height: 32),
          Text(
            'onboarding_wiki'.tr(),
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'onboarding_wiki_description'.tr(),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<WikiLanguage>(
                isExpanded: true,
                value: currentLanguage,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: theme.colorScheme.primary,
                ),
                dropdownColor: theme.colorScheme.surfaceContainer,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                onChanged: (WikiLanguage? newValue) async {
                  if (newValue != null) {
                    ref.read(languageProvider.notifier).setLanguage(newValue);
                    // Update EasyLocalization locale (affects app UI strings)
                    await context.setLocale(Locale(newValue.code));
                    // Refresh the widget
                    setState(() {});
                  }
                },
                items: WikiLanguage.values.map<DropdownMenuItem<WikiLanguage>>((
                  WikiLanguage value,
                ) {
                  return DropdownMenuItem<WikiLanguage>(
                    value: value,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(value.displayName),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              9,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? theme.colorScheme.primary
                      : theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: () async {
                if (_currentPage == 8) {
                  final selectedLanguage = ref.read(languageProvider);
                  await context.setLocale(Locale(selectedLanguage.code));
                  ref.read(onboardingProvider.notifier).completeOnboarding();
                } else {
                  _nextPage();
                }
              },
              child: Text(
                _currentPage == 8 ? 'get_started'.tr() : 'next'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
