import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

enum Rarity { common, rare, special, legendary, finalTier, mythic }

class ElementDef {
  const ElementDef(this.id, this.name, this.rarity);

  final String id;
  final String name;
  final Rarity rarity;
}

class FieldElement {
  FieldElement({required this.uid, required this.elementId, required this.position});

  final String uid;
  String elementId;
  Offset position;
}

class MegaRecipe {
  const MegaRecipe({required this.id, required this.ingredients, required this.rewardMythicId});

  final String id;
  final List<String> ingredients;
  final String rewardMythicId;
}

const elementDefs = <String, ElementDef>{
  'fire': ElementDef('fire', '불', Rarity.common),
  'water': ElementDef('water', '물', Rarity.common),
  'earth': ElementDef('earth', '흙', Rarity.common),
  'air': ElementDef('air', '바람', Rarity.common),
  'steam': ElementDef('steam', '증기', Rarity.rare),
  'mud': ElementDef('mud', '진흙', Rarity.rare),
  'dust': ElementDef('dust', '먼지', Rarity.special),
  'energy': ElementDef('energy', '에너지', Rarity.legendary),
  'phoenix_seed': ElementDef('phoenix_seed', '불사 씨앗', Rarity.mythic),
};

const mergeRecipes = <String, String>{
  'fire+water': 'steam',
  'water+earth': 'mud',
  'air+earth': 'dust',
  'fire+air': 'energy',
};

const megaRecipes = <MegaRecipe>[
  MegaRecipe(
    id: 'mega_1',
    ingredients: ['fire', 'water', 'earth', 'air'],
    rewardMythicId: 'phoenix_seed',
  ),
];

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App One',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const ElementalIdleHome(),
    );
  }
}

class ElementalIdleHome extends StatefulWidget {
  const ElementalIdleHome({super.key});

  @override
  State<ElementalIdleHome> createState() => _ElementalIdleHomeState();
}

class _ElementalIdleHomeState extends State<ElementalIdleHome> {
  static const _adDayKey = 'app1_ad_day';
  static const _adCountKey = 'app1_ad_count';

  final random = Random();
  final elements = <FieldElement>[];
  final discovered = <String>{};

  int currentPage = 0; // 0 home, 1 codex, 2 mega
  int tickets = 20;
  int ticketCap = 30;
  int ticketRemainSec = 0;
  int adRewardUsedToday = 0;

  Size canvasSize = const Size(380, 580);

  FieldElement? dragging;
  Offset dragDelta = Offset.zero;
  String? hoverTargetUid;
  double hoverSec = 0;
  double trashHoldSec = 0;

  Timer? loop;

