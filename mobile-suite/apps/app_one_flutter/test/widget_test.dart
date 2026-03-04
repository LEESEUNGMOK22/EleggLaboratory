import 'package:app_one_flutter/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('elemental home renders', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('홈'), findsOneWidget);
    expect(find.textContaining('포인트'), findsWidgets);
  });
}
