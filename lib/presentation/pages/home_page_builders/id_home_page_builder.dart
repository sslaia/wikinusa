import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:wikinusa/presentation/pages/article_screen.dart';
import 'package:wikinusa/presentation/pages/search_results_screen.dart';
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

    final contentBoxes = document.querySelectorAll('.mp-content-box');

    // Helper to extract specific section data
    Map<String, dynamic>? extractSection(String title) {
      final box = contentBoxes.firstWhere((b) {
        final header = b
            .querySelector('.mp-content-box__header-text')
            ?.text
            .trim()
            .toLowerCase();
        return header == title.toLowerCase();
      }, orElse: () => dom.Element.tag('div'));

      if (box.innerHtml.isEmpty) return null;

      final header = box
          .querySelector('.mp-content-box__header-text')
          ?.text
          .trim();
      final content = box.querySelector('.mp-content-box__content');

      if (content == null) return null;

      // Fix URLs before extraction
      _fixUrls(content, langCode);

      // Find thumb/image container BEFORE removing images to maintain reference
      final thumb = content.querySelector(
        '.thumb, .mp-gambar-pilihan, .mw-file-element',
      );
      dom.Element? nextAfterThumb = thumb?.nextElementSibling;

      // 1. Extract images to display them at the top of the card
      final List<String> images = [];
      String? firstAlt;
      content.querySelectorAll('img').forEach((img) {
        final src = img.attributes['src'];
        final alt = img.attributes['alt'];
        if (src != null && src.isNotEmpty) {
          // Skip tiny icons
          final widthAttr = img.attributes['width'];
          if (widthAttr != null) {
            final width = int.tryParse(widthAttr);
            if (width != null && width < 100) return;
          }

          images.add(src);
          if (firstAlt == null && alt != null && alt.isNotEmpty) {
            firstAlt = alt;
          }
        }
        img.remove(); // Remove from HTML to display manually at top
      });

      // 2. Refinement logic: Collect relevant content nodes
      final List<dom.Node> relevantNodes = [];
      final titleLower = title.toLowerCase();

      if (thumb != null) {
        var current = nextAfterThumb;
        if (titleLower == 'gambar pilihan') {
          // For Featured Image, prioritize finding a caption div
          while (current != null) {
            if (current.localName == 'div') {
              relevantNodes.add(current);
              break;
            }
            current = current.nextElementSibling;
          }
        } else {
          // For other sections, collect all siblings until we hit administrative links
          while (current != null) {
            final text = current.text.toLowerCase();
            if (text.contains('selengkapnya') ||
                text.contains('arsip') ||
                current.classes.contains('noprint') ||
                current.classes.contains('mp-footer')) {
              break;
            }
            relevantNodes.add(current);
            current = current.nextElementSibling;
          }
        }
      }

      // 3. Rebuild content or use fallback
      String finalBody;
      if (relevantNodes.isNotEmpty) {
        content.nodes.clear();
        content.nodes.addAll(relevantNodes);
        finalBody = content.innerHtml;
      } else if (titleLower == 'gambar pilihan' && firstAlt != null) {
        finalBody = '<p>$firstAlt</p>';
      } else {
        // Fallback: If traversal failed, use the content (images are already stripped)
        finalBody = content.innerHtml;
      }

      return {'header': header, 'body': finalBody, 'images': images};
    }

    // Explicitly target Indonesian Wikipedia sections
    final featuredArticle = extractSection('Artikel pilihan');
    final featuredImage = extractSection('Gambar pilihan');
    final didYouKnow = extractSection('Tahukah Anda');
    final currentEvents = extractSection('Peristiwa terkini');
    final onThisDay = extractSection('Hari ini dalam sejarah');

    // Determine header background image
    String? headerBg;
    if (featuredImage != null && featuredImage['images'].isNotEmpty) {
      headerBg = featuredImage['images'].first;
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildHeaderCard(context, theme, headerBg),
        const SizedBox(height: 16),

        if (featuredArticle != null) ...[
          _buildSectionHeader(theme, featuredArticle['header']),
          _buildSectionCard(context, theme, featuredArticle, langCode),
          const SizedBox(height: 24),
        ],

        if (featuredImage != null) ...[
          _buildSectionHeader(theme, featuredImage['header']),
          _buildSectionCard(context, theme, featuredImage, langCode),
          const SizedBox(height: 24),
        ],

        if (didYouKnow != null) ...[
          _buildSectionHeader(theme, didYouKnow['header']),
          _buildSectionCard(context, theme, didYouKnow, langCode),
          const SizedBox(height: 24),
        ],

        if (currentEvents != null) ...[
          _buildSectionHeader(theme, currentEvents['header']),
          _buildSectionCard(context, theme, currentEvents, langCode),
          const SizedBox(height: 24),
        ],

        if (onThisDay != null) ...[
          _buildSectionHeader(theme, onThisDay['header']),
          _buildSectionCard(context, theme, onThisDay, langCode),
          const SizedBox(height: 24),
        ],

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildSectionCard(BuildContext context, ThemeData theme, Map<String, dynamic> section, String langCode) {
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
                // 1. Display images first (100% width)
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
  
                // 2. Display refined HTML content
                HtmlWidget(
                  section['body'],
                  onTapUrl: (url) async {
                    await ArticleScreen.handleWikipediaLink(context, ref, url, langCode);
                    return true;
                  },
                  textStyle: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'serif',
                    fontSize: 16,
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

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.secondary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
    BuildContext context,
    ThemeData theme,
    String? imageUrl,
  ) {
    return Stack(
      children: [
        Container(
          height: 300,
          width: double.infinity,
          decoration: BoxDecoration(color: theme.colorScheme.surface),
          child: imageUrl != null
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  headers: const {
                    'User-Agent': 'WikinusaApp/1.0 (slaia@yahoo.com) FlutterApp',
                  },
                  errorBuilder: (context, error, stackTrace) => Container(color: theme.colorScheme.primaryContainer),
                )
              : Container(color: theme.colorScheme.primaryContainer),
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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'welcome_to'.tr(),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    shadows: [
                      const Shadow(blurRadius: 10, color: Colors.black),
                    ],
                  ),
                ),
                Text(
                  'WikiNusa',
                  style: GoogleFonts.cinzelDecorative(
                    textStyle: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        const Shadow(blurRadius: 10, color: Colors.black),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'motto'.tr(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    shadows: [
                      const Shadow(blurRadius: 10, color: Colors.black),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildSearchField(context, theme),
              ],
            ),
          ),
        ),
      ],
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
      child: TextField(
        style: const TextStyle(color: Colors.white),
        onSubmitted: (String str) {
          if (str.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SearchResultsScreen(query: str),
              ),
            );
          }
        },
        onTapOutside: (event) {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        decoration: InputDecoration(
          hintText: 'search_wikipedia'.tr(),
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}
