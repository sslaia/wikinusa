import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wikinusa/presentation/pages/home_page_builders/webview_home_page_builder.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/custom_drawer.dart';
import '../providers/article_provider.dart';
import '../providers/language_provider.dart';
import 'home_page_builders/home_page_builders.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final language = ref.watch(languageProvider);
    final homePage = ref.watch(homePageProvider);
    final orientation = MediaQuery.of(context).orientation;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      drawer: const CustomDrawer(),
      body: homePage.when(
        data: (html) {
          final builder = _getPageBuilder(language.code);
          // Get the titles map from the provider
          final titlesData = ref.watch(pageTitlesProvider).value ?? {};

          // Resolve the localized "Main Page" title
          String mainPageTitle = 'Main_Page';
          if (titlesData.containsKey(language.code)) {
            final langTitles = titlesData[language.code] as List;
            final entry = langTitles.firstWhere(
                  (e) => e.containsKey('main_page'),
              orElse: () => {'main_page': 'Main_Page'},
            );
            mainPageTitle = entry['main_page'];
          }
          return SafeArea(
            bottom: false,
            child: builder.build(context, mainPageTitle, html, language.code, orientation),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('${'failed_to_load_content'.tr()}: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(homePageProvider),
                child: const Text('retry').tr(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        isHomeScreen: true,
        scaffoldKey: _scaffoldKey,
      ),
    );
  }

  HomePageBuilder _getPageBuilder(String languageCode) {
    final builders = <String, HomePageBuilder>{
      'bew': WebViewHomePageBuilder(),
      'bjn': WebViewHomePageBuilder(),
      'btm': WebViewHomePageBuilder(),
      'en': WebViewHomePageBuilder(),
      'gor': WebViewHomePageBuilder(),
      'id': IndonesianHomePageBuilder(),
      'jv': WebViewHomePageBuilder(),
      'mad': WebViewHomePageBuilder(),
      'min': WebViewHomePageBuilder(),
      'ms': WebViewHomePageBuilder(),
      'nia': NiasHomePageBuilder(),
      'su': WebViewHomePageBuilder(),
    };
    return builders[languageCode] ?? DefaultHomePageBuilder();
  }
}
