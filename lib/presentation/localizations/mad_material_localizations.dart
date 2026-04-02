import 'package:flutter/material.dart';

class MadMaterialLocalizations extends DefaultMaterialLocalizations {
  const MadMaterialLocalizations();

  @override
  String get okButtonLabel => 'Ok';
}

class MadMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const MadMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'mad';

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    return const MadMaterialLocalizations();
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<MaterialLocalizations> old) => false;
}
