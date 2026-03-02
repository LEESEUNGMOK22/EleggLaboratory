import 'dart:math';

import 'package:app_one_flutter/core/board_game_state.dart';
import 'package:app_one_flutter/core/upgrades.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('summon consumes ticket and fills board', () {
    final g = BoardGameState(random: Random(1));
    final before = g.tickets;
    final ok = g.summonOne();
    expect(ok, isTrue);
    expect(g.tickets, before - 1);
    expect(g.filledCount, 1);
  });

  test('merge upgrades tier', () {
    final g = BoardGameState();
    g.board[0] = BoardTile(form: BoardGameState.summonPool.first, tier: 1);
    g.board[1] = BoardTile(form: BoardGameState.summonPool.first, tier: 1);
    final merged = g.merge(0, 1);
    expect(merged, isTrue);
    expect(g.board[0], isNull);
    expect(g.board[1]!.tier, 2);
  });

  test('can buy upgrade with enough essence', () {
    final g = BoardGameState();
    g.essence = 999;
    final ok = g.buyUpgrade(kUpgradeDefs.first);
    expect(ok, isTrue);
    expect(g.purchased[kUpgradeDefs.first.id], 1);
  });

  test('board expansion upgrade increases slots', () {
    final g = BoardGameState();
    g.boardSlots = 24;
    g.mergeCount = 200;
    g.essence = 999;
    final up = kUpgradeDefs.firstWhere((u) => u.id == 'prod_board_expand_1');
    final ok = g.buyUpgrade(up);
    expect(ok, isTrue);
    expect(g.boardSlots, 30);
  });

  test('tap burst starts every 50 taps when upgrade bought', () {
    final g = BoardGameState();
    g.essence = 999;
    final up = kUpgradeDefs.firstWhere((u) => u.id == 'click_burst_1');
    g.buyUpgrade(up);
    for (var i = 0; i < 50; i++) {
      g.tap();
    }
    expect(g.clickBurstSec, greaterThan(0));
  });

  test('auto tap can be triggered after upgrade', () {
    final g = BoardGameState();
    g.essence = 999;
    final up = kUpgradeDefs.firstWhere((u) => u.id == 'click_auto_1');
    g.buyUpgrade(up);
    final ok = g.triggerAutoTap();
    expect(ok, isTrue);
    expect(g.autoTapRemainSec, greaterThan(0));
  });

  test('upgrade gate blocks board expansion before 200 merges', () {
    final g = BoardGameState();
    g.essence = 9999;
    final up = kUpgradeDefs.firstWhere((u) => u.id == 'prod_board_expand_1');
    expect(g.cannotBuyReason(up), isNotNull);
    expect(g.buyUpgrade(up), isFalse);
  });
}
