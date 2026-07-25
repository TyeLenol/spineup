import 'package:flutter_test/flutter_test.dart';
import 'package:spineup/main.dart';
import 'package:spineup/screens/splash_screen.dart';

void main() {
  testWidgets('SpineUpApp boots up with SplashScreen and transitions to NavigationShell', (WidgetTester tester) async {
    await tester.pumpWidget(const SpineUpApp());
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('SpineUp'), findsOneWidget);

    // Tap splash screen to skip directly to NavigationShell
    await tester.tap(find.byType(SplashScreen));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsWidgets);
  });
}
