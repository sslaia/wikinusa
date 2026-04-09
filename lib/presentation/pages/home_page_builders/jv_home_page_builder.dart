import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:wikinusa/core/constants/home_portals.dart';
import 'package:wikinusa/presentation/pages/article_screen.dart';
import 'package:wikinusa/presentation/providers/html_rules_provider.dart';
import 'package:wikinusa/presentation/widgets/home_header_card.dart';
import 'package:wikinusa/presentation/widgets/home_section_header.dart';
import 'package:wikinusa/presentation/widgets/portals_card.dart';
import 'package:wikinusa/presentation/widgets/contribute_card.dart';
import 'package:wikinusa/presentation/widgets/wiki_footer.dart';
import 'home_page_builder.dart';

class JavaneseHomePageBuilder implements HomePageBuilder {
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

    Map<String, dynamic> extractCardData(dom.Element card) {
      _fixUrls(card, langCode);

      final List<String> images = [];
      card.querySelectorAll('img').forEach((img) {
        final src = img.attributes['src'];
        if (src != null && src.isNotEmpty) {
          final widthAttr = img.attributes['width'];
          if (widthAttr != null) {
            final width = int.tryParse(widthAttr);
            if (width != null && width < 100) return;
          }
          images.add(src);
        }
        img.remove();
      });

      // Try to find a header (h2, h3, or .mw-headline, etc)
      String headerText = '';
      final headerElement = card.querySelector('h2, h3, .mw-headline');
      if (headerElement != null) {
        headerText = headerElement.text.trim();
        headerElement.remove();
      }

      String finalBody = card.innerHtml;

      return {'header': headerText, 'body': finalBody, 'images': images};
    }

    final portals = HomePortals.getPortals(context)[langCode] ?? [];

    return Consumer(
      builder: (context, ref, child) {
        final rulesAsync = ref.watch(htmlRulesProvider);

        return rulesAsync.when(
          data: (rules) {
            // Extract from focus
            final focusSection = document.querySelector(
              'div.mp-main-content__focus',
            );
            final focusCardsRaw =
                focusSection?.querySelectorAll('div.card') ?? [];
            final focusCards = focusCardsRaw
                .map((e) => extractCardData(e))
                .toList();

            // Extract from other
            final otherSection = document.querySelector(
              'div.mp-main-content__other',
            );
            final otherCardsRaw =
                otherSection?.querySelectorAll('div.card') ?? [];

            // Remove the second card in other
            if (otherCardsRaw.length > 1) {
              otherCardsRaw.removeAt(1);
            }

            final otherCards = otherCardsRaw
                .map((e) => extractCardData(e))
                .toList();

            // All cards to display
            final allCards = [...focusCards, ...otherCards];

            // Determine header background image
            String? headerBg;
            for (var card in allCards) {
              if (card['images'].isNotEmpty) {
                headerBg = card['images'].first;
                break; // Use the first available image as the header background
              }
            }

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                HomeHeaderCard(
                  imageUrl: headerBg,
                  languageName: 'Basa Jawa',
                ),

                const SizedBox(height: 16),
                for (var cardData in allCards) ...[
                  if (cardData['body']!.trim().isNotEmpty) ...[
                    if (cardData['header']!.isNotEmpty)
                      HomeSectionHeader(theme: theme, title: cardData['header']),
                    _buildSectionCard(context, theme, cardData, langCode),
                    const SizedBox(height: 24),
                  ],
                ],

                const SizedBox(height: 48),
                if (portals.isNotEmpty)
                  PortalsCard(portals: portals, langCode: langCode),
                const ContributeCard(),
                const WikiFooter(),
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

                // Display HTML content
                HtmlWidget(
                  // Remove the div style if the text should not be justify aligned
                  '<div style="text-align: justify;">$sectionBody</div>',
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
                            '#${theme.colorScheme.primary.toARGB32().toRadixString(16).substring(2)}',
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
}
