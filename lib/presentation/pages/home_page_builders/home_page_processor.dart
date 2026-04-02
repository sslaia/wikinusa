import 'package:html/parser.dart' as html_parser;

class HomePageProcessor {
  static String process(String html, String langCode) {
    final document = html_parser.parse(html);

    // Common removals for many Wikipedias
    document.querySelectorAll('script, style, link, .mw-empty-elt').forEach((e) => e.remove());

    if (langCode == 'nia') {
      // Specific removals for Nias Wikipedia
      document.querySelectorAll('#mp-header, #mp-wikimedia-projects, #mp-footer').forEach((e) => e.remove());
      
      // Also common IDs used in other languages/older templates
      document.querySelectorAll('.mp-header, .mp-wikimedia-projects, .mp-footer').forEach((e) => e.remove());
    }
    
    // You can add more language-specific rules here
    if (langCode == 'id') {
      // Specific removals for Nias Wikipedia
      document.querySelectorAll('#nomobile, #mp-footer').forEach((e) => e.remove());

      // Also common IDs used in other languages/older templates
      document.querySelectorAll('.nomobile, .mp-footer').forEach((e) => e.remove());
    }

    if (langCode == 'jv') {
      // Specific removals for Nias Wikipedia
      document.querySelectorAll('#nomobile, #container_welcome, #mp-footer').forEach((e) => e.remove());

      // Also common IDs used in other languages/older templates
      document.querySelectorAll('.nomobile, .container_welcome, .mp-footer').forEach((e) => e.remove());
    }


    // Target the main content div if available to reduce noise further
    final contentElement = document.querySelector('.mw-parser-output') ?? document.body!;
    
    return contentElement.innerHtml;
  }
}
