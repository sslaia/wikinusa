import 'dart:convert';
import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:easy_localization/easy_localization.dart';
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

    /// Resolve Wikipedia lazy loading
    document.querySelectorAll('noscript').forEach((ns) {
      final nsHtml = ns.innerHtml;
      if (nsHtml.contains('<img')) {
        final fragment = html_parser.parseFragment(nsHtml);
        ns.parentNode?.insertBefore(fragment, ns);
      }
      ns.remove();
    });
    document.querySelectorAll('.lazy-image-placeholder').forEach((el) => el.remove());

    /// Handle tables
    document.querySelectorAll('table').forEach((table) {
      // 1. Remove inline width and set to 100%
      table.attributes.remove('width');
      table.attributes.remove('style');
      table.attributes['style'] = 'width: 100%; border-collapse: collapse; margin: 16px 0;';

      // 2. Create a wrapper div for horizontal scrolling
      final wrapper = dom.Element.tag('div');
      wrapper.attributes['style'] = 'overflow-x: auto; width: 100%; -webkit-overflow-scrolling: touch;';

      // 3. Insert wrapper into the DOM and move the table inside it
      table.parentNode?.insertBefore(wrapper, table);
      wrapper.append(table);

      // 4. Basic cell styling for readability
      table.querySelectorAll('th, td').forEach((cell) {
        cell.attributes['style'] = 'border: 1px solid #ddd; padding: 8px; text-align: left;';
      });
    });

    final jsonString = await rootBundle.loadString('assets/data/html_rules.json');
    final htmlRules = jsonDecode(jsonString);
    final projectRules = htmlRules[languageCode]?[projectStr] as Map<String, dynamic>?;
    final globalRules = htmlRules['global']?[projectStr] as Map<String, dynamic>?;

    final removeSelectors = _getRulesList(globalRules, projectRules, 'remove');
    final hideSelectors = _getRulesList(globalRules, projectRules, 'hide');
    final refKeywords = _getRulesList(globalRules, projectRules, 'referenceKeywords');

    /// Extract Hero Image Candidate
    String? heroImageUrl;
    final allImages = document.querySelectorAll('img');
    dom.Element? heroElement;

    for (var img in allImages) {
      final src = img.attributes['src'] ?? '';
      if (!WikiUtils.isIcon(src)) {
        heroElement = img;
        break;
      }
    }

    /// Parallel Image Optimization
    final List<Future<void>> imageTasks = [];
    for (var img in allImages) {
      final src = img.attributes['src'] ?? '';
      if (src.isNotEmpty) {
        final widthAttr = int.tryParse(img.attributes['width'] ?? '');
        final heightAttr = int.tryParse(img.attributes['height'] ?? '');
        final isIcon = (widthAttr != null && widthAttr <= 48) || (heightAttr != null && heightAttr <= 48) || WikiUtils.isIcon(src);

        imageTasks.add(WikiUtils.optimizeImageUrl(
          src,
          htmlString: img.outerHtml,
          width: isIcon ? 100 : 500,
        ).then((optimizedUrl) {
          img.attributes['src'] = optimizedUrl;
          if (isIcon) img.classes.add('wiki-inline-icon');
          if (img == heroElement) heroImageUrl = optimizedUrl;
        }));
      }
    }

    await Future.wait(imageTasks);

    if (heroElement != null) {
      _markImageContainerForHiding(heroElement);
    }

    /// Apply removals
    for (var s in removeSelectors) {
      document.querySelectorAll(s).forEach((el) => el.remove());
    }
    
    /// Apply hides
    for (var s in hideSelectors) {
      document.querySelectorAll(s).forEach((el) => el.classes.add('wikinusa-hidden'));
    }

    /// Process reference sections (Headings like Umbu, Rujukan, etc.)
    /// Note: We HIDE these instead of removing them so the reference popup can still find the content.
    if (refKeywords.isNotEmpty) {
      final headings = document.querySelectorAll('h2, h3, h4');
      for (var h in headings) {
        final text = h.text.toLowerCase().trim();
        if (refKeywords.any((kw) => text.contains(kw.toLowerCase()))) {
          // Hide the heading itself or its parent container (mw-heading)
          var targetToHide = h;
          if (h.parent?.classes.contains('mw-heading') == true) {
            targetToHide = h.parent!;
          }
          targetToHide.classes.add('wikinusa-hidden');

          // Hide everything until the next heading
          var next = targetToHide.nextElementSibling;
          while (next != null) {
            if (['h2', 'h3', 'h4'].contains(next.localName) || next.classes.contains('mw-heading')) {
              break;
            }
            next.classes.add('wikinusa-hidden');
            next = next.nextElementSibling;
          }
        }
      }
    }

    String processedHtml = document.body?.innerHtml ?? '';
    if (languageCode == 'nia' && project == ProjectType.wiktionary) {
      final soup = BeautifulSoup(processedHtml);
      _removeEmptySections(soup);
      _removeEmptyImageSections(soup);
      processedHtml = soup.toString();
    }

    return {'html': processedHtml, 'imageUrl': heroImageUrl};
  }

  static List<String> _getRulesList(Map<String, dynamic>? global, Map<String, dynamic>? project, String key) {
    final list = <String>[];
    if (global != null && global[key] != null && global[key] is List) {
      list.addAll((global[key] as List).map((e) => e.toString()));
    }
    if (project != null && project[key] != null && project[key] is List) {
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

  static void _removeEmptySections(BeautifulSoup root) {
    final potentialMarkers = root.findAll('dd') + root.findAll('li');
    final emptyMarkers = potentialMarkers.where((element) => element.string.trim() == 'Lö hadöi');
    for (final marker in emptyMarkers) {
      Bs4Element? listContainer = marker.name == 'dd' ? marker.findParent('dl') : (marker.findParent('ul') ?? marker.findParent('ol'));
      if (listContainer == null) continue;
      final headingDiv = listContainer.findPreviousSibling('div');
      if (headingDiv != null && headingDiv.className.contains('mw-heading')) {
        headingDiv.extract();
        listContainer.extract();
      }
    }
  }

  static void _removeEmptyImageSections(BeautifulSoup root) {
    final imageHeadings = root.findAll('h3', id: 'Gambara');
    for (final h3 in imageHeadings) {
      final headingContainer = h3.findParent('div');
      if (headingContainer == null) continue;
      final Bs4Element? nextElement = headingContainer.nextSibling;
      if (nextElement == null || nextElement.name != 'figure') headingContainer.extract();
    }
  }
}
