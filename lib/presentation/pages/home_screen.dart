import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:wikinusa/presentation/pages/home_page_builders/webview_home_page_builder.dart';
import 'package:wikinusa/presentation/widgets/custom_bottom_nav_bar.dart';
import 'package:wikinusa/presentation/widgets/custom_drawer.dart';
import 'package:wikinusa/presentation/providers/article_provider.dart';
import 'package:wikinusa/presentation/providers/language_provider.dart';
import 'package:wikinusa/presentation/providers/project_provider.dart';
import 'package:wikinusa/presentation/pages/home_page_builders/home_page_builders.dart';
import 'package:wikinusa/domain/entities/wiki_project.dart';

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
    final currentProject = ref.watch(projectProvider);
    final homePage = ref.watch(homePageProvider);
    final orientation = MediaQuery.of(context).orientation;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      drawer: const CustomDrawer(),
      // appBar: AppBar(
      //   title: Text(currentProject.displayName),
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,
      // ),
      body: homePage.when(
        data: (html) {
          final builder = _getPageBuilder(language.code);
          final titlesData = ref.watch(pageTitlesProvider).value ?? {};

          String mainPageTitle = 'Main_Page';
          if (titlesData.containsKey(language.code)) {
            final langData = titlesData[language.code];
            
            // Handle nested structure: titlesData[langCode][project.name]
            if (langData is Map<String, dynamic> && langData.containsKey(currentProject.name)) {
              final projectData = langData[currentProject.name];
              if (projectData is List) {
                final entry = projectData.firstWhere(
                  (e) => e is Map && e.containsKey('main_page'),
                  orElse: () => {'main_page': 'Main_Page'},
                );
                mainPageTitle = entry['main_page'];
              } else if (projectData is Map && projectData.containsKey('main_page')) {
                mainPageTitle = projectData['main_page'];
              }
            } 
            // Fallback for old flat list structure
            else if (langData is List) {
              final entry = langData.firstWhere(
                (e) => e is Map && e.containsKey('main_page'),
                orElse: () => {'main_page': 'Main_Page'},
              );
              mainPageTitle = entry['main_page'];
            }
          }
          
          return SafeArea(
            bottom: false,
            child: builder.build(
              context,
              mainPageTitle,
              html,
              language.code,
              orientation,
              currentProject,
            ),
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
                child: Text('retry').tr(),
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
      'en': EnglishHomePageBuilder(),
      'gor': WebViewHomePageBuilder(),
      'id': IndonesianHomePageBuilder(),
      'jv': JavaneseHomePageBuilder(),
      'mad': WebViewHomePageBuilder(),
      'min': WebViewHomePageBuilder(),
      'ms': WebViewHomePageBuilder(),
      'nia': NiasHomePageBuilder(),
      'su': WebViewHomePageBuilder(),
    };
    return builders[languageCode] ?? DefaultHomePageBuilder();
  }
}
