import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Routes/app_routes.dart';
import '../Screens/SelectCountryScreen/select_country_screen.dart';
import 'api_service.dart';
import 'push_service.dart';
import 'session_provider.dart';

/// Shared actions behind the Profile screens (client/attorney, student,
/// firm) so the three stay identical.
class AccountActions {
  AccountActions._();

  /// Profile > Notifications. Missing on older accounts means "on".
  static bool get notificationsEnabled =>
      Session.user?['notificationsEnabled'] != false;

  /// Turns phone push + email on/off on the backend. Returns the new value.
  /// Turning it on also (re)registers this phone for push, which asks for
  /// the Android/iOS permission if it was never granted.
  static Future<bool> setNotifications(bool enabled) async {
    final user = await ApiService.setNotifications(enabled);
    Session.user = user;
    if (enabled) {
      PushService.instance.ensureRegistered().catchError((_) {});
    }
    return enabled;
  }

  /// Profile > Switch User Type: signs out and opens the login screen for
  /// the same country, so the person can sign in with another account.
  static void switchUserType(BuildContext context) {
    final country = countryByName(Session.country);
    context.read<SessionProvider>().logout();
    final nav = Navigator.of(context);
    if (country != null) {
      nav.pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
        arguments: country,
      );
    } else {
      nav.pushNamedAndRemoveUntil(AppRoutes.selectCountry, (route) => false);
    }
  }
}
