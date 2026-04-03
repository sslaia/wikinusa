import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'home_page_builder.dart';

class DefaultHomePageBuilder implements HomePageBuilder {
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

    // Remove scripts and styles that might confuse the layout engine
    document.querySelectorAll('script, style, link').forEach((e) => e.remove());

    // Target the main content div if available, otherwise use body
    final contentElement =
        document.querySelector('.mw-parser-output') ?? document.body!;

    // Fix URLs for images and links
    _fixUrls(contentElement, langCode);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildHeaderCard(theme),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _buildHtmlContent(theme, contentElement.innerHtml),
        ),
        const SizedBox(height: 80), // Padding for BottomNavigationBar
      ],
    );
  }

  Widget _buildHtmlContent(ThemeData theme, String html) {
    final document = html_parser.parse(html);

    // Extract images to ensure they aren't constrained by nested desktop-oriented HTML
    final imgElements = document.querySelectorAll('img');
    final List<String> imageUrls = [];
    for (var img in imgElements) {
      final src = img.attributes['src'];
      // Only extract images that aren't tiny icons
      final width = int.tryParse(img.attributes['width'] ?? '');
      final height = int.tryParse(img.attributes['height'] ?? '');

      if (src != null && src.isNotEmpty) {
        if ((width == null || width > 20) && (height == null || height > 20)) {
          imageUrls.add(src);
          img.remove();
        }
      }
    }

    final remainingHtml = document.body?.innerHtml ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var url in imageUrls)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                url,
                width: double.infinity,
                fit: BoxFit.fitWidth,
                headers: const {
                  'User-Agent': 'WikinusaApp/1.0 (slaia@yahoo.com) FlutterApp',
                },
                errorBuilder: (ctx, err, stack) => const SizedBox.shrink(),
              ),
            ),
          ),
        HtmlWidget(
          remainingHtml,
          textStyle: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 14,
            height: 1.6,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
          ),
          customStylesBuilder: (element) {
            if (element.classes.contains('mp-content-box__header-text')) {
              return {
                'font-weight': 'bold',
                'font-size': '1.2em',
                'color':
                    '#${theme.colorScheme.primary.value.toRadixString(16).substring(2)}',
                'margin-bottom': '8px',
              };
            }
            if (element.classes.contains('mp-content-box__content')) {
              return {'padding': '10px', 'text-align': 'justify'};
            }
            if (element.localName == 'a') {
              return {
                'color':
                    '#${theme.colorScheme.primary.value.toRadixString(16).substring(2)}',
                'text-decoration': 'none',
                'font-weight': '600',
              };
            }
            if (element.localName == 'table') {
              return {'width': '100%'};
            }
            return null;
          },
        ),
      ],
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
    });

    element.querySelectorAll('a').forEach((a) {
      final href = a.attributes['href'];
      if (href != null && href.startsWith('/')) {
        a.attributes['href'] = 'https://$langCode.wikipedia.org$href';
      }
    });
  }

  Widget _buildHeaderCard(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'WikiNusa',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'motto'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer.withValues(
                alpha: 0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
