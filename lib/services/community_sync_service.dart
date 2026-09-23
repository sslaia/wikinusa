import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wikimedia_core/wikimedia_core.dart';

/// Result summary of an OTA synchronization operation.
class SyncResult {
  final bool success;
  final List<String> newLanguages;
  final List<String> updatedLanguages;
  final String? errorMessage;

  const SyncResult({
    required this.success,
    this.newLanguages = const [],
    this.updatedLanguages = const [],
    this.errorMessage,
  });

  bool get hasChanges => newLanguages.isNotEmpty || updatedLanguages.isNotEmpty;
}

/// Service handling Over-The-Air (OTA) synchronization of community manifests,
/// translations, and datasets directly from GitHub.
class CommunitySyncService {
  static const String defaultRepositoryBaseUrl =
      'https://raw.githubusercontent.com/sslaia/wikinusa/main';

  static const String _prefLastSyncTime = 'ota_communities_last_sync_time';
  static const String _prefSyncedVersion = 'ota_communities_synced_version';

  final String baseUrl;
  final http.Client _client;
  final Directory? baseDocumentsDirectory;

  CommunitySyncService({
    this.baseUrl = defaultRepositoryBaseUrl,
    http.Client? client,
    this.baseDocumentsDirectory,
  }) : _client = client ?? http.Client();

  /// Gets the local directory where downloaded community manifest JSON files are stored.
  static Future<Directory> getCommunitiesDirectory([Directory? baseDir]) async {
    final docDir = baseDir ?? await getApplicationDocumentsDirectory();
    final dir = Directory('${docDir.path}/communities');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Gets the local directory where downloaded translation JSON files are stored.
  static Future<Directory> getTranslationsDirectory([Directory? baseDir]) async {
    final docDir = baseDir ?? await getApplicationDocumentsDirectory();
    final dir = Directory('${docDir.path}/translations');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Gets the local directory where downloaded dataset files (gallery, crosswords) are stored.
  static Future<Directory> getDataDirectory([Directory? baseDir]) async {
    final docDir = baseDir ?? await getApplicationDocumentsDirectory();
    final dir = Directory('${docDir.path}/data');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Checks and synchronizes languages from GitHub.
  /// If [force] is true, checks all languages regardless of previous sync time.
  Future<SyncResult> syncLanguages({
    bool force = false,
    SharedPreferences? prefs,
  }) async {
    try {
      final sharedPrefs = prefs ?? await SharedPreferences.getInstance();

      // 1. Fetch communities_index.json
      final indexUri = Uri.parse('$baseUrl/assets/communities_index.json');
      final indexResponse = await _client
          .get(indexUri)
          .timeout(const Duration(seconds: 8));

      if (indexResponse.statusCode != 200) {
        return SyncResult(
          success: false,
          errorMessage:
              'Failed to fetch community index (${indexResponse.statusCode})',
        );
      }

      final dynamic decodedIndex = jsonDecode(utf8.decode(indexResponse.bodyBytes));
      if (decodedIndex is! Map<String, dynamic>) {
        return const SyncResult(
          success: false,
          errorMessage: 'Invalid index format received from server',
        );
      }

      final remoteVersion = decodedIndex['version'] as int? ?? 1;
      final remoteLanguages = (decodedIndex['languages'] as List<dynamic>?)
              ?.map((e) => e.toString().toLowerCase().trim())
              .where((code) => code.isNotEmpty)
              .toList() ??
          [];

      final localVersion = sharedPrefs.getInt(_prefSyncedVersion) ?? 0;
      final registeredCodes =
          CommunityRegistry.languages.map((l) => l.code).toSet();

      // Check if there are new languages not currently in the registry
      final newLanguageCodes = remoteLanguages
          .where((code) => !registeredCodes.contains(code))
          .toList();

      if (!force && newLanguageCodes.isEmpty && remoteVersion <= localVersion) {
        return const SyncResult(success: true);
      }

      final communitiesDir = await getCommunitiesDirectory(baseDocumentsDirectory);
      final translationsDir = await getTranslationsDirectory(baseDocumentsDirectory);

      final List<String> added = [];
      final List<String> updated = [];

      // 2. Download and install manifests & translations
      for (final langCode in remoteLanguages) {
        final isNew = !registeredCodes.contains(langCode);

        // Download community manifest: assets/communities/<langCode>.json
        final manifestUri =
            Uri.parse('$baseUrl/assets/communities/$langCode.json');
        try {
          final manifestRes = await _client
              .get(manifestUri)
              .timeout(const Duration(seconds: 8));

          if (manifestRes.statusCode == 200) {
            final manifestBody = utf8.decode(manifestRes.bodyBytes);
            final decodedManifest = jsonDecode(manifestBody);

            if (decodedManifest is Map<String, dynamic> &&
                decodedManifest['code'] == langCode) {
              // Write manifest to local storage
              final manifestFile =
                  File('${communitiesDir.path}/$langCode.json');
              await manifestFile.writeAsString(manifestBody, flush: true);

              // Dynamically register in CommunityRegistry in memory
              CommunityRegistry.registerLanguageFromMap(decodedManifest);

              // Also download translation file: assets/translations/<langCode>.json
              final transUri =
                  Uri.parse('$baseUrl/assets/translations/$langCode.json');
              try {
                final transRes = await _client
                    .get(transUri)
                    .timeout(const Duration(seconds: 8));

                if (transRes.statusCode == 200) {
                  final transBody = utf8.decode(transRes.bodyBytes);
                  final decodedTrans = jsonDecode(transBody);
                  if (decodedTrans is Map<String, dynamic>) {
                    final transFile =
                        File('${translationsDir.path}/$langCode.json');
                    await transFile.writeAsString(transBody, flush: true);
                  }
                }
              } catch (e) {
                debugPrint(
                  'CommunitySyncService: Error syncing translations for $langCode: $e',
                );
              }

              if (isNew) {
                added.add(langCode);
              } else {
                updated.add(langCode);
              }
            }
          }
        } catch (e) {
          debugPrint(
            'CommunitySyncService: Error syncing manifest for $langCode: $e',
          );
        }
      }

      // Update sync preferences
      await sharedPrefs.setInt(_prefSyncedVersion, remoteVersion);
      await sharedPrefs.setString(
        _prefLastSyncTime,
        DateTime.now().toIso8601String(),
      );

      return SyncResult(
        success: true,
        newLanguages: added,
        updatedLanguages: updated,
      );
    } catch (e) {
      debugPrint('CommunitySyncService: Sync failed: $e');
      return SyncResult(
        success: false,
        errorMessage: e.toString(),
      );
    }
  }
}
