import 'package:google_sign_in/google_sign_in.dart';

import 'api_service.dart';

/// OAuth 2.0 **Web application** client ID from Google Cloud Console.
/// The app requests its Google ID token for this audience and the backend
/// verifies against the same ID (backend env var GOOGLE_CLIENT_ID).
///
/// Replace the default below with your real ID, or pass it at run time:
/// flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com
const String _serverClientId = String.fromEnvironment(
  'GOOGLE_SERVER_CLIENT_ID',
  defaultValue: 'REPLACE_ME.apps.googleusercontent.com',
);

/// Runs the native Google sign-in flow and logs the user in on the backend.
class GoogleAuthService {
  GoogleAuthService._();

  static bool _initialized = false;

  /// Returns true when the user is logged in ([Session] is filled), or false
  /// when they dismissed the Google account picker. Throws [ApiException]
  /// for real failures so callers can show the message in a snackbar.
  static Future<bool> signIn({String? country}) async {
    if (_serverClientId.startsWith('REPLACE_ME')) {
      throw ApiException(
        'Google login is not set up yet: paste your Web client ID in '
        'google_auth_service.dart (see the comment at the top of that file).',
      );
    }
    final signIn = GoogleSignIn.instance;
    if (!_initialized) {
      try {
        await signIn.initialize(serverClientId: _serverClientId);
      } catch (_) {
        throw ApiException(
          'Google sign-in is not available. Check the app configuration.',
        );
      }
      _initialized = true;
    }

    final GoogleSignInAccount account;
    try {
      account = await signIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return false;
      }
      // Surface Google's own reason — e.g. a clientMismatch/providerConfiguration
      // error means the OAuth client (package name / SHA-1) doesn't match.
      final detail = e.description == null || e.description!.isEmpty
          ? e.code.name
          : '${e.code.name}: ${e.description}';
      throw ApiException('Google sign-in failed ($detail)');
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw ApiException('Google did not return a sign-in token.');
    }
    await ApiService.loginWithGoogle(idToken, country: country);
    return true;
  }
}
