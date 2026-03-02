import 'package:app_one_flutter/core/offline_summary.dart';
import 'package:app_one_flutter/data/element_tables.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('transform rule exists for flame', () {
    final rule = ruleFor(ElementForm.flame);
    expect(rule, isNotNull);
    expect(rule!.to, ElementForm.smoke);
  });

  test('ticket charge respects cap', () {
    final result = chargeTickets(
      currentTickets: 28,
      cap: 30,
      elapsedSec: 3600,
      intervalSec: 600,
      remainSec: 0,
    );
    expect(result.newTickets, 30);
    expect(result.gainedTickets, 2);
  });
}
