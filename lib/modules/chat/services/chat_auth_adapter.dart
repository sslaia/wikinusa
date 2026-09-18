import 'package:flutter/material.dart';

/// Abstract adapter decoupling WikiChat module from the host app's authentication system.
abstract class ChatAuthAdapter {
  /// Whether the user currently has an authenticated session.
  bool get isAuthenticated;

  /// Cached username of the logged-in Wikimedia user, if available.
  String? get currentUsername;

  /// Returns a valid OAuth Bearer access token, refreshing if necessary.
  Future<String?> getValidAccessToken();

  /// Prompts the user to log in via the parent app's authentication flow.
  /// Returns `true` if login succeeded, `false` otherwise.
  Future<bool> requireLogin(BuildContext context);

  /// Resolves the authenticated username from the wiki API using the access token.
  Future<String?> fetchCurrentUsername(String domain);
}
