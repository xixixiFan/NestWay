import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solotrip/pages/home/home_page.dart';
import 'package:solotrip/pages/sos/sos_page.dart';
import 'package:solotrip/widgets/primary_button.dart';
import 'package:solotrip/widgets/sos_button.dart';
import 'package:solotrip/widgets/app_bottom_nav.dart';

void main() {
  group('Page Unit Tests', () {
    group('HomePage Tests', () {
      testWidgets('HomePage should display NestWay title', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: HomePage(),
          ),
        );

        expect(find.text('NestWay'), findsOneWidget);
      });

      testWidgets('HomePage should display location info', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: HomePage(),
          ),
        );

        expect(find.text('深圳 · 当前安全'), findsOneWidget);
      });

      testWidgets('HomePage should display PrimaryButton with correct text', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: HomePage(),
          ),
        );

        expect(find.text('虚拟护送'), findsOneWidget);
        expect(find.byType(PrimaryButton), findsOneWidget);
      });

      testWidgets('HomePage should display subtitle text', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: HomePage(),
          ),
        );

        expect(find.text('设置目的地，全程守护你'), findsOneWidget);
      });

      testWidgets('HomePage should have bottom navigation', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: HomePage(),
          ),
        );

        expect(find.byType(AppBottomNav), findsOneWidget);
      });
    });

    group('SosPage Tests', () {
      testWidgets('SosPage should display correct title', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: SosPage(),
          ),
        );

        expect(find.text('紧急求助'), findsOneWidget);
      });

      testWidgets('SosPage should display instruction text', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: SosPage(),
          ),
        );

        expect(find.text('长按按钮启动求助'), findsOneWidget);
      });

      testWidgets('SosPage should display SosButton', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: SosPage(),
          ),
        );

        expect(find.byType(SosButton), findsOneWidget);
      });

      testWidgets('SosPage should display history icon button', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: SosPage(),
          ),
        );

        expect(find.byIcon(Icons.history), findsOneWidget);
      });

      testWidgets('SosPage should display risk cards', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: SosPage(),
          ),
        );

        expect(find.text('轻度不安'), findsOneWidget);
        expect(find.text('中度风险'), findsOneWidget);
        expect(find.text('紧急危险'), findsOneWidget);
      });

      testWidgets('SosPage should have bottom navigation', (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: SosPage(),
          ),
        );

        expect(find.byType(AppBottomNav), findsOneWidget);
      });
    });
  });
}
