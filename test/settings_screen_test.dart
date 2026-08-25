import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spineup/screens/settings_screen.dart';

void main() {
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets(
    'renders grouped settings without Android reminder on other platforms',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: SettingsScreen(onReplayQuickTour: () {})),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Preferences'), findsOneWidget);
      expect(find.text('Help & guidance'), findsOneWidget);
      expect(find.text('Privacy & portability'), findsOneWidget);
      expect(find.text('Danger zone'), findsOneWidget);
      expect(find.text('Daily reminder'), findsNothing);
      expect(find.text('Delete all local data'), findsOneWidget);
    },
  );
}
