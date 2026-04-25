import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project_type.dart';
import 'shared_prefs_provider.dart';

/// Notifier for the current project type (Wikipedia, Wiktionary, etc.)
class AppStateNotifier extends Notifier<ProjectType> {
  @override
  ProjectType build() {
    return ProjectType.wikipedia;
  }

  void setProject(ProjectType project) {
    state = project;
  }
}

final appStateProvider = NotifierProvider<AppStateNotifier, ProjectType>(() {
  return AppStateNotifier();
});

/// Notifier for the application language with persistence
class LanguageNotifier extends Notifier<String> {
  static const _languageKey = 'selected_language_code';

  @override
  String build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString(_languageKey) ?? 'id';
  }

  void setLanguage(String code) {
    if (state != code) {
      state = code;
      ref.read(sharedPreferencesProvider).setString(_languageKey, code);
    }
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, String>(() {
  return LanguageNotifier();
});
