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
    }
  }

  @override
  void dispose() {
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
    final url = Uri.parse(widget.authorizationUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      setState(() {
        _errorMessage = 'Could not launch the browser. Please copy and open the URL manually.';
      });
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
            constraints: const BoxConstraints(maxWidth: 500),
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
                      Icons.security,
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
                    const SizedBox(height: 24),
                    Text(
                      'Since webview is not supported on this platform, please complete authentication using your external web browser.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Step-by-step guide
                    _buildStep(
                      context,
                      '1',
                      'Click the button below to open the Wikimedia authorization page in your browser.',
                    ),
                    _buildStep(
                      context,
                      '2',
                      'Log in (if required) and approve the application permissions.',
                    ),
                    _buildStep(
                      context,
                      '3',
                      'You will be redirected to a blank/callback page. Copy the entire redirect URL from your browser\'s address bar (or copy the code).',
                    ),
                    _buildStep(
                      context,
                      '4',
                      'Paste the URL or code into the text field below and press Submit.',
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _launchAuthUrl,
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Open Browser to Log In'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.copy),
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
                    const SizedBox(height: 24),
                    TextField(
                      controller: _codeController,
                      decoration: InputDecoration(
                        labelText: 'Authorization URL or Code',
                        hintText: 'https://sslaia.github.io/wikinusa/callback?code=...',
                        errorText: _errorMessage,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.paste),
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
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: _submitCode,
                          child: const Text('Submit'),
                        ),
                      ],
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

  Widget _buildStep(BuildContext context, String number, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              number,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
