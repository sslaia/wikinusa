import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/wiki_project.dart';
import 'shared_prefs_provider.dart';

class ProjectNotifier extends Notifier<WikiProject> {
  static const _projectKey = 'selected_wiki_project';

  @override
  WikiProject build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final savedName = prefs.getString(_projectKey);
    if (savedName != null) {
      return WikiProject.values.firstWhere(
        (p) => p.name == savedName,
        orElse: () => WikiProject.wikipedia,
      );
    }
    return WikiProject.wikipedia;
  }

  void setProject(WikiProject project) {
    state = project;
    ref.read(sharedPreferencesProvider).setString(_projectKey, project.name);
  }
}

final projectProvider = NotifierProvider<ProjectNotifier, WikiProject>(() {
  return ProjectNotifier();
});
