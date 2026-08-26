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

  testWidgets('page guide focuses real targets and teaches a usable flow', (
    tester,
  ) async {
    final registry = QuickTourTargetRegistry();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Column(
              children: [
                TextButton(
                  onPressed: () => showPageQuickTourIfNeeded(
                    context,
                    page: QuickTourPage.today,
                    registry: registry,
                    force: true,
                  ),
                  child: const Text('Open guide'),
                ),
                quickTourTarget(
                  registry: registry,
                  page: QuickTourPage.today,
                  id: 'check-in',
                  child: const Text('Check-in area'),
                ),
                quickTourTarget(
                  registry: registry,
                  page: QuickTourPage.today,
                  id: 'routine',
                  child: const Text('Routine area'),
                ),
                quickTourTarget(
                  registry: registry,
                  page: QuickTourPage.today,
                  id: 'today-progress',
                  child: const Text('Progress area'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open guide'));
    await tester.pumpAndSettle();
    expect(find.text('Start with a check-in'), findsOneWidget);
    expect(find.text('1 of 3'), findsOneWidget);
    expect(find.text('Skip guide'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Keep movement close'), findsOneWidget);
    expect(find.text('2 of 3'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Notice your momentum'), findsOneWidget);
    expect(find.text('3 of 3'), findsOneWidget);

    await tester.tap(find.text('Finish guide'));
    await tester.pumpAndSettle();
    expect(find.text('Notice your momentum'), findsNothing);
    expect(await QuickTourService.hasSeen(QuickTourPage.today), isTrue);
  });

  test('tutorial completion is independent per page', () async {
    await QuickTourService.markSeen(QuickTourPage.today);

    expect(await QuickTourService.hasSeen(QuickTourPage.today), isTrue);
    expect(await QuickTourService.hasSeen(QuickTourPage.journey), isFalse);
  });
}
