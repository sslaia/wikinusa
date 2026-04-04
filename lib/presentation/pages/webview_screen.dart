import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:wikinusa/presentation/widgets/custom_bottom_nav_bar.dart';

class WebViewScreen extends StatefulWidget {
  final String langCode;
  final String pageTitle;

  const WebViewScreen({
    super.key,
    required this.langCode,
    required this.pageTitle,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    final encodedTitle = Uri.encodeComponent(widget.pageTitle.replaceAll(' ', '_'));
    final url = 'https://${widget.langCode}.m.wikipedia.org/wiki/$encodedTitle';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            // Hide header and footer elements after page finishes loading
            _controller.runJavaScript("""
              (function() {
                var style = document.createElement('style');
                style.innerHTML = '.header-container.header-chrome, .mw-footer.minerva-footer { display: none !important; }';
                document.head.appendChild(style);
              })();
            """);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('${'webview_error'.tr()}: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  Future<bool> _showExitConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('discard_changes'.tr()),
            content: Text('unfinished_editing_warning'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('cancel'.tr()),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: Text('discard'.tr()),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _findInPage(String text, {bool backward = false}) {
    if (text.isEmpty) return;
    _controller.runJavaScript(
      "window.find('$text', false, $backward, true, false, false, false)",
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final langCode = widget.langCode;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // To prevent webview from closing when editing
        final url = await _controller.currentUrl();
        final isEditing = url?.contains('action=edit') ?? false;

        if (isEditing) {
          final confirm = await _showExitConfirmation();
          if (!confirm) return;
        }

        if (await _controller.canGoBack()) {
          await _controller.goBack();
        } else {
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          titleSpacing: 0,
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'find_in_page'.tr(),
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  onChanged: (val) => _findInPage(val),
                  onSubmitted: (val) => _findInPage(val),
                )
              : Text('$langCode.wikipedia.org'),
          actions: [
            if (_isSearching) ...[
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up),
                onPressed: () =>
                    _findInPage(_searchController.text, backward: true),
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down),
                onPressed: () => _findInPage(_searchController.text),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isSearching = false;
                    _searchController.clear();
                  });
                },
              ),
            ] else ...[
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => setState(() => _isSearching = true),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => _controller.reload(),
              ),
            ],
          ],
        ),
        bottomNavigationBar: const CustomBottomNavBar(),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
