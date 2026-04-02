import 'package:flutter/material.dart';

class MinMaterialLocalizations extends DefaultMaterialLocalizations {
  const MinMaterialLocalizations();

  @override
  String get okButtonLabel => 'Ok';
}

class MinMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const MinMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'min';

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    return const MinMaterialLocalizations();
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<MaterialLocalizations> old) => false;
}
