import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spineup/models/user_profile.dart';
import 'package:spineup/screens/daily_check_in_screen.dart';

void main() {
  testWidgets('DailyCheckInScreen renders 5-point mood chips and controls', (
    WidgetTester tester,
  ) async {
    const profile = UserProfile(
      presetId: 'preset_sun',
      name: 'Alex',
      diagnosis: 'Thoracic Curve',
      braceStatus: 'Yes',
      ageRange: '13-17',
    );

    await tester.pumpWidget(
      const MaterialApp(home: DailyCheckInScreen(userProfile: profile)),
    );

    // Verify Title and View past entries button
    expect(find.text('Daily Check-In'), findsOneWidget);
    expect(find.byTooltip('View past entries'), findsOneWidget);

    // Unanswered health fields are explicit rather than silently prefilled.
    expect(find.text('Not recorded'), findsOneWidget);

    // Verify 5-point mood scale options
    expect(find.text('Awful'), findsOneWidget);
    expect(find.text('Low'), findsOneWidget);
    expect(find.text('Okay'), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);
    expect(find.text('Great'), findsOneWidget);

    // Select 'Great' mood
    await tester.tap(find.text('Great'));
    await tester.pumpAndSettle();

    // Verify the recording CTA exists
    expect(find.text('Record check-in'), findsOneWidget);
  });
}
