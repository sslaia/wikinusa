import 'package:flutter/material.dart';

class SuMaterialLocalizations extends DefaultMaterialLocalizations {
  const SuMaterialLocalizations();

  @override
  String get okButtonLabel => 'Ok';
}

class SuMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const SuMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'su';

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    return const SuMaterialLocalizations();
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<MaterialLocalizations> old) => false;
}
