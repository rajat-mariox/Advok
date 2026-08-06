import 'package:flutter/material.dart';

import 'Screens/SplashScreen/splash_screen.dart';
import 'Utils/AppColors/app_colors.dart';

void main() {
  runApp(const AdvokApp());
}

class AdvokApp extends StatelessWidget {
  const AdvokApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Advok',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.black),
        fontFamily: 'Inter',
        useMaterial3: true,
      ),
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        // Scale every hardcoded fontSize with the device (shortest side vs
        // the 390dp design width) and clamp the user's system font scale so
        // accessibility sizes can't overflow fixed-height layouts.
        final deviceScale =
            (mq.size.shortestSide / 390.0).clamp(0.85, 1.20).toDouble();
        final userScale =
            mq.textScaler.scale(1.0).clamp(0.85, 1.20).toDouble();
        return MediaQuery(
          data: mq.copyWith(
            textScaler: TextScaler.linear(deviceScale * userScale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const SplashScreen(),
    );
  }
}
