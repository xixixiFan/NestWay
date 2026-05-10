import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solotrip/pages/sos/sos_history_page.dart';
import 'package:solotrip/widgets/app_bottom_nav.dart';

void main() {
  group('SosHistoryPage Tests', () {
    testWidgets('SosHistoryPage should display title after loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SosHistoryPage(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('求助历史'), findsOneWidget);
    });

    testWidgets('SosHistoryPage should display history records after loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SosHistoryPage(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('语音通话'), findsOneWidget);
      expect(find.text('短信'), findsOneWidget);
      expect(find.text('视频通话'), findsOneWidget);
    });

    testWidgets('SosHistoryPage should have back button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SosHistoryPage(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('SosHistoryPage should display location descriptions', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SosHistoryPage(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('东京涩谷站附近'), findsOneWidget);
      expect(find.text('新宿歌舞伎町'), findsOneWidget);
      expect(find.text('池袋西口'), findsOneWidget);
    });

    testWidgets('SosHistoryPage should have bottom navigation', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SosHistoryPage(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(AppBottomNav), findsOneWidget);
    });
  });
}
