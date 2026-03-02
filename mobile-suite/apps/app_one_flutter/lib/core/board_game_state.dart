import 'dart:math';

import '../data/element_tables.dart';
import 'logbook.dart';

class BoardTile {
  BoardTile({required this.form, this.tier = 1, this.transformElapsedSec = 0});

  ElementForm form;
  int tier;
  double transformElapsedSec;
}

class BoardGameState {
  BoardGameState({Random? random}) : _random = random ?? Random();

  static const int rows = 5;
  static const int cols = 6;
  static const int size = rows * cols;

  final Random _random;
  final List<BoardTile?> board = List<BoardTile?>.filled(size, null);
  final List<LogEvent> logs = [];

  double essence = 0;
  int residue = 0;
  int tickets = 10;
  int ticketCap = 30;
  int ticketRemainderSec = 0;
  int ticketIntervalSec = 600;

  static const List<ElementForm> summonPool = [
    ElementForm.flame,
    ElementForm.water,
    ElementForm.soil,
    ElementForm.air,
  ];

  int get filledCount => board.whereType<BoardTile>().length;

  void tick(double deltaSec) {
    _chargeTickets(deltaSec);
    _produceEssence(deltaSec);
    _progressTransform(deltaSec);
  }

  bool summonOne() {
    if (tickets <= 0) return false;
    final empty = _firstEmptyIndex();
    if (empty == -1) return false;

    tickets -= 1;
    final form = summonPool[_random.nextInt(summonPool.length)];
    board[empty] = BoardTile(form: form, tier: 1);
    logs.add(
      LogEvent(
        timestampMs: DateTime.now().millisecondsSinceEpoch,
        type: LogType.summon,
        deltaTickets: -1,
        payload: {'index': empty, 'form': form.name, 'tier': 1},
      ),
    );
    return true;
  }

  bool merge(int from, int to) {
    if (from == to) return false;
    final a = board[from];
    final b = board[to];
    if (a == null || b == null) return false;
    if (a.form != b.form || a.tier != b.tier) return false;

    board[from] = null;
    b.tier += 1;
    b.transformElapsedSec = 0;

    logs.add(
      LogEvent(
        timestampMs: DateTime.now().millisecondsSinceEpoch,
        type: LogType.merge,
        payload: {'from': from, 'to': to, 'form': b.form.name, 'tier': b.tier},
      ),
    );
    return true;
  }

  int _firstEmptyIndex() {
    for (var i = 0; i < board.length; i++) {
      if (board[i] == null) return i;
    }
    return -1;
  }

  void _chargeTickets(double deltaSec) {
    ticketRemainderSec += deltaSec.floor();
    if (tickets >= ticketCap) return;
    if (ticketRemainderSec < ticketIntervalSec) return;

    final gained = ticketRemainderSec ~/ ticketIntervalSec;
    ticketRemainderSec = ticketRemainderSec % ticketIntervalSec;
    tickets = min(ticketCap, tickets + gained);
  }

  void _produceEssence(double deltaSec) {
    var income = 0.0;
    for (final tile in board) {
      if (tile == null) continue;
      income += _tileIncome(tile);
    }
    essence += income * deltaSec;
  }

  void _progressTransform(double deltaSec) {
    for (var i = 0; i < board.length; i++) {
      final tile = board[i];
      if (tile == null) continue;
      final rule = ruleFor(tile.form);
      if (rule == null) continue;

      tile.transformElapsedSec += deltaSec;
      final need = _transformDuration(tile.tier, rule.baseDurationSec);

      if (tile.transformElapsedSec >= need) {
        tile.transformElapsedSec = 0;
        final from = tile.form;
        tile.form = rule.to;
        final gain = _transformResidue(tile.tier, rule.baseResidue);
        residue += gain;

        logs.add(
          LogEvent(
            timestampMs: DateTime.now().millisecondsSinceEpoch,
            type: LogType.transform,
            deltaResidue: gain,
            payload: {
              'index': i,
              'from': from.name,
              'to': tile.form.name,
              'tier': tile.tier,
            },
          ),
        );
      }
    }
  }

  static double _tileIncome(BoardTile tile) {
    final base = switch (tile.form) {
      ElementForm.flame => 4.0,
      ElementForm.smoke => 2.0,
      ElementForm.ash => 1.0,
      ElementForm.soot => 0.5,
      ElementForm.water => 4.0,
      ElementForm.vapor => 2.0,
      ElementForm.cloud => 1.0,
      ElementForm.dew => 0.5,
      ElementForm.soil => 4.0,
      ElementForm.mud => 2.0,
      ElementForm.clay => 1.0,
      ElementForm.stone => 0.5,
      ElementForm.air => 4.0,
      ElementForm.breeze => 2.0,
      ElementForm.gust => 1.0,
      ElementForm.storm => 0.5,
    };

    return base * pow(2, tile.tier - 1);
  }

  static int _transformDuration(int tier, int baseDurationSec) {
    return (baseDurationSec * (1 + (tier - 1) * 0.2)).round();
  }

  static int _transformResidue(int tier, int baseResidue) {
    return (baseResidue * pow(1.35, tier - 1)).round();
  }
}
