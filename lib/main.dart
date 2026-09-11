import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'localizations/fallback_localizations_delegate.dart';
import 'providers/shared_prefs_provider.dart';

import 'providers/theme_provider.dart';
import 'providers/font_size_provider.dart';
import 'providers/app_state.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';
import 'package:wikimedia_core/wikimedia_core.dart';

class WikiHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..userAgent =
          'WikiNusa/1.5 (https://sslaia.github.io/wikinusa; slaia@yahoo.com) Flutter/3.x';
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Set global User-Agent to comply with Wikimedia's API policy and avoid 429 errors.
  HttpOverrides.global = WikiHttpOverrides();

  // Initialize wikimedia_core configuration
  await WikiConfig.init(appName: 'wikinusa');

  // Memory optimization: Cap Flutter image cache to reduce memory footprint (RSS)
  PaintingBinding.instance.imageCache.maximumSize = 100;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 40 * 1024 * 1024; // 40 MB

  final prefs = await SharedPreferences.getInstance();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('id'),
        Locale('nia'),
        Locale('jv'),
      ],
      startLocale: const Locale('id'),
      fallbackLocale: const Locale('nia'),
      path: 'assets/translations',
      child: ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const WikiNusaApp(),
      ),
    ),
  );
}

class WikiNusaApp extends ConsumerStatefulWidget {
  const WikiNusaApp({super.key});

  @override
  ConsumerState<WikiNusaApp> createState() => _WikiNusaAppState();
}

class _WikiNusaAppState extends ConsumerState<WikiNusaApp>
    with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();
    // Comply with Google Play Android Vitals memory requirements: purge bitmap cache under pressure
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Release bitmap resources when app is paused/hidden to avoid holding bitmaps in background
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentProject = ref.watch(appStateProvider);
    final themeMode = ref.watch(themeModeProvider);
    final fontSize = ref.watch(fontSizeProvider);
    final prefs = ref.watch(sharedPreferencesProvider);
    final bool isCompleted = prefs.getBool('onboarding_completed') ?? false;

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'WikiNusa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(currentProject, brightness: Brightness.light),
      darkTheme: AppTheme.getTheme(currentProject, brightness: Brightness.dark),
      themeMode: themeMode,
      localizationsDelegates: [
        EasyLocalization.of(context)!.delegate,
        const FallbackMaterialLocalizationsDelegate(),
        const FallbackCupertinoLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(fontSize.scale)),
          child: child!,
        );
      },
      home: isCompleted
          ? HomeScreen(key: ValueKey(currentProject))
          : const OnboardingScreen(),
    );
  }
}
