import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wikinusa/theme/app_theme.dart';
import 'package:wikinusa/widgets/wiki_footer.dart';

import '../models/home_page_section.dart';
import '../widgets/search_field_widget.dart';
import '../widgets/custom_bottom_app_bar.dart';
import '../models/project_type.dart';
import '../providers/app_state.dart';
import '../providers/wiki_api_provider.dart';
import '../widgets/drawer_menu.dart';
import '../services/home_page_builder.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final currentProject = ref.watch(appStateProvider);
    final wikiContent = ref.watch(wikiApiProvider(null));

    return Scaffold(
      key: _scaffoldKey,
      drawer: const DrawerMenu(),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: wikiContent.when(
              data: (content) {
                String? featuredImageUrl;
                if (content is List<HomePageSection>) {
                  // Prioritize the 'featuredImage' section for the hero image
                  for (var section in content) {
                    if (section.titleKey == 'featuredImage') {
                      featuredImageUrl = section.imageUrl;
                      break;
                    }
                  }

                  // Fallback to the first available image if 'featuredImage' section is not found
                  if (featuredImageUrl == null || featuredImageUrl.isEmpty) {
                    for (var section in content) {
                      if (section.imageUrl != null &&
                          section.imageUrl!.isNotEmpty) {
                        featuredImageUrl = section.imageUrl;
                        break;
                      }
                    }
                  }
                }

                return Stack(
                  children: [
                    Container(
                      height: 300,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      child: Image.network(
                        featuredImageUrl ??
                            'https://upload.wikimedia.org/wikipedia/commons/thumb/3/39/Reading_-_Hugues_Merle.jpg/960px-Reading_-_Hugues_Merle.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/thumb/3/39/Reading_-_Hugues_Merle.jpg/960px-Reading_-_Hugues_Merle.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Gradient Overlay for Text Readability
                    Container(
                      height: 300,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.2),
                            Colors.black.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                    ),

                    Positioned.fill(
                      child: MediaQuery(
                        // Overriding the textScaleFactor to 1.0 to prevent overflow
                        // and maintain the UI design regardless of system font settings.
                        data: MediaQuery.of(
                          context,
                        ).copyWith(textScaler: TextScaler.noScaling),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'welcome_to'.tr(),
                                style: GoogleFonts.offside(
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        fontSize: 14,
                                        shadows: const [
                                          Shadow(
                                            blurRadius: 10,
                                            color: Colors.black,
                                          ),
                                        ],
                                      ),
                                ),
                              ),
                              Text(
                                currentProject.name.toLowerCase().tr(),
                                style: GoogleFonts.cinzelDecorative(
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        shadows: const [
                                          Shadow(
                                            blurRadius: 10,
                                            color: Colors.black,
                                          ),
                                        ],
                                      ),
                                ),
                              ),
                              Text(
                                context.locale.languageCode.toLowerCase().tr(),
                                style: GoogleFonts.cinzelDecorative(
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontSize: 18,
                                        shadows: const [
                                          Shadow(
                                            blurRadius: 10,
                                            color: Colors.black,
                                          ),
                                        ],
                                      ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'motto'.tr(),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.offside(
                                  textStyle: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        fontSize: 14,
                                        shadows: const [
                                          Shadow(
                                            blurRadius: 10,
                                            color: Colors.black,
                                          ),
                                        ],
                                      ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              SearchFieldWidget(
                                context: context,
                                theme: Theme.of(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => Container(
                height: 200,
                color: currentProject.primaryColor.withValues(alpha: 0.1),
                child: const Center(child: CircularProgressIndicator()),
              ),
              error: (err, stack) => Container(
                height: 200,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(currentProject.homeHeroImagePath),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  alignment: Alignment.center,
                  child: const Icon(Icons.error_outline, color: Colors.white),
                ),
              ),
            ),
          ),
          wikiContent.when(
            data: (content) {
              if (content is List<HomePageSection>) {
                return SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final section = content[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 8),
                            child: Text(
                              section.titleKey.tr(),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontFeatures: [FontFeature.enable('smcp')],
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    color: currentProject.primaryColor,
                                  ),
                            ),
                          ),
                          Card(
                            elevation: 2,
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (section.imageHtml != null)
                                  HtmlWidget(
                                    section.imageHtml!,
                                    onTapUrl: (url) {
                                      debugPrint('Tapped Image URL: $url');
                                      return true;
                                    },
                                  ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: HtmlWidget(
                                    section.textHtml,
                                    onTapUrl: (url) {
                                      debugPrint('Tapped URL: $url');
                                      return true;
                                    },
                                    textStyle: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontFamily: GoogleFonts.notoSerif()
                                              .fontFamily,
                                          fontSize: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium?.fontSize,
                                          height: 1.8,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.85),
                                        ),
                                    customStylesBuilder: (element) {
                                      if (element.localName == 'p') {
                                        return {
                                          'margin-bottom': '12px',
                                          'text-align': 'justify',
                                        };
                                      }
                                      if (element.localName == 'a') {
                                        final href =
                                            element.attributes['href'] ?? '';
                                        final isRedLink = href.contains(
                                          'action=edit',
                                        );
                                        final color = AppTheme.getLinkColor(
                                          context,
                                          isRedLink: isRedLink,
                                        );
                                        return {
                                          'color':
                                              '#${color.toARGB32().toRadixString(16).substring(2)}',
                                          'text-decoration': 'none',
                                          'font-weight': '600',
                                        };
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }, childCount: content.length),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverToBoxAdapter(
                  child: HtmlWidget(content as String),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: SizedBox.shrink(), // Loading handled in hero section
            ),
            error: (error, stack) => SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '${'error_loading_content'.tr()}: $error',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(child: WikiFooter()),
        ],
      ),
      bottomNavigationBar: CustomBottomAppBar(
        scaffoldKey: _scaffoldKey,
        currentProject: currentProject,
        isHomeScreen: true,
      ),
    );
  }
}
