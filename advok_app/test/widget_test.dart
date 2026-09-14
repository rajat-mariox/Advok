import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:advok_app/main.dart';
import 'package:advok_app/Screens/SelectCountryScreen/select_country_screen.dart';
import 'package:advok_app/Screens/SplashScreen/splash_screen.dart';

void main() {
  testWidgets('App shows the splash screen with the logo', (tester) async {
    // No saved session on disk — splash should land on Select Country.
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const AdvokApp());

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    // After the branding delay the app moves on to country selection.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byType(SelectCountryScreen), findsOneWidget);
  });
}
