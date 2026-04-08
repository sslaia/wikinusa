import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:wikinusa/presentation/pages/article_screen.dart';
import 'package:wikinusa/presentation/pages/search_results_screen.dart';
import 'package:wikinusa/presentation/providers/html_rules_provider.dart';
import 'package:wikinusa/presentation/widgets/home_header_card.dart';
import 'package:wikinusa/presentation/widgets/section_header.dart';
import 'package:wikinusa/presentation/widgets/wiki_portals_card.dart';
import 'package:wikinusa/presentation/widgets/wikinusa_contribute_card.dart';
import 'package:wikinusa/presentation/widgets/wikinusa_footer.dart';
import 'home_page_builder.dart';

class IndonesianHomePageBuilder implements HomePageBuilder {
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

    // Remove scripts and styles
    document.querySelectorAll('script, style, link').forEach((e) => e.remove());

    // Helper to extract specific section data
    Map<String, dynamic>? extractSection(String id, String header) {
      final section = document.getElementById(id);

      if (section == null) return null;

      // 1. Extract images to display them at the top of the card
      final List<String> images = [];
      section.querySelectorAll('img').forEach((img) {
        String? src = img.attributes['data-src'] ?? img.attributes['src'];
        if (src != null && src.isNotEmpty) {
          // Skip tiny icons
          final widthAttr = img.attributes['width'];
          if (widthAttr != null) {
            final width = int.tryParse(widthAttr);
            if (width != null && width < 100) return;
          }

          if (src.startsWith('//')) {
            src = 'https:$src';
          } else if (src.startsWith('/')) {
            src = 'https://$langCode.wikipedia.org$src';
          }
          images.add(src);
        }
        img.remove(); // Remove from HTML to display manually at top
      });

      // Fix URLs for remaining HTML content
      _fixUrls(section, langCode);

      String finalBody = '';

      if (id == 'mf-artikelpilihan') {
        final pElements = section
            .querySelectorAll('p')
            .where((e) => e.text.trim().isNotEmpty);
        if (pElements.isNotEmpty) finalBody = pElements.first.outerHtml;
      } else if (id == 'mf-gambarpilihan') {
        final divElements = section
            .querySelectorAll('div')
            .where((e) => e.text.trim().isNotEmpty);
        if (divElements.isNotEmpty) finalBody = divElements.first.outerHtml;
      } else if (id == 'mf-peristiwaterkini') {
        final ul = section.querySelector('ul');
        if (ul != null) finalBody = ul.outerHtml;
      } else if (id == 'mf-tahukahanda') {
        finalBody = section.innerHtml;
      } else if (id == 'mf-hids') {
        final pElements = section
            .querySelectorAll('p')
            .where((e) => e.text.trim().isNotEmpty);
        if (pElements.isNotEmpty) finalBody += pElements.first.outerHtml;
        final ul = section.querySelector('ul');
        if (ul != null) finalBody += ul.outerHtml;
      } else {
        finalBody = section.innerHtml;
      }

      if (finalBody.trim().isEmpty) return null;

      return {'header': header, 'body': finalBody, 'images': images};
    }

