import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html/dom.dart' as dom;
import 'package:wikinusa/utils/wiki_utils.dart';

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
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
                      ),
                      onTapUrl: (url) => WikiUtils.handleTapUrl(context, url, htmlContent),
                      customStylesBuilder: (element) => WikiUtils.customStyles(context, element),
                      customWidgetBuilder: (element) {
                        // Priority 1: Use shared utils (for h2 short underline, etc.)
                        final sharedWidget = WikiUtils.customWidgetBuilder(context, element);
                        if (sharedWidget != null) return sharedWidget;

                        // Priority 2: Screen-specific logic (Galleries)
                        if (element.classes.contains('gallery')) {
                          return _buildNativeGallery(element);
                        }

                        // Priority 3: Screen-specific logic (Full-width body images)
                        if (element.localName == 'img' || element.classes.contains('thumb') || element.localName == 'figure') {
                           if (element.classes.contains('hidden-hero-container')) {
                             return const SizedBox.shrink();
                           }
                           
                           final img = element.localName == 'img' ? element : element.querySelector('img');
                           if (img != null) {
                             final caption = element.querySelector('.caption')?.text ?? 
                                             element.querySelector('.thumbcaption')?.text ??
                                             element.querySelector('figcaption')?.text;
                                             
                             return _buildFullWidthImage(img, caption);
                           }
                        }
                        return null;
                      },
                    ),
                  ),
                  const WikiFooter(),
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

  Widget _buildNativeGallery(dom.Element galleryElement) {
    final items = galleryElement.querySelectorAll('.gallerybox');
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 280,
      margin: const EdgeInsets.symmetric(vertical: 24),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final box = items[index];
          final img = box.querySelector('img');
          final caption = box.querySelector('.gallerytext')?.text ?? '';
          
          if (img == null) return const SizedBox.shrink();
          final src = img.attributes['src'] ?? '';

          return Container(
            width: MediaQuery.of(context).size.width * 0.8,
            margin: const EdgeInsets.only(right: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    src.startsWith('http') ? src : 'https:$src',
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                        ),
                      ),
                      child: Text(
                        caption,
                        style: const TextStyle(
                          color: Colors.white, 
                          fontSize: 12, 
                          fontStyle: FontStyle.italic
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFullWidthImage(dom.Element img, String? caption) {
    final src = img.attributes['src'] ?? '';
    if (src.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              src.startsWith('http') ? src : 'https:$src',
              width: double.infinity,
              fit: BoxFit.fitWidth,
            ),
          ),
          if (caption != null && caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Text(
                caption,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
