import 'dart:math';

import '../data/balance_table.dart';
import '../data/element_tables.dart';
import 'logbook.dart';
import 'offline_summary.dart';
import 'upgrades.dart';

class BoardTile {
  BoardTile({required this.form, this.tier = 1, this.transformElapsedSec = 0});

  ElementForm form;
  int tier;
  double transformElapsedSec;
}

class BoardGameState {
  BoardGameState({Random? random}) : _random = random ?? Random();

  factory BoardGameState.fromMap(Map<String, dynamic> map, {Random? random}) {
    final s = BoardGameState(random: random);
    s.boardSlots = (map['boardSlots'] as num?)?.toInt() ?? 24;
    s.essence = (map['essence'] as num?)?.toDouble() ?? 0;
    s.residue = (map['residue'] as num?)?.toInt() ?? 0;
    s.tickets = (map['tickets'] as num?)?.toInt() ?? 10;
    s.ticketCap = (map['ticketCap'] as num?)?.toInt() ?? 30;
    s.ticketRemainderSec = (map['ticketRemainderSec'] as num?)?.toInt() ?? 0;
    s.ticketIntervalSec = (map['ticketIntervalSec'] as num?)?.toInt() ?? 600;
    s.tapValue = (map['tapValue'] as num?)?.toDouble() ?? 1;
    s.productionMultiplier = (map['productionMultiplier'] as num?)?.toDouble() ?? 1;
    s.offlineMultiplier = (map['offlineMultiplier'] as num?)?.toDouble() ?? 1;
    s.residueMultiplier = (map['residueMultiplier'] as num?)?.toDouble() ?? 1;
    s.transformSpeedMultiplier = (map['transformSpeedMultiplier'] as num?)?.toDouble() ?? 1;
    s.clickBurstSec = (map['clickBurstSec'] as num?)?.toDouble() ?? 0;
    s.autoTapEnabled = (map['autoTapEnabled'] as bool?) ?? false;
    s.autoTapRemainSec = (map['autoTapRemainSec'] as num?)?.toDouble() ?? 0;
    s.autoTapCooldownSec = (map['autoTapCooldownSec'] as num?)?.toDouble() ?? 0;
    s.tapCount = (map['tapCount'] as num?)?.toInt() ?? 0;
    s.summonCount = (map['summonCount'] as num?)?.toInt() ?? 0;
    s.mergeCount = (map['mergeCount'] as num?)?.toInt() ?? 0;
    s.transformCountTotal = (map['transformCountTotal'] as num?)?.toInt() ?? 0;
    s.upgradeCount = (map['upgradeCount'] as num?)?.toInt() ?? 0;
    final disc = map['discovered'];
    if (disc is List) {
      s.discovered.addAll(disc.cast<String>());
    }

    final purchasedMap = map['purchased'];
    if (purchasedMap is Map) {
      for (final e in purchasedMap.entries) {
        s.purchased[e.key.toString()] = (e.value as num).toInt();
      }
    }

    final boardList = map['board'];
    if (boardList is List) {
      for (var i = 0; i < boardList.length && i < s.board.length; i++) {
        final t = boardList[i];
        if (t is Map<String, dynamic>) {
          s.board[i] = BoardTile(
            form: ElementForm.values.byName(t['form'] as String),
            tier: (t['tier'] as num).toInt(),
            transformElapsedSec: (t['elapsed'] as num).toDouble(),
          );
        }
      }
    }

    return s;
  }

  static const int rows = 5;
  static const int cols = 6;
  static const int size = rows * cols;
  int boardSlots = 24;

  final Random _random;
  final List<BoardTile?> board = List<BoardTile?>.filled(size, null);
  final List<LogEvent> logs = [];
  final Map<String, int> purchased = {};

  double essence = 0;
  double tapValue = 1;
  double productionMultiplier = 1;
  double offlineMultiplier = 1;
  double residueMultiplier = 1;
  double transformSpeedMultiplier = 1;
  double clickBurstSec = 0;
  bool autoTapEnabled = false;
  double autoTapRemainSec = 0;
  double autoTapCooldownSec = 0;
  int tapCount = 0;
  int residue = 0;
  int summonCount = 0;
  int mergeCount = 0;
  int transformCountTotal = 0;
  int upgradeCount = 0;
  final Set<String> discovered = {};
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

  int get filledCount => board.take(boardSlots).whereType<BoardTile>().length;

  Map<String, dynamic> toMap() {
    return {
      'boardSlots': boardSlots,
      'essence': essence,
      'residue': residue,
      'tickets': tickets,
      'ticketCap': ticketCap,
      'ticketRemainderSec': ticketRemainderSec,
      'ticketIntervalSec': ticketIntervalSec,
      'tapValue': tapValue,
      'productionMultiplier': productionMultiplier,
      'offlineMultiplier': offlineMultiplier,
      'residueMultiplier': residueMultiplier,
      'transformSpeedMultiplier': transformSpeedMultiplier,
      'clickBurstSec': clickBurstSec,
      'autoTapEnabled': autoTapEnabled,
      'autoTapRemainSec': autoTapRemainSec,
      'autoTapCooldownSec': autoTapCooldownSec,
      'tapCount': tapCount,
      'summonCount': summonCount,
      'mergeCount': mergeCount,
      'transformCountTotal': transformCountTotal,
      'upgradeCount': upgradeCount,
      'discovered': discovered.toList(),
      'purchased': purchased,
      'board': board
          .map((t) => t == null
              ? null
              : {
                  'form': t.form.name,
                  'tier': t.tier,
                  'elapsed': t.transformElapsedSec,
                })
          .toList(),
    };
  }



