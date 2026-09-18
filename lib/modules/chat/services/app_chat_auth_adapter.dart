import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../providers/auth_provider.dart';
import '../config/chat_module_config.dart';
import 'chat_auth_adapter.dart';

/// Concrete implementation of [ChatAuthAdapter] using WikiNusa's Riverpod [authProvider].
class AppChatAuthAdapter implements ChatAuthAdapter {
  final Ref ref;
  String? _cachedUsername;

  AppChatAuthAdapter(this.ref);

  @override
  bool get isAuthenticated => ref.read(authProvider).isLoggedIn;

  @override
  String? get currentUsername => _cachedUsername;

  @override
  Future<String?> getValidAccessToken() async {
    return await ref.read(authProvider.notifier).getValidAccessToken();
  }

  @override
  Future<bool> requireLogin(BuildContext context) async {
    if (isAuthenticated) return true;
    try {
      await ref.read(authProvider.notifier).login(context);
      return ref.read(authProvider).isLoggedIn;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<String?> fetchCurrentUsername(String domain) async {
    if (_cachedUsername != null) return _cachedUsername;

    final token = await getValidAccessToken();
    if (token == null || token.isEmpty) return null;

    final uri = Uri.https(domain, '/w/api.php', {
      'action': 'query',
      'meta': 'userinfo',
      'format': 'json',
      'formatversion': '2',
    });

    try {
      final res = await http.get(
        uri,
        headers: {
          'User-Agent': ChatModuleConfig.userAgent,
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final userinfo = data['query']?['userinfo'] as Map<String, dynamic>?;
        if (userinfo != null) {
          final isAnon = userinfo['anon'] != null;
          final name = userinfo['name'] as String?;
          if (!isAnon && name != null && name.isNotEmpty) {
            _cachedUsername = name;
            return name;
          }
        }
      }
    } catch (_) {}

    return null;
  }
}
