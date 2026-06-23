import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    // Parse redirectUri to extract domain and path for matching
    final redirectUriObj = Uri.parse(widget.redirectUri);
    final redirectHostAndPath = '${redirectUriObj.host}${redirectUriObj.path}';

    _controller = WebViewController()
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login to Wikimedia'),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
