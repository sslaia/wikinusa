import 'package:html/parser.dart' as html_parser;
import '../../../domain/entities/wiki_project.dart';

class HomePageProcessor {
  static String process(String html, String langCode, WikiProject project) {
    final document = html_parser.parse(html);

    // Common removals for all Wikimedia projects
    document
        .querySelectorAll('script, style, link, .mw-empty-elt')
        .forEach((e) => e.remove());

    // Project-specific cleaning
    switch (project) {
      case WikiProject.wikipedia:
        _processWikipedia(document, langCode);
        break;
      case WikiProject.wiktionary:
        _processWiktionary(document, langCode);
        break;
      case WikiProject.wikibooks:
        _processWikibooks(document, langCode);
        break;
    }

    // Target the main content div if available to reduce noise further
    final contentElement =
        document.querySelector('.mw-parser-output') ?? document.body!;

    return contentElement.innerHtml;
  }

  static void _processWikipedia(var document, String langCode) {
    if (langCode == 'nia') {
      document
          .querySelectorAll('#mp-header, #mp-wikimedia-projects, #mp-footer')
          .forEach((e) => e.remove());
      document
          .querySelectorAll('.mp-header, .mp-wikimedia-projects, .mp-footer')
          .forEach((e) => e.remove());
    }

    if (langCode == 'id') {
      document.querySelectorAll('#nomobile, #mp-footer').forEach((e) => e.remove());
      document.querySelectorAll('.nomobile, .mp-footer').forEach((e) => e.remove());
    }

    if (langCode == 'jv') {
      document
          .querySelectorAll('#nomobile, #container_welcome, #mp-footer')
          .forEach((e) => e.remove());
      document
          .querySelectorAll('.nomobile, .container_welcome, .mp-footer')
          .forEach((e) => e.remove());
    }
  }

  static void _processWiktionary(var document, String langCode) {
    // Placeholder for Wiktionary specific cleaning
    // Often Wiktionary homepages use different IDs for their word of the day containers
    document
        .querySelectorAll('#mf-header, .mf-header, #mf-footer, .mf-footer')
        .forEach((e) => e.remove());
    
    // Add more selectors here as you discover them
  }

  static void _processWikibooks(var document, String langCode) {
    // Placeholder for Wikibooks specific cleaning
    document
        .querySelectorAll('.sisterproject, #sisterproject, .mp-bottom')
        .forEach((e) => e.remove());
        
    // Add more selectors here as you discover them
  }
}