  bool get hasOpenedLog => logs.isNotEmpty;

  Map<String, int> last24hTypeCounts() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final cutoff = now - const Duration(hours: 24).inMilliseconds;
    final out = <String, int>{};
    for (final e in logs) {
      if (e.timestampMs < cutoff) continue;
      out[e.type.name] = (out[e.type.name] ?? 0) + 1;
    }
    return out;
  }

  List<LogEvent> getRecentLogs({LogType? type, int limit = 60}) {
    final src = logs.reversed.where((e) => type == null || e.type == type).take(limit);
    return src.toList();
  }

  void tick(double deltaSec) {
    _chargeTickets(deltaSec);
    _produceEssence(deltaSec, useOfflineMultiplier: false);
    _progressTransform(deltaSec, grouped: null, offline: false);
    if (autoTapEnabled && autoTapRemainSec > 0) {
      essence += tapValue * deltaSec;
      autoTapRemainSec = (autoTapRemainSec - deltaSec).clamp(0, 99999);
    }
    if (autoTapCooldownSec > 0) {
      autoTapCooldownSec = (autoTapCooldownSec - deltaSec).clamp(0, 99999);
    }
    if (clickBurstSec > 0) {
      clickBurstSec = (clickBurstSec - deltaSec).clamp(0, 99999);
    }
  }

  OfflineSummary applyOffline(int elapsedSec) {
    if (elapsedSec <= 0) {
      return const OfflineSummary(elapsedSec: 0, essenceGained: 0, residueGained: 0, ticketsGained: 0, transformCount: 0);
    }

    final essenceBefore = essence;
    final residueBefore = residue;
    final ticketsBefore = tickets;

    _chargeTickets(elapsedSec.toDouble());
    _produceEssence(elapsedSec.toDouble(), useOfflineMultiplier: true);
    final grouped = <String,int>{};
    _progressTransform(elapsedSec.toDouble(), grouped: grouped, offline: true);

    final summary = OfflineSummary(
      elapsedSec: elapsedSec,
      essenceGained: essence - essenceBefore,
      residueGained: residue - residueBefore,
      ticketsGained: tickets - ticketsBefore,
      transformCount: grouped.values.fold(0, (a,b)=>a+b),
      transformGroups: grouped,
    );

    logs.add(LogEvent(
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      type: LogType.offlineSummary,
      deltaEssence: summary.essenceGained,
      deltaResidue: summary.residueGained,
      deltaTickets: summary.ticketsGained,
      payload: {'elapsedSec': elapsedSec, 'transformCount': summary.transformCount, 'groups': grouped},
      isOffline: true,
    ));

    return summary;
  }


  void tap() {
    final tapMult = clickBurstSec > 0 ? 2.0 : 1.0;
    essence += tapValue * tapMult;
    tapCount += 1;
    if ((purchased['click_burst_1'] ?? 0) > 0 && tapCount % 50 == 0) {
      clickBurstSec = 10;
      logs.add(LogEvent(
        timestampMs: DateTime.now().millisecondsSinceEpoch,
        type: LogType.upgrade,
        payload: {'event': 'tap_burst_start', 'durationSec': 10},
      ));
    }
  }

  bool triggerAutoTap() {
    if (!autoTapEnabled) return false;
    if (autoTapCooldownSec > 0 || autoTapRemainSec > 0) return false;
    autoTapRemainSec = 30;
    autoTapCooldownSec = 600;
    logs.add(LogEvent(
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      type: LogType.upgrade,
      payload: {'event': 'auto_tap_start', 'remainSec': 30},
    ));
    return true;
  }

  bool stabilizerAt(int index) {
    if ((purchased['trans_stabilizer'] ?? 0) == 0) return false;
    final tile = board[index];
    if (tile == null) return false;
    tile.transformElapsedSec = 0;
    logs.add(LogEvent(
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      type: LogType.upgrade,
      payload: {'event': 'stabilizer', 'index': index, 'form': tile.form.name},
    ));
    return true;
  }

  bool catalystAt(int index) {
    if ((purchased['trans_catalyst'] ?? 0) == 0) return false;
    final tile = board[index];
    if (tile == null) return false;
    final rule = ruleFor(tile.form);
    if (rule == null) return false;
    final from = tile.form;
    tile.form = rule.to;
    tile.transformElapsedSec = 0;
    final gain = ((_transformResidue(tile.tier, rule.baseResidue) * residueMultiplier) * 1.5).round();
    residue += gain;
    logs.add(LogEvent(
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      type: LogType.transform,
      deltaResidue: gain,
      payload: {'event': 'catalyst', 'index': index, 'from': from.name, 'to': tile.form.name, 'tier': tile.tier},
    ));
    return true;
  }

  bool summonOne() {
    if (tickets <= 0) return false;
    final empty = _firstEmptyIndex();
    if (empty == -1) return false;

    tickets -= 1;
    summonCount += 1;
    final form = summonPool[_random.nextInt(summonPool.length)];
    board[empty] = BoardTile(form: form, tier: 1);
    discovered.add('${form.name}:T1');
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
    mergeCount += 1;
    discovered.add('${b.form.name}:T${b.tier}');

    logs.add(
      LogEvent(
        timestampMs: DateTime.now().millisecondsSinceEpoch,
        type: LogType.merge,
        payload: {'from': from, 'to': to, 'form': b.form.name, 'tier': b.tier},
      ),
    );
    return true;
  }


  String? cannotBuyReason(UpgradeDef def) {
    final level = purchased[def.id] ?? 0;
    if (level >= def.maxLevel) return '이미 구매 완료';
    if (def.id == 'prod_board_expand_1' && mergeCount < 200) return '총 머지 200회 필요';
    if (def.id == 'click_tap_2' && discovered.length < 8) return '도감 8종 발견 필요';
    if (essence < def.cost) return 'Essence 부족';
    return null;
  }

  bool buyUpgrade(UpgradeDef def) {
    final reason = cannotBuyReason(def);
    if (reason != null) return false;

    final level = purchased[def.id] ?? 0;
    essence -= def.cost;
    purchased[def.id] = level + 1;

    switch (def.id) {
      case 'summon_charge_1':
        ticketIntervalSec = (ticketIntervalSec * 0.9).round();
        break;
      case 'summon_cap_1':
        ticketCap += 10;
        break;
      case 'prod_all_1':
        productionMultiplier *= 1.10;
        break;
      case 'prod_offline_1':
        offlineMultiplier *= 1.10;
        break;
      case 'prod_element_1':
        productionMultiplier *= 1.15;
        break;
      case 'prod_board_expand_1':
        boardSlots = (boardSlots + 6).clamp(6, size);
        break;
      case 'prod_recycle_1':
        productionMultiplier *= 1.05;
        break;
      case 'trans_residue_1':
        residueMultiplier *= 1.15;
        break;
      case 'trans_speed_1':
        transformSpeedMultiplier *= 1.10;
        break;
      case 'trans_stabilizer':
        residueMultiplier *= 1.05;
        break;
      case 'trans_catalyst':
        residueMultiplier *= 1.10;
        break;
      case 'trans_penalty_reduce':
        productionMultiplier *= 1.05;
        break;
      case 'click_tap_1':
        tapValue += 1;
        break;
      case 'click_tap_2':
        tapValue += 2;
        break;
      case 'click_burst_1':
        tapValue += 1;
        break;
      case 'click_auto_1':
        autoTapEnabled = true;
        break;
      case 'click_ticket_gauge':
        ticketRemainderSec += 60;
        break;
      default:
        break;
    }

    upgradeCount += 1;
    logs.add(LogEvent(
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      type: LogType.upgrade,
      payload: {'id': def.id, 'name': def.name},
    ));

    return true;
  }

  int _firstEmptyIndex() {
    for (var i = 0; i < boardSlots; i++) {
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

  void _produceEssence(double deltaSec, {required bool useOfflineMultiplier}) {
    var income = 0.0;
    for (final tile in board) {
      if (tile == null) continue;
      income += _tileIncome(tile);
    }
    final mult = productionMultiplier * (useOfflineMultiplier ? offlineMultiplier : 1.0);
    essence += income * mult * deltaSec;
  }

  void _progressTransform(double deltaSec, {Map<String,int>? grouped, required bool offline}) {
    for (var i = 0; i < boardSlots; i++) {
      final tile = board[i];
      if (tile == null) continue;
      final rule = ruleFor(tile.form);
      if (rule == null) continue;

      tile.transformElapsedSec += deltaSec;
      final need = _transformDuration(tile.tier, rule.baseDurationSec, transformSpeedMultiplier);

      if (tile.transformElapsedSec >= need) {
        tile.transformElapsedSec = 0;
        final from = tile.form;
        transformCountTotal += 1;
        tile.form = rule.to;
        discovered.add('${tile.form.name}:T${tile.tier}');
        final gain = (_transformResidue(tile.tier, rule.baseResidue) * residueMultiplier).round();
        residue += gain;

        if (offline) {
          final key = '${from.name}->${tile.form.name}:T${tile.tier}';
          if (grouped != null) {
            grouped[key] = (grouped[key] ?? 0) + 1;
          }
        } else {
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
  }

  static double _tileIncome(BoardTile tile) {
    final base = kBaseIncome[tile.form] ?? 1.0;
    return base * pow(2, tile.tier - 1);
  }

  static int _transformDuration(int tier, int baseDurationSec, double speedMultiplier) {
    final raw = (baseDurationSec * (1 + (tier - 1) * 0.2) / speedMultiplier).round();
    return max(1, raw);
  }

  static int _transformResidue(int tier, int baseResidue) {
    return (baseResidue * pow(1.35, tier - 1)).round();
  }
}
