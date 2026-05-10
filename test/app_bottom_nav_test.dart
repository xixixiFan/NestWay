import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solotrip/widgets/app_bottom_nav.dart';

void main() {
  group('AppBottomNav Widget Tests', () {
    testWidgets('AppBottomNav should render with currentIndex 0', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppBottomNav(currentIndex: 0),
          ),
        ),
      );

      expect(find.byType(AppBottomNav), findsOneWidget);
    });

    testWidgets('AppBottomNav should display map icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppBottomNav(currentIndex: 0),
          ),
        ),
      );

      expect(find.byIcon(Icons.map), findsOneWidget);
    });

    testWidgets('AppBottomNav should display person icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppBottomNav(currentIndex: 0),
          ),
        ),
      );

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('AppBottomNav should display SOS text in CircleAvatar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppBottomNav(currentIndex: 0),
          ),
        ),
      );

      expect(find.text('SOS'), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('AppBottomNav should have Container decoration', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppBottomNav(currentIndex: 0),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.decoration, isA<BoxDecoration>());
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.white));
    });

    testWidgets('AppBottomNav should highlight map icon when currentIndex is 0', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppBottomNav(currentIndex: 0),
          ),
        ),
      );

      final mapIcon = tester.widget<Icon>(find.byIcon(Icons.map));
      expect(mapIcon.color, equals(Colors.black));
    });

    testWidgets('AppBottomNav should have 3 GestureDetector items', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppBottomNav(currentIndex: 0),
          ),
        ),
      );

      expect(find.byType(GestureDetector), findsNWidgets(3));
    });
  });
}
