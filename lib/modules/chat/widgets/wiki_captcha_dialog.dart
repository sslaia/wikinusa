import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Modal dialog that presents an hCaptcha challenge in a webview
/// and returns the solved response token.
class WikiCaptchaDialog extends StatefulWidget {
  final String siteKey;
  final String domain;
  final String pageTitle;
  final String? captchaId;
  final String? captchaUrl;
  final String? captchaQuestion;
  final String? prefillTitle;
  final String? prefillContent;

  const WikiCaptchaDialog({
    super.key,
    required this.siteKey,
    required this.domain,
    required this.pageTitle,
    this.captchaId,
    this.captchaUrl,
    this.captchaQuestion,
    this.prefillTitle,
    this.prefillContent,
  });

  /// Helper to show this dialog and return the solved token (or null if canceled)
  static Future<String?> show(
    BuildContext context, {
    required String siteKey,
    required String domain,
    required String pageTitle,
    String? captchaId,
    String? captchaUrl,
    String? captchaQuestion,
    String? prefillTitle,
    String? prefillContent,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => WikiCaptchaDialog(
        siteKey: siteKey,
        domain: domain,
        pageTitle: pageTitle,
        captchaId: captchaId,
        captchaUrl: captchaUrl,
        captchaQuestion: captchaQuestion,
        prefillTitle: prefillTitle,
        prefillContent: prefillContent,
      ),
    );
  }

  @override
  State<WikiCaptchaDialog> createState() => _WikiCaptchaDialogState();
}

class _WikiCaptchaDialogState extends State<WikiCaptchaDialog> {
  final TextEditingController _inputController = TextEditingController();
  WebViewController? _webViewController;
  bool _isLoading = true;
  bool _isMobile = false;

  @override
  void initState() {
    super.initState();
    _isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);

    if (_isMobile && widget.siteKey.isNotEmpty) {
      _initWebView();
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _initWebView() {
    final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
  <style>
    * { box-sizing: border-box; }
    body {
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      margin: 0;
      padding: 8px;
      background-color: transparent;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    }
    .h-captcha {
      display: flex;
      justify-content: center;
    }
  </style>
  <script src="https://js.hcaptcha.com/1/api.js" async defer></script>
</head>
<body>
  <div class="h-captcha"
       data-sitekey="${widget.siteKey}"
       data-callback="onCaptchaSolved"
       data-expired-callback="onCaptchaExpired"></div>
  <script>
    function onCaptchaSolved(token) {
      if (window.CaptchaChannel) {
        window.CaptchaChannel.postMessage(token);
      }
    }
    function onCaptchaExpired() {
      if (window.CaptchaChannel) {
        window.CaptchaChannel.postMessage("EXPIRED");
      }
    }
  </script>
</body>
</html>
''';

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'CaptchaChannel',
        onMessageReceived: (JavaScriptMessage message) {
          if (message.message != 'EXPIRED' && message.message.isNotEmpty) {
            Navigator.of(context).pop(message.message);
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
        ),
      )
      ..loadHtmlString(
        html,
        baseUrl: 'https://${widget.domain}',
      );
  }

  void _openWebFallback() async {
    final cleanPage = widget.pageTitle.replaceAll(' ', '_');
    final queryParams = <String, String>{
      'action': 'edit',
    };
    if (widget.prefillTitle != null && widget.prefillTitle!.isNotEmpty) {
      queryParams['section'] = 'new';
      queryParams['preloadtitle'] = widget.prefillTitle!;
    }
    final uri = Uri.https(widget.domain, '/wiki/$cleanPage', queryParams);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    if (mounted) {
      Navigator.of(context).pop(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final hasImageUrl =
        widget.captchaUrl != null && widget.captchaUrl!.isNotEmpty;
    final hasQuestion =
        widget.captchaQuestion != null && widget.captchaQuestion!.isNotEmpty;
    final isInteractive = hasImageUrl || hasQuestion;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.security_rounded,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'chat_captcha_title'.tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(null),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'chat_captcha_desc'.tr(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),

          // Image CAPTCHA challenge (FancyCaptcha)
          if (hasImageUrl) ...[
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.captchaUrl!.startsWith('http')
                      ? widget.captchaUrl!
                      : 'https://${widget.domain}${widget.captchaUrl}',
                  height: 60,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Question CAPTCHA challenge (QuestyCaptcha)
          if (hasQuestion) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.captchaQuestion!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Text input for Image or Question CAPTCHA
          if (isInteractive) ...[
            TextField(
              controller: _inputController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'chat_captcha_solve'.tr(),
                filled: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onSubmitted: (val) {
                if (val.trim().isNotEmpty) {
                  Navigator.of(context).pop(val.trim());
                }
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                final val = _inputController.text.trim();
                if (val.isNotEmpty) {
                  Navigator.of(context).pop(val);
                }
              },
              child: Text('submit'.tr()),
            ),
          ],

          // WebView for hCaptcha
          if (!isInteractive &&
              _isMobile &&
              widget.siteKey.isNotEmpty &&
              _webViewController != null) ...[
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  WebViewWidget(controller: _webViewController!),
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          // Fallback button to open on web
          OutlinedButton.icon(
            icon: const Icon(Icons.open_in_browser_rounded, size: 18),
            label: Text('chat_open_web'.tr()),
            onPressed: _openWebFallback,
          ),
        ],
      ),
    );
  }
}
