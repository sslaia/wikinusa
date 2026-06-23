import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wikimedia_oauth2/wikimedia_oauth2.dart';
import 'package:wikinusa/oauth_config.dart';

class AuthState {
  final bool isLoggedIn;
  final bool isLoading;

  AuthState({required this.isLoggedIn, required this.isLoading});
}

class AuthNotifier extends Notifier<AuthState> {
  late final AuthService _authService;

  @override
  AuthState build() {
    _authService = AuthService(
      clientId: OAuthConfig.clientId,
      redirectUrl: OAuthConfig.redirectUrl,
      authorizationEndpoint: 'https://id.wikipedia.org/w/rest.php/oauth2/authorize',
      tokenEndpoint: 'https://id.wikipedia.org/w/rest.php/oauth2/access_token',
    );
    
    // Asynchronously check login status after initial build
    Future.microtask(() => _checkLoginStatus());
    
    return AuthState(isLoggedIn: false, isLoading: true);
  }

  Future<void> _checkLoginStatus() async {
    final loggedIn = await _authService.isLoggedIn();
    state = AuthState(isLoggedIn: loggedIn, isLoading: false);
  }

  Future<void> login(BuildContext context) async {
    state = AuthState(isLoggedIn: state.isLoggedIn, isLoading: true);
    try {
      await _authService.login(context);
    } finally {
      await _checkLoginStatus();
    }
  }

  Future<void> logout() async {
    state = AuthState(isLoggedIn: state.isLoggedIn, isLoading: true);
    await _authService.logout();
    await _checkLoginStatus();
  }

  Future<String?> getValidAccessToken() async {
    return await _authService.getValidAccessToken();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
