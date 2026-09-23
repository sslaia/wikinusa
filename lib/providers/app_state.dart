import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wikimedia_core/wikimedia_core.dart';
import '../utils/locale_utils.dart';
import 'shared_prefs_provider.dart';

/// Notifier for the current project type (Wikipedia, Wiktionary, Wikibooks)
class AppStateNotifier extends Notifier<ProjectType> {
  static const _projectKey = 'selected_project_type';

  @override
  ProjectType build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final projectStr = prefs.getString(_projectKey);
    if (projectStr != null) {
      try {
        return ProjectType.values.firstWhere(
          (e) =>
              e.toString() == projectStr ||
              e.name.toLowerCase() == projectStr.toLowerCase(),
        );
      } catch (_) {}
    }
    return ProjectType.wikipedia;
  }

  void setProject(ProjectType project, String langCode) {
    if (project.isSupported(langCode)) {
      state = project;
      ref.read(sharedPreferencesProvider).setString(_projectKey, project.toString());
    }
  }
}

final appStateProvider = NotifierProvider<AppStateNotifier, ProjectType>(() {
  return AppStateNotifier();
});

/// Notifier for the user's enabled projects list.
/// Wikipedia is the anchor project and is always enabled.
class EnabledProjectsNotifier extends Notifier<List<ProjectType>> {
  static const _enabledProjectsKey = 'user_enabled_projects';
  static const ProjectType anchorProject = ProjectType.wikipedia;
  static const List<ProjectType> defaultProjects = [
    ProjectType.wikipedia,
    ProjectType.wiktionary,
    ProjectType.wikibooks,
  ];

  @override
  List<ProjectType> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final saved = prefs.getStringList(_enabledProjectsKey);
    if (saved != null && saved.isNotEmpty) {
      final list = <ProjectType>[];
      for (final s in saved) {
        try {
          final p = ProjectType.values.firstWhere(
            (e) =>
                e.name.toLowerCase() == s.toLowerCase() ||
                e.toString().toLowerCase() == s.toLowerCase(),
          );
          if (!list.contains(p)) {
            list.add(p);
          }
        } catch (_) {}
      }
      if (!list.contains(anchorProject)) {
        list.insert(0, anchorProject);
      }
      return list;
    }
    return List<ProjectType>.from(defaultProjects);
  }

  bool canDisableProject(ProjectType project) {
    if (project == anchorProject) return false;
    return true;
  }

  bool toggleProject(ProjectType project, bool enable) {
    if (project == anchorProject && !enable) {
      return false; // Wikipedia cannot be disabled
    }

    final current = List<ProjectType>.from(state);
    if (enable) {
      if (!current.contains(project)) {
        current.add(project);
      }
    } else {
      if (!canDisableProject(project)) {
        return false;
      }
      current.remove(project);
    }

    // Read currentProject before mutating state to avoid Riverpod re-entrancy / cycle issues
    final currentProject = ref.read(appStateProvider);

    state = current;
    ref.read(sharedPreferencesProvider).setStringList(
      _enabledProjectsKey,
      current.map((e) => e.name.toLowerCase()).toList(),
    );

    // If current selected project is disabled, switch to first available
    if (!current.contains(currentProject)) {
      final currentLang = ref.read(languageProvider);
      final fallbackProject = current.firstWhere(
        (p) => p.isSupported(currentLang),
        orElse: () => anchorProject,
      );
      ref.read(appStateProvider.notifier).setProject(fallbackProject, currentLang);
    }
    return true;
  }

  void resetToDefaults() {
    state = List<ProjectType>.from(defaultProjects);
    ref.read(sharedPreferencesProvider).setStringList(
      _enabledProjectsKey,
      defaultProjects.map((e) => e.name.toLowerCase()).toList(),
    );
  }
}

final enabledProjectsProvider =
    NotifierProvider<EnabledProjectsNotifier, List<ProjectType>>(() {
  return EnabledProjectsNotifier();
});

/// Notifier for the application language
class LanguageNotifier extends Notifier<String> {
  static const _languageKey = 'selected_language_code';

