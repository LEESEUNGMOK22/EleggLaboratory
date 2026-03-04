import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  'philosopher_stone': ElementDef('philosopher_stone', '현자의 돌', Rarity.finalTier),
  'phoenix_seed': ElementDef('phoenix_seed', '불사 씨앗', Rarity.mythic),
};

const mergeRecipes = <String, String>{
  'fire+water': 'steam',
  'water+earth': 'mud',
  'air+earth': 'dust',
  'fire+air': 'energy',
  'energy+dust': 'philosopher_stone',
};

const defaultMegaRecipes = <MegaRecipe>[
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
      title: '원소 숙성소',
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
  static const _adExpireKey = 'app1_ad_expire_ms';
  static const double holdSec = 2.0;
  static const int maxFieldElements = 80;

  final random = Random();
  final elements = <FieldElement>[];
  final discovered = <String>{};

  int page = 2; // 0 time, 1 gacha, 2 home, 3 codex, 4 mega, 5 ads

  int tickets = 20;
  int ticketCap = 30;

  int elementPoint = 0;
  int clickBase = 5;

  int adRewardUsedToday = 0;
  DateTime? adBuffExpiresAt;

  double gachaCommon = 0.72;
  double gachaRare = 0.20;
  double gachaSpecial = 0.072;
  double gachaLegendary = 0.008;

  List<MegaRecipe> megaRecipes = List<MegaRecipe>.from(defaultMegaRecipes);

  Size canvasSize = const Size(380, 580);

  FieldElement? dragging;
  String? hoverTargetUid;
  bool hoverTargetCombinable = false;
  double hoverSec = 0;
  double trashHoldSec = 0;

  Timer? loop;

  @override
  void initState() {
    super.initState();
    _loadAdRewardState();
    _loadDesignConfig();
    loop = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() => _tick(0.1));
    });
  }

  @override
  void dispose() {
    loop?.cancel();
    super.dispose();
  }

  bool get _isAdBuffActive {
    if (adBuffExpiresAt == null) return false;
    return DateTime.now().isBefore(adBuffExpiresAt!);
  }

  int get _clickPower {
    final finalCount = discovered.where((id) => elementDefs[id]?.rarity == Rarity.finalTier).length;
    final power = clickBase + finalCount * 2;
    return (_isAdBuffActive ? power * 2 : power);
  }

  void _tick(double dt) {
    // 1초당 1 원소포인트
    final add = dt >= 1 ? 1 : (random.nextDouble() < dt ? 1 : 0);
    if (add > 0) {
      elementPoint += (_isAdBuffActive ? add * 2 : add);
    }

    if (_isAdBuffActive && DateTime.now().isAfter(adBuffExpiresAt!)) {
      adBuffExpiresAt = null;
    }

    if (dragging != null) {
      final target = _findNearestTarget(dragging!);
      if (target != null) {
        final combinable = _isCombinable(dragging!.elementId, target.elementId);
        if (hoverTargetUid == target.uid) {
          if (combinable) {
            hoverSec += dt;
          } else {
            hoverSec = 0;
          }
        } else {
          hoverTargetUid = target.uid;
          hoverTargetCombinable = combinable;
          hoverSec = 0;
        }
        hoverTargetCombinable = combinable;
      } else {
        hoverTargetUid = null;
        hoverTargetCombinable = false;
        hoverSec = 0;
      }

      if (_isOverTrash(dragging!.position)) {
        trashHoldSec += dt;
      } else {
        trashHoldSec = 0;
      }
    }
  }

  void _clickGain() {
    setState(() {
      elementPoint += _clickPower;
    });
  }

  void _buyTicket(int count) {
    const pricePerTicket = 20;
    final total = count * pricePerTicket;
    if (elementPoint < total) return;
    setState(() {
      elementPoint -= total;
      tickets = (tickets + count).clamp(0, ticketCap);
    });
  }

  void _spawnFromGacha({int count = 1}) {
    for (var i = 0; i < count; i++) {
      if (tickets <= 0) break;
      if (elements.length >= maxFieldElements) break;
      tickets -= 1;
      final roll = random.nextDouble();
      String id;
      if (roll < gachaCommon) {
        id = ['fire', 'water', 'earth', 'air'][random.nextInt(4)];
      } else if (roll < gachaCommon + gachaRare) {
        id = ['steam', 'mud'][random.nextInt(2)];
      } else if (roll < gachaCommon + gachaRare + gachaSpecial) {
        id = 'dust';
      } else {
        id = 'energy';
      }
      _spawnElement(id);
    }
  }

  void _spawnElement(String id) {
    if (elements.length >= maxFieldElements) return;
    final p = _findNonOverlappingSpawnPoint();

    final e = FieldElement(uid: '${DateTime.now().microsecondsSinceEpoch}_${random.nextInt(9999)}', elementId: id, position: p);
    elements.add(e);
    discovered.add(id);
  }


  Offset _findNonOverlappingSpawnPoint() {
    for (var i = 0; i < 40; i++) {
      final p = Offset(
        20 + random.nextDouble() * (canvasSize.width - 80).clamp(40, 900),
        70 + random.nextDouble() * (canvasSize.height - 160).clamp(80, 1200),
      );
      if (_isPositionFree(p, minDist: 54)) return p;
    }
    return const Offset(30, 100);
  }

  bool _isPositionFree(Offset p, {double minDist = 52}) {
    for (final e in elements) {
      if ((e.position - p).distance < minDist) return false;
    }
    return true;
  }

  void _pushAwayNearby(FieldElement moving) {
    for (final e in elements) {
      if (e.uid == moving.uid) continue;
      final v = e.position - moving.position;
      final d = v.distance;
      if (d == 0) continue;
      if (d < 54) {
        final push = (54 - d) * 0.15;
        final dir = Offset(v.dx / d, v.dy / d);
        e.position = Offset(
          (e.position.dx + dir.dx * push).clamp(0, canvasSize.width - 56),
          (e.position.dy + dir.dy * push).clamp(0, canvasSize.height - 96),
        );
      }
    }
  }

  bool _isCombinable(String a, String b) {
    return mergeRecipes.containsKey('$a+$b') || mergeRecipes.containsKey('$b+$a');
  }

  FieldElement? _findNearestTarget(FieldElement src) {
    FieldElement? best;
    var bestDist = 999999.0;
    for (final e in elements) {
      if (e.uid == src.uid) continue;
      final d = (e.position - src.position).distance;
      if (d < bestDist && d <= 56) {
        bestDist = d;
        best = e;
      }
    }
    return best;
  }

  bool _isOverTrash(Offset p) {
    final trash = Rect.fromLTWH(canvasSize.width - 88, canvasSize.height - 88, 72, 72);
    return trash.contains(p);
  }

  void _commitMergeIfReady() {
    if (dragging == null || hoverTargetUid == null || hoverSec < holdSec || !hoverTargetCombinable) return;

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
    if (dragging == null || trashHoldSec < holdSec) return;
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

  String _megaIngredientStatus(MegaRecipe r) {
    final counts = <String, int>{};
    for (final e in elements) {
      counts[e.elementId] = (counts[e.elementId] ?? 0) + 1;
    }
    final parts = <String>[];
    for (final ing in r.ingredients) {
      final ok = (counts[ing] ?? 0) > 0;
      parts.add('${elementDefs[ing]?.name ?? ing}:${ok ? 'O' : 'X'}');
      if (ok) counts[ing] = (counts[ing] ?? 1) - 1;
    }
    return parts.join(', ');
  }

  void _consumeForMega(MegaRecipe r) {
    final req = List<String>.from(r.ingredients);
    for (final ing in req) {
      final idx = elements.indexWhere((e) => e.elementId == ing);
      if (idx >= 0) elements.removeAt(idx);
    }
    _spawnElement(r.rewardMythicId);
  }

  void _autoArrangeElements() {
    const col = 6;
    const x0 = 16.0;
    const y0 = 80.0;
    const dx = 60.0;
    const dy = 64.0;
    for (var i = 0; i < elements.length; i++) {
      final r = i ~/ col;
      final c = i % col;
      elements[i].position = Offset(x0 + c * dx, y0 + r * dy);
    }
    setState(() {});
  }

  Future<void> _loadDesignConfig() async {
    try {
      final raw = await rootBundle.loadString('assets/config/app1_design.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final g = json['gacha'] as Map<String, dynamic>?;
      if (g != null) {
        gachaCommon = (g['common'] as num?)?.toDouble() ?? gachaCommon;
        gachaRare = (g['rare'] as num?)?.toDouble() ?? gachaRare;
        gachaSpecial = (g['special'] as num?)?.toDouble() ?? gachaSpecial;
        gachaLegendary = (g['legendary'] as num?)?.toDouble() ?? gachaLegendary;
      }

      final list = json['megaRecipes'];
      if (list is List) {
        final parsed = list
            .whereType<Map>()
            .map(
              (m) => MegaRecipe(
                id: (m['id'] ?? '').toString(),
                ingredients: ((m['ingredients'] as List?) ?? const []).map((e) => e.toString()).toList(),
                rewardMythicId: (m['rewardMythicId'] ?? '').toString(),
              ),
            )
            .where((r) => r.id.isNotEmpty && r.ingredients.length == 4 && r.rewardMythicId.isNotEmpty)
            .toList();
        if (parsed.isNotEmpty) megaRecipes = parsed;
      }

      if (mounted) setState(() {});
    } catch (_) {
      // defaults
    }
  }

  Future<void> _loadAdRewardState() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';
    final savedDay = prefs.getString(_adDayKey);
    final savedCount = prefs.getInt(_adCountKey) ?? 0;
    final expMs = prefs.getInt(_adExpireKey);

    setState(() {
      if (savedDay == today) {
        adRewardUsedToday = savedCount;
      } else {
        adRewardUsedToday = 0;
      }
      if (expMs != null) {
        adBuffExpiresAt = DateTime.fromMillisecondsSinceEpoch(expMs);
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
    final today = '${now.year}-${now.month}-${now.day}';

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

  Future<void> _activateAdBuff() async {
    if (_isAdBuffActive) return;
    final prefs = await SharedPreferences.getInstance();
    final exp = DateTime.now().add(const Duration(hours: 16));
    setState(() => adBuffExpiresAt = exp);
    await prefs.setInt(_adExpireKey, exp.millisecondsSinceEpoch);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: switch (page) {
        0 => _buildTimePage(),
        1 => _buildGachaPage(),
        2 => _buildHome(),
        3 => _buildCodex(),
        4 => _buildMega(),
        _ => _buildAdsPage(),
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
            if (dragging != null && hoverTargetUid != null)
              Positioned(
                top: 46,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    hoverTargetCombinable
                        ? '${elementDefs[dragging!.elementId]?.name ?? dragging!.elementId} + ${elementDefs[elements.firstWhere((x) => x.uid == hoverTargetUid).elementId]?.name ?? ''}'
                        : '합성불가',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            Positioned(
              left: 8,
              top: 8,
              child: Row(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text('Tickets: $tickets/$ticketCap · 포인트: $elementPoint · 원소 ${elements.length}/$maxFieldElements'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: _autoArrangeElements,
                    icon: const Icon(Icons.auto_fix_high),
                    label: const Text('정렬'),
                  ),
                ],
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
          setState(() {
            dragging = e;
            elements.removeWhere((x) => x.uid == e.uid);
            elements.add(e);
            hoverSec = 0;
            trashHoldSec = 0;
          });
        },
        onPanUpdate: (d) {
          setState(() {
            e.position = Offset(
              (e.position.dx + d.delta.dx).clamp(0, canvasSize.width - 56),
              (e.position.dy + d.delta.dy).clamp(0, canvasSize.height - 96),
            );
            _pushAwayNearby(e);
          });
        },
        onPanEnd: (_) {
          setState(() {
            _commitMergeIfReady();
            _commitTrashIfReady();
            dragging = null;
            hoverTargetUid = null;
            hoverTargetCombinable = false;
            hoverSec = 0;
            trashHoldSec = 0;
          });
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: isDragging ? 67.2 : 56,
              height: isDragging ? 67.2 : 56,
              decoration: BoxDecoration(
                color: _rarityColor(def.rarity),
                borderRadius: BorderRadius.circular(isDragging ? 33.6 : 28),
                border: Border.all(
                  color: isDragging
                      ? Colors.black
                      : (isHoverTarget ? Colors.amber : Colors.white),
                  width: isDragging ? 3 : 2,
                ),
              ),
              child: Center(
                child: Text(
                  def.name,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            if (isDragging && hoverSec > 0)
              Positioned.fill(
                child: CircularProgressIndicator(
                  value: (hoverSec / holdSec).clamp(0.0, 1.0),
                  strokeWidth: 3,
                ),
              ),
            if (isDragging && hoverTargetUid != null && !hoverTargetCombinable)
              const Positioned(
                top: -4,
                right: -4,
                child: Icon(Icons.close, color: Colors.redAccent, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  Widget _trashWidget() {
    final progress = (trashHoldSec / holdSec).clamp(0.0, 1.0).toDouble();
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

  Widget _buildTimePage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('시간 페이지', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('원소 포인트: $elementPoint'),
          Text('클릭 파워: $_clickPower'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _clickGain,
            icon: const Icon(Icons.touch_app),
            label: const Text('클릭 (+포인트)'),
          ),
          const SizedBox(height: 8),
          const Text('기본: 1초당 포인트 1개, 클릭 시 포인트 +5 (최종원소 발견 수에 따라 증가)'),
          if (_isAdBuffActive)
            Text('광고 버프 적용 중: ${adBuffExpiresAt!.difference(DateTime.now()).inHours}h 남음'),
        ],
      ),
    );
  }

  Widget _buildGachaPage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const Text('가챠샵', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('티켓: $tickets/$ticketCap'),
          Text('원소 포인트: $elementPoint'),
          const SizedBox(height: 8),
          Text('확률: 일반 ${(gachaCommon * 100).toStringAsFixed(1)}% / 희귀 ${(gachaRare * 100).toStringAsFixed(1)}% / 특수 ${(gachaSpecial * 100).toStringAsFixed(1)}% / 전설 ${(gachaLegendary * 100).toStringAsFixed(2)}%'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => setState(() => _spawnFromGacha(count: 1)),
                  child: const Text('1회 뽑기'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _spawnFromGacha(count: 10)),
                  child: const Text('10회 뽑기'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('티켓 구매', style: TextStyle(fontWeight: FontWeight.bold)),
          const Text('티켓 1장 = 원소포인트 20'),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(onPressed: () => _buyTicket(1), child: const Text('1장 구매')),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(onPressed: () => _buyTicket(5), child: const Text('5장 구매')),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('광고 보상(가챠권)', style: TextStyle(fontWeight: FontWeight.bold)),
          FilledButton.tonal(
            onPressed: adRewardUsedToday < 3 ? _rewardByAdPlaceholder : null,
            child: Text('광고 보고 +가챠권 10 (오늘 $adRewardUsedToday/3)'),
          ),
          const Text('※ 현재 광고 API 미연동. 보상만 지급'),
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
              subtitle: Text(active ? '활성화됨 (3초 꾹 눌러 발동)' : '재료 부족: ${_megaIngredientStatus(r)}'),
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

  Widget _buildAdsPage() {
    final remain = adBuffExpiresAt?.difference(DateTime.now());
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const Text('광고 페이지', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(_isAdBuffActive
              ? '버프 활성: ${remain?.inHours ?? 0}h ${(remain?.inMinutes ?? 0) % 60}m 남음'
              : '버프 비활성'),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: _isAdBuffActive ? null : _activateAdBuff,
            child: const Text('광고 시청 (16시간 모든 수치 2배)'),
          ),
          const SizedBox(height: 6),
          const Text('버프 지속 중에는 재시청으로 누적되지 않습니다.'),
        ],
      ),
    );
  }

  Widget _bottomNav() {
    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          children: [
            Expanded(child: _navBtn('시간', 0, Icons.schedule)),
            Expanded(child: _navBtn('가챠', 1, Icons.casino)),
            Expanded(child: _navBtn('홈', 2, Icons.home)),
            Expanded(child: _navBtn('도감', 3, Icons.menu_book)),
            Expanded(child: _navBtn('합성', 4, Icons.auto_awesome)),
            Expanded(child: _navBtn('광고', 5, Icons.ondemand_video)),
          ],
        ),
      ),
    );
  }

  Widget _navBtn(String label, int idx, IconData icon) {
    final selected = page == idx;
    return InkWell(
      onTap: () => setState(() => page = idx),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: selected ? Colors.teal : Colors.grey),
          Text(label, style: TextStyle(fontSize: 11, color: selected ? Colors.teal : Colors.grey)),
        ],
      ),
    );
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
              CircularProgressIndicator(value: (sec / 3).clamp(0.0, 1.0), strokeWidth: 3),
          ],
        ),
      ),
    );
  }
}
