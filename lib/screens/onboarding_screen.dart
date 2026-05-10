import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wikinusa/providers/app_state.dart';
import 'package:wikinusa/providers/onboarding_provider.dart';

import 'home_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      titleKey: 'onboarding_title_1',
      descKey: 'onboarding_desc_1',
      imagePath: 'assets/images/onboarding1.webp',
      color: const Color(0xFF121298),
    ),
    OnboardingData(
      titleKey: 'onboarding_title_2',
      descKey: 'onboarding_desc_2',
      imagePath: 'assets/images/onboarding2.webp',
      color: const Color(0xFF9B00A1),
    ),
    OnboardingData(
      titleKey: 'onboarding_title_3',
      descKey: 'onboarding_desc_3',
      imagePath: 'assets/images/onboarding3.webp',
      color: const Color(0xFF121298),
    ),
    OnboardingData(
      titleKey: 'onboarding_title_4',
      descKey: 'onboarding_desc_4',
      imagePath: 'assets/images/onboarding4.webp',
      color: const Color(0xFFFF5722),
    ),
    OnboardingData(
      titleKey: 'onboarding_title_5',
      descKey: 'onboarding_desc_5',
      imagePath: 'assets/images/onboarding5.webp',
      color: const Color(0xFF9B00A1),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              return _buildPage(_pages[index], size, theme);
            },
          ),

          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. Back Button or Skip
                if (_currentPage > 0)
                  IconButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    },
                    icon: Icon(Icons.arrow_back_ios_rounded,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                  )
                else
                  TextButton(
                    onPressed: () => _complete(ref, context), // Using helper method
                    child: Text('skip'.tr(),
                        style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                  ),

                // Page Indicators - Using helper method
                Row(
                  children: List.generate(
                    _pages.length,
                        (index) => _buildIndicator(index, theme),
                  ),
                ),

                // Next or Get Started Button
                _currentPage == _pages.length - 1
                    ? ElevatedButton(
                  onPressed: () => _complete(ref, context), // Using helper method
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pages[_currentPage].color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('get_started'.tr()),
                )
                    : IconButton(
                  onPressed: () {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: Icon(Icons.arrow_forward_ios_rounded, color: _pages[_currentPage].color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingData page, Size size, ThemeData theme) {
    final isLandscape = size.width > size.height;

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Centers content vertically
        children: [
          if (!isLandscape) SizedBox(height: size.height * 0.05),
          Container(
            width: size.width > 600 ? 375 : size.width,
            height: isLandscape ? 150 : size.height * 0.45,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(page.imagePath),
                fit: BoxFit.contain,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: isLandscape ? 12 : 24),
                Text(
                  page.titleKey.tr(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserratAlternates(
                    fontSize: isLandscape ? 20 : 26,
                    fontWeight: FontWeight.w800,
                    color: page.color,
                  ),
                ),
                SizedBox(height: isLandscape ? 8 : 16),
                Text(
                  page.descKey.tr(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.notoSerif(
                    fontSize: isLandscape ? 14 : 16,
                    height: 1.4,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(height: isLandscape ? 16 : 32),
                _buildLanguageSelector(context, theme),
              ],
            ),
          ),
          SizedBox(height: isLandscape ? 80 : 120),
        ],
      ),
    );
  }

  Widget _buildIndicator(int index, ThemeData theme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? _pages[_currentPage].color : theme.colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Future<void> _complete(WidgetRef ref, BuildContext context) async {
    await ref.read(onboardingProvider.notifier).completeOnboarding();
    if (context.mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  Widget _buildLanguageSelector(BuildContext context, ThemeData theme) {
    return PopupMenuButton<Locale>(
      onSelected: (Locale locale) async {
        await context.setLocale(locale);
        ref.read(languageProvider.notifier).setLanguage(locale.languageCode);
      },
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.translate, size: 16),
            const SizedBox(width: 8),
            Text(context.locale.languageCode.toUpperCase(), style: theme.textTheme.labelLarge),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: Locale('id'), child: Text('Bahasa Indonesia')),
        const PopupMenuItem(value: Locale('en'), child: Text('English')),
        const PopupMenuItem(value: Locale('nia'), child: Text('Li Niha')),
      ],
    );
  }
}

class OnboardingData {
  final String titleKey;
  final String descKey;
  final String imagePath; // Changed from IconData
  final Color color;

  OnboardingData({
    required this.titleKey,
    required this.descKey,
    required this.imagePath,
    required this.color,
  });
}