import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solotrip/widgets/sos_button.dart';

void main() {
  group('SosButton Widget Tests', () {
    testWidgets('SosButton should render with default text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SosButton(
                onTriggered: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('长按求助'), findsOneWidget);
    });

    testWidgets('SosButton should render with custom text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SosButton(
                onTriggered: () {},
                text: '自定义求助文本',
              ),
            ),
          ),
        ),
      );

      expect(find.text('自定义求助文本'), findsOneWidget);
    });

    testWidgets('SosButton should display SOS icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SosButton(
                onTriggered: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.sos), findsOneWidget);
    });

    testWidgets('SosButton should have long press gesture detector', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SosButton(
                onTriggered: () {},
              ),
            ),
          ),
        ),
      );

      final gestureDetector = tester.widget<GestureDetector>(find.byType(GestureDetector));
      expect(gestureDetector.onLongPressStart, isNotNull);
    });

    testWidgets('SosButton should respect custom size', (WidgetTester tester) async {
      const customSize = 200.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SosButton(
                onTriggered: () {},
                size: customSize,
              ),
            ),
          ),
        ),
      );

      final animatedContainer = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(SosButton),
          matching: find.byType(AnimatedContainer),
        ),
      );

      expect(animatedContainer.constraints?.maxWidth, equals(customSize));
      expect(animatedContainer.constraints?.maxHeight, equals(customSize));
    });

    testWidgets('SosButton callback should be called after countdown', (WidgetTester tester) async {
      bool wasTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SosButton(
                onTriggered: () {
                  wasTriggered = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.longPress(find.byType(GestureDetector));

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      expect(wasTriggered, isTrue);
    });
  });
}
