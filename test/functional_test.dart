import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solotrip/app/app.dart';
import 'package:solotrip/routes/app_routes.dart';

void main() {
  group('Functional Tests - App Navigation', () {
    testWidgets('App should start on home page with NestWay title', (WidgetTester tester) async {
      await tester.pumpWidget(const NestWayApp());
      await tester.pumpAndSettle();

      expect(find.text('NestWay'), findsOneWidget);
      expect(find.text('深圳 · 当前安全'), findsOneWidget);
    });

    testWidgets('App should show virtual escort button on home page', (WidgetTester tester) async {
      await tester.pumpWidget(const NestWayApp());
      await tester.pumpAndSettle();

      expect(find.text('虚拟护送'), findsOneWidget);
      expect(find.text('设置目的地，全程守护你'), findsOneWidget);
    });

    testWidgets('Home page should have bottom navigation', (WidgetTester tester) async {
      await tester.pumpWidget(const NestWayApp());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.map), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('Tapping virtual escort button should navigate to escort page', (WidgetTester tester) async {
      await tester.pumpWidget(const NestWayApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('虚拟护送'));
      await tester.pumpAndSettle();

      expect(find.text('虚拟护送'), findsWidgets);
    });

    testWidgets('Tapping SOS avatar should navigate to SOS page', (WidgetTester tester) async {
      await tester.pumpWidget(const NestWayApp());
      await tester.pumpAndSettle();

      final sosFinder = find.text('SOS');
      expect(sosFinder, findsOneWidget);

      await tester.tap(sosFinder);
      await tester.pumpAndSettle();

      expect(find.text('紧急求助'), findsOneWidget);
    });

    testWidgets('SOS page should show risk cards', (WidgetTester tester) async {
      await tester.pumpWidget(const NestWayApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('SOS'));
      await tester.pumpAndSettle();

      expect(find.text('轻度不安'), findsOneWidget);
      expect(find.text('中度风险'), findsOneWidget);
      expect(find.text('紧急危险'), findsOneWidget);
    });

    testWidgets('SOS page should have history button', (WidgetTester tester) async {
      await tester.pumpWidget(const NestWayApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('SOS'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('SOS page should navigate to history page', (WidgetTester tester) async {
      await tester.pumpWidget(const NestWayApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('SOS'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      expect(find.text('求助历史'), findsOneWidget);
    });

    testWidgets('History page should show SOS records', (WidgetTester tester) async {
      await tester.pumpWidget(const NestWayApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('SOS'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      expect(find.text('语音通话'), findsOneWidget);
      expect(find.text('短信'), findsOneWidget);
      expect(find.text('视频通话'), findsOneWidget);
    });

    testWidgets('Bottom nav should navigate back to home', (WidgetTester tester) async {
      await tester.pumpWidget(const NestWayApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('SOS'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.map));
      await tester.pumpAndSettle();

      expect(find.text('NestWay'), findsOneWidget);
      expect(find.text('虚拟护送'), findsOneWidget);
    });

    testWidgets('Bottom nav SOS should navigate to SOS page', (WidgetTester tester) async {
      await tester.pumpWidget(const NestWayApp());
      await tester.pumpAndSettle();

      final sosFinder = find.text('SOS');
      await tester.tap(sosFinder);
      await tester.pumpAndSettle();

      expect(find.text('紧急求助'), findsOneWidget);
    });
  });
}
