import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../Screens/Screens/MessagesScreen/messages_screen.dart';
import '../Screens/Screens/NotificationScreen/notification_screen.dart';
import '../Utils/AppColors/app_colors.dart';
import 'api_service.dart';

/// App-wide keys so push taps (which arrive outside any widget) can open a
/// screen or show a snackbar. Wired into MaterialApp in main.dart.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> appMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// Phone push notifications via Firebase Cloud Messaging.
///
/// Firebase is configured from the backend (GET /auth/config, values in
/// backend/.env), so no google-services files are bundled. When the backend
/// has no Firebase config the service stays idle and the app works exactly
/// as before (in-app notifications + live updates).
class PushService {
  PushService._();

  static final PushService instance = PushService._();

  bool _starting = false;
  bool _ready = false;
  String? _token;
  String? _registeredForUser;

  /// Called whenever an authenticated request is made: sets Firebase up
  /// once, asks for permission, and registers this device for the current
  /// user. Cheap to call repeatedly.
  Future<void> ensureRegistered() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    final userId = Session.userId;
    if (userId == null || Session.token == null) return;
    if (_ready && _registeredForUser == userId) return;
    if (_starting) return;
    _starting = true;
    try {
      if (!_ready) {
        final ok = await _initFirebase();
        if (!ok) return;
        _ready = true;
      }
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      if (Platform.isIOS) {
        // iOS needs the APNs token before FCM can issue its own.
        await messaging.getAPNSToken();
      }
      final token = await messaging.getToken();
      if (token == null) return;
      _token = token;
      await ApiService.registerPushToken(token, Platform.isIOS ? 'ios' : 'android');
      _registeredForUser = userId;
    } catch (_) {
      // Push is best-effort; the app keeps working without it.
    } finally {
      _starting = false;
    }
  }

  /// Stops pushes to this device (logout). Uses the auth token still held
  /// by the caller, so call it before the session is cleared.
  Future<void> unregister() async {
    final token = _token;
    _registeredForUser = null;
    if (token == null) return;
    try {
      // Runs synchronously up to its first await, so it reads the auth
      // token before Session.clear() drops it.
      await ApiService.unregisterPushToken(token);
    } catch (_) {}
  }

  Future<bool> _initFirebase() async {
    if (Firebase.apps.isNotEmpty) {
      _wireHandlers();
      return true;
    }
    final config = await ApiService.fetchAuthConfig();
    final fb = config['firebase'] as Map<String, dynamic>?;
    if (fb == null) return false;
    final platform =
        (Platform.isIOS ? fb['ios'] : fb['android']) as Map<String, dynamic>?;
    if (platform == null) return false;
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: platform['apiKey'] as String? ?? '',
        appId: platform['appId'] as String? ?? '',
        messagingSenderId: fb['messagingSenderId'] as String? ?? '',
        projectId: fb['projectId'] as String? ?? '',
      ),
    );
    _wireHandlers();
    return true;
  }

  void _wireHandlers() {
    final messaging = FirebaseMessaging.instance;
    // iOS: show the banner even while the app is open.
    messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    // Android shows nothing for foreground pushes; the screens already
    // update live, so a light snackbar is enough.
    FirebaseMessaging.onMessage.listen((m) {
      final n = m.notification;
      if (n == null || !Platform.isAndroid) return;
      appMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            [n.title, n.body].whereType<String>().join(' — '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(label: 'View', onPressed: () => _open(m)),
        ),
      );
    });
    FirebaseMessaging.onMessageOpenedApp.listen(_open);
    messaging.getInitialMessage().then((m) {
      if (m != null) {
        // Wait for the first screen (splash → home) before navigating.
        Future.delayed(const Duration(seconds: 2), () => _open(m));
      }
    });
    messaging.onTokenRefresh.listen((t) {
      _token = t;
      if (Session.token != null) {
        ApiService.registerPushToken(t, Platform.isIOS ? 'ios' : 'android')
            .catchError((_) {});
      }
    });
  }

  /// Opens the screen a notification is about.
  void _open(RemoteMessage m) {
    final nav = appNavigatorKey.currentState;
    if (nav == null || Session.token == null) return;
    final isMessage = m.data['type'] == 'message';
    nav.push(
      MaterialPageRoute(
        builder: (ctx) => isMessage
            ? Scaffold(
                backgroundColor: AppColors.white,
                body: SafeArea(
                  child: MessagesScreen(onBack: () => Navigator.of(ctx).pop()),
                ),
              )
            : const NotificationScreen(),
      ),
    );
  }
}
