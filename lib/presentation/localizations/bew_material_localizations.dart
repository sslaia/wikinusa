import 'package:flutter/material.dart';

class BewMaterialLocalizations extends DefaultMaterialLocalizations {
  const BewMaterialLocalizations();

  @override
  String get okButtonLabel => 'Ok';
}

class BewMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const BewMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'bew';

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    return const BewMaterialLocalizations();
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<MaterialLocalizations> old) => false;
}
