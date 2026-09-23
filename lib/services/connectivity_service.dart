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

class ConnectivityNotifier extends AsyncNotifier<bool> {
  Timer? _timer;

  @override
  Future<bool> build() async {
    ref.onDispose(() {
      _timer?.cancel();
    });

    final online = await ConnectivityService.isOnline();
    _scheduleCheck(online: online);
    return online;
  }

  void _scheduleCheck({bool? online}) {
    _timer?.cancel();
    final isOnlineNow = online ?? state.value ?? false;
    final interval = isOnlineNow
        ? const Duration(seconds: 30)
        : const Duration(seconds: 4);

    _timer = Timer(interval, () async {
      await checkConnectivity();
    });
  }

  Future<bool> checkConnectivity() async {
    final online = await ConnectivityService.isOnline();
    if (state.value != online) {
      state = AsyncData(online);
    }
    _scheduleCheck(online: online);
    return online;
  }

  void setOnline(bool online) {
    if (state.value != online) {
      state = AsyncData(online);
      _scheduleCheck(online: online);
    }
  }
}

final isOnlineProvider =
    AsyncNotifierProvider<ConnectivityNotifier, bool>(ConnectivityNotifier.new);
