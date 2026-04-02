import 'package:flutter/material.dart';

class GorMaterialLocalizations extends DefaultMaterialLocalizations {
  const GorMaterialLocalizations();

  @override
  String get okButtonLabel => 'Ok';
}

class GorMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const GorMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'gor';

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    return const GorMaterialLocalizations();
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<MaterialLocalizations> old) => false;
}
