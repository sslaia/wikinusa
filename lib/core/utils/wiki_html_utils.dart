import 'package:html/dom.dart' as dom;

class WikiHtmlUtils {
  /// Fixes wiki specific URL issues for images and links within a DOM element.
  static void fixUrls(dom.Element element, String langCode) {
    // Clean layout attributes
    void cleanLayout(dom.Element e) {
      e.attributes.removeWhere(
        (key, _) => [
          'style',
          'width',
          'height',
          'align',
          'valign',
          'border',
          'cellpadding',
          'cellspacing',
        ].contains(key),
      );
    }

    cleanLayout(element);
    element.querySelectorAll('*').forEach(cleanLayout);

    // Fix Image URLs and remove responsive attributes
    element.querySelectorAll('img').forEach((img) {
      String? src = img.attributes['data-src'] ?? img.attributes['src'];
      if (src != null) {
        if (src.startsWith('//')) {
          src = 'https:$src';
        } else if (src.startsWith('/')) {
          src = 'https://$langCode.wikipedia.org$src';
        }
        img.attributes['src'] = src;
      }
      img.attributes.remove('srcset');
      img.attributes.remove('data-srcset');
      img.attributes.remove('width');
      img.attributes.remove('height');
    });

    // Fix anchor link URLs
    element.querySelectorAll('a').forEach((a) {
      final href = a.attributes['href'];
      if (href != null && href.startsWith('/')) {
        a.attributes['href'] = 'https://$langCode.wikipedia.org$href';
      }
    });
  }
}
