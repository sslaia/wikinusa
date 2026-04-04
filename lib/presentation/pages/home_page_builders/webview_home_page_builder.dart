import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'home_page_builder.dart';

class WebViewHomePageBuilder implements HomePageBuilder {
  @override
  Widget build(
    BuildContext context,
    String pageTitle,
    String html,
    String langCode,
    Orientation orientation,
  ) {
    final encodedTitle = Uri.encodeComponent(pageTitle.replaceAll(' ', '_'));

    final controller = WebViewController();

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Theme.of(context).scaffoldBackgroundColor)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            // Hide header and footer elements after page finishes loading
            controller.runJavaScript("""
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
      ..loadRequest(
        Uri.parse('https://$langCode.m.wikipedia.org/wiki/$encodedTitle'),
      );

    return WebViewWidget(controller: controller);
  }
}
