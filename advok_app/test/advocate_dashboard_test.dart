import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advok_app/Screens/Screens/AdvocateDashboardScreen/advocate_dashboard_screen.dart';

Finder _svgAsset(String assetName) => find.byWidgetPredicate(
      (widget) =>
          widget is SvgPicture &&
          widget.bytesLoader is SvgAssetLoader &&
          (widget.bytesLoader as SvgAssetLoader).assetName == assetName,
    );

void main() {
  testWidgets('declining client requests updates badge and empties the list',
      (tester) async {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AdvocateDashboardScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('3 New'), findsOneWidget);
    expect(find.text('Alex Thompson'), findsOneWidget);

    // Decline the first request via its ✕ button.
    await tester.tap(_svgAsset('assets/icons/ic_clear.svg').first);
    await tester.pumpAndSettle();

    expect(find.text('Alex Thompson'), findsNothing);
    expect(find.text('2 New'), findsOneWidget);

    // Resolve the remaining two.
    await tester.tap(_svgAsset('assets/icons/ic_clear.svg').first);
    await tester.pumpAndSettle();
    await tester.tap(_svgAsset('assets/icons/ic_clear.svg').first);
    await tester.pumpAndSettle();

    expect(find.text('No new requests'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^\d+ New$')), findsNothing);
  });
}
