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
    Map<String, dynamic>? bundledMap;

    // 1. Load bundled assets from rootBundle as the authoritative base
    try {
      final assetPath = '$path/$langCode.json';
      final content = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(content);
      if (decoded is Map<String, dynamic>) {
        bundledMap = decoded;
      }
    } catch (e) {
      debugPrint(
        'MultiSourceAssetLoader: Error loading bundled translation for $langCode: $e',
      );
    }

    // 2. Check local OTA storage for newly added languages or missing keys
    if (!kIsWeb && localTranslationsDirectory != null) {
      try {
        final localFile = File('$localTranslationsDirectory/$langCode.json');
        if (localFile.existsSync()) {
          final content = await localFile.readAsString();
          final decoded = jsonDecode(content);
          if (decoded is Map<String, dynamic>) {
            if (bundledMap == null) {
              return decoded;
            }
            // Merge so local OTA keys can add new entries without overriding
            // updated bundled keys or leaving new bundled keys missing.
            return <String, dynamic>{...decoded, ...bundledMap};
          }
        }
      } catch (e) {
        debugPrint(
          'MultiSourceAssetLoader: Error loading local translation for $langCode: $e',
        );
      }
    }

    return bundledMap;
  }
}
