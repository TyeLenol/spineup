import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spineup/screens/navigation_shell.dart';

void main() {
  testWidgets('NavigationShell displays tabs and switches screens on tap', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NavigationShell(),
      ),
    );

    // Initial screen should be Today
    expect(find.text('Today'), findsNWidgets(2)); // Nav item label + body text
    expect(find.text('My Journey'), findsOneWidget); // Nav item label
    expect(find.text('Community'), findsOneWidget); // Nav item label

    // Tap My Journey tab
    await tester.tap(find.byIcon(Icons.show_chart_outlined));
    await tester.pumpAndSettle();

    expect(find.text('My Journey'), findsNWidgets(2)); // Nav item label + body text

    // Tap Community tab
    await tester.tap(find.byIcon(Icons.people_outline_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Community'), findsNWidgets(2)); // Nav item label + body text
  });
}