  @override
  void initState() {
    super.initState();
    _loadAdRewardState();
    loop = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() {
        _tick(0.1);
      });
    });
  }

  @override
  void dispose() {
    loop?.cancel();
    super.dispose();
  }

  void _tick(double dt) {
    if (tickets < ticketCap) {
      ticketRemainSec += (dt * 1).round();
      if (ticketRemainSec >= 600) {
        ticketRemainSec = 0;
        tickets += 1;
      }
    }

    if (dragging != null) {
      final target = _findMergeTarget(dragging!);
      if (target != null) {
        if (hoverTargetUid == target.uid) {
          hoverSec += dt;
        } else {
          hoverTargetUid = target.uid;
          hoverSec = 0;
        }
      } else {
        hoverTargetUid = null;
        hoverSec = 0;
      }

      if (_isOverTrash(dragging!.position)) {
        trashHoldSec += dt;
      } else {
        trashHoldSec = 0;
      }
    }
  }

  void _spawnFromGacha({int count = 1}) {
    for (var i = 0; i < count; i++) {
      if (tickets <= 0) break;
      tickets -= 1;
      final roll = random.nextDouble();
      String id;
      if (roll < 0.72) {
        id = ['fire', 'water', 'earth', 'air'][random.nextInt(4)];
      } else if (roll < 0.92) {
        id = ['steam', 'mud'][random.nextInt(2)];
      } else if (roll < 0.992) {
        id = 'dust';
      } else {
        id = 'energy';
      }
      _spawnElement(id);
    }
  }

  void _spawnElement(String id) {
    final p = Offset(
      30 + random.nextDouble() * (canvasSize.width - 80).clamp(40, 500),
      30 + random.nextDouble() * (canvasSize.height - 120).clamp(60, 700),
    );
    final e = FieldElement(uid: '${DateTime.now().microsecondsSinceEpoch}_${random.nextInt(9999)}', elementId: id, position: p);
    elements.add(e);
    discovered.add(id);
  }

  FieldElement? _findMergeTarget(FieldElement src) {
    for (final e in elements) {
      if (e.uid == src.uid) continue;
      final d = (e.position - src.position).distance;
      if (d > 56) continue;
      final key1 = '${src.elementId}+${e.elementId}';
      final key2 = '${e.elementId}+${src.elementId}';
      if (mergeRecipes.containsKey(key1) || mergeRecipes.containsKey(key2)) {
        return e;
      }
    }
    return null;
  }

  bool _isOverTrash(Offset p) {
    final trash = Rect.fromLTWH(canvasSize.width - 88, canvasSize.height - 88, 72, 72);
    return trash.contains(p);
  }

  void _commitMergeIfReady() {
    if (dragging == null || hoverTargetUid == null || hoverSec < 3) return;

    final src = dragging!;
    final dst = elements.firstWhere((e) => e.uid == hoverTargetUid, orElse: () => src);
    if (src.uid == dst.uid) return;

    final key1 = '${src.elementId}+${dst.elementId}';
    final key2 = '${dst.elementId}+${src.elementId}';
    final resultId = mergeRecipes[key1] ?? mergeRecipes[key2];
    if (resultId == null) return;

    elements.removeWhere((e) => e.uid == src.uid || e.uid == dst.uid);
    final merged = FieldElement(uid: '${DateTime.now().microsecondsSinceEpoch}', elementId: resultId, position: dst.position);
    elements.add(merged);
    discovered.add(resultId);
  }

  void _commitTrashIfReady() {
    if (dragging == null) return;
    if (trashHoldSec < 3) return;
    elements.removeWhere((e) => e.uid == dragging!.uid);
  }

  bool _canMega(MegaRecipe r) {
    final counts = <String, int>{};
    for (final e in elements) {
      counts[e.elementId] = (counts[e.elementId] ?? 0) + 1;
    }
    for (final ing in r.ingredients) {
      final c = counts[ing] ?? 0;
      if (c <= 0) return false;
      counts[ing] = c - 1;
    }
    return true;
  }

  void _consumeForMega(MegaRecipe r) {
    final required = List<String>.from(r.ingredients);
    for (final ing in required) {
      final idx = elements.indexWhere((e) => e.elementId == ing);
      if (idx >= 0) elements.removeAt(idx);
    }
    _spawnElement(r.rewardMythicId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('원소 숙성소')),
      body: switch (currentPage) {
        0 => _buildHome(),
        1 => _buildCodex(),
        _ => _buildMega(),
      },
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _buildHome() {
    return LayoutBuilder(
      builder: (context, c) {
        canvasSize = c.biggest;
        return Stack(
          children: [
            Positioned(
              left: 12,
              top: 12,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text('Tickets: $tickets/$ticketCap · 전설 <1%'),
                ),
              ),
            ),
            ...elements.map(_elementWidget),
            _trashWidget(),
          ],
        );
      },
    );
  }

  Widget _elementWidget(FieldElement e) {
    final def = elementDefs[e.elementId]!;
    final isDragging = dragging?.uid == e.uid;
    final isHoverTarget = hoverTargetUid == e.uid;

    return Positioned(
      left: e.position.dx,
      top: e.position.dy,
      child: GestureDetector(
        onPanStart: (_) {
          dragging = e;
          dragDelta = Offset.zero;
          hoverSec = 0;
          trashHoldSec = 0;
        },
        onPanUpdate: (d) {
          setState(() {
            dragDelta += d.delta;
            e.position = Offset(
              (e.position.dx + d.delta.dx).clamp(0, canvasSize.width - 56),
              (e.position.dy + d.delta.dy).clamp(0, canvasSize.height - 96),
            );
          });
        },
        onPanEnd: (_) {
          setState(() {
            _commitMergeIfReady();
            _commitTrashIfReady();
            dragging = null;
            hoverTargetUid = null;
            hoverSec = 0;
            trashHoldSec = 0;
          });
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _rarityColor(def.rarity),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDragging ? Colors.black : (isHoverTarget ? Colors.amber : Colors.white),
                  width: isDragging ? 3 : 2,
                ),
              ),
              child: Center(
                child: Text(def.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ),
            ),
            if (isHoverTarget && dragging != null)
              Positioned.fill(
                child: CircularProgressIndicator(
                  value: (hoverSec / 3).clamp(0, 1),
                  strokeWidth: 3,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _trashWidget() {
    final progress = (trashHoldSec / 3).clamp(0.0, 1.0).toDouble();
    return Positioned(
      right: 16,
      bottom: 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade700, width: 2),
            ),
            child: const Icon(Icons.delete_forever),
          ),
          if (trashHoldSec > 0)
            SizedBox(
              width: 72,
              height: 72,
              child: CircularProgressIndicator(value: progress, strokeWidth: 3),
            ),
        ],
      ),
    );
  }

  Widget _buildCodex() {
    final all = elementDefs.values.toList()..sort((a, b) => a.name.compareTo(b.name));
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('도감', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...all.map((e) {
          final found = discovered.contains(e.id);
          return ListTile(
            leading: Icon(found ? Icons.check_circle : Icons.radio_button_unchecked),
            title: Text(e.name),
            subtitle: Text('등급: ${e.rarity.name}'),
            trailing: Text(found ? '발견' : '미발견'),
          );
        }),
      ],
    );
  }

  Widget _buildMega() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Text('대규모 합성', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...megaRecipes.map((r) {
          final active = _canMega(r);
          final reward = elementDefs[r.rewardMythicId]!;
          return Card(
            child: ListTile(
              title: Text('${r.ingredients.join(' + ')} => ${reward.name}'),
              subtitle: Text(active ? '활성화됨 (3초 꾹 눌러 발동)' : '재료 부족'),
              trailing: _Hold3sButton(
                enabled: active,
                onCommit: () {
                  setState(() {
                    _consumeForMega(r);
                  });
                },
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _bottomNav() {
    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: IconButton(
                onPressed: () => _showTimeInfo(),
                icon: const Icon(Icons.schedule),
                tooltip: '시간',
              ),
            ),
            Expanded(
              child: IconButton(
                onPressed: () => _openGachaSheet(),
                icon: const Icon(Icons.casino),
                tooltip: '원소 가챠',
              ),
            ),
            Expanded(
              child: FilledButton.tonal(
                onPressed: () => setState(() => currentPage = 0),
                child: const Text('홈'),
              ),
            ),
            Expanded(
              child: IconButton(
                onPressed: () => setState(() => currentPage = 1),
                icon: const Icon(Icons.menu_book),
                tooltip: '도감',
              ),
            ),
            Expanded(
              child: IconButton(
                onPressed: () => setState(() => currentPage = 2),
                icon: const Icon(Icons.auto_awesome),
                tooltip: '대규모 합성',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimeInfo() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('시간 정보'),
        content: Text('다음 티켓까지: ${600 - ticketRemainSec}s'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인'))],
      ),
    );
  }

  void _openGachaSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('원소 가챠 확률', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text('일반 72% / 희귀 20% / 특수 7.2% / 전설 0.8% (<1%)'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        setState(() => _spawnFromGacha(count: 1));
                        Navigator.pop(context);
                      },
                      child: const Text('1회'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => _spawnFromGacha(count: 10));
                        Navigator.pop(context);
                      },
                      child: const Text('10회'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: adRewardUsedToday < 3
                          ? () async {
                              await _rewardByAdPlaceholder();
                              if (mounted) Navigator.pop(context);
                            }
                          : null,
                      child: Text('광고 보고 +가챠권 10 (오늘 $adRewardUsedToday/3)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text('※ 현재는 광고 API 미연동. 버튼 누르면 보상만 지급됩니다.', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadAdRewardState() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = '$now.year-$now.month-$now.day';
    final savedDay = prefs.getString(_adDayKey);
    final savedCount = prefs.getInt(_adCountKey) ?? 0;

    setState(() {
      if (savedDay == today) {
        adRewardUsedToday = savedCount;
      } else {
        adRewardUsedToday = 0;
      }
    });

    if (savedDay != today) {
      await prefs.setString(_adDayKey, today);
      await prefs.setInt(_adCountKey, 0);
    }
  }

  Future<void> _rewardByAdPlaceholder() async {
    if (adRewardUsedToday >= 3) return;
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = '$now.year-$now.month-$now.day';

    final savedDay = prefs.getString(_adDayKey);
    if (savedDay != today) {
      adRewardUsedToday = 0;
      await prefs.setString(_adDayKey, today);
    }

    setState(() {
      adRewardUsedToday += 1;
      tickets = (tickets + 10).clamp(0, ticketCap);
    });

    await prefs.setInt(_adCountKey, adRewardUsedToday);
  }

  Color _rarityColor(Rarity r) {
    return switch (r) {
      Rarity.common => Colors.grey.shade300,
      Rarity.rare => Colors.blue.shade200,
      Rarity.special => Colors.purple.shade200,
      Rarity.legendary => Colors.orange.shade300,
      Rarity.finalTier => Colors.red.shade300,
      Rarity.mythic => Colors.amber.shade300,
    };
  }
}

class _Hold3sButton extends StatefulWidget {
  const _Hold3sButton({required this.enabled, required this.onCommit});

  final bool enabled;
  final VoidCallback onCommit;

  @override
  State<_Hold3sButton> createState() => _Hold3sButtonState();
}

class _Hold3sButtonState extends State<_Hold3sButton> {
  Timer? timer;
  double sec = 0;

  void _start() {
    if (!widget.enabled) return;
    timer?.cancel();
    sec = 0;
    timer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      setState(() => sec += 0.1);
      if (sec >= 3) {
        t.cancel();
        sec = 0;
        widget.onCommit();
      }
    });
  }

  void _stop() {
    timer?.cancel();
    setState(() => sec = 0);
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _start(),
      onTapUp: (_) => _stop(),
      onTapCancel: _stop,
      child: SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              backgroundColor: widget.enabled ? Colors.green.shade100 : Colors.grey.shade300,
              child: const Icon(Icons.play_arrow),
            ),
            if (sec > 0)
              CircularProgressIndicator(value: (sec / 3).clamp(0, 1), strokeWidth: 3),
          ],
        ),
      ),
    );
  }
}
