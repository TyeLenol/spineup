import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spineup/models/learn_topic.dart';
import 'package:spineup/screens/learn_screen.dart';

void main() {
  test('canonical topic lookup returns one topic and rejects unknown IDs', () {
    final cobbAngle = learnTopicById('cobb-angle');

    expect(cobbAngle, isNotNull);
    expect(cobbAngle!.title, 'Cobb angle');
    expect(learnTopicById('not-a-real-topic'), isNull);
  });

  testWidgets('Learn library opens a topic detail page', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: LearnScreen())),
    );

    expect(find.text('Learn'), findsOneWidget);
    expect(find.text('Cobb angle'), findsOneWidget);

    await tester.tap(find.text('Cobb angle'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'A number from an imaging report that describes a spinal curve measurement.',
      ),
      findsOneWidget,
    );
    expect(find.byTooltip('Close'), findsOneWidget);
    expect(find.text('Sources'), findsOneWidget);
  });

  testWidgets('contextual help opens short explanation and Learn more page', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: ContextualHelpIcon(topicId: 'cobb-angle')),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Learn about Cobb angle'));
    await tester.pumpAndSettle();

    expect(find.text('Learn more'), findsOneWidget);
    expect(
      find.text(
        'A number from an imaging report that describes a spinal curve measurement.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Learn more'));
    await tester.pumpAndSettle();

    expect(find.text('Sources'), findsOneWidget);
    expect(find.text('Scoliosis Research Society'), findsNothing);
    expect(find.text('SOSORT'), findsOneWidget);
  });
}
