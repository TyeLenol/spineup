import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spineup/widgets/action_reward_feedback.dart';

void main() {
  testWidgets('completion feedback leads with the care action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showActionRewardFeedback(
                  context,
                  title: 'Check-in saved',
                  xpAwarded: 25,
                  dailyBonusAwarded: true,
                ),
                child: const Text('Complete'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Complete'));
    await tester.pump(const Duration(milliseconds: 320));

    expect(find.text('Check-in saved'), findsOneWidget);
    expect(find.text('+25 XP'), findsOneWidget);
    expect(find.text('Saved · daily bonus included'), findsOneWidget);
  });
}
