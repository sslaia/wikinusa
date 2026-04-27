import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wikinusa/models/project_type.dart';

import '../utils/wiki_utils.dart';
import '../widgets/wiki_footer.dart';
import '../models/home_page_section.dart';
import '../widgets/search_field_widget.dart';
import '../widgets/custom_bottom_app_bar.dart';
import '../providers/app_state.dart';
import '../providers/wiki_api_provider.dart';
import '../widgets/drawer_menu.dart';

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
                  for (var section in content) {
                    if (section.titleKey == 'featuredImage') {
                      featuredImageUrl = section.imageUrl;
                      break;
                    }
                  }
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
                      child: featuredImageUrl != null && featuredImageUrl.isNotEmpty
                          ? Image.network(
                              featuredImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Image.asset(
                                currentProject.homeHeroImagePath,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Image.asset(
                              currentProject.homeHeroImagePath,
                              fit: BoxFit.cover,
                            ),
                    ),
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
                      final sectionBody = section.textHtml;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 8),
                            child: Text(
                              section.titleKey.tr(),
                              style: GoogleFonts.montserratAlternates(
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.secondary,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                      fontSize: 16,
                                    ),
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
                                    onTapUrl: (url) => WikiUtils.handleTapUrl(
                                      context,
                                      url,
                                      null,
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: HtmlWidget(
                                    sectionBody,
                                    onTapUrl: (url) => WikiUtils.handleTapUrl(
                                      context,
                                      url,
                                      null,
                                    ),
                                    textStyle: GoogleFonts.notoSerif(
                                      textStyle: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            height: 1.6,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.8),
                                          ),
                                    ),
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
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            },
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (err, stack) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
          const SliverToBoxAdapter(child: WikiFooter()),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
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
