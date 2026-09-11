import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/gallery_item.dart';
import '../../../providers/app_state.dart';
import '../../../providers/modules_provider.dart';

final galleryDataProvider =
    FutureProvider<Map<String, List<GalleryItem>>>((ref) async {
  final langCode = ref.watch(languageProvider);
  final config = ref.watch(
    moduleConfigProvider((moduleKey: 'gallery', langCode: langCode)),
  );
  final localDataFile = config?.dataFile ?? 'assets/data/gallery.json';
  Map<String, dynamic> jsonData;

  const onlineUrl =
      'https://raw.githubusercontent.com/sslaia/wikinusa/main/assets/data/gallery.json';

  final customDataPath = config?.dataFile;
  if (config?.isCustomDataFile == true &&
      customDataPath != null &&
      File(customDataPath).existsSync()) {
    try {
      final String jsonString = await File(customDataPath).readAsString();
      jsonData = jsonDecode(jsonString);
    } catch (_) {
      final String jsonString = await rootBundle.loadString('assets/data/gallery.json');
      jsonData = jsonDecode(jsonString);
    }
  } else {
    try {
      // Try fetching online version first
      final response = await http
          .get(Uri.parse(onlineUrl))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        jsonData = jsonDecode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Failed to load online gallery');
      }
    } catch (e) {
      // Fallback to local asset
      try {
        final String jsonString = await rootBundle.loadString(localDataFile);
        jsonData = jsonDecode(jsonString);
      } catch (_) {
        final String jsonString = await rootBundle.loadString('assets/data/gallery.json');
        jsonData = jsonDecode(jsonString);
      }
    }
  }

  final Map<String, List<GalleryItem>> galleryData = {};

  final dynamic rawLangData = jsonData[langCode] ?? jsonData;

  if (rawLangData is Map<String, dynamic>) {
    rawLangData.forEach((key, value) {
      if (value is List) {
        galleryData[key] =
            value.map((item) => GalleryItem.fromJson(item)).toList();
      }
    });
  }

  return galleryData;
});

class SelectedCategoryNotifier extends Notifier<String?> {
  @override
  String? build() {
    final galleryData = ref.watch(galleryDataProvider).value;
    if (galleryData != null && galleryData.isNotEmpty) {
      return galleryData.keys.first;
    }
    return null;
  }

  void setCategory(String category) {
    state = category;
  }
}

final selectedCategoryProvider = NotifierProvider<SelectedCategoryNotifier, String?>(() {
  return SelectedCategoryNotifier();
});
