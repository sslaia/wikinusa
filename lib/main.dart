import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wikinusa/localizations/nia_material_localizations.dart';
import 'package:wikinusa/providers/shared_prefs_provider.dart';
import 'package:wikinusa/providers/theme_provider.dart';
import 'package:wikinusa/providers/font_size_provider.dart';

import 'providers/app_state.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

class WikiHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..userAgent = 'WikiNusa/1.0 (https://io.github.sslaia.wikinusa; sslaia@gmail.com) Flutter/3.x';
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  
  // Set global User-Agent to comply with Wikimedia's API policy and avoid 429 errors.
  HttpOverrides.global = WikiHttpOverrides();
  
  final prefs = await SharedPreferences.getInstance();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('id'),
        Locale('nia'),
      ],
      startLocale: const Locale('id'),
      fallbackLocale: const Locale('nia'),
      path: 'assets/translations',
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const WikiNusaApp(),
      ),
    ),
  );
}

class WikiNusaApp extends ConsumerWidget {
  const WikiNusaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentProject = ref.watch(appStateProvider);
    final themeMode = ref.watch(themeModeProvider);
    final fontSize = ref.watch(fontSizeProvider);

    return MaterialApp(
      title: 'WikiNusa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getTheme(
        currentProject,
        brightness: Brightness.light,
      ),
      darkTheme: AppTheme.getTheme(
        currentProject,
        brightness: Brightness.dark,
      ),
      themeMode: themeMode,
      localizationsDelegates: [
        EasyLocalization.of(context)!.delegate,
        const NiaMaterialLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(fontSize.scale),
          ),
          child: child!,
        );
      },
      home: const HomeScreen(),
    );
  }
}
