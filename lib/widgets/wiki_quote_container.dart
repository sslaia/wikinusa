import 'package:flutter/material.dart';

/// A presentation container for blockquotes in articles that displays
/// an elegant decorative quotation mark alongside the italicized serif quote text,
/// reproducing the aesthetic of MediaWiki web quotes.
class WikiQuoteContainer extends StatelessWidget {
  final Widget child;

  const WikiQuoteContainer({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Distinct olive-green quote mark from MediaWiki web stylesheet (#889C0B),
    // lightened in dark theme to ensure sufficient contrast.
    final quoteColor = isDark
        ? const Color(0xFFA8BE20)
        : const Color(0xFF889C0B);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0, top: 0.0),
            child: Text(
              '“',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 44,
                height: 0.75,
                fontWeight: FontWeight.bold,
                color: quoteColor,
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}
