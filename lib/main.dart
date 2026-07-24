import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'localizations/jv_material_localizations.dart';
import 'localizations/nia_material_localizations.dart';
import 'providers/shared_prefs_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/font_size_provider.dart';
import 'providers/app_state.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'modules/crosswords/screens/crosswords_screen.dart';
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

class _WikiNusaAppState extends ConsumerState<WikiNusaApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _checkWidgetLaunch();
  }

  void _checkWidgetLaunch() {
    HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleWidgetUri);
    HomeWidget.widgetClicked.listen(_handleWidgetUri);
  }

  void _handleWidgetUri(Uri? uri) {
    if (uri == null) return;
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setBool('onboarding_completed', true);

    if (uri.host == 'crossword' || uri.toString().contains('crossword')) {
      _navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => const CrosswordsScreen()),
      );
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
        const NiaMaterialLocalizationsDelegate(),
        const JvMaterialLocalizationsDelegate(),
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
