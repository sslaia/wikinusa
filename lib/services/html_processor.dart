import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import '../models/project_type.dart';
import '../utils/wiki_utils.dart';

class HtmlProcessor {
  static Future<Map<String, dynamic>> processArticleHtml(
    String rawHtml,
    String languageCode,
    ProjectType project,
  ) async {
    final projectStr = project.name.toLowerCase();
    final document = html_parser.parse(rawHtml);

    // 0. Resolve Wikipedia lazy loading
    document.querySelectorAll('noscript').forEach((ns) {
      final nsHtml = ns.innerHtml;
      if (nsHtml.contains('<img')) {
        final fragment = html_parser.parseFragment(nsHtml);
        ns.parentNode?.insertBefore(fragment, ns);
      }
      ns.remove();
    });
    document.querySelectorAll('.lazy-image-placeholder').forEach((el) => el.remove());

    // 0.1 Handle Tables: Wrap in scrollable div
    document.querySelectorAll('table').forEach((table) {
      table.attributes.remove('width');
      table.attributes.remove('style');
      
      final wrapper = dom.Element.tag('div');
      wrapper.attributes['style'] = 'overflow-x: auto; width: 100%; margin: 16px 0; border: 1px solid #ddd; border-radius: 8px;';
      wrapper.classes.add('table-scroll-wrapper');
      
      table.replaceWith(wrapper);
      wrapper.append(table);
      
      table.attributes['style'] = 'border-collapse: collapse; min-width: 100%;';
      table.querySelectorAll('th, td').forEach((cell) {
        cell.attributes['style'] = 'border: 1px solid #ddd; padding: 8px; text-align: left;';
      });
    });

    // Load rules
    final jsonString = await rootBundle.loadString('assets/data/html_rules.json');
    final htmlRules = jsonDecode(jsonString);
    final projectRules = htmlRules[languageCode]?[projectStr] as Map<String, dynamic>?;
    final globalRules = htmlRules['global']?[projectStr] as Map<String, dynamic>?;

    final removeSelectors = _getRulesList(globalRules, projectRules, 'remove');
    final hideSelectors = _getRulesList(globalRules, projectRules, 'hide');
    final refKeywords = _getRulesList(globalRules, projectRules, 'referenceKeywords');

    String? imageUrl;
    
    // 1. Find Hero image using centralized WikiUtils logic
    final images = document.querySelectorAll('img');
    dom.Element? heroImageElement;
    for (var img in images) {
       final src = img.attributes['src'] ?? '';
       if (!WikiUtils.isIcon(src)) {
          imageUrl = WikiUtils.optimizeImageUrl(src, langCode: languageCode, projectStr: projectStr, width: 800);
          heroImageElement = img;
          break;
       }
    }

    if (heroImageElement != null) {
       _markImageContainerForHiding(heroImageElement);
    }

    // 2. Process all other images using centralized WikiUtils logic
    document.querySelectorAll('img').forEach((img) {
       var src = img.attributes['src'] ?? '';
       if (src.isNotEmpty) {
          // Detect if it's an inline icon by size
          final widthAttr = int.tryParse(img.attributes['width'] ?? '');
          final heightAttr = int.tryParse(img.attributes['height'] ?? '');
          
          if ((widthAttr != null && widthAttr <= 48) || (heightAttr != null && heightAttr <= 48)) {
             img.classes.add('wiki-inline-icon');
             // For inline icons, we don't scale up to 600px
             img.attributes['src'] = WikiUtils.optimizeImageUrl(src, langCode: languageCode, projectStr: projectStr, width: 100);
          } else {
             img.attributes['src'] = WikiUtils.optimizeImageUrl(src, langCode: languageCode, projectStr: projectStr, width: 600);
          }
       }
    });

    // Apply removals/hides
    for (var s in removeSelectors) {
      document.querySelectorAll(s).forEach((el) => el.remove());
    }
    for (var s in hideSelectors) {
      document.querySelectorAll(s).forEach((el) => el.attributes['style'] = 'display: none;');
    }

    // Process reference sections
    if (refKeywords.isNotEmpty) {
      final headings = document.querySelectorAll('h2, h3, h4');
      for (var h in headings) {
        final text = h.text.toLowerCase();
        if (refKeywords.any((kw) => text.contains(kw.toLowerCase()))) {
          h.attributes['style'] = 'display: none;';
          var next = h.nextElementSibling;
          while (next != null && !['h2', 'h3', 'h4'].contains(next.localName)) {
             next.attributes['style'] = 'display: none;';
             next = next.nextElementSibling;
          }
        }
      }
    }
    
    return {
      'html': document.body?.innerHtml ?? '',
      'imageUrl': imageUrl,
    };
  }

  static List<String> _getRulesList(Map<String, dynamic>? global, Map<String, dynamic>? project, String key) {
    final list = <String>[];
    if (global != null && global[key] != null) {
      list.addAll((global[key] as List).map((e) => e.toString()));
    }
    if (project != null && project[key] != null) {
      list.addAll((project[key] as List).map((e) => e.toString()));
    }
    return list;
  }

  static void _markImageContainerForHiding(dom.Element img) {
    dom.Element? containerToHide = img;
    var parent = img.parent;
    while (parent != null && parent.localName != 'body') {
      if (parent.localName == 'figure' || parent.classes.contains('thumb') || parent.classes.contains('infobox-image')) {
        containerToHide = parent;
        break;
      }
      parent = parent.parent;
    }
    containerToHide?.attributes['class'] = '${containerToHide.attributes['class'] ?? ''} hidden-hero-container';
  }
}
