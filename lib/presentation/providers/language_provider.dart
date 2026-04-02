import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/wiki_language.dart';
import 'shared_prefs_provider.dart';

class LanguageNotifier extends Notifier<WikiLanguage> {
  static const _languageKey = 'selected_wiki_language';

  @override
  WikiLanguage build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final savedCode = prefs.getString(_languageKey);
    if (savedCode != null) {
      return WikiLanguage.fromCode(savedCode);
    }
    return WikiLanguage.nia;
  }

  void setLanguage(WikiLanguage language) {
    state = language;
    ref.read(sharedPreferencesProvider).setString(_languageKey, language.code);
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, WikiLanguage>(() {
  return LanguageNotifier();
});
