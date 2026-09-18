import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/chat_module_config.dart';

/// Service that listens to Wikimedia's public EventStreams Server-Sent Events (SSE)
/// for real-time `recentchange` updates on a specific talk page.
class WikiEventStreamService {
  static const String _streamUrl =
      'https://stream.wikimedia.org/v2/stream/recentchange';

  final String domain;
  final String pageTitle;
  final VoidCallback onPageUpdated;

  http.Client? _client;
  StreamSubscription<String>? _streamSub;
  bool _isDisposed = false;
  Timer? _reconnectTimer;

  WikiEventStreamService({
    required this.domain,
    required this.pageTitle,
    required this.onPageUpdated,
  });

  /// Starts listening to the SSE stream.
  void startListening() {
    if (_isDisposed) return;
    _connect();
  }

  void _connect() {
    _client?.close();
    _streamSub?.cancel();

    _client = http.Client();
    final request = http.Request('GET', Uri.parse(_streamUrl));
    request.headers['User-Agent'] = ChatModuleConfig.userAgent;
    request.headers['Accept'] = 'text/event-stream';

    _client!
        .send(request)
        .then((response) {
          if (response.statusCode != 200) {
            _scheduleReconnect();
            return;
          }

          _streamSub = response.stream
              .transform(utf8.decoder)
              .transform(const LineSplitter())
              .listen(
                _handleLine,
                onError: (e) {
                  debugPrint('WikiEventStreamService error: $e');
                  _scheduleReconnect();
                },
                onDone: () {
                  _scheduleReconnect();
                },
                cancelOnError: true,
              );
        })
        .catchError((e) {
          debugPrint('WikiEventStreamService connect error: $e');
          _scheduleReconnect();
        });
  }

  void _handleLine(String line) {
    if (!line.startsWith('data: ')) return;
    final jsonStr = line.substring(6).trim();
    if (jsonStr.isEmpty) return;

    try {
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      final serverName = data['server_name'] as String?;
      final eventTitle = data['title'] as String?;

      if (serverName != null && eventTitle != null) {
        final normServer = serverName.toLowerCase();
        final targetDomain = domain.toLowerCase();

        if (normServer == targetDomain) {
          final normEventTitle = eventTitle.replaceAll('_', ' ').toLowerCase();
          final normPageTitle = pageTitle.replaceAll('_', ' ').toLowerCase();

          if (normEventTitle == normPageTitle) {
            // Talk page was updated!
            onPageUpdated();
          }
        }
      }
    } catch (_) {
      // Ignore malformed SSE lines
    }
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 8), () {
      if (!_isDisposed) {
        _connect();
      }
    });
  }

  /// Stops stream listening and releases resources.
  void dispose() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    _streamSub?.cancel();
    _client?.close();
  }
}
