import 'package:flutter/material.dart';

class BjnMaterialLocalizations extends DefaultMaterialLocalizations {
  const BjnMaterialLocalizations();

  @override
  String get okButtonLabel => 'Ok';
}

class BjnMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const BjnMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'bjn';

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    return const BjnMaterialLocalizations();
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<MaterialLocalizations> old) => false;
}
