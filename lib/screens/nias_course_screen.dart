import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/project_type.dart';
import '../providers/wiki_api_provider.dart';
import '../services/wiki_api_service.dart';
import '../utils/wiki_utils.dart';
import '../widgets/wiki_footer.dart';
import '../widgets/drawer_menu.dart';
import '../widgets/custom_bottom_app_bar.dart';
import 'image_screen.dart';

import 'package:html/parser.dart' as html_parser;

class NiasCourseScreen extends ConsumerStatefulWidget {
  const NiasCourseScreen({super.key});

  @override
  ConsumerState<NiasCourseScreen> createState() => _NiasCourseScreenState();
}

class _NiasCourseScreenState extends ConsumerState<NiasCourseScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late String _courseTitle;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final monthStr = now.month.toString().padLeft(2, '0');
    _courseTitle = 'Wikikamus:Sulu/$monthStr';
  }

  @override
  Widget build(BuildContext context) {
    // Explicitly target Nias Wiktionary
    final courseContent = ref.watch(courseApiProvider(_courseTitle));
    final theme = Theme.of(context);

    // Mix of project colors
    final mixedColor = Color.lerp(
      ProjectType.wikipedia.primaryColor,
      Color.lerp(ProjectType.wiktionary.primaryColor, ProjectType.wikibooks.primaryColor, 0.5),
      0.5,
    )!;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const DrawerMenu(),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: mixedColor,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'nias_course'.tr(),
                style: GoogleFonts.cinzelDecorative(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      ProjectType.wikipedia.primaryColor,
                      ProjectType.wiktionary.primaryColor,
                      ProjectType.wikibooks.primaryColor,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.auto_stories_rounded,
                        size: 60,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(height: 40), // Spacer for title
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          "Li Niha khö ndra awöda fao ba gu'ö digital",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dancingScript(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          courseContent.when(
            data: (data) {
              String htmlContent;

              if (data is Map<String, dynamic>) {
                htmlContent = data['html'] ?? '';
              } else if (data is String) {
                htmlContent = data;
              } else {
                htmlContent = '';
              }

              if (htmlContent.isEmpty ||
                  htmlContent.contains('Error: Could not parse')) {
                // Try fallback to January if current month fails
                if (!_courseTitle.endsWith('/01')) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      _courseTitle = 'Wikikamus:Sulu/01';
                    });
                  });
                }
              }

              // Strip all inline styles to use app fonts and styles
              final cleanHtml = htmlContent.replaceAll(
                RegExp(r'style="[^"]*"'),
                '',
              );

              // Parse and extract specific Sulu lesson components
              final doc = html_parser.parse(cleanHtml);
              String? lessonTitle;
              
              final titleElement = doc.querySelector('.lesson-title') ?? doc.querySelector('h2');
              if (titleElement != null) {
                lessonTitle = titleElement.text;
                titleElement.remove();
              }

              // Remove reply links [tema li] and their brackets
              doc.querySelectorAll('.ext-discussiontools-init-replylink-reply, .ext-discussiontools-init-replylink-bracket').forEach((el) {
                el.remove();
              });

              // Also check for any remaining [tema li] text that might be outside those classes
              doc.querySelectorAll('a').forEach((link) {
                if (link.text.trim() == '[tema li]' || link.text.trim() == 'tema li') {
                  link.remove();
                }
              });

              final cleanBody = doc.body?.innerHtml ?? cleanHtml;

              return SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (lessonTitle != null && lessonTitle.isNotEmpty) ...[
                      Text(
                        lessonTitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserratAlternates(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: mixedColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    HtmlWidget(
                      cleanBody,
                      textStyle: GoogleFonts.notoSerif(
                        height: 1.8,
                        fontSize: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.9),
                      ),
                      onTapUrl: (url) =>
                          WikiUtils.handleTapUrl(context, url, htmlContent),
                      customStylesBuilder: (element) {
                        if (element.localName == 'blockquote') {
                          return {
                            'border-left': '4px solid ${mixedColor.toHtmlRgba()}',
                            'background-color':
                                mixedColor.withOpacity(0.05).toHtmlRgba(),
                            'padding': '16px',
                            'margin': '16px 0',
                            'font-style': 'italic',
                            'border-radius': '0 12px 12px 0',
                          };
                        }
                        return WikiUtils.customStyles(context, element);
                      },
                      customWidgetBuilder: (element) {
                        // Handle images: animate them and make them clickable
                        if (element.localName == 'img' ||
                            element.localName == 'figure' ||
                            element.classes.contains('thumb')) {
                          final img = element.localName == 'img'
                              ? element
                              : element.querySelector('img');

                          if (img != null) {
                            final src = img.attributes['src'] ?? '';
                            if (src.isNotEmpty && !WikiUtils.isIcon(src)) {
                              final fullUrl = src.startsWith('http')
                                  ? src
                                  : 'https:$src';
                              return _buildAnimatedHeroImage(
                                fullUrl,
                                mixedColor,
                              );
                            }
                          }
                        }

                        return WikiUtils.customWidgetBuilder(context, element);
                      },
                    ),
                    const SizedBox(height: 32),
                    const WikiFooter(),
                    const SizedBox(height: 80),
                  ]),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => SliverFillRemaining(
              child: Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomAppBar(
        scaffoldKey: _scaffoldKey,
        currentProject: ProjectType.wiktionary,
        pageTitle: _courseTitle,
      ),
    );
  }

  Widget _buildAnimatedHeroImage(String url, Color themeColor) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ImageScreen(imagePath: url),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: themeColor.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
        ),
      ),
    );
  }
}

extension ColorToHtml on Color {
  String toHtmlRgba() {
    return 'rgba($red, $green, $blue, $opacity)';
  }
}

// Special provider for course to force Nias Wiktionary
final courseApiProvider = FutureProvider.autoDispose.family<dynamic, String>((ref, pageTitle) async {
  return WikiApiService.fetchPageHtml(
    ProjectType.wiktionary,
    'nia',
    pageTitle,
    true,
  );
});
