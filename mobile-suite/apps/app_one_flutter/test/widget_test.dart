import 'package:app_one_flutter/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('board prototype renders', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.textContaining('Board Prototype'), findsOneWidget);
    expect(find.textContaining('Tickets:'), findsOneWidget);
  });
}
