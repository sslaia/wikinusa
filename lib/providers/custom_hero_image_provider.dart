import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wikimedia_core/wikimedia_core.dart';
import '../services/commons_service.dart';
import 'shared_prefs_provider.dart';

class CustomHeroImageNotifier extends Notifier<Map<ProjectType, String?>> {
  static String _prefKey(ProjectType project) =>
      'custom_hero_image_${project.name.toLowerCase()}';

  @override
  Map<ProjectType, String?> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final Map<ProjectType, String?> loaded = {};
    for (final project in ProjectType.values) {
      final saved = prefs.getString(_prefKey(project));
      if (saved != null && saved.trim().isNotEmpty) {
        loaded[project] = saved.trim();
      }
    }
    return loaded;
  }

  /// Normalizes user input (URL or Commons file name) to a valid image URL.
  static String normalizeImageInput(String input) {
    String trimmed = input.trim();
    if (trimmed.isEmpty) return '';

    // If full URL:
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://') || trimmed.startsWith('//')) {
      if (trimmed.startsWith('//')) trimmed = 'https:$trimmed';
      return trimmed;
    }

    // Clean up File: or Berkas: prefix
    String fileName = trimmed
        .replaceFirst(RegExp(r'^(File|Berkas|Gambar):', caseSensitive: false), '')
        .trim();

    // Replace spaces with underscores for Commons filename conventions
    fileName = fileName.replaceAll(' ', '_');

    return CommonsService.getThumbnailUrl(fileName, width: 1200);
  }

  Future<void> setCustomHeroImage(ProjectType project, String input) async {
    final normalized = normalizeImageInput(input);
    if (normalized.isEmpty) {
      await resetCustomHeroImage(project);
      return;
    }

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_prefKey(project), normalized);

    state = {
      ...state,
      project: normalized,
    };
  }

  Future<void> resetCustomHeroImage(ProjectType project) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_prefKey(project));

    final updated = Map<ProjectType, String?>.from(state);
    updated.remove(project);
    state = updated;
  }

  String? getCustomHeroImage(ProjectType project) => state[project];
}

final customHeroImageProvider =
    NotifierProvider<CustomHeroImageNotifier, Map<ProjectType, String?>>(
  CustomHeroImageNotifier.new,
);
