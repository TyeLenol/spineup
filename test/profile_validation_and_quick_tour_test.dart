import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:spineup/models/profile_data.dart';
import 'package:spineup/screens/profile_setup/steps/step_curve.dart';
import 'package:spineup/widgets/quick_tour.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Cobb angle accepts blank and 0–180 but rejects outside values', (
    tester,
  ) async {
    var latestValidity = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StepCurve(
              initialData: const ProfileData(),
              onSave: (_) {},
              onValidityChanged: (valid) => latestValidity = valid,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final primaryField = find.byType(TextField).first;
    expect(latestValidity, isTrue);

    await tester.enterText(primaryField, '181');
    await tester.pump();
    expect(find.text('Enter a number from 0 to 180°.'), findsOneWidget);
    expect(latestValidity, isFalse);

    await tester.enterText(primaryField, '180');
    await tester.pump();
    expect(find.text('Enter a number from 0 to 180°.'), findsNothing);
    expect(latestValidity, isTrue);
  });

  testWidgets('quick tour entry exposes an optional start and later action', (
    tester,
  ) async {
    var started = false;
    var deferred = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuickTourEntryCard(
            onStart: () => started = true,
            onLater: () => deferred = true,
          ),
        ),
      ),
    );

    expect(find.text('Want a quick look around?'), findsOneWidget);
    await tester.tap(find.text('Show me around'));
    await tester.pump();
    expect(started, isTrue);

    await tester.tap(find.text('Maybe later'));
    await tester.pump();
    expect(deferred, isTrue);
  });

  testWidgets('quick tour advances through four pointers and can finish', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showQuickTour(context),
            child: const Text('Open tour'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open tour'));
    await tester.pumpAndSettle();
    expect(find.text('Start with today'), findsOneWidget);
    expect(find.text('1 of 4'), findsOneWidget);

    for (final expected in [
      ('Capture what matters', '2 of 4'),
      ('Look back on your journey', '3 of 4'),
      ('Learn at your pace', '4 of 4'),
    ]) {
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text(expected.$1), findsOneWidget);
      expect(find.text(expected.$2), findsOneWidget);
    }

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Learn at your pace'), findsNothing);
    expect(await QuickTourService.hasSeen(), isTrue);
  });
}
