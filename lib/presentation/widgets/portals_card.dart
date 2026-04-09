import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../pages/article_screen.dart';

class PortalsCard extends ConsumerWidget {
  final List<Map<String, dynamic>> portals;
  final String langCode;

  const PortalsCard({
    super.key,
    required this.portals,
    required this.langCode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'wiki_portals'.tr().toUpperCase(),
            style: GoogleFonts.montserratAlternates(
              textStyle: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontSize: 16,
              ),
            ),
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: portals.length,
            itemBuilder: (context, index) {
              final portal = portals[index];
              return _buildPortalItem(context, ref, theme, portal);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPortalItem(BuildContext context, WidgetRef ref, ThemeData theme, Map<String, dynamic> portal) {
    return GestureDetector(
      onTap: () => ArticleScreen.handleWikipediaLink(
        context,
        ref,
        'https://$langCode.wikipedia.org/wiki/${portal['pageTitle']}',
        langCode,
      ),
      child: Container(
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: portal['color'] as Color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(portal['icon'] as IconData, color: portal['iconColor'] as Color, size: 32),
            const SizedBox(height: 8),
            Text(
              (portal['title'] as String).tr(),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}