    return Consumer(
      builder: (context, ref, child) {
        final rulesAsync = ref.watch(htmlRulesProvider);

        final portals = [
          {
            'title': 'portal_biography',
            'pageTitle': 'Portal:Biografi',
            'icon': Icons.person_outline,
            'color': const Color(0xFFE8F5E9),
            'iconColor': Colors.green[800],
          },
          {
            'title': 'portal_geography',
            'pageTitle': 'Portal:Geografi',
            'icon': Icons.map_outlined,
            'color': const Color(0xFFE0F7FA),
            'iconColor': Colors.cyan[900],
          },
          {
            'title': 'portal_chemistry',
            'pageTitle': 'Portal:Kimia',
            'icon': Icons.science,
            'color': const Color(0xFFFFF8E1),
            'iconColor': Colors.amber[900],
          },
          {
            'title': 'portal_community',
            'pageTitle': 'Portal:Komunitas',
            'icon': Icons.groups_outlined,
            'color': const Color(0xFFFCE4EC),
            'iconColor': Colors.pink,
          },
          {
            'title': 'portal_science',
            'pageTitle': 'Portal:Ilmu',
            'icon': Icons.science_outlined,
            'color': const Color(0xFFE1F5FE),
            'iconColor': Colors.lightBlue[900],
          },
          {
            'title': 'portal_history',
            'pageTitle': 'Portal:Sejarah',
            'icon': Icons.castle_outlined,
            'color': const Color(0xFFEFEBE9),
            'iconColor': Colors.brown,
          },
          {
            'title': 'portal_arts',
            'pageTitle': 'Portal:Seni',
            'icon': Icons.palette_outlined,
            'color': const Color(0xFFF3E5F5),
            'iconColor': Colors.deepPurple,
          },
          {
            'title': 'portal_technology',
            'pageTitle': 'Portal:Teknologi',
            'icon': Icons.memory_outlined,
            'color': const Color(0xFFF5F5F5),
            'iconColor': Colors.blueGrey[700],
          },
        ];

        return rulesAsync.when(
          data: (rules) {
            final idRules = rules['id'] as Map<String, dynamic>?;
            final homePageSections =
                idRules?['homePageSections'] as Map<String, dynamic>?;

            final featuredArticleId =
                homePageSections?['featuredArticle'] as String? ??
                'mf-artikelpilihan';
            final featuredImageId =
                homePageSections?['featuredImage'] as String? ??
                'mf-gambarpilihan';
            final didYouKnowId =
                homePageSections?['doYouKnow'] as String? ?? 'mf-tahukahanda';
            final currentEventsId =
                homePageSections?['recentEvents'] as String? ??
                'mf-peristiwaterkini';
            final onThisDayId =
                homePageSections?['onThisDay'] as String? ?? 'mf-hids';

            // Explicitly target Indonesian Wikipedia sections by IDs
            final featuredArticle = extractSection(
              featuredArticleId,
              'Artikel pilihan',
            );
            final featuredImage = extractSection(
              featuredImageId,
              'Gambar pilihan',
            );
            final didYouKnow = extractSection(didYouKnowId, 'Tahukah Anda');
            final currentEvents = extractSection(
              currentEventsId,
              'Peristiwa terkini',
            );
            final onThisDay = extractSection(
              onThisDayId,
              'Hari ini dalam sejarah',
            );

            // Determine header background image
            String? headerBg;
            if (featuredImage != null && featuredImage['images'].isNotEmpty) {
              headerBg = featuredImage['images'].first;
            }

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                HomeHeaderCard(
                  imageUrl: headerBg,
                  languageName: 'Bahasa Indonesia',
                ),

                const SizedBox(height: 16),
                if (featuredArticle != null) ...[
                  SectionHeader(theme: theme, title: featuredArticle['header']),
                  _buildSectionCard(context, theme, featuredArticle, langCode),
                  const SizedBox(height: 24),
                ],

                if (featuredImage != null) ...[
                  SectionHeader(theme: theme, title: featuredImage['header']),
                  _buildSectionCard(context, theme, featuredImage, langCode),
                  const SizedBox(height: 24),
                ],

                if (didYouKnow != null) ...[
                  SectionHeader(theme: theme, title: didYouKnow['header']),
                  _buildSectionCard(context, theme, didYouKnow, langCode),
                  const SizedBox(height: 24),
                ],

                if (currentEvents != null) ...[
                  SectionHeader(theme: theme, title: currentEvents['header']),
                  _buildSectionCard(context, theme, currentEvents, langCode),
                  const SizedBox(height: 24),
                ],

                if (onThisDay != null) ...[
                  SectionHeader(theme: theme, title: onThisDay['header']),
                  _buildSectionCard(context, theme, onThisDay, langCode),
                  const SizedBox(height: 24),
                ],

                const SizedBox(height: 32),
                WikiPortalsCard(portals: portals, langCode: langCode),
                const SizedBox(height: 48),
                const WikinusaContributeCard(),
                const WikinusaFooter(),
                const SizedBox(height: 80),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) =>
              const Center(child: Text('Error loading rules')),
        );
      },
    );
  }

  Widget _buildSectionCard(
    BuildContext context,
    ThemeData theme,
    Map<String, dynamic> section,
    String langCode,
  ) {
    final sectionBody = section['body'];

    return Consumer(
      builder: (context, ref, child) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Card(
          margin: EdgeInsets.zero,
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
                // Display images first (100% width)
                for (var url in section['images'])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        url,
                        width: double.infinity,
                        fit: BoxFit.fitWidth,
                        headers: const {
                          'User-Agent':
                              'WikinusaApp/1.0 (slaia@yahoo.com) FlutterApp',
                        },
                        errorBuilder: (ctx, err, stack) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  ),

                // Display refined HTML content
                HtmlWidget(
                  // Remove the div style if the text should not be justify aligned
                  '<div style="text-align: justify;">$sectionBody</div>',
                  // section['body'],
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
                    // fontSize: 16,
                    height: 1.6,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                  ),
                  customStylesBuilder: (element) {
                    if (element.localName == 'p') {
                      return {'margin-bottom': '12px', 'text-align': 'justify'};
                    }
                    if (element.localName == 'a') {
                      return {
                        'color':
                            '#${theme.colorScheme.primary.value.toRadixString(16).substring(2)}',
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
      ),
    );
  }

  void _fixUrls(dom.Element element, String langCode) {
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
      img.attributes.remove('width');
      img.attributes.remove('height');
    });

    element.querySelectorAll('a').forEach((a) {
      final href = a.attributes['href'];
      if (href != null && href.startsWith('/')) {
        a.attributes['href'] = 'https://$langCode.wikipedia.org$href';
      }
    });
  }
}
