import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import '../models/project_type.dart';

class HtmlProcessor {
  static Future<Map<String, dynamic>> processArticleHtml(
    String rawHtml,
    String languageCode,
    ProjectType project,
  ) async {
    final projectStr = project.name.toLowerCase();
    final document = html_parser.parse(rawHtml);

    // 0. Resolve Wikipedia lazy loading by unwrapping <noscript> and removing placeholders
    document.querySelectorAll('noscript').forEach((ns) {
      final nsHtml = ns.innerHtml;
      if (nsHtml.contains('<img')) {
        final fragment = html_parser.parseFragment(nsHtml);
        ns.parentNode?.insertBefore(fragment, ns);
      }
      ns.remove();
    });
    document.querySelectorAll('.lazy-image-placeholder').forEach((el) => el.remove());

    // 0.1 Handle Tables: Wrap in scrollable div and clean up width constraints
    document.querySelectorAll('table').forEach((table) {
      // Remove explicit width attributes that force squishing
      table.attributes.remove('width');
      table.attributes.remove('style'); // Remove inline styles that often have width:100%
      
      final wrapper = dom.Element.tag('div');
      wrapper.attributes['style'] = 'overflow-x: auto; width: 100%; margin: 16px 0; border: 1px solid #ddd; border-radius: 8px;';
      wrapper.classes.add('table-scroll-wrapper');
      
      // Use replaceWith to wrap the table correctly
      table.replaceWith(wrapper);
      wrapper.append(table);
      
      // Basic styling for table inside the scrollable wrapper
      table.attributes['style'] = 'border-collapse: collapse; min-width: 100%;';
      table.querySelectorAll('th, td').forEach((cell) {
        cell.attributes['style'] = 'border: 1px solid #ddd; padding: 8px; text-align: left;';
      });
      table.querySelectorAll('th').forEach((th) {
        th.attributes['style'] = (th.attributes['style'] ?? '') + ' background-color: #f5f5f5; font-weight: bold;';
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
    
    // 1. Find first image that is not an icon for the Hero image
    final images = document.querySelectorAll('img');
    dom.Element? heroImageElement;
    for (var img in images) {
       final src = img.attributes['src'] ?? '';
       final isIcon = _isIcon(src);
       
       if (!isIcon) {
          imageUrl = src;
          if (!imageUrl.startsWith('http')) imageUrl = 'https:$imageUrl';
          if (imageUrl.contains('/thumb/')) {
            final regExp = RegExp(r'\/(\d+)px-');
            if (regExp.hasMatch(imageUrl)) imageUrl = imageUrl.replaceFirst(regExp, '/800px-');
          }
          heroImageElement = img;
          break;
       }
    }

    // Mark ONLY the first image (Hero image) in the body so ArticleScreen can hide it
    if (heroImageElement != null) {
       _markImageContainerForHiding(heroImageElement);
    }

    // 2. Process all other images: add high-res
    document.querySelectorAll('img').forEach((img) {
       var src = img.attributes['src'] ?? '';
       if (src.isNotEmpty) {
          if (!src.startsWith('http')) src = 'https:$src';
          if (src.contains('/thumb/')) {
             final regExp = RegExp(r'\/(\d+)px-');
             if (regExp.hasMatch(src)) src = src.replaceFirst(regExp, '/600px-');
          }
          img.attributes['src'] = src;
       }
    });

    // Apply removals
    for (var s in removeSelectors) {
      document.querySelectorAll(s).forEach((el) => el.remove());
    }
    // Apply hides
    for (var s in hideSelectors) {
      document.querySelectorAll(s).forEach((el) => el.attributes['style'] = 'display: none;');
    }

    // HIDE references sections instead of stripping them
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

  static bool _isIcon(String src) {
    return src.contains('/static/images/mobile/copyright/') || 
           src.contains('/static/images/footer/') ||
           src.contains('.svg') ||
           src.contains('px-Gnome-') || 
           src.contains('px-Icon-') ||
           src.contains('px-Symbol_') ||
           src.contains('px-Help-') ||
           src.contains('px-Information_') ||
           src.contains('px-Ambox_') ||
           src.contains('px-Question_mark') ||
           src.contains('px-Edit-clear') ||
           src.contains('px-Magnifying_glass');
  }

  static void _markImageContainerForHiding(dom.Element img) {
    dom.Element? containerToHide = img;
    var parent = img.parent;
    while (parent != null && parent.localName != 'body') {
      if (parent.localName == 'figure' || 
          parent.classes.contains('thumb') || 
          parent.classes.contains('infobox-image')) {
        containerToHide = parent;
        break;
      }
      parent = parent.parent;
    }
    containerToHide?.attributes['class'] = '${containerToHide.attributes['class'] ?? ''} hidden-hero-container';
  }
}
