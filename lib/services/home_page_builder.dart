import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import '../models/home_page_section.dart';
import '../models/project_type.dart';

class HomePageBuilder {
  static Future<List<HomePageSection>> build(
    List<int> responseBodyBytes,
    String languageCode,
    ProjectType project,
  ) async {
    final projectStr = project.name.toLowerCase();

    // Decode with UTF-8 to handle foreign characters properly
    final bodyStr = utf8.decode(responseBodyBytes);
    final document = html_parser.parse(bodyStr);

    final jsonString =
        await rootBundle.loadString('assets/data/html_rules.json');
    final htmlRules = jsonDecode(jsonString);

    final projectRules = htmlRules[languageCode]?[projectStr] as Map<String, dynamic>?;
    final globalRules = htmlRules['global']?[projectStr] as Map<String, dynamic>?;

    final removeSelectors = _getRulesList(globalRules, projectRules, 'remove');
    final hideSelectors = _getRulesList(globalRules, projectRules, 'hide');

    final sectionsConfig =
        projectRules?['homePageSections'] as Map<String, dynamic>?;

    List<HomePageSection> sections = [];

    if (sectionsConfig != null) {
      for (final entry in sectionsConfig.entries) {
        final titleKey = entry.key;
        final dynamic config = entry.value;

        String selector;
        dynamic keepSelector;
        bool firstOnly = false;
        bool stripStyle = false;

        if (config is Map) {
          selector = config['selector'] ?? '';
          keepSelector = config['keep'];
          firstOnly = config['firstOnly'] ?? false;
          stripStyle = config['stripStyle'] ?? false;
        } else {
          selector = config.toString();
        }

        if (selector.isEmpty) continue;

        final finalSelector = selector.startsWith('.') || selector.startsWith('#')
            ? selector
            : '#$selector';

        final element = document.querySelector(finalSelector);

        if (element != null) {
          sections.add(_extractSection(
            element,
            titleKey,
            languageCode: languageCode,
            projectStr: projectStr,
            removeSelectors: removeSelectors,
            hideSelectors: hideSelectors,
            keepSelector: keepSelector,
            firstOnly: firstOnly,
            stripStyle: stripStyle,
          ));
        }
      }
    } else {
      // Fallback logic
      final mwContentText = document.querySelector('#mw-content-text');
      if (mwContentText != null) {
        final fallbackSections = mwContentText.querySelectorAll('section');
        for (var section in fallbackSections) {
          if (section.querySelector('#mwAQ') != null) {
            sections.add(_extractSection(
              section, 
              'mainContent',
              languageCode: languageCode,
              projectStr: projectStr,
            ));
            break;
          }
        }
      }
    }

    if (sections.isEmpty) {
      sections.add(HomePageSection(
        titleKey: 'no_content',
        textHtml: '<i>No specific content found for this language and project.</i>',
        data: {},
      ));
    }

    return sections;
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

  static String _optimizeImageUrl(String url, String languageCode, String projectStr) {
    String normalized = url;
    if (url.startsWith('//')) {
      normalized = 'https:$url';
    } else if (url.startsWith('/')) {
      normalized = 'https://$languageCode.$projectStr.org$url';
    }

    // Optimize Wikipedia thumbnails for mobile by construction a 500px version.
    // This ensures we download a resolution appropriate for mobile and reuse it across widgets (cache).
    if (normalized.contains('/thumb/')) {
      final regExp = RegExp(r'\/(\d+)px-');
      if (regExp.hasMatch(normalized)) {
        return normalized.replaceFirst(regExp, '/500px-');
      }
    }
    return normalized;
  }

  static HomePageSection _extractSection(
    dom.Element element,
    String titleKey, {
    required String languageCode,
    required String projectStr,
    List<String> removeSelectors = const [],
    List<String> hideSelectors = const [],
    dynamic keepSelector,
    bool firstOnly = false,
    bool stripStyle = false,
  }) {
    // 1. Extract image first (before removals)
    final imgElement = element.querySelector('img');
    String? imageHtml;
    String? imageUrl;

    if (imgElement != null) {
      final imgClone = imgElement.clone(true);
      
      // We force a 500px version for both hero and section display to optimize loading and memory.
      // We take the original 'src' as the base and transform it into a 500px thumbnail.
      String? src = imgClone.attributes['src'];
      if (src != null) {
        imageUrl = _optimizeImageUrl(src, languageCode, projectStr);
        imgClone.attributes['src'] = imageUrl;
      }
      
      // Remove srcset to ensure consistent behavior across widgets and avoid downloading extra resolutions.
      imgClone.attributes.remove('srcset');

      imgClone.attributes.remove('width');
      imgClone.attributes.remove('height');
      imgClone.attributes['style'] = 'width: 100%; height: auto; display: block;';
      
      imageHtml = imgClone.outerHtml;
      imgElement.remove();
    }

    // 2. Apply removals to remaining content
    for (var s in removeSelectors) {
      if (s == 'img' || s == 'figure') continue;
      element.querySelectorAll(s).forEach((el) => el.remove());
    }
    for (var s in hideSelectors) {
      if (s == 'img' || s == 'figure') continue;
      element.querySelectorAll(s).forEach((el) => el.remove());
    }

    // 3. Filter content if keepSelector is provided
    String textHtml;
    if (keepSelector != null) {
      final List<String> selectors = keepSelector is List
          ? List<String>.from(keepSelector)
          : [keepSelector.toString()];

      List<String> htmlParts = [];
      for (var s in selectors) {
        if (firstOnly) {
          final allKept = element.querySelectorAll(s);
          dom.Element? kept;
          for (var el in allKept) {
            if (el.text.trim().isNotEmpty) {
              kept = el;
              break;
            }
          }
          if (kept != null) {
            if (stripStyle) {
              kept.attributes.remove('style');
              kept.querySelectorAll('*').forEach((child) => child.attributes.remove('style'));
            }
            htmlParts.add(kept.outerHtml);
          }
        } else {
          final kept = element.querySelectorAll(s);
          if (stripStyle) {
            for (var el in kept) {
              el.attributes.remove('style');
              el.querySelectorAll('*').forEach((child) => child.attributes.remove('style'));
            }
          }
          htmlParts.addAll(kept.map((e) => e.outerHtml));
        }
      }
      textHtml = htmlParts.join();
    } else {
      if (stripStyle) {
        element.attributes.remove('style');
        element.querySelectorAll('*').forEach((child) => child.attributes.remove('style'));
      }
      textHtml = element.innerHtml;
    }

    final Map<String, String?> sectionData = {
      if (imageHtml != null) '${titleKey}ImageHtml': imageHtml,
      if (imageUrl != null) '${titleKey}ImageUrl': imageUrl,
    };

    return HomePageSection(
      titleKey: titleKey,
      textHtml: textHtml,
      data: sectionData,
    );
  }
}
