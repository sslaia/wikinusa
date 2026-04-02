import 'package:flutter/material.dart';

enum WikiLanguage {
  bew('Betawi', 'bew', Color(0xFFE65100)),      // Orange
  bjn('Banjar', 'bjn', Color(0xFF00695C)),      // Teal
  btm('Batak Mandailing', 'btm', Color(0xFF3E2723)), // Brown
  en('English', 'en', Color(0xFF24389C)),       // Standard Blue
  gor('Gorontalo', 'gor', Color(0xFFC62828)),   // Red
  id('Indonesian', 'id', Color(0xFF24389C)),    // Standard Blue
  jv('Javanese', 'jv', Color(0xFF8D6E63)),      // Light Brown/Batik
  mad('Madurese', 'mad', Color(0xFFD32F2F)),    // Bold Red
  min('Minangkabau', 'min', Color(0xFFB71C1C)),  // Dark Red/Maroon
  ms('Malay', 'ms', Color(0xFF1565C0)),         // Blue
  nia('Nias', 'nia', Color(0xFFF9A825)),        // Gold/Yellow
  su('Sundanese', 'su', Color(0xFF2E7D32));     // Green

  final String displayName;
  final String code;
  final Color seedColor;

  const WikiLanguage(this.displayName, this.code, this.seedColor);

  String get domain => '$code.wikipedia.org';

  static WikiLanguage fromCode(String code) {
    return WikiLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => WikiLanguage.en,
    );
  }
}
