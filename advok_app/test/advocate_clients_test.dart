import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advok_app/Screens/Screens/AdvocateClientsScreen/advocate_clients_screen.dart';
import 'package:advok_app/Screens/Screens/AdvocateClientsScreen/client_directory.dart';
import 'package:advok_app/Screens/Screens/AdvocateDashboardScreen/advocate_dashboard_screen.dart';

Finder _svgAsset(String assetName) => find.byWidgetPredicate(
      (widget) =>
          widget is SvgPicture &&
          widget.bytesLoader is SvgAssetLoader &&
          (widget.bytesLoader as SvgAssetLoader).assetName == assetName,
    );

void main() {
  test('accepted request lands on top of the client directory', () {
    final directory = ClientDirectory.instance;
    final initialCount = directory.clients.length;

    directory.addFromAcceptedRequest(
      name: 'David Park',
      avatar: 'assets/images/img_adv_david.jpg',
      matter: 'White Collar Investigation',
    );

    expect(directory.clients.length, initialCount + 1);
    expect(directory.clients.first.name, 'David Park');
    expect(directory.clients.first.status, ClientStatus.active);
    expect(directory.clients.first.sessions, 0);

    // Re-accepting the same client replaces instead of duplicating.
    directory.addFromAcceptedRequest(
      name: 'David Park',
      avatar: 'assets/images/img_adv_david.jpg',
      matter: 'Fraud Investigation',
    );
    expect(directory.clients.length, initialCount + 1);
    expect(directory.clients.first.matter, 'Fraud Investigation');
  });

  testWidgets('accepting a request on the dashboard shows it in My Clients',
      (tester) async {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AdvocateDashboardScreen())),
    );
    await tester.pumpAndSettle();

    // Accept the first request (Alex Thompson) via its ✓ button.
    await tester.tap(_svgAsset('assets/icons/ic_check.svg').first);
    await tester.pumpAndSettle();
    expect(find.text('2 New'), findsOneWidget);

    // The Clients screen should now list the accepted client on top.
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AdvocateClientsScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alex Thompson'), findsOneWidget);
    expect(find.text('Criminal Defense — DUI'), findsOneWidget);
    expect(find.text('0 sessions'), findsWidgets);
  });
}
