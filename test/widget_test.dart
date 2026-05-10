import 'package:flutter_test/flutter_test.dart';
import 'package:solotrip/app/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NestWayApp());
    expect(find.text('NestWay'), findsOneWidget);
  });
}
