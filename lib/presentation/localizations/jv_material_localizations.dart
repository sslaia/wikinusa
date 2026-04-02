import 'package:flutter/material.dart';

class JvMaterialLocalizations extends DefaultMaterialLocalizations {
  const JvMaterialLocalizations();

  @override
  String get okButtonLabel => 'Ok';
}

class JvMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const JvMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'jv';

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    return const JvMaterialLocalizations();
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<MaterialLocalizations> old) => false;
}
