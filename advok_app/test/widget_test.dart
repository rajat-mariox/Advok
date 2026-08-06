import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advok_app/main.dart';
import 'package:advok_app/Screens/SplashScreen/splash_screen.dart';

void main() {
  testWidgets('App shows the splash screen with the logo', (tester) async {
    await tester.pumpWidget(const AdvokApp());

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });
}
