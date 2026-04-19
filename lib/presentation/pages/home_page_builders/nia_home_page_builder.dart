import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import 'package:wikinusa/core/constants/home_portals.dart';
import 'package:wikinusa/core/utils/wiki_html_utils.dart';
import 'package:wikinusa/presentation/providers/html_rules_provider.dart';
import 'package:wikinusa/presentation/widgets/home_header_card.dart';
import 'package:wikinusa/presentation/widgets/home_section_body.dart';
import 'package:wikinusa/presentation/widgets/home_section_header.dart';
import 'package:wikinusa/presentation/widgets/portals_card.dart';
import 'package:wikinusa/presentation/widgets/contribute_card.dart';
import 'package:wikinusa/presentation/widgets/wiki_footer.dart';
import 'package:wikinusa/presentation/pages/home_page_builders/home_page_builder.dart';
import 'package:wikinusa/domain/entities/wiki_project.dart';

class NiasHomePageBuilder implements HomePageBuilder {
  @override
  Widget build(
    BuildContext context,
    String pageTitle,
    String html,
    String langCode,
    Orientation orientation,
    WikiProject project,
  ) {
    final theme = Theme.of(context);

    // If not Wikipedia, use a generic adaptive layout for now
    if (project != WikiProject.wikipedia) {
      return _buildGenericProjectLayout(context, html, langCode, project);
    }

    final document = html_parser.parse(html);
    document.querySelectorAll('script, style, link').forEach((e) => e.remove());

    // Helper to extract specific section data
    Map<String, dynamic>? extractSection(String id, String header) {
      final section = document.getElementById(id);
      if (section == null) return null;

      WikiHtmlUtils.fixUrls(section, langCode);

      final List<String> images = [];
      section.querySelectorAll('img').forEach((img) {
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

      String finalBody = '';
      if (id == 'mp-featured-article') {
        final bodyContainer = section.querySelector('#mp-featured-article-body');
        if (bodyContainer != null) {
          finalBody = bodyContainer.innerHtml;
        } else {
          section.querySelectorAll('.mp-h2, #mp-featured-article').forEach((e) => e.remove());
          finalBody = section.innerHtml;
        }
      } else if (id == 'mp-featured-photo') {
        final pElements = section.querySelectorAll('span').where((e) => e.text.trim().isNotEmpty);
        if (pElements.isNotEmpty) finalBody = pElements.first.outerHtml;
      } else if (id == 'mp-dyk' || id == 'mp-otm') {
        final ulElements = section.querySelectorAll('ul').where((e) => e.text.trim().isNotEmpty);
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
            final langRules = rules[langCode] as Map<String, dynamic>?;
            final projectRules = langRules?[project.name] as Map<String, dynamic>?;
            final homePageSections = projectRules?['homePageSections'] as Map<String, dynamic>?;

            final featuredArticleId = homePageSections?['featuredArticle'] as String? ?? 'mp-featured-article';
            final featuredImageId = homePageSections?['featuredImage'] as String? ?? 'mp-featured-photo';
            final doYouKnowId = homePageSections?['doYouKnow'] as String? ?? 'mp-dyk';
            final onThisMonthId = homePageSections?['onThisMonth'] as String? ?? 'mp-otm';

            final featuredArticle = extractSection(featuredArticleId, 'Sura amilita');
            final featuredImage = extractSection(featuredImageId, 'Gamara amilita');
            final doYouKnow = extractSection(doYouKnowId, "Hadia ö'ila");
            final onThisMonth = extractSection(onThisMonthId, 'Salua föna');

            String? headerBg;
            if (featuredImage != null && featuredImage['images'].isNotEmpty) {
              headerBg = featuredImage['images'].first;
            }

            final portals = HomePortals.getPortals(context)[langCode] ?? [];

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HomeHeaderCard(imageUrl: headerBg, languageName: 'Li Niha'),
                  const SizedBox(height: 16),
                  if (featuredArticle != null) ...[
                    HomeSectionHeader(theme: theme, title: featuredArticle['header']),
                    HomeSectionBody(context: context, theme: theme, section: featuredArticle, langCode: langCode),
                    const SizedBox(height: 24),
                  ],
                  if (featuredImage != null) ...[
                    HomeSectionHeader(theme: theme, title: featuredImage['header']),
                    HomeSectionBody(context: context, theme: theme, section: featuredImage, langCode: langCode),
                    const SizedBox(height: 24),
                  ],
                  if (doYouKnow != null) ...[
                    HomeSectionHeader(theme: theme, title: doYouKnow['header']),
                    HomeSectionBody(context: context, theme: theme, section: doYouKnow, langCode: langCode),
                    const SizedBox(height: 24),
                  ],
                  if (onThisMonth != null) ...[
                    HomeSectionHeader(theme: theme, title: onThisMonth['header']),
                    HomeSectionBody(context: context, theme: theme, section: onThisMonth, langCode: langCode),
                    const SizedBox(height: 32),
                  ],
                  if (portals.isNotEmpty) PortalsCard(portals: portals, langCode: langCode),
                  const SizedBox(height: 48),
                  const ContributeCard(),
                  const WikiFooter(),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('error_loading_rules').tr()),
        );
      },
    );
  }

  Widget _buildGenericProjectLayout(BuildContext context, String html, String langCode, WikiProject project) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const HomeHeaderCard(imageUrl: null, languageName: 'Li Niha'),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: HtmlWidget(
            html,
            textStyle: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 48),
        const ContributeCard(),
        const WikiFooter(),
        const SizedBox(height: 32),
      ],
    );
  }
}
