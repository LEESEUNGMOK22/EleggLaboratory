import 'dart:math';

import 'package:app_one_flutter/core/board_game_state.dart';
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
}
