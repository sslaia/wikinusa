import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import '../models/project_type.dart';
import '../core/wiki_config.dart';
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
    document
        .querySelectorAll('.lazy-image-placeholder')
        .forEach((el) => el.remove());

    /// Handle tables
    document.querySelectorAll('table').forEach((table) {
      final isInfobox = table.classes.any((c) => c.contains('infobox'));
      final isNavbox = table.classes.any((c) =>
          c.contains('navbox') ||
          c.contains('navbox-inner') ||
          c.contains('mw-collapsible'));
      final isAmbox = table.classes.any((c) =>
          c.contains('ambox') ||
          c.contains('tmbox') ||
          c.contains('cmbox') ||
          c.contains('imbox') ||
          c.contains('metadata'));

      table.attributes.remove('width');
      table.attributes.remove('style');
      table.classes.add('wikinusa-table');

      if (isInfobox || isNavbox || isAmbox) {
        table.attributes['style'] =
            'width: 100%; border-collapse: collapse; margin: 0;';
      } else {
        // Data table: do NOT force width: 100% so columns can size and scroll comfortably
        table.attributes['style'] = 'border-collapse: collapse; margin: 0;';

        // Style headers with subtle background, bold text, and balanced min/max width
        table.querySelectorAll('th').forEach((th) {
          th.attributes['style'] =
              'padding: 10px 14px; font-weight: 700; text-align: left; vertical-align: middle; min-width: 90px; max-width: 260px; border: 1px solid rgba(128, 128, 128, 0.25); background-color: rgba(128, 128, 128, 0.08);';
        });
        // Style data cells with clean padding, balanced min/max width, and soft divider borders
        table.querySelectorAll('td').forEach((td) {
          td.attributes['style'] =
              'padding: 8px 12px; text-align: left; vertical-align: top; min-width: 70px; max-width: 320px; border: 1px solid rgba(128, 128, 128, 0.18);';
        });
      }
    });

    final removeSelectors = WikiConfig.getCombinedRulesList(
      languageCode,
      projectStr,
      'remove',
    );
    final hideSelectors = WikiConfig.getCombinedRulesList(
      languageCode,
      projectStr,
      'hide',
    );
    final refKeywords = WikiConfig.getCombinedRulesList(
      languageCode,
      projectStr,
      'referenceKeywords',
    );

    /// Extract Hero Image Candidate
    String? heroImageUrl;
    final allImages = document.querySelectorAll('img');
    dom.Element? heroElement;

    for (var img in allImages) {
      final src = img.attributes['src'] ?? '';
      if (!CoreWikiUtils.isIcon(src, img)) {
        heroElement = img;
        break;
      }
    }

    /// Parallel Image Optimization
    final List<Future<void>> imageTasks = [];
    for (var img in allImages) {
      final src = img.attributes['src'] ?? '';
      if (src.isNotEmpty) {
        final isIcon = CoreWikiUtils.isIcon(src, img);

        imageTasks.add(
          CoreWikiUtils.optimizeImageUrl(
            src,
            htmlString: img.outerHtml,
            width: isIcon ? 100 : 500,
          ).then((optimizedUrl) {
            img.attributes['src'] = optimizedUrl;
            if (isIcon) img.classes.add('wiki-inline-icon');
            if (img == heroElement) heroImageUrl = optimizedUrl;
          }),
        );
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
      document
          .querySelectorAll(s)
          .forEach((el) => el.classes.add('wikinusa-hidden'));
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
            if (['h2', 'h3', 'h4'].contains(next.localName) ||
                next.classes.contains('mw-heading')) {
              break;
            }
            next.classes.add('wikinusa-hidden');
            next = next.nextElementSibling;
          }
        }
      }
    }

    String processedHtml = document.body?.innerHtml ?? '';
    final soup = BeautifulSoup(processedHtml);
    bool soupChanged = false;

    if (WikiConfig.hasProcessingFlag(
      languageCode,
      projectStr,
      'removeEmptySections',
    )) {
      _removeEmptySections(soup);
      soupChanged = true;
    }

    if (WikiConfig.hasProcessingFlag(
      languageCode,
      projectStr,
      'removeEmptyImageSections',
    )) {
      _removeEmptyImageSections(soup);
      soupChanged = true;
    }

    if (soupChanged) {
      processedHtml = soup.toString();
    }

    return {'html': processedHtml, 'imageUrl': heroImageUrl};
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
    containerToHide?.attributes['class'] =
        '${containerToHide.attributes['class'] ?? ''} hidden-hero-container';
  }

  static void _removeEmptySections(BeautifulSoup root) {
    final potentialMarkers = root.findAll('dd') + root.findAll('li');
    final emptyMarkers = potentialMarkers.where(
      (element) => element.string.trim() == 'Lö hadöi',
    );
    for (final marker in emptyMarkers) {
      Bs4Element? listContainer = marker.name == 'dd'
          ? marker.findParent('dl')
          : (marker.findParent('ul') ?? marker.findParent('ol'));
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
      if (nextElement == null || nextElement.name != 'figure') {
        headingContainer.extract();
      }
    }
  }
}
