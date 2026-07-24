import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:wikimedia_core/wikimedia_core.dart';
import 'package:html/parser.dart' as html_parser;
import '../modules/crosswords/models/crossword_model.dart';

class WidgetDataService {
  /// Save home page sections (Featured Article/Word/Story) data to HomeWidget
  static Future<void> updateHomeSectionsWidgets(
    List<HomePageSection> sections,
    String project,
    String languageCode,
  ) async {
    try {
      final projLower = project.toLowerCase();

      for (final section in sections) {
        final titleKey = section.titleKey;

        if (titleKey == 'featuredArticle' ||
            titleKey == 'featuredWord' ||
            titleKey == 'featuredStory') {
          final plainText = _stripHtml(section.textHtml);
          final extractedTitle = _extractTitle(section.textHtml);

          String labelTitle = 'FEATURED ARTICLE';
          if (projLower == 'wiktionary' || titleKey == 'featuredWord') {
            labelTitle = 'WORD OF THE DAY';
          } else if (projLower == 'wikibooks' || titleKey == 'featuredStory') {
            labelTitle = 'FEATURED STORY';
          }

          final displayTitle = extractedTitle.isNotEmpty ? extractedTitle : labelTitle;

          await HomeWidget.saveWidgetData<String>(
            'featured_article_label',
            labelTitle,
          );
          await HomeWidget.saveWidgetData<String>(
            'featured_article_title',
            displayTitle,
          );
          await HomeWidget.saveWidgetData<String>(
            'featured_article_snippet',
            plainText,
          );
          await HomeWidget.saveWidgetData<String>(
            'featured_article_project',
            project.toUpperCase(),
          );

          // Save project specific slot for alternating
          await HomeWidget.saveWidgetData<String>(
            'featured_article_label_$projLower',
            labelTitle,
          );
          await HomeWidget.saveWidgetData<String>(
            'featured_article_title_$projLower',
            displayTitle,
          );
          await HomeWidget.saveWidgetData<String>(
            'featured_article_snippet_$projLower',
            plainText,
          );

          await HomeWidget.updateWidget(
            name: 'FeaturedArticleWidgetProvider',
            androidName: 'FeaturedArticleWidgetProvider',
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating home sections widgets: $e');
    }
  }

  /// Save daily crossword puzzle data to HomeWidget
  static Future<void> updateCrosswordWidget(
    CrosswordPuzzle puzzle,
    String project,
  ) async {
    try {
      final clueCount = puzzle.words.length;
      final sampleClue = puzzle.words.isNotEmpty ? puzzle.words.first.clue : '';

      await HomeWidget.saveWidgetData<String>(
        'crossword_title',
        'DAILY CROSSWORD',
      );
      await HomeWidget.saveWidgetData<String>(
        'crossword_puzzle_id',
        '#${puzzle.puzzleId}',
      );
      await HomeWidget.saveWidgetData<String>(
        'crossword_clue_count',
        '$clueCount clues',
      );
      await HomeWidget.saveWidgetData<String>(
        'crossword_sample_clue',
        sampleClue.isNotEmpty ? sampleClue : 'Tap to solve today\'s crossword puzzle!',
      );
      await HomeWidget.saveWidgetData<String>(
        'crossword_project',
        project.toUpperCase(),
      );

      await HomeWidget.updateWidget(
        name: 'CrosswordWidgetProvider',
        androidName: 'CrosswordWidgetProvider',
      );
    } catch (e) {
      debugPrint('Error updating crossword widget: $e');
    }
  }

  static String _extractTitle(String htmlString) {
    if (htmlString.isEmpty) return '';
    try {
      final document = html_parser.parse(htmlString);
      final heading = document.querySelector('h1, h2, h3, h4, b, strong, a');
      if (heading != null && heading.text.trim().isNotEmpty) {
        return heading.text.trim();
      }
      final text = document.body?.text.trim() ?? '';
      if (text.isNotEmpty) {
        final lines = text.split('\n');
        return lines.first.trim();
      }
    } catch (_) {}
    return '';
  }

  static String _stripHtml(String htmlString) {
    if (htmlString.isEmpty) return '';
    try {
      final document = html_parser.parse(htmlString);
      return document.body?.text.trim() ?? htmlString;
    } catch (_) {
      return htmlString;
    }
  }
}
