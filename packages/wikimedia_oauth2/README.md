# Wikimedia OAuth2 Package

A modular, reusable Flutter package that handles OAuth 2.0 authentication for Wikimedia APIs.

## Installation in Another App

1. **Copy the Package:**
   Copy the `wikimedia_oauth2` directory into your application's structure (e.g., into a `packages/` folder).

2. **Add to `pubspec.yaml`:**
   Add the package as a path dependency in your main app's `pubspec.yaml`:
   ```yaml
   dependencies:
     flutter:
       sdk: flutter
     wikimedia_oauth2:
       path: packages/wikimedia_oauth2
   ```

3. **Get Dependencies:**
   Run `flutter pub get` in your main application directory.

## Usage Guide

### 1. Instantiate the `AuthService`
Initialize the `AuthService` with your app's Wikimedia Client ID and Redirect URL. You can store these values securely in a `.env` file using a package like `flutter_dotenv`.

```dart
import 'package:wikimedia_oauth2/wikimedia_oauth2.dart';

// Assuming you've loaded your client ID from your environment variables
final authService = AuthService(
  clientId: 'YOUR_WIKIMEDIA_CLIENT_ID',
  redirectUrl: 'https://your-domain.com/oauth2/callback',
);
```

### 2. Perform Login
You can call the login method directly from any UI button. It will automatically handle showing the `WikimediaLoginScreen` webview and completing the authentication flow.

```dart
await authService.login(context);
```

### 3. Check Authentication Status
You can check whether the user is logged in:

```dart
bool isLoggedIn = await authService.isLoggedIn();
if (isLoggedIn) {
  print("User is authenticated!");
}
```

### 4. Fetch the Access Token for API calls
When you need to make authenticated requests to a Wikimedia API, use `getValidAccessToken()`. This automatically handles checking for token expiration and refreshing it if necessary!

```dart
final token = await authService.getValidAccessToken();

if (token != null) {
  final response = await http.get(
    Uri.parse('https://id.wiktionary.org/w/api.php?...'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );
}
```

### 5. Logout
To log the user out and securely clear the stored tokens:

```dart
await authService.logout();
```

## State Management
It is highly recommended to wrap `AuthService` in your preferred state management solution (e.g., `Provider`, `Riverpod`, `Bloc`) within your main app so that your UI can easily rebuild when authentication state changes.
