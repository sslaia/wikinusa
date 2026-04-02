import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:wikinusa/presentation/localizations/bew_material_localizations.dart';
import 'package:wikinusa/presentation/localizations/bjn_material_localizations.dart';
import 'package:wikinusa/presentation/localizations/btm_material_localizations.dart';
import 'package:wikinusa/presentation/localizations/gor_material_localizations.dart';
import 'package:wikinusa/presentation/localizations/jv_material_localizations.dart';
import 'package:wikinusa/presentation/localizations/mad_material_localizations.dart';
import 'package:wikinusa/presentation/localizations/min_material_localizations.dart';
import 'package:wikinusa/presentation/localizations/nia_material_localizations.dart';
import 'package:wikinusa/presentation/localizations/su_material_localizations.dart';
import 'core/theme_config.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/language_provider.dart';
import 'presentation/providers/font_size_provider.dart';
import 'presentation/providers/onboarding_provider.dart';
import 'presentation/providers/shared_prefs_provider.dart';
import 'presentation/pages/home_screen.dart';
import 'presentation/pages/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('bew'),
        Locale('bjn'),
        Locale('btm'),
        Locale('en'),
        Locale('gor'),
        Locale('id'),
        Locale('jv'),
        Locale('mad'),
        Locale('min'),
        Locale('ms'),
        Locale('nia'),
        Locale('su'),
      ],
      startLocale: const Locale('nia'),
      fallbackLocale: const Locale('id'),
      path: 'assets/translations',
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const WikinusaApp(),
      ),
    ),
  );
}

class WikinusaApp extends ConsumerWidget {
  const WikinusaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final hasCompletedOnboarding = ref.watch(onboardingProvider);
    final fontSize = ref.watch(fontSizeProvider);
    final selectedLanguage = ref.watch(languageProvider);

    return MaterialApp(
      title: 'WikiNusa',
      theme: WikinusaThemeConfig.createTheme(selectedLanguage.seedColor, Brightness.light),
      darkTheme: WikinusaThemeConfig.createTheme(selectedLanguage.seedColor, Brightness.dark),
      themeMode: themeMode,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(fontSize.scale),
          ),
          child: child!,
        );
      },
      localizationsDelegates: [
        EasyLocalization.of(context)!.delegate,
        const BewMaterialLocalizationsDelegate(),
        const BjnMaterialLocalizationsDelegate(),
        const BtmMaterialLocalizationsDelegate(),
        const GorMaterialLocalizationsDelegate(),
        const JvMaterialLocalizationsDelegate(),
        const MadMaterialLocalizationsDelegate(),
        const MinMaterialLocalizationsDelegate(),
        const NiaMaterialLocalizationsDelegate(),
        const SuMaterialLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: context.supportedLocales,
      locale: context.locale, // This is crucial for syncing with context.setLocale()
      home: hasCompletedOnboarding ? const HomeScreen() : const OnboardingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
