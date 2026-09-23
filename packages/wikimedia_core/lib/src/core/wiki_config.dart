import '../models/project_type.dart';
import 'community_registry.dart';

class WikiConfig {
  static String _appName = 'wikinusa';
  static bool _isInitialized = false;

  /// Returns true if WikiConfig is initialized
  static bool get isInitialized => _isInitialized;

  /// Wikimedia requires a descriptive User-Agent
  static Map<String, String> get uaHeaders => {
    'User-Agent':
        'WikiNusa/1.5 (https://sslaia.github.io/$_appName; slaia@yahoo.com) Generic/1.0',
  };

  static ProjectType _parseProject(String projectStr) {
    try {
      return ProjectType.values.byName(projectStr.toLowerCase());
    } catch (_) {
      return ProjectType.wikipedia;
    }
  }

  /// Initialize the WikiConfig.
  /// Ensures CommunityRegistry is initialized with communities.json.
  static Future<void> init({required String appName}) async {
    if (_isInitialized) return;
    _appName = appName;
    if (!CommunityRegistry.isInitialized) {
      await CommunityRegistry.init(appName: appName);
    }
    _isInitialized = true;
  }

  /// Get the full rules map for a language code and project
  static Map<String, dynamic>? getRules(
    String languageCode,
    String projectStr,
  ) {
    return CommunityRegistry.getRules(languageCode, _parseProject(projectStr));
  }

  /// Get global rules for a project
  static Map<String, dynamic>? getGlobalRules(String projectStr) {
    return CommunityRegistry.getGlobalRules(_parseProject(projectStr));
  }

  /// Get the domain for a given language code and project.
  /// Falls back to `<langCode>.<projectStr>.org` if no override is specified.
  static String getDomain(String languageCode, String projectStr) {
    return CommunityRegistry.getDomain(languageCode, _parseProject(projectStr));
  }

  /// Get the API prefix for a given language code and project.
  /// Falls back to an empty string.
  static String getApiPrefix(String languageCode, String projectStr) {
    return CommunityRegistry.getApiPrefix(
      languageCode,
      _parseProject(projectStr),
    );
  }

  /// Get the processing flags for a given language code and project.
  static List<String> getProcessingFlags(
    String languageCode,
    String projectStr,
  ) {
    return CommunityRegistry.getProcessingFlags(
      languageCode,
      _parseProject(projectStr),
    );
  }

  /// Check if a specific processing flag exists
  static bool hasProcessingFlag(
    String languageCode,
    String projectStr,
    String flag,
  ) {
    return CommunityRegistry.hasProcessingFlag(
      languageCode,
      _parseProject(projectStr),
      flag,
    );
  }

  /// Get combined rule list (e.g., 'remove' or 'hide') from both global and project specific rules
  static List<String> getCombinedRulesList(
    String languageCode,
    String projectStr,
    String key,
  ) {
    return CommunityRegistry.getCombinedRulesList(
      languageCode,
      _parseProject(projectStr),
      key,
    );
  }
}
