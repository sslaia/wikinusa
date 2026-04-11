import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:wikinusa/core/constants/home_portals.dart';
import 'package:wikinusa/core/utils/wiki_html_utils.dart';
import 'package:wikinusa/presentation/providers/html_rules_provider.dart';
import 'package:wikinusa/presentation/widgets/home_header_card.dart';
import 'package:wikinusa/presentation/widgets/home_section_body.dart';
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

    Map<String, dynamic> extractCardData(dom.Element card) {
      WikiHtmlUtils.fixUrls(card, langCode);

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

      String headerText = '';
      final headerElement = card.querySelector('h2, h3, .mw-headline, .card-header');
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
            final focusSection = document.querySelector('div.mp-main-content__focus');
            final focusCards = focusSection?.querySelectorAll('div.card')
                .map((e) => extractCardData(e)).toList() ?? [];

            final otherSection = document.querySelector('div.mp-main-content__other');
            final otherCardsRaw = otherSection?.querySelectorAll('div.card') ?? [];
            if (otherCardsRaw.length > 1) otherCardsRaw.removeAt(1);

            final otherCards = otherCardsRaw
                .map((e) => extractCardData(e)).toList();

            final allCards = [...focusCards, ...otherCards];

            String? headerBg;
            for (var card in allCards) {
              if (card['images'].isNotEmpty) {
                headerBg = card['images'].first;
                break;
              }
            }

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                HomeHeaderCard(imageUrl: headerBg, languageName: 'Basa Jawa'),
                const SizedBox(height: 16),
                for (var cardData in allCards) ...[
                  if (cardData['body']!.trim().isNotEmpty) ...[
                    if (cardData['header']!.isNotEmpty)
                      HomeSectionHeader(theme: theme, title: cardData['header']),
                    HomeSectionBody(
                      context: context,
                      theme: theme,
                      section: cardData,
                      langCode: langCode,
                    ),
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
          error: (err, stack) => const Center(child: Text('Error loading rules')),
        );
      },
    );
  }
}