  @override
  String build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString(_languageKey) ?? LocaleUtils.getOnboardingLanguage();
  }

  void setLanguage(String code) {
    if (state != code) {
      state = code;
      ref.read(sharedPreferencesProvider).setString(_languageKey, code);
      
      // Safety check: if current project is not supported or not enabled in new language, revert to first supported enabled project
      final currentProject = ref.read(appStateProvider);
      final enabledProjects = ref.read(enabledProjectsProvider);
      if (!currentProject.isSupported(code) || !enabledProjects.contains(currentProject)) {
        final fallback = enabledProjects.firstWhere(
          (p) => p.isSupported(code),
          orElse: () => ProjectType.wikipedia,
        );
        ref.read(appStateProvider.notifier).setProject(fallback, code);
      }
    }
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, String>(() {
  return LanguageNotifier();
});

/// Notifier for the user's enabled languages list (filter for drawer / switcher).
/// In WikiNusa:
/// - 'id' (Bahasa Indonesia) is the national anchor language and is always enabled.
/// - At least one local/regional language must always remain enabled.
class EnabledLanguagesNotifier extends Notifier<List<String>> {
  static const _enabledLangsKey = 'user_enabled_languages';
  static const String anchorLanguage = 'id';
  static const List<String> fallbackDefaultLanguages = ['id', 'nia'];

  /// Dynamically returns non-experimental languages registered in CommunityRegistry,
  /// falling back to [fallbackDefaultLanguages] if registry is not initialized.
  static List<String> get defaultLanguages {
    if (CommunityRegistry.isInitialized && CommunityRegistry.languages.isNotEmpty) {
      final nonExp = CommunityRegistry.languages
          .where((l) => !l.isExperimental)
          .map((l) => l.code)
          .toList();
      if (nonExp.isNotEmpty) {
        if (!nonExp.contains(anchorLanguage)) {
          nonExp.insert(0, anchorLanguage);
        }
        return nonExp;
      }
    }
    return fallbackDefaultLanguages;
  }

  @override
  List<String> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final saved = prefs.getStringList(_enabledLangsKey);
    if (saved != null && saved.isNotEmpty) {
      final list = List<String>.from(saved);
      // Ensure anchor language (id) is always present
      if (!list.contains(anchorLanguage)) {
        list.insert(0, anchorLanguage);
      }
      // Ensure at least one other (local/secondary) language is present
      if (list.where((code) => code != anchorLanguage).isEmpty) {
        list.add('nia');
      }
      return list;
    }
    return List<String>.from(defaultLanguages);
  }

  /// Returns true if a language can be toggled off.
  /// - 'id' can never be disabled.
  /// - The last remaining non-id language cannot be disabled.
  bool canDisableLanguage(String code) {
    if (code == anchorLanguage) return false;
    final otherLangs = state.where((c) => c != anchorLanguage).toList();
    if (otherLangs.length <= 1 && otherLangs.contains(code)) {
      return false;
    }
    return true;
  }

  /// Toggles a language on or off.
  /// Returns true if the toggle succeeded, false if disallowed.
  bool toggleLanguage(String code, bool enable) {
    if (code == anchorLanguage && !enable) {
      return false; // Indonesian cannot be disabled
    }

    final current = List<String>.from(state);
    if (enable) {
      if (!current.contains(code)) {
        current.add(code);
      }
    } else {
      if (!canDisableLanguage(code)) {
        return false; // Cannot disable last regional language
      }
      current.remove(code);
    }

    state = current;
    ref.read(sharedPreferencesProvider).setStringList(_enabledLangsKey, current);

    // If current selected language is disabled, switch to first available
    final currentLang = ref.read(languageProvider);
    if (!current.contains(currentLang)) {
      ref.read(languageProvider.notifier).setLanguage(current.first);
    }
    return true;
  }

  void resetToDefaults() {
    state = List<String>.from(defaultLanguages);
    ref.read(sharedPreferencesProvider).setStringList(_enabledLangsKey, defaultLanguages);
  }
}

final enabledLanguagesProvider =
    NotifierProvider<EnabledLanguagesNotifier, List<String>>(() {
  return EnabledLanguagesNotifier();
});

