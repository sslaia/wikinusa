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

    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Theme.of(context).scaffoldBackgroundColor)
      ..loadRequest(
        Uri.parse('https://$langCode.m.wikipedia.org/wiki/$encodedTitle'),
      );

    return WebViewWidget(controller: controller);
  }
}
