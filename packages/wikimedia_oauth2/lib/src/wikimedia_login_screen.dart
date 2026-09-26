import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class WikimediaLoginScreen extends StatefulWidget {
  final String authorizationUrl;
  final String redirectUri;

  const WikimediaLoginScreen({
    super.key,
    required this.authorizationUrl,
    required this.redirectUri,
  });

  @override
  State<WikimediaLoginScreen> createState() => _WikimediaLoginScreenState();
}

class _WikimediaLoginScreenState extends State<WikimediaLoginScreen> {
  late final WebViewController? _webViewController;
  final TextEditingController _codeController = TextEditingController();
  bool _isMobile = false;
  String? _errorMessage;

  // Local loopback server for desktop OAuth callback relay
  HttpServer? _loopbackServer;
  static const int loopbackPort = 8765;
  bool _isListening = false;
  bool _showManualInput = false;

  @override
  void initState() {
    super.initState();
    _isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    if (_isMobile) {
      // Parse redirectUri to extract domain and path for matching
      final redirectUriObj = Uri.parse(widget.redirectUri);
      final redirectHostAndPath = '${redirectUriObj.host}${redirectUriObj.path}';

      _webViewController = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onUrlChange: (UrlChange change) {
              final url = change.url;
              if (url != null && url.contains(redirectHostAndPath)) {
                final uri = Uri.parse(url);
                final code = uri.queryParameters['code'];
                if (code != null) {
                  Navigator.of(context).pop(code);
                } else if (uri.queryParameters.containsKey('error')) {
                  Navigator.of(context).pop('ERROR:${uri.queryParameters['error']}');
                }
              }
            },
            onNavigationRequest: (NavigationRequest request) {
              if (request.url.contains(redirectHostAndPath)) {
                final uri = Uri.parse(request.url);
                final code = uri.queryParameters['code'];
                if (code != null) {
                  Navigator.of(context).pop(code);
                  return NavigationDecision.prevent;
                } else if (uri.queryParameters.containsKey('error')) {
                  Navigator.of(context).pop('ERROR:${uri.queryParameters['error']}');
                  return NavigationDecision.prevent;
                }
              }
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.authorizationUrl));
    } else {
      _webViewController = null;
      _startLoopbackServer();
      // Automatically launch external browser on desktop
      Future.microtask(() => _launchAuthUrl());
    }
  }

  Future<void> _startLoopbackServer() async {
    try {
      _loopbackServer = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        loopbackPort,
        shared: true,
      );
      if (mounted) {
        setState(() {
          _isListening = true;
        });
      }

      _loopbackServer?.listen((HttpRequest request) async {
        // Handle CORS preflight & headers
        request.response.headers.add('Access-Control-Allow-Origin', '*');
        request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
        request.response.headers.add('Access-Control-Allow-Headers', '*');

        if (request.method == 'OPTIONS') {
          request.response.statusCode = HttpStatus.ok;
          await request.response.close();
          return;
        }

        final code = request.uri.queryParameters['code'];
        final error = request.uri.queryParameters['error'];

        if (code != null && code.isNotEmpty) {
          request.response.statusCode = HttpStatus.ok;
          request.response.headers.contentType = ContentType.json;
          request.response.write('{"status":"ok"}');
          await request.response.close();

          if (mounted) {
            // Slight delay so HTTP response completes before widget unmounts & closes server
            Future.delayed(const Duration(milliseconds: 50), () {
              if (mounted) {
                Navigator.of(context).pop(code);
              }
            });
          }
        } else if (error != null && error.isNotEmpty) {
          request.response.statusCode = HttpStatus.ok;
          request.response.headers.contentType = ContentType.json;
          request.response.write('{"status":"error"}');
          await request.response.close();

          if (mounted) {
            Future.delayed(const Duration(milliseconds: 50), () {
              if (mounted) {
                Navigator.of(context).pop('ERROR:$error');
              }
            });
          }
        } else {
          request.response.statusCode = HttpStatus.badRequest;
          request.response.write('Missing code parameter');
          await request.response.close();
        }
      });
    } catch (e) {
      debugPrint('Desktop OAuth loopback server error: $e');
    }
  }

  @override
  void dispose() {
    _loopbackServer?.close();
    _codeController.dispose();
    super.dispose();
  }

  void _submitCode() {
    final input = _codeController.text.trim();
    if (input.isEmpty) return;

    String code = input;
    // Check if the input is a full URL containing the 'code' parameter
    if (input.startsWith('http://') || input.startsWith('https://')) {
      try {
        final uri = Uri.parse(input);
        final extractedCode = uri.queryParameters['code'];
        if (extractedCode != null) {
          code = extractedCode;
        } else {
          setState(() {
            _errorMessage = 'The URL does not contain an authorization code.';
          });
          return;
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Invalid URL format.';
        });
        return;
      }
    }

    Navigator.of(context).pop(code);
  }

  Future<void> _launchAuthUrl() async {
    try {
      final url = Uri.parse(widget.authorizationUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'Could not launch the browser. Please copy and open the URL manually.';
            _showManualInput = true;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not launch the browser. Please copy and open the URL manually.';
          _showManualInput = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isMobile) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Login to Wikimedia'),
        ),
        body: WebViewWidget(controller: _webViewController!),
      );
    }

    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login to Wikimedia'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.security_rounded,
                      size: 64,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Wikimedia Authentication',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isListening
                                      ? 'Waiting for browser approval...'
                                      : 'Preparing authentication...',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Complete login in your browser. This window will automatically finish logging in once approved.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _launchAuthUrl,
                            icon: const Icon(Icons.open_in_new_rounded),
                            label: const Text('Open Browser Again'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded),
                          tooltip: 'Copy login link',
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: widget.authorizationUrl));
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Login link copied to clipboard.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showManualInput = !_showManualInput;
                        });
                      },
                      icon: Icon(
                        _showManualInput
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 20,
                      ),
                      label: Text(
                        _showManualInput
                            ? 'Hide manual code entry'
                            : 'Having trouble? Enter code manually',
                        style: TextStyle(
                          color: theme.colorScheme.secondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (_showManualInput) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _codeController,
                        decoration: InputDecoration(
                          labelText: 'Authorization Code or URL',
                          hintText: 'Paste code or redirect URL here',
                          errorText: _errorMessage,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.paste_rounded),
                            tooltip: 'Paste from clipboard',
                            onPressed: () async {
                              final data = await Clipboard.getData(Clipboard.kTextPlain);
                              if (data?.text != null) {
                                _codeController.text = data!.text!;
                                setState(() {
                                  _errorMessage = null;
                                });
                              }
                            },
                          ),
                        ),
                        onSubmitted: (_) => _submitCode(),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: _submitCode,
                          child: const Text('Submit Code'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
