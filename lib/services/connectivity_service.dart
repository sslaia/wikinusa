import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectivityService {
  static Future<bool> isOnline() async {
    try {
      final result = await InternetAddress.lookup('wikimedia.org')
          .timeout(const Duration(seconds: 4));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {}
    return false;
  }
}

final isOnlineProvider = FutureProvider.autoDispose<bool>((ref) async {
  return await ConnectivityService.isOnline();
});
