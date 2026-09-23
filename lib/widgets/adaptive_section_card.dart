import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wikimedia_core/wikimedia_core.dart';
import '../screens/image_screen.dart';
import '../utils/wiki_utils.dart';
import '../utils/responsive_utils.dart';
import '../providers/app_state.dart';

class AdaptiveSectionCard extends ConsumerWidget {
  final HomePageSection section;
  final ProjectType project;

  const AdaptiveSectionCard({
    super.key,
    required this.section,
    required this.project,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isCompactPortrait = ResponsiveUtils.isCompact(context) && ResponsiveUtils.isPortrait(context);
    final langCode = ref.watch(languageProvider);
    
    final imageUrl = section.imageUrl;
    final hasValidImage = (imageUrl != null &&
            imageUrl.isNotEmpty &&
            !CoreWikiUtils.isIcon(imageUrl)) ||
        (section.imageHtml != null &&
            (imageUrl == null ||
                (imageUrl.isNotEmpty &&
                    !CoreWikiUtils.isIcon(imageUrl))));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            section.titleKey.tr(),
            style: GoogleFonts.plusJakartaSans(
              textStyle: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontSize: 16,
              ),
            ),
          ),
        ),
        Card(
          elevation: 2,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 24),
          child: isCompactPortrait 
              ? _buildVerticalLayout(context, langCode, hasValidImage) 
              : _buildHorizontalLayout(context, langCode, hasValidImage),
        ),
      ],
    );
  }

  Widget _buildVerticalLayout(
    BuildContext context,
    String langCode,
    bool hasValidImage,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasValidImage)
          _buildSectionImage(context, langCode, isVertical: true),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildBodyText(context, langCode),
        ),
      ],
    );
  }

  Widget _buildHorizontalLayout(
    BuildContext context,
    String langCode,
    bool hasValidImage,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (hasValidImage)
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: _buildSectionImage(context, langCode, isVertical: false),
            ),
          ),
        Expanded(
          flex: hasValidImage ? 3 : 1,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildBodyText(context, langCode),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionImage(
    BuildContext context,
    String langCode, {
    required bool isVertical,
  }) {
    final imageUrl = section.imageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty && !CoreWikiUtils.isIcon(imageUrl)) {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ImageScreen(
                imagePath: imageUrl,
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: isVertical
              ? const BorderRadius.vertical(top: Radius.circular(12))
              : BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: isVertical ? 200 : 140,
            headers: WikiConfig.uaHeaders,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: isVertical ? 200 : 140,
                width: double.infinity,
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.3),
                child: const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              if (section.imageHtml != null && section.imageHtml!.isNotEmpty) {
                return HtmlWidget(
                  section.imageHtml!,
                  onTapUrl: (url) =>
                      WikiUtils.handleTapUrl(context, url, null, project, langCode),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    }

    if (section.imageHtml != null && section.imageHtml!.isNotEmpty) {
      return GestureDetector(
        onTap: () {
          if (imageUrl != null && imageUrl.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ImageScreen(
                  imagePath: imageUrl,
                ),
              ),
            );
          }
        },
        child: HtmlWidget(
          section.imageHtml!,
          onTapUrl: (url) =>
              WikiUtils.handleTapUrl(context, url, null, project, langCode),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildBodyText(BuildContext context, String langCode) {
    return HtmlWidget(
      section.textHtml,
      onTapUrl: (url) => WikiUtils.handleTapUrl(context, url, null, project, langCode),
      textStyle: GoogleFonts.plusJakartaSans(
        textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
          height: 1.6,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
        ),
      ),
      customStylesBuilder: (element) => WikiUtils.customStyles(context, element),
    );
  }
}
