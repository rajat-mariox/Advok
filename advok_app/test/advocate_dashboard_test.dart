import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advok_app/Screens/Screens/AdvocateDashboardScreen/advocate_dashboard_screen.dart';

void main() {
  testWidgets('dashboard renders its empty states when the API is unreachable',
      (tester) async {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // flutter_test blocks real HTTP, so bookings/cases fail to load and the
    // dashboard must fall back to its empty states without crashing.
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AdvocateDashboardScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('No new requests'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^\d+ New$')), findsNothing);
  });
}
