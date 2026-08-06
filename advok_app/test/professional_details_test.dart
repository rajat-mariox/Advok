import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:advok_app/Screens/AdvocateRegistration/advocate_registration_models.dart';
import 'package:advok_app/Screens/AdvocateRegistration/professional_details_screen.dart';

void main() {
  testWidgets('Continue enables and navigates after filling the form',
      (tester) async {
    // Tall viewport so every form field is on screen at once.
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: ProfessionalDetailsScreen(advocateType: AdvocateType.junior),
      ),
    );
    await tester.pumpAndSettle();

    // Junior flow shows 5 text fields: full name, senior name, email,
    // bar number, practice area.
    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(5));

    await tester.enterText(fields.at(0), 'Mithu');
    await tester.enterText(fields.at(1), 'Amit');
    await tester.enterText(fields.at(2), 'mithu@gmail.com');
    await tester.enterText(fields.at(3), 'NY2135');
    await tester.pump();

    // Pick the court from the bottom sheet.
    await tester.tap(find.text('Select court…'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('High Court'));
    await tester.pumpAndSettle();

    // Footer button should now be fully opaque (enabled).
    final opacity = tester.widget<Opacity>(
      find.ancestor(
        of: find.text('Continue'),
        matching: find.byType(Opacity),
      ),
    );
    expect(opacity.opacity, 1.0);

    // Tapping Continue should push the schedule step.
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('My Schedule'), findsOneWidget);
  });

  testWidgets('field text survives being scrolled out of the lazy ListView',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ProfessionalDetailsScreen(advocateType: AdvocateType.junior),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Mithu');
    await tester.pump();

    // Scroll the field out of view (ListView disposes it) and back.
    final list = find.byType(ListView);
    await tester.drag(list, const Offset(0, -800));
    await tester.pumpAndSettle();
    await tester.drag(list, const Offset(0, 800));
    await tester.pumpAndSettle();

    expect(find.text('Mithu'), findsOneWidget);
  });
}
