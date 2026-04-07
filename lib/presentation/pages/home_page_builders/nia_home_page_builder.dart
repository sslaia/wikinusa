import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;

import 'package:wikinusa/presentation/pages/article_screen.dart';
import 'package:wikinusa/presentation/pages/search_results_screen.dart';
import 'package:wikinusa/presentation/widgets/home_header_card.dart';
import 'package:wikinusa/presentation/widgets/wiki_portals_card.dart';
import 'package:wikinusa/presentation/widgets/wikinusa_contribute_card.dart';
import 'package:wikinusa/presentation/widgets/wikinusa_footer.dart';
import 'package:wikinusa/presentation/pages/home_page_builders/home_page_builder.dart';
import 'package:wikinusa/core/theme_config.dart';

class NiasHomePageBuilder implements HomePageBuilder {
  @override
  Widget build(
    BuildContext context,
    String pageTitle,
    String html,
    String langCode,
    Orientation orientation,
  ) {
    final theme = Theme.of(context);
    final document = html_parser.parse(html);

    String extractHtmlSnippet(String selector, {bool removeHeadings = false}) {
      final element = document.querySelector(selector);
      if (element == null) return '';

      if (removeHeadings) {
        element
            .querySelectorAll('h2, h3, .mw-headline, .mp-h2')
            .forEach((e) => e.remove());
      }

      _fixUrls(element, langCode);
      return element.outerHtml;
    }

    final featuredArticle = extractHtmlSnippet(
      'div#mp-featured-article, div#mf-tfa',
      removeHeadings: true,
    );
    final featuredPhotoHtml = extractHtmlSnippet(
      'div#mp-featured-photo, div#mf-tfp',
      removeHeadings: true,
    );
    final doYouKnow = extractHtmlSnippet('div#mp-dyk-body, div#mf-dyk');
    final thisMonthInHistory = extractHtmlSnippet(
      'div#mp-otm-body, div#mf-otd',
    );

    // Extract featured image URL for background
    String? featuredImageUrl;
    if (featuredPhotoHtml.isNotEmpty) {
      final photoDoc = html_parser.parse(featuredPhotoHtml);
      final img = photoDoc.querySelector('img');
      featuredImageUrl = img?.attributes['src'];
    }

    final portals = [
      {
        'title': 'portal_religion',
        'pageTitle': 'Portal:Agama',
        'icon': Icons.account_balance,
        'color': const Color(0xFFE8EAF6),
        'iconColor': Colors.indigo,
      },
      {
        'title': 'portal_biology',
        'pageTitle': 'Portal:Biologi',
        'icon': Icons.eco,
        'color': const Color(0xFFE8F5E9),
        'iconColor': Colors.green,
      },
      {
        'title': 'portal_government',
        'pageTitle': 'Portal:Famatörö',
        'icon': Icons.gavel,
        'color': const Color(0xFFFFF8E1),
        'iconColor': Colors.amber[900],
      },
      {
        'title': 'portal_geography',
        'pageTitle': 'Portal:Geografi',
        'icon': Icons.public,
        'color': const Color(0xFFE0F7FA),
        'iconColor': Colors.cyan[900],
      },
      {
        'title': 'portal_culture',
        'pageTitle': 'Portal:Hada',
        'icon': Icons.theater_comedy,
        'color': const Color(0xFFFCE4EC),
        'iconColor': Colors.pink,
      },
      {
        'title': 'portal_maths',
        'pageTitle': 'Portal:Matematika',
        'icon': Icons.functions,
        'color': const Color(0xFFF3E5F5),
        'iconColor': Colors.deepPurple,
      },
      {
        'title': 'portal_media',
        'pageTitle': 'Portal:Media',
        'icon': Icons.newspaper,
        'color': const Color(0xFFFFF3E0),
        'iconColor': Colors.orange[900],
      },
      {
        'title': 'portal_science',
        'pageTitle': 'Portal:Sains',
        'icon': Icons.biotech,
        'color': const Color(0xFFE1F5FE),
        'iconColor': Colors.lightBlue[900],
      },
      {
        'title': 'portal_history',
        'pageTitle': 'Portal:Sejarah',
        'icon': Icons.history,
        'color': const Color(0xFFEFEBE9),
        'iconColor': Colors.brown,
      },
      {
        'title': 'portal_technology',
        'pageTitle': 'Portal:Teknologi',
        'icon': Icons.devices,
        'color': const Color(0xFFF5F5F5),
        'iconColor': Colors.blueGrey[700],
      },
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeHeaderCard(
            imageUrl: featuredImageUrl,
            languageName: 'Li Niha',
            searchField: _buildSearchField(context, theme),
          ),
          const SizedBox(height: 16),
          if (featuredArticle.isNotEmpty) ...[
            _buildSectionHeader(theme, 'featured_article'.tr()),
            _buildHtmlCard(
              context,
              theme,
              featuredArticle,
              langCode,
              isFeatured: true,
            ),
            const SizedBox(height: 24),
          ],
          if (featuredPhotoHtml.isNotEmpty) ...[
            _buildSectionHeader(theme, 'featured_image'.tr()),
            _buildHtmlCard(
              context,
              theme,
              featuredPhotoHtml,
              langCode,
              isFeatured: true,
            ),
            const SizedBox(height: 24),
          ],
          if (doYouKnow.isNotEmpty) ...[
            _buildSectionHeader(theme, 'dyk'.tr()),
            _buildHtmlCard(context, theme, doYouKnow, langCode),
            const SizedBox(height: 24),
          ],
          if (thisMonthInHistory.isNotEmpty) ...[
            _buildSectionHeader(theme, 'otm'.tr()),
            _buildHtmlCard(context, theme, thisMonthInHistory, langCode),
            const SizedBox(height: 32),
          ],
          WikiPortalsCard(portals: portals, langCode: langCode),
          const SizedBox(height: 48),
          const WikinusaContributeCard(),
          const WikinusaFooter(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _fixUrls(dom.Element element, String langCode) {
    void cleanLayout(dom.Element e) {
      e.attributes.remove('style');
      e.attributes.remove('width');
      e.attributes.remove('height');
      e.attributes.remove('align');
      e.attributes.remove('valign');
      e.attributes.remove('border');
      e.attributes.remove('cellpadding');
      e.attributes.remove('cellspacing');
    }

    cleanLayout(element);
    element.querySelectorAll('*').forEach(cleanLayout);

    element.querySelectorAll('img').forEach((img) {
      String? src = img.attributes['data-src'] ?? img.attributes['src'];
      if (src != null) {
        if (src.startsWith('//')) {
          src = 'https:$src';
        } else if (src.startsWith('/')) {
          src = 'https://$langCode.wikipedia.org$src';
        }
        img.attributes['src'] = src;
      }
      img.attributes.remove('srcset');
      img.attributes.remove('data-srcset');
    });

    element.querySelectorAll('a').forEach((a) {
      final href = a.attributes['href'];
      if (href != null && href.startsWith('/')) {
        a.attributes['href'] = 'https://$langCode.wikipedia.org$href';
      }
    });
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.montserratAlternates(
          textStyle: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.secondary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildHtmlCard(
    BuildContext context,
    ThemeData theme,
    String htmlContent,
    String langCode, {
    bool isFeatured = false,
  }) {
    final document = html_parser.parse(htmlContent);

    // Extract all images to display them at the top of the card
    // ensuring they are not constrained by nested HTML layout elements.
    final imgElements = document.querySelectorAll('img');
    final List<String> imageUrls = [];
    for (var img in imgElements) {
      final src = img.attributes['src'];
      if (src != null && src.isNotEmpty) {
        imageUrls.add(src);
      }
      img.remove(); // Remove from HTML to handle layout manually in a Column
    }

    final remainingHtml = document.body?.innerHtml ?? '';

    return Consumer(
      builder: (context, ref, child) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        elevation: 0,
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Display images first (100% width of the padded card area)
              for (var url in imageUrls)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      url,
                      width: double.infinity,
                      fit: BoxFit.fitWidth,
                      errorBuilder: (ctx, err, stack) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),

              // 2. Display text content second
              HtmlWidget(
                '<div style="text-align: justify;">$remainingHtml</div>',
                onTapUrl: (url) async {
                  await ArticleScreen.handleWikipediaLink(
                    context,
                    ref,
                    url,
                    langCode,
                  );
                  return true;
                },
                textStyle: theme.textTheme.bodyMedium?.copyWith(
                  // fontFamily: 'serif',
                  // fontSize: 16,
                  height: 1.6,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                ),
                customStylesBuilder: (element) {
                  if (element.localName == 'p') {
                    return {'margin-bottom': '12px', 'text-align': 'justify'};
                  }
                  if (element.localName == 'a') {
                    final href = element.attributes['href'] ?? '';
                    final isRedLink = href.contains('action=edit');
                    return {
                      'color': isRedLink
                          ? '#${WikinusaThemeConfig.getLinkRed(theme.brightness).value.toRadixString(16).substring(2)}'
                          : '#${theme.colorScheme.primary.value.toRadixString(16).substring(2)}',
                      'text-decoration': 'none',
                      'font-weight': '600',
                    };
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context, ThemeData theme) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Consumer(
        builder: (context, ref, child) => TextField(
          style: const TextStyle(color: Colors.white),
          onSubmitted: (String str) {
            if (str.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  settings: const RouteSettings(name: 'SearchResultsScreen'),
                  builder: (_) => SearchResultsScreen(query: str),
                ),
              );
            }
          },
          onTapOutside: (event) {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          decoration: InputDecoration(
            hintText: 'search_wikipedia'.tr(),
            hintStyle: TextStyle(
              fontFamily: 'sans',
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            prefixIcon: const Icon(Icons.search_outlined, color: Colors.white),
            border: InputBorder.none,
            // The calculation to adjust the text vertically
            // the height minus the font size divide by two
            contentPadding: const EdgeInsets.symmetric(vertical: 19),
          ),
        ),
      ),
    );
  }
}
