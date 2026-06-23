import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'wikimedia_login_screen.dart';

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final String clientId;
  final String redirectUrl;
  final String authorizationEndpoint;
  final String tokenEndpoint;

  AuthService({
    required this.clientId,
    required this.redirectUrl,
    this.authorizationEndpoint = 'https://meta.wikimedia.org/w/rest.php/oauth2/authorize',
    this.tokenEndpoint = 'https://meta.wikimedia.org/w/rest.php/oauth2/access_token',
  });

  String _generateCodeVerifier() {
    var random = Random.secure();
    var values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64UrlEncode(values).replaceAll('=', '');
  }

  String _generateCodeChallenge(String verifier) {
    var bytes = utf8.encode(verifier);
    var digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  Future<void> login(BuildContext context) async {
    try {
      final codeVerifier = _generateCodeVerifier();
      final codeChallenge = _generateCodeChallenge(codeVerifier);

      final authUri = Uri.parse(authorizationEndpoint).replace(queryParameters: {
        'response_type': 'code',
        'client_id': clientId,
        'redirect_uri': redirectUrl,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
      });

      // Navigate to the webview screen
      final code = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (context) => WikimediaLoginScreen(
            authorizationUrl: authUri.toString(),
            redirectUri: redirectUrl,
          ),
        ),
      );

      if (code != null) {
        if (code.startsWith('ERROR:')) {
          throw Exception('Wikimedia OAuth Error: ${code.substring(6)}');
        }
        
        // Exchange code for token
        final response = await http.post(
          Uri.parse(tokenEndpoint),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {
            'grant_type': 'authorization_code',
            'client_id': clientId,
            'code': code,
            'redirect_uri': redirectUrl,
            'code_verifier': codeVerifier,
          },
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          await _storage.write(key: 'access_token', value: data['access_token']);
          if (data['refresh_token'] != null) {
            await _storage.write(key: 'refresh_token', value: data['refresh_token']);
          }
          final expiresIn = data['expires_in'] as int?;
          if (expiresIn != null) {
            final expiry = DateTime.now().add(Duration(seconds: expiresIn));
            await _storage.write(key: 'token_expiry', value: expiry.toIso8601String());
          }
        } else {
          debugPrint('Token Exchange Error: ${response.statusCode} - ${response.body}');
          throw Exception('Token Exchange Error ${response.statusCode}: ${response.body}');
        }
      }
    } catch (e) {
      debugPrint('Login Error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    // Add call the token revocation endpoint later
    await _storage.deleteAll();
  }

  Future<bool> isLoggedIn() async {
    final accessToken = await getValidAccessToken();
    return accessToken != null;
  }

  // Checks for expiry and refreshes the token if needed
  Future<String?> getValidAccessToken() async {
    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      return null;
    }

    final refreshToken = await _storage.read(key: 'refresh_token');
    final tokenExpiry = await _storage.read(key: 'token_expiry');

    if (tokenExpiry != null) {
      // Check if the token is expired or close to expiring
      final expiryDate = DateTime.parse(tokenExpiry);
      if (DateTime.now().isAfter(expiryDate.subtract(const Duration(minutes: 1)))) {
        if (refreshToken == null) {
          // Token expired but no refresh token available.
          // Instead of prematurely logging out, return the access token and let the API call fail if it really is expired.
          return accessToken;
        }

        // Token is expired, try to refresh
        try {
          final response = await http.post(
            Uri.parse(tokenEndpoint),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {
              'grant_type': 'refresh_token',
              'client_id': clientId,
              'refresh_token': refreshToken,
            },
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            await _storage.write(key: 'access_token', value: data['access_token']);
            if (data['refresh_token'] != null) {
              await _storage.write(key: 'refresh_token', value: data['refresh_token']);
            }
            final expiresIn = data['expires_in'] as int?;
            if (expiresIn != null) {
              final expiry = DateTime.now().add(Duration(seconds: expiresIn));
              await _storage.write(key: 'token_expiry', value: expiry.toIso8601String());
            }
            return data['access_token'];
          } else {
            // Refresh failed, log the user out
            debugPrint('Token Refresh Error: ${response.statusCode} - ${response.body}');
            await logout();
            return null;
          }
        } catch (e) {
          debugPrint('Error refreshing token: $e');
          await logout();
          return null;
        }
      }
    }

    return accessToken;
  }
}
