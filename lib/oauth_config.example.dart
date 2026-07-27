// Copy this file to lib/oauth_config.dart or pass credentials via --dart-define.
// Example command:
// flutter run --dart-define=WIKIMEDIA_CLIENT_ID=your_id --dart-define=WIKIMEDIA_REDIRECT_URL=your_url
class OAuthConfig {
  static const String clientId = String.fromEnvironment(
    'WIKIMEDIA_CLIENT_ID',
    defaultValue: 'YOUR_CLIENT_ID',
  );
  static const String redirectUrl = String.fromEnvironment(
    'WIKIMEDIA_REDIRECT_URL',
    defaultValue: 'YOUR_REDIRECT_URL',
  );
}

