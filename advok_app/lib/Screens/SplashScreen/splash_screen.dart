import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../Utils/AppColors/app_colors.dart';
import '../SelectCountryScreen/select_country_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const double _logoSize = 128;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SelectCountryScreen()),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
