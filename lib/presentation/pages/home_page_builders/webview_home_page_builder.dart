import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:wikinusa/domain/entities/wiki_project.dart';
import 'package:wikinusa/presentation/providers/webview_warning_provider.dart';
import 'home_page_builder.dart';

class WebViewHomePageBuilder implements HomePageBuilder {
  @override
  Widget build(
    BuildContext context,
    String pageTitle,
    String html,
    String langCode,
    Orientation orientation,
    WikiProject project,
  ) {
    return Consumer(
      builder: (context, ref, child) {
        // Logic to show snackbar only once per language code
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final shownSets = ref.read(webViewWarningProvider);

          if (!shownSets.contains(langCode)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'webview_mobile_warning'.tr(),
                  style: const TextStyle(fontSize: 14, fontFamily: 'sans'),
                ),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'OK',
                  onPressed: () =>
                      ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                ),
              ),
            );

            // Mark this language as "shown"
            ref
                .read(webViewWarningProvider.notifier)
                .update((state) => {...state, langCode});
          }
        });

        final encodedTitle = Uri.encodeComponent(
          pageTitle.replaceAll(' ', '_'),
        );

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
                style.innerHTML = '.header-container, .header-chrome, .mw-footer, .minerva-footer { display: none !important; }
                a.new, a[href*="action=edit"] { color: #a77364 !important; }
                ';
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
      },
    );
  }
}
