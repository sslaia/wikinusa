import 'package:flutter/material.dart';

enum WikiProject {
  wikipedia(
    'Wikipedia',
    'wikipedia.org',
    Icons.article_outlined,
    Color(0xFF121298),
  ),
  wiktionary(
    'Wiktionary',
    'wiktionary.org',
    Icons.translate_outlined,
    Color(0xFFFF5722),
  ),
  wikibooks(
    'Wikibooks',
    'wikibooks.org',
    Icons.menu_book_outlined,
    Color(0xFF9B00A1),
  );

  final String displayName;
  final String domain;
  final IconData icon;
  final Color seedColor;

  const WikiProject(this.displayName, this.domain, this.icon, this.seedColor);

  static WikiProject fromDomain(String domain) {
    return WikiProject.values.firstWhere(
      (project) => project.domain == domain,
      orElse: () => WikiProject.wikipedia,
    );
  }
}
