import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wikinusa/presentation/widgets/search_field_widget.dart';

class HomeHeaderCard extends StatelessWidget {
  final String? imageUrl;
  final String? languageName;

  const HomeHeaderCard({
    super.key,
    required this.imageUrl,
    required this.languageName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Container(
          height: 300,
          width: double.infinity,
          decoration: BoxDecoration(color: theme.colorScheme.surface),
          child: Image.network(
            imageUrl ??
                'https://upload.wikimedia.org/wikipedia/commons/thumb/3/39/Reading_-_Hugues_Merle.jpg/960px-Reading_-_Hugues_Merle.jpg',
            fit: BoxFit.cover,
            headers: const {
              'User-Agent': 'WikinusaApp/1.0 (slaia@yahoo.com) FlutterApp',
            },
            errorBuilder: (context, error, stackTrace) => Image.network(
              'https://upload.wikimedia.org/wikipedia/commons/thumb/3/39/Reading_-_Hugues_Merle.jpg/960px-Reading_-_Hugues_Merle.jpg',
              fit: BoxFit.cover,
              headers: const {
                'User-Agent': 'WikinusaApp/1.0 (slaia@yahoo.com) FlutterApp',
              },
            ),
          ),
        ),

        // Gradient Overlay for Text Readability
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
                  style: GoogleFonts.offside(
                    textStyle: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      shadows: [
                        const Shadow(blurRadius: 10, color: Colors.black),
                      ],
                    ),
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
                if (languageName != null)
                  Text(
                    languageName!,
                    style: GoogleFonts.cinzelDecorative(
                      textStyle: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 18,
                        // fontWeight: FontWeight.bold,
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
                  style: GoogleFonts.offside(
                    textStyle: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      shadows: [
                        const Shadow(blurRadius: 10, color: Colors.black),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // searchField,
                SearchFieldWidget(context: context, theme: theme),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
