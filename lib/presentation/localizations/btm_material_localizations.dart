import 'package:flutter/material.dart';

class BtmMaterialLocalizations extends DefaultMaterialLocalizations {
  const BtmMaterialLocalizations();

  @override
  String get okButtonLabel => 'Ok';
}

class BtmMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const BtmMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'btm';

  @override
  Future<MaterialLocalizations> load(Locale locale) async {
    return const BtmMaterialLocalizations();
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<MaterialLocalizations> old) => false;
}
