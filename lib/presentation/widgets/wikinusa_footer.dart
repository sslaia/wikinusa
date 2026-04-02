import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class WikinusaFooter extends StatelessWidget {
  const WikinusaFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 24),
          Text(
            'WikiNusa',
            style: GoogleFonts.cinzelDecorative(
              textStyle: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 14,
                letterSpacing: 2.0,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'footer_license'.tr(),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'sans',
              fontSize: 10,
              height: 1.6,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'footer_disclaimer'.tr(),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'sans',
              fontSize: 10,
              height: 1.6,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _FooterLink(
                label: 'Disclaimer',
                url: 'https://wikinusa.blogspot.com/2026/04/disclaimer.html',
              ),
              const SizedBox(width: 16),
              _FooterLink(
                label: 'Privacy Policy',
                url: 'https://wikinusa.blogspot.com/2026/04/wikinusa-privacy-policy.html',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  final String url;

  const _FooterLink({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton(
      onPressed: () => launchUrl(
        Uri.parse(url),
        mode: LaunchMode.inAppBrowserView,
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}