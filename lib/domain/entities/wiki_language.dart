import 'package:flutter/material.dart';
import 'wiki_project.dart';

enum WikiLanguage {
  bew('Betawi', 'bew', Color(0xFFE65100)),
  bjn('Banjar', 'bjn', Color(0xFF00695C)),
  btm('Batak Mandailing', 'btm', Color(0xFF3E2723)),
  en('English', 'en', Color(0xFF24389C)),
  gor('Gorontalo', 'gor', Color(0xFFC62828)),
  id('Indonesia', 'id', Color(0xFF24389C)),
  jv('Jawa', 'jv', Color(0xFF8D6E63)),
  mad('Madura', 'mad', Color(0xFFD32F2F)),
  min('Minangkabau', 'min', Color(0xFFB71C1C)),
  ms('Melayu', 'ms', Color(0xFF1565C0)),
  nia('Nias', 'nia', Color(0xFFF9A825)),
  su('Sunda', 'su', Color(0xFF2E7D32));

  final String displayName;
  final String code;
  final Color seedColor;

  const WikiLanguage(this.displayName, this.code, this.seedColor);

  /// Returns whether a specific project is supported for this language.
  bool isProjectSupported(WikiProject project) {
    switch (this) {
      case WikiLanguage.bjn:
        // Banjar doesn't have Wikibooks
        return project != WikiProject.wikibooks;
      case WikiLanguage.btm:
      // Batak Mandailing doesn't have Wikibooks
        return project != WikiProject.wikibooks;
      case WikiLanguage.gor:
      // Gorontalo doesn't have Wikibooks
        return project != WikiProject.wikibooks;
      case WikiLanguage.mad:
      // Madurese doesn't have Wikibooks
        return project != WikiProject.wikibooks;
      case WikiLanguage.su:
      // Sundanese doesn't have Wikibooks
        return project != WikiProject.wikibooks;
      default:
        return true;
    }
  }

  /// Returns the custom domain/path logic for specific projects and languages.
  String getFullDomain(WikiProject project) {
    if (this == WikiLanguage.bew && project == WikiProject.wikibooks) {
      return 'incubator.wikimedia.org';
    } else if (this == WikiLanguage.jv && project == WikiProject.wikibooks) {
      return 'incubator.wikimedia.org';
    } else if (this == WikiLanguage.nia && project == WikiProject.wikibooks) {
      return 'incubator.wikimedia.org';
    }
    
    return '$code.${project.domain}';
  }

  /// Returns the API path prefix for specific projects (like Incubator)
  String getPagePrefix(WikiProject project) {
     if (this == WikiLanguage.bew && project == WikiProject.wikibooks) {
      return 'Wb/bew/';
    } else if (this == WikiLanguage.jv && project == WikiProject.wikibooks) {
       return 'Wb/jv/';
     } else if (this == WikiLanguage.nia && project == WikiProject.wikibooks) {
       return 'Wb/nia/';
     }
    return '';
  }

  static WikiLanguage fromCode(String code) {
    return WikiLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => WikiLanguage.en,
    );
  }
}
