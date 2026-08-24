import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../Services/api_service.dart';
import '../../Services/post_login_navigator.dart';
import '../../Utils/AppColors/app_colors.dart';
import '../SelectCountryScreen/select_country_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const double _logoSize = 128;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    // Restore any saved login while the branding delay runs.
    final restoring = _restoreSession();
    await Future<void>.delayed(const Duration(seconds: 2));
    final restored = await restoring;
    if (!mounted) return;
    if (restored) {
      PostLoginNavigator.navigateAfterLogin(context);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SelectCountryScreen()),
      );
    }
  }

  /// True when a saved login exists and is still usable. Refreshes the
  /// user's role/status from the backend; an expired or revoked token
  /// (401) clears the session, while a network hiccup keeps the saved
  /// login so the user isn't logged out for being offline.
  Future<bool> _restoreSession() async {
    if (!await Session.restore()) return false;
    try {
      await ApiService.fetchMe();
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        Session.clear();
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.white,
      ),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: Center(
          child: ClipRRect(
            // Same corner ratio as the app icon (34/128).
            borderRadius: BorderRadius.circular(_logoSize * 34 / 128),
            child: Image.asset(
              'assets/images/app_logo.png',
              width: _logoSize,
              height: _logoSize,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
