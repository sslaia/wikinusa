import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:wikimedia_oauth2/src/wikimedia_login_screen.dart';

void main() {
  setUp(() {
    HttpOverrides.global = null;
  });

  testWidgets('Desktop loopback server intercepts OAuth callback and pops with code', (tester) async {
    await tester.runAsync(() async {
      String? returnedCode;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  returnedCode = await Navigator.push<String>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WikimediaLoginScreen(
                        authorizationUrl: 'https://example.com/auth',
                        redirectUri: 'https://sslaia.github.io/wikinusa/callback',
                      ),
                    ),
                  );
                },
                child: const Text('Start Login'),
              ),
            ),
          ),
        ),
      );

      // Open login screen
      await tester.tap(find.text('Start Login'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(find.byType(WikimediaLoginScreen), findsOneWidget);
      expect(find.text('Wikimedia Authentication'), findsOneWidget);

      // Send HTTP GET request to loopback server (as the GitHub Pages relay would)
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8765/callback?code=test_auth_code_999'),
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(response.headers['access-control-allow-origin'], equals('*'));

      // Allow pop and server shutdown
      await Future.delayed(const Duration(milliseconds: 150));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify screen popped and returned the extracted code
      expect(find.byType(WikimediaLoginScreen), findsNothing);
      expect(returnedCode, equals('test_auth_code_999'));
    });
  });

  testWidgets('Desktop loopback server handles OPTIONS CORS preflight', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WikimediaLoginScreen(
              authorizationUrl: 'https://example.com/auth',
              redirectUri: 'https://sslaia.github.io/wikinusa/callback',
            ),
          ),
        ),
      );

      await tester.pump();
      await Future.delayed(const Duration(milliseconds: 100));

      // Send OPTIONS request to loopback server
      final client = HttpClient();
      final request = await client.openUrl(
        'OPTIONS',
        Uri.parse('http://127.0.0.1:8765/callback'),
      );
      final response = await request.close();

      expect(response.statusCode, HttpStatus.ok);
      expect(response.headers.value('access-control-allow-origin'), equals('*'));
      client.close();
    });
  });
}
