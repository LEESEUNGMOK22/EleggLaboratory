import 'package:app_one_flutter/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('idle merge app renders', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.textContaining('Idle Merge'), findsOneWidget);
    expect(find.textContaining('Tickets:'), findsOneWidget);
  });
}
