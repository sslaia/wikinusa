import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:wikinusa/core/constants/home_portals.dart';
import 'package:wikinusa/core/utils/wiki_html_utils.dart';
import 'package:wikinusa/presentation/pages/article_screen.dart';
import 'package:wikinusa/presentation/providers/html_rules_provider.dart';
import 'package:wikinusa/presentation/widgets/home_header_card.dart';
import 'package:wikinusa/presentation/widgets/home_section_header.dart';
import 'package:wikinusa/presentation/widgets/portals_card.dart';
import 'package:wikinusa/presentation/widgets/contribute_card.dart';
import 'package:wikinusa/presentation/widgets/wiki_footer.dart';
import 'package:wikinusa/domain/entities/wiki_project.dart';
import 'home_page_builder.dart';

class IndonesianHomePageBuilder implements HomePageBuilder {
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
    final document = html_parser.parse(html);
    
    // 1. Initial Cleanup: Remove scripts, styles, etc.
    document.querySelectorAll('script, style, link').forEach((e) => e.remove());

    return Consumer(
      builder: (context, ref, child) {
        final rulesAsync = ref.watch(htmlRulesProvider);
        final portals = HomePortals.getPortals(context)[langCode] ?? [];

        return rulesAsync.when(
          data: (rules) {
            // 2. Fetch Section IDs and Labels
            final langRules = rules[langCode] as Map<String, dynamic>?;
            final projectRules = langRules?[project.name] as Map<String, dynamic>?;
            final homePageSections = projectRules?['homePageSections'] as Map<String, dynamic>?;

            if (homePageSections == null || homePageSections.isEmpty) {
              return _buildGenericProjectLayout(context, html, langCode, project);
            }

            // 3. Extract sections dynamically based on JSON keys
            final List<Map<String, dynamic>> sections = [];
            homePageSections.forEach((key, id) {
              final section = _extractSection(document, id, _getLabel(key), langCode);
              if (section != null) sections.add(section);
            });

            String? headerBg;
            final featuredImageSection = sections.firstWhere((s) => s['id'] == homePageSections['featuredImage'], orElse: () => {});
            if (featuredImageSection.isNotEmpty && (featuredImageSection['images'] as List).isNotEmpty) {
              headerBg = featuredImageSection['images'].first;
            }

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                HomeHeaderCard(imageUrl: headerBg, languageName: 'Bahasa Indonesia'),
                const SizedBox(height: 16),
                
                for (var section in sections) ...[
                  HomeSectionHeader(theme: theme, title: section['header']),
                  _buildSectionCard(context, theme, section, langCode),
                  const SizedBox(height: 24),
                ],

                const SizedBox(height: 32),
                if (portals.isNotEmpty) PortalsCard(portals: portals, langCode: langCode),
                const SizedBox(height: 48),
                const ContributeCard(),
                const WikiFooter(),
                const SizedBox(height: 80),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('error_loading_rules').tr()),
        );
      },
    );
  }

  Map<String, dynamic>? _extractSection(dom.Document document, String id, String header, String langCode) {
    final section = document.getElementById(id);
    if (section == null) return null;

    // Clean section
    WikiHtmlUtils.fixUrls(section, langCode);

    final List<String> images = [];
    section.querySelectorAll('img').forEach((img) {
      String? src = img.attributes['data-src'] ?? img.attributes['src'];
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

    // Strategy-based cleaning for the body
    String finalBody = '';
    if (id == 'mf-artikelpilihan' || id == 'mp-tfa') {
      final pElements = section.querySelectorAll('p').where((e) => e.text.trim().isNotEmpty);
      if (pElements.isNotEmpty) finalBody = pElements.first.outerHtml;
    } else {
      // Remove complex structures like infoboxes or tables that might be inside a section
      section.querySelectorAll('table, .infobox, .navbox, .metadata').forEach((e) => e.remove());
      finalBody = section.innerHtml;
    }

    if (finalBody.trim().isEmpty) return null;
    return {'id': id, 'header': header, 'body': finalBody, 'images': images};
  }

  String _getLabel(String key) {
    switch (key) {
      case 'featuredArticle': return 'Artikel pilihan';
      case 'featuredImage': return 'Gambar pilihan';
      case 'doYouKnow': return 'Tahukah Anda';
      case 'recentEvents': return 'Peristiwa terkini';
      case 'onThisDay': return 'Hari ini dalam sejarah';
      case 'onThisMonth': return 'Salua föna';
      case 'featuredWord': return 'Leksikon pilihan';
      case 'featuredStory': return 'Sura amilita';
      default: return '';
    }
  }

  Widget _buildGenericProjectLayout(BuildContext context, String html, String langCode, WikiProject project) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const HomeHeaderCard(imageUrl: null, languageName: 'Bahasa Indonesia'),
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

  Widget _buildSectionCard(BuildContext context, ThemeData theme, Map<String, dynamic> section, String langCode) {
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
            side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var url in section['images'])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        WikiHtmlUtils.getHighResUrl(url),
                        width: double.infinity,
                        fit: BoxFit.fitWidth,
                        headers: const {'User-Agent': 'WikinusaApp/1.0 (slaia@yahoo.com) FlutterApp'},
                        errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                HtmlWidget(
                  '<div style="text-align: justify;">$sectionBody</div>',
                  onTapUrl: (url) async {
                    await ArticleScreen.handleWikipediaLink(context, ref, url, langCode);
                    return true;
                  },
                  textStyle: theme.textTheme.bodyMedium?.copyWith(height: 1.6, color: theme.colorScheme.onSurface.withValues(alpha: 0.85)),
                  customStylesBuilder: (element) {
                    if (element.localName == 'p') return {'margin-bottom': '12px', 'text-align': 'justify'};
                    if (element.localName == 'a') {
                      return {
                        'color': '#${theme.colorScheme.primary.toARGB32().toRadixString(16).substring(2)}',
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
