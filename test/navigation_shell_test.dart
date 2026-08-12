import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:spineup/screens/navigation_shell.dart';
import 'package:spineup/screens/today_screen.dart';
import 'package:spineup/screens/my_journey_screen.dart';
import 'package:spineup/screens/community_screen.dart';
import 'package:spineup/screens/me_screen.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('NavigationShell displays 4 tabs and switches screens on tap', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NavigationShell(),
      ),
    );
    // Allow the initial screen to settle (includes Database futures and animations)
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    // Initial screen should be Today
    expect(find.byType(TodayScreen), findsOneWidget);
    expect(find.byType(MyJourneyScreen), findsNothing);
    expect(find.byType(CommunityScreen), findsNothing);
    expect(find.byType(MeScreen), findsNothing);

    // Tap My Journey tab
    await tester.tap(find.byIcon(Icons.show_chart_outlined));
    await tester.pump(const Duration(seconds: 1)); // Transition animation
    await tester.pump(const Duration(seconds: 1)); // Content loading

    expect(find.byType(MyJourneyScreen), findsOneWidget);
    expect(find.byType(TodayScreen), findsNothing);

    // Tap Community tab
    await tester.tap(find.byIcon(Icons.people_outline_rounded));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(CommunityScreen), findsOneWidget);
    expect(find.byType(MyJourneyScreen), findsNothing);

    // Tap Me tab
    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(MeScreen), findsOneWidget);
    expect(find.byType(CommunityScreen), findsNothing);
  });
}
