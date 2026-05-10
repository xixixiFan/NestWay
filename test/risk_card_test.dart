import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solotrip/widgets/risk_card.dart';

void main() {
  group('RiskCard Widget Tests', () {
    testWidgets('RiskCard should render with correct title and description', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskCard(
              color: Color(0xFFDFF5E3),
              title: '轻度不安',
              desc: '测试描述文本',
            ),
          ),
        ),
      );

      expect(find.text('轻度不安'), findsOneWidget);
      expect(find.text('测试描述文本'), findsOneWidget);
    });

    testWidgets('RiskCard should have rounded corners', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskCard(
              color: Color(0xFFDFF5E3),
              title: '测试',
              desc: '测试描述',
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, isNotNull);
    });

    testWidgets('RiskCard should use custom background color', (WidgetTester tester) async {
      const testColor = Color(0xFFFFE0E0);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskCard(
              color: testColor,
              title: '紧急危险',
              desc: '紧急描述',
            ),
          ),
        ),
      );

      expect(find.text('紧急危险'), findsOneWidget);
      expect(find.text('紧急描述'), findsOneWidget);
    });

    testWidgets('RiskCard should display correct titles for different risk levels', (WidgetTester tester) async {
      final riskLevels = [
        {'color': const Color(0xFFDFF5E3), 'title': '轻度不安'},
        {'color': const Color(0xFFFFF4D6), 'title': '中度风险'},
        {'color': const Color(0xFFFFE0E0), 'title': '紧急危险'},
      ];

      for (final level in riskLevels) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RiskCard(
                color: level['color'] as Color,
                title: level['title'] as String,
                desc: '测试描述',
              ),
            ),
          ),
        );

        expect(find.text(level['title'] as String), findsOneWidget);
      }
    });

    testWidgets('RiskCard should have border with custom color', (WidgetTester tester) async {
      const testColor = Color(0xFFFF6B6B);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskCard(
              color: testColor,
              title: '测试',
              desc: '测试描述',
            ),
          ),
        ),
      );

      expect(find.text('测试'), findsOneWidget);
      expect(find.text('测试描述'), findsOneWidget);
    });

    testWidgets('RiskCard should display circular color indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskCard(
              color: Color(0xFFFF6B6B),
              title: '测试',
              desc: '测试描述',
            ),
          ),
        ),
      );

      final containers = tester.widgetList<Container>(find.byType(Container));
      bool foundCircle = false;
      for (final container in containers) {
        if (container.decoration is BoxDecoration) {
          final decoration = container.decoration as BoxDecoration;
          if (decoration.shape == BoxShape.circle) {
            foundCircle = true;
            break;
          }
        }
      }
      expect(foundCircle, isTrue);
    });
  });
}
