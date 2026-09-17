import 'package:flutter/material.dart';
import 'package:wikimedia_core/wikimedia_core.dart';
class ArticleHeroImage extends StatelessWidget {
  const ArticleHeroImage({
    super.key,
    required this.theme,
    required this.title,
    required this.imageUrl,
    required this.project,
  });

  final ThemeData theme;
  final String title;
  final String imageUrl;
  final ProjectType project;

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final iconColor = project.getThemedColor(isDark);

    return Stack(
      children: [
        Container(
          height: 350,
          width: double.infinity,
          color: theme.colorScheme.surface,
          child: imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  headers: WikiConfig.uaHeaders,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 350,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    project.articleHeroImagePath,
                    fit: BoxFit.cover,
                  ),
                )
              : Image.asset(
                  project.articleHeroImagePath,
                  fit: BoxFit.cover,
                ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  theme.colorScheme.surface.withValues(alpha: 0.7),
                  theme.colorScheme.surface,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.4, 0.85, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 24,
          left: 20,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFeatures: const [FontFeature.enable('smcp')],
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? theme.colorScheme.surfaceContainerHigh.withValues(
                        alpha: 0.95,
                      )
                    : theme.colorScheme.surface.withValues(alpha: 0.95),
                border: Border.all(
                  color: iconColor.withValues(alpha: isDark ? 0.5 : 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withValues(alpha: isDark ? 0.25 : 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: iconColor),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
