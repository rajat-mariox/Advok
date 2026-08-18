import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'api_service.dart';

/// Runs the native Sign in with Apple flow and logs the user in on the
/// backend. The native sheet exists only on Apple devices — on Android the
/// button is visible but explains that Apple login needs an iPhone.
///
/// Requires the "Sign in with Apple" capability on the App ID (Apple
/// Developer portal + Xcode Signing & Capabilities tab).
class AppleAuthService {
  AppleAuthService._();

  /// Returns true when the user is logged in ([Session] is filled), or false
  /// when they dismissed the Apple sign-in sheet. Throws [ApiException] for
  /// real failures so callers can show the message.
  static Future<bool> signIn({String? country}) async {
    if (kIsWeb || !(Platform.isIOS || Platform.isMacOS)) {
      throw ApiException(
        'Apple login works on iPhone and iPad. On this device, please use '
        'Google or phone number login.',
      );
    }
    final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return false;
      throw ApiException('Apple sign-in failed (${e.code.name})');
    } on SignInWithAppleNotSupportedException {
      throw ApiException('Apple sign-in is not available on this device.');
    }

    final identityToken = credential.identityToken;
    if (identityToken == null) {
      throw ApiException('Apple did not return a sign-in token.');
    }

    // Apple provides the name only on the first sign-in — pass it along so
    // the backend can store it; it will never be available again.
    final fullName = [credential.givenName, credential.familyName]
        .whereType<String>()
        .where((part) => part.trim().isNotEmpty)
        .join(' ');

    await ApiService.loginWithApple(
      identityToken,
      fullName: fullName.isEmpty ? null : fullName,
      country: country,
    );
    return true;
  }
}
