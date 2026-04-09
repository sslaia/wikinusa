import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:wikinusa/core/utils/wiki_html_utils.dart';
import 'package:wikinusa/presentation/providers/html_rules_provider.dart';
import 'package:wikinusa/presentation/widgets/home_header_card.dart';
import 'package:wikinusa/presentation/widgets/home_section_body.dart';
import 'package:wikinusa/presentation/widgets/home_section_header.dart';
import 'package:wikinusa/presentation/widgets/contribute_card.dart';
import 'package:wikinusa/presentation/widgets/wiki_footer.dart';
import 'home_page_builder.dart';

class EnglishHomePageBuilder implements HomePageBuilder {
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

      // Fix URLs before extraction
      WikiHtmlUtils.fixUrls(section, langCode);

      // Extract images to display them at the top of the card
      final List<String> images = [];
      section.querySelectorAll('img').forEach((img) {
        final src = img.attributes['src'];
        if (src != null && src.isNotEmpty) {
          // Skip tiny icons
          final widthAttr = img.attributes['width'];
          if (widthAttr != null) {
            final width = int.tryParse(widthAttr);
            if (width != null && width < 100) return;
          }

          images.add(src);
        }
        img.remove(); // Remove from HTML to display manually at top
      });

      String finalBody = '';

      if (id == 'mp-tfa') {
        final pElements = section
            .querySelectorAll('p')
            .where((e) => e.text.trim().isNotEmpty);
        if (pElements.isNotEmpty) finalBody = pElements.first.outerHtml;
      } else if (id == 'mp-itn') {
        final ul = section.querySelector('ul');
        if (ul != null) finalBody = ul.outerHtml;
      } else if (id == 'mp-otd') {
        final pElements = section
            .querySelectorAll('p')
            .where((e) => e.text.trim().isNotEmpty);
        if (pElements.isNotEmpty) finalBody += pElements.first.outerHtml;
        final ul = section.querySelector('ul');
        if (ul != null) finalBody += ul.outerHtml;
      } else if (id == 'mp-tfp') {
        final pElements = section
            .querySelectorAll('p')
            .where((e) => e.text.trim().isNotEmpty);
        if (pElements.isNotEmpty) finalBody = pElements.first.outerHtml;
      } else if (id == 'mp-tfl') {
        final pElements = section
            .querySelectorAll('p')
            .where((e) => e.text.trim().isNotEmpty);
        if (pElements.isNotEmpty) finalBody = pElements.first.outerHtml;
      } else if (id == 'mp-dyk') {
        final ulElements = section
            .querySelectorAll('ul')
            .where((e) => e.text.trim().isNotEmpty);
        if (ulElements.isNotEmpty) finalBody = ulElements.first.outerHtml;
      } else {
        finalBody = section.innerHtml;
      }

      if (finalBody.trim().isEmpty) return null;

      return {'header': header, 'body': finalBody, 'images': images};
    }

    return Consumer(
      builder: (context, ref, child) {
        final rulesAsync = ref.watch(htmlRulesProvider);

        return rulesAsync.when(
          data: (rules) {
            final enRules = rules['en'] as Map<String, dynamic>?;
            final homePageSections =
                enRules?['homePageSections'] as Map<String, dynamic>?;

            final featuredArticleId =
                homePageSections?['featuredArticle'] as String? ?? 'mp-tfa';
            final inTheNewsId =
                homePageSections?['inTheNews'] as String? ?? 'mp-itn';
            final onThisDayId =
                homePageSections?['onThisDay'] as String? ?? 'mp-otd';
            final featuredImageId =
                homePageSections?['featuredImage'] as String? ?? 'mp-tfp';
            final featuredListId =
                homePageSections?['featuredList'] as String? ?? 'mp-tfl';
            final doYouKnowId =
                homePageSections?['doYouKnow'] as String? ?? 'mp-dyk';

            // Explicitly target Wikipedia sections by IDs
            final featuredArticle = extractSection(
              featuredArticleId,
              'Featured Article',
            );
            final inTheNews = extractSection(inTheNewsId, 'In the news');
            final onThisDay = extractSection(onThisDayId, 'On this day');
            final featuredImage = extractSection(
              featuredImageId,
              'Featured picture',
            );
            final featuredList = extractSection(
              featuredListId,
              'Featured list',
            );
            final doYouKnow = extractSection(doYouKnowId, 'Did you know');

            // Determine header background image
            String? headerBg;
            if (featuredImage != null && featuredImage['images'].isNotEmpty) {
              headerBg = featuredImage['images'].first;
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HomeHeaderCard(
                    imageUrl: headerBg,
                    languageName: 'English Language',
                  ),
                  const SizedBox(height: 16),

                  if (featuredArticle != null) ...[
                    HomeSectionHeader(
                      theme: theme,
                      title: featuredArticle['header'],
                    ),
                    HomeSectionBody(
                      context: context,
                      theme: theme,
                      section: featuredArticle,
                      langCode: langCode,
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (inTheNews != null) ...[
                    HomeSectionHeader(theme: theme, title: inTheNews['header']),
                    HomeSectionBody(
                      context: context,
                      theme: theme,
                      section: inTheNews,
                      langCode: langCode,
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (onThisDay != null) ...[
                    HomeSectionHeader(theme: theme, title: onThisDay['header']),
                    HomeSectionBody(
                      context: context,
                      theme: theme,
                      section: onThisDay,
                      langCode: langCode,
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (featuredImage != null) ...[
                    HomeSectionHeader(
                      theme: theme,
                      title: featuredImage['header'],
                    ),
                    HomeSectionBody(
                      context: context,
                      theme: theme,
                      section: featuredImage,
                      langCode: langCode,
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (featuredList != null) ...[
                    HomeSectionHeader(
                      theme: theme,
                      title: featuredList['header'],
                    ),
                    HomeSectionBody(
                      context: context,
                      theme: theme,
                      section: featuredList,
                      langCode: langCode,
                    ),
                    const SizedBox(height: 24),
                  ],

                  if (doYouKnow != null) ...[
                    HomeSectionHeader(theme: theme, title: doYouKnow['header']),
                    HomeSectionBody(
                      context: context,
                      theme: theme,
                      section: doYouKnow,
                      langCode: langCode,
                    ),
                    const SizedBox(height: 24),
                  ],

                  const SizedBox(height: 48),
                  const ContributeCard(),
                  const WikiFooter(),
                  const SizedBox(height: 80),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) =>
              const Center(child: Text('Error loading rules')),
        );
      },
    );
  }
}
