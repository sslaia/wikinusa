import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

import 'package:wikinusa/core/constants/home_portals.dart';
import 'package:wikinusa/core/utils/wiki_html_utils.dart';
import 'package:wikinusa/presentation/widgets/home_header_card.dart';
import 'package:wikinusa/presentation/widgets/home_section_body.dart';
import 'package:wikinusa/presentation/widgets/home_section_header.dart';
import 'package:wikinusa/presentation/widgets/portals_card.dart';
import 'package:wikinusa/presentation/widgets/contribute_card.dart';
import 'package:wikinusa/presentation/widgets/wiki_footer.dart';
import 'package:wikinusa/presentation/pages/home_page_builders/home_page_builder.dart';
import 'package:wikinusa/domain/entities/wiki_project.dart';

class EnglishHomePageBuilder implements HomePageBuilder {
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

    if (project != WikiProject.wikipedia) {
      return _buildGenericProjectLayout(context, html, langCode, project);
    }

    final document = html_parser.parse(html);
    document.querySelectorAll('script, style, link').forEach((e) => e.remove());

    Map<String, dynamic>? extractSection(String id, String header) {
      final section = document.getElementById(id);
      if (section == null) return null;

      WikiHtmlUtils.fixUrls(section, langCode);

      final List<String> images = [];
      section.querySelectorAll('img').forEach((img) {
        final src = img.attributes['src'];
        if (src != null && src.isNotEmpty) {
          images.add(src);
        }
        img.remove();
      });

      return {'header': header, 'body': section.innerHtml, 'images': images};
    }

    final featuredArticle = extractSection('mp-tfa', 'Featured article');
    final inTheNews = extractSection('mp-itn', 'In the news');
    final didYouKnow = extractSection('mp-dyk', 'Did you know...');
    final onThisDay = extractSection('mp-otd', 'On this day');

    String? headerBg;
    if (featuredArticle != null && featuredArticle['images'].isNotEmpty) {
      headerBg = featuredArticle['images'].first;
    }

    final portals = HomePortals.getPortals(context)[langCode] ?? [];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeHeaderCard(imageUrl: headerBg, languageName: 'English'),
          const SizedBox(height: 16),
          if (featuredArticle != null) ...[
            HomeSectionHeader(theme: theme, title: featuredArticle['header']),
            HomeSectionBody(context: context, theme: theme, section: featuredArticle, langCode: langCode),
            const SizedBox(height: 24),
          ],
          if (inTheNews != null) ...[
            HomeSectionHeader(theme: theme, title: inTheNews['header']),
            HomeSectionBody(context: context, theme: theme, section: inTheNews, langCode: langCode),
            const SizedBox(height: 24),
          ],
          if (didYouKnow != null) ...[
            HomeSectionHeader(theme: theme, title: didYouKnow['header']),
            HomeSectionBody(context: context, theme: theme, section: didYouKnow, langCode: langCode),
            const SizedBox(height: 24),
          ],
          if (onThisDay != null) ...[
            HomeSectionHeader(theme: theme, title: onThisDay['header']),
            HomeSectionBody(context: context, theme: theme, section: onThisDay, langCode: langCode),
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
  }

  Widget _buildGenericProjectLayout(BuildContext context, String html, String langCode, WikiProject project) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const HomeHeaderCard(imageUrl: null, languageName: 'English'),
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
