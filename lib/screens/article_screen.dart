import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html/parser.dart' as html_parser;

import '../widgets/wiki_footer.dart';
import '../providers/app_state.dart';
import '../providers/wiki_api_provider.dart';
import '../widgets/article_hero_image.dart';
import '../widgets/custom_bottom_app_bar.dart';
import '../widgets/drawer_menu.dart';

class ArticleScreen extends ConsumerStatefulWidget {
  final String title;

  const ArticleScreen({super.key, required this.title});

  @override
  ConsumerState<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends ConsumerState<ArticleScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final currentProject = ref.watch(appStateProvider);
    final wikiContent = ref.watch(wikiApiProvider(widget.title));
    final languageCode = context.locale.languageCode;

    return PopScope(
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const DrawerMenu(),
        body: wikiContent.when(
          data: (data) {
            String htmlContent;
            String? imageUrl;

            if (data is Map<String, dynamic>) {
              htmlContent = data['html'] ?? '';
              imageUrl = data['imageUrl'];
            } else if (data is String) {
              htmlContent = data;
            } else {
              htmlContent = '';
            }

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ArticleHeroImage(
                    theme: Theme.of(context),
                    title: widget.title,
                    imageUrl: imageUrl ?? '',
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: HtmlWidget(
                      htmlContent,
                      textStyle: GoogleFonts.notoSerif(
                        fontSize: Theme.of(context).textTheme.bodyMedium?.fontSize,
                        height: 1.8,
                      ),
                      onTapUrl: (url) {
                        if (url.contains('cite_note')) {
                          final refId = url.split('#').last;
                          _showReferencePopup(context, refId, htmlContent, languageCode);
                          return true;
                        }
                        // ArticleScreen.handleWikipediaLink(context, ref, url, languageCode);
                        return true;
                      },                    ),
                  ),
                  WikiFooter(),
                ],
              ),
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error loading article: $error'),
            ),
          ),
        ),
        bottomNavigationBar: CustomBottomAppBar(
          scaffoldKey: _scaffoldKey,
          currentProject: currentProject,
          pageTitle: widget.title,
        ),
      ),
    );
  }

  void _showReferencePopup(
      BuildContext context,
      String referenceId,
      String htmlContent,
      String langCode,
      ) {
    final theme = Theme.of(context);
    final document = html_parser.parse(htmlContent);

    // Wikipedia reference IDs might be URI encoded
    final decodedId = Uri.decodeComponent(referenceId);
    final refElement =
        document.getElementById(decodedId) ??
            document.getElementById(referenceId);

    if (refElement == null) {
      debugPrint('Reference element not found: $referenceId');
      return;
    }

    // Remove backlink arrows commonly found in Wikipedia references
    refElement.querySelectorAll('.mw-cite-backlink').forEach((e) => e.remove());

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.4,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: theme.colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Text(
                  'reference'.tr(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.secondary,
                    letterSpacing: 1.1,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            Flexible(
              child: SingleChildScrollView(
                child: HtmlWidget(
                  refElement.innerHtml,
                  onTapUrl: (url) {
                    // ArticleScreen.handleWikipediaLink(
                    //   context,
                    //   ref,
                    //   url,
                    //   langCode,
                    // );
                    return true;
                  },
                  textStyle: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    height: 1.6,
                    color: theme.colorScheme.onSurface,
                  ),
                  customStylesBuilder: (element) {
                    // Fix footnote line breaks inside the popup as well
                    if (element.localName == 'sup' ||
                        element.classes.contains('reference')) {
                      return {
                        'display': 'inline',
                        'font-size': '0.75em',
                        'vertical-align': 'super',
                        'line-height': '0',
                      };
                    }
                    // Fix red link colors
                    if (element.localName == 'a') {
                      return {
                        'color':
                        '#${theme.colorScheme.primary.toARGB32().toRadixString(16).substring(2)}',
                        'text-decoration': 'none',
                      };
                    }
                    return null;
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
