import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// An [AssetLoader] that checks for downloaded/synced translations in the
/// local application documents directory before falling back to bundled assets in [rootBundle].
class MultiSourceAssetLoader extends AssetLoader {
  /// Base directory on local storage where downloaded translation JSON files reside.
  final String? localTranslationsDirectory;

  const MultiSourceAssetLoader({this.localTranslationsDirectory});

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    final langCode = locale.languageCode;

    // 1. Try loading from local storage if provided and exists
    if (!kIsWeb && localTranslationsDirectory != null) {
      try {
        final localFile = File('$localTranslationsDirectory/$langCode.json');
        if (localFile.existsSync()) {
          final content = await localFile.readAsString();
          final decoded = jsonDecode(content);
          if (decoded is Map<String, dynamic>) {
            return decoded;
          }
        }
      } catch (e) {
        debugPrint(
          'MultiSourceAssetLoader: Error loading local translation for $langCode: $e',
        );
      }
    }

    // 2. Fallback to bundled assets in rootBundle
    try {
      final assetPath = '$path/$langCode.json';
      final content = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(content);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (e) {
      debugPrint(
        'MultiSourceAssetLoader: Error loading bundled translation for $langCode: $e',
      );
    }

    return null;
  }
}
