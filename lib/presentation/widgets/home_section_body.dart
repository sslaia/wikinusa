import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wikinusa/core/theme_config.dart';
import 'package:wikinusa/presentation/pages/article_screen.dart';

class HomeSectionBody extends StatelessWidget {
  const HomeSectionBody({
    super.key,
    required this.context,
    required this.theme,
    required this.section,
    required this.langCode,
  });

  final BuildContext context;
  final ThemeData theme;
  final Map<String, dynamic> section;
  final String langCode;

  @override
  Widget build(BuildContext context) {
    final String sectionBody = section['body'];

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
                    // Provide support for a very wide range of characters including Arabic, Javanese, etc.
                    fontFamily: GoogleFonts.notoSerif().fontFamily,
                    // Ensures that the HTML text scales based on the global font size provider
                    fontSize: theme.textTheme.bodyMedium?.fontSize,
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
                            ? '#${WikinusaThemeConfig.getLinkRed(theme.brightness).toARGB32().toRadixString(16).substring(2)}'
                            : '#${theme.colorScheme.primary.toARGB32().toRadixString(16).substring(2)}',
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
