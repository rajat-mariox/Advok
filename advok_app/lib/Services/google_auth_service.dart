import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import 'api_service.dart';

/// Optional build-time override of the Google client IDs. Normally empty:
/// the IDs come from the backend (GET /auth/config, backend/.env), so a
/// credential change never needs a new app build.
const String _envServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
const String _envIosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

/// Runs the native Google sign-in flow and logs the user in on the backend.
class GoogleAuthService {
  GoogleAuthService._();

  static bool _initialized = false;

  /// Returns true when the user is logged in ([Session] is filled), or false
  /// when they dismissed the Google account picker. Throws [ApiException]
  /// for real failures so callers can show the message in a snackbar.
  static Future<bool> signIn({String? country}) async {
    final signIn = GoogleSignIn.instance;
    if (!_initialized) {
      var serverClientId = _envServerClientId;
      var iosClientId = _envIosClientId;
      if (serverClientId.isEmpty) {
        final config = await ApiService.fetchAuthConfig();
        final google = config['google'] as Map<String, dynamic>? ?? const {};
        serverClientId = google['webClientId'] as String? ?? '';
        iosClientId = iosClientId.isNotEmpty ? iosClientId : (google['iosClientId'] as String? ?? '');
      }
      if (serverClientId.isEmpty) {
        throw ApiException(
          'Google login is not set up yet. Add GOOGLE_CLIENT_ID to backend/.env '
          'and restart the server.',
        );
      }
      try {
        await signIn.initialize(
          serverClientId: serverClientId,
          clientId: (!kIsWeb && Platform.isIOS && iosClientId.isNotEmpty) ? iosClientId : null,
        );
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
