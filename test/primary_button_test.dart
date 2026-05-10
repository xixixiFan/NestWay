import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solotrip/widgets/primary_button.dart';

void main() {
  group('PrimaryButton Widget Tests', () {
    testWidgets('PrimaryButton should render with correct text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PrimaryButton(
                text: '测试按钮',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('测试按钮'), findsOneWidget);
    });

    testWidgets('PrimaryButton should have circular shape', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PrimaryButton(
                text: '测试',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.decoration, isA<BoxDecoration>());
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.shape, equals(BoxShape.circle));
    });

    testWidgets('PrimaryButton should have yellow background color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PrimaryButton(
                text: '测试',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(const Color(0xFFFFE066)));
    });

    testWidgets('PrimaryButton should call onPressed when tapped', (WidgetTester tester) async {
      bool wasPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PrimaryButton(
                text: '测试',
                onPressed: () {
                  wasPressed = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PrimaryButton));
      await tester.pumpAndSettle();

      expect(wasPressed, isTrue);
    });

    testWidgets('PrimaryButton should work with null onPressed', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PrimaryButton(
                text: '测试',
                onPressed: null,
              ),
            ),
          ),
        ),
      );

      expect(find.text('测试'), findsOneWidget);
    });

    testWidgets('PrimaryButton should respect custom size', (WidgetTester tester) async {
      const customSize = 200.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PrimaryButton(
                text: '测试',
                size: customSize,
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.constraints?.maxWidth, equals(customSize));
      expect(container.constraints?.maxHeight, equals(customSize));
    });
  });
}
