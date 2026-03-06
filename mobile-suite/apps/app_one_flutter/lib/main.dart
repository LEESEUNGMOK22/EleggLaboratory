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
enum ArrangeMode { kind, rarity, recent }

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
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
        fontFamily: 'ChogoonKR',
        scaffoldBackgroundColor: const Color(0xFF0B1220),
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Color(0xFFE5E7EB))),
      ),
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
  static const _saveStateKey = 'app1_state_v2';
  static const double holdSec = 2.0;
  static const int maxFieldElements = 80;

  final random = Random();
  final elements = <FieldElement>[];
  final discovered = <String>{};

  int page = 2; // 0 time, 1 gacha, 2 home, 3 codex, 4 mega

  int tickets = 20;
  int ticketCap = 30;

  int elementPoint = 0;
  int clickBase = 5;
  double passivePointPerSec = 1;
  int finalElementClickBonus = 2;
  int ticketPointCost = 20;

  int adRewardUsedToday = 0;
  int adDailyClaims = 3;
  int adTicketRewardAmount = 10;
  int adBuffHours = 16;
  int adBuffMultiplier = 2;
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
  double _autosaveSec = 0;
  ArrangeMode arrangeMode = ArrangeMode.kind;
  bool megaActiveOnly = false;
  String megaQuery = '';
  String? fxMessage;
  Color fxColor = Colors.white;
  Rarity? codexFilter;
  final Set<String> codexRarityRewarded = {};

  @override
  void initState() {
    super.initState();
    _loadAdRewardState();
    _loadDesignConfig();
    _loadBalanceConfig();
    _loadGameState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (elements.isEmpty) {
        _spawnElement('fire');
        _spawnElement('water');
        _spawnElement('earth');
        _spawnElement('air');
      }
    });
    loop = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() => _tick(0.1));
    });
  }

  @override
  void dispose() {
    loop?.cancel();
    _saveGameState();
    super.dispose();
  }

  bool get _isAdBuffActive {
    if (adBuffExpiresAt == null) return false;
    return DateTime.now().isBefore(adBuffExpiresAt!);
  }

  int get _clickPower {
    final finalCount = discovered.where((id) => elementDefs[id]?.rarity == Rarity.finalTier).length;
    final power = clickBase + finalCount * finalElementClickBonus;
    return (_isAdBuffActive ? power * adBuffMultiplier : power);
  }


  void _showFx(String msg, {Color color = Colors.white}) {
    fxMessage = msg;
    fxColor = color;
    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) return;
      if (fxMessage == msg) {
        setState(() => fxMessage = null);
      }
    });
  }

  int _ticketUnitCost() {
    if (tickets < 10) return ticketPointCost;
    if (tickets < 20) return ticketPointCost + 5;
    return ticketPointCost + 10;
  }

  void _tick(double dt) {
    // 초당 포인트
    final perTick = passivePointPerSec * dt;
    final add = perTick.floor() + (random.nextDouble() < (perTick % 1) ? 1 : 0);
    if (add > 0) {
      elementPoint += (_isAdBuffActive ? add * adBuffMultiplier : add);
    }

    if (_isAdBuffActive && DateTime.now().isAfter(adBuffExpiresAt!)) {
      adBuffExpiresAt = null;
    }

    _autosaveSec += dt;
    if (_autosaveSec >= 5) {
      _autosaveSec = 0;
      _saveGameState();
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
    final total = count * _ticketUnitCost();
    if (elementPoint < total) return;
    setState(() {
      elementPoint -= total;
      tickets = (tickets + count).clamp(0, ticketCap);
    });
    _saveGameState();
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
    _saveGameState();
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
    FieldElement? bestAny;
    var bestAnyDist = 999999.0;
    FieldElement? bestCombinable;
    var bestCombDist = 999999.0;

    for (final e in elements) {
      if (e.uid == src.uid) continue;
      final d = (e.position - src.position).distance;
      if (d > 56) continue;

      if (d < bestAnyDist) {
        bestAnyDist = d;
        bestAny = e;
      }

      if (_isCombinable(src.elementId, e.elementId) && d < bestCombDist) {
        bestCombDist = d;
        bestCombinable = e;
      }
    }
    return bestCombinable ?? bestAny;
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
    _showFx('합성 성공!', color: const Color(0xFF2CCFBF));
  }

  void _commitTrashIfReady() {
    if (dragging == null || trashHoldSec < holdSec) return;
    elements.removeWhere((e) => e.uid == dragging!.uid);
    _showFx('원소 삭제됨', color: const Color(0xFFF87171));
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
    _saveGameState();
    _showFx('신화 원소 획득!', color: const Color(0xFFFBBF24));
  }

  String _arrangeModeLabel(ArrangeMode m) {
    return switch (m) {
      ArrangeMode.kind => '종류',
      ArrangeMode.rarity => '등급',
      ArrangeMode.recent => '최근',
    };
  }

  void _nextArrangeModeAndApply() {
    arrangeMode = ArrangeMode.values[(arrangeMode.index + 1) % ArrangeMode.values.length];
    _autoArrangeElements();
  }

  void _autoArrangeElements() {
    const col = 6;
    const x0 = 16.0;
    const y0 = 80.0;
    const dx = 60.0;
    const dy = 64.0;

    final list = List<FieldElement>.from(elements);
    if (arrangeMode == ArrangeMode.kind) {
      list.sort((a, b) => a.elementId.compareTo(b.elementId));
    } else if (arrangeMode == ArrangeMode.rarity) {
      list.sort((a, b) {
        final ra = elementDefs[a.elementId]!.rarity.index;
        final rb = elementDefs[b.elementId]!.rarity.index;
        return ra.compareTo(rb);
      });
    } else {
      list.sort((a, b) => b.uid.compareTo(a.uid));
    }

    for (var i = 0; i < list.length; i++) {
      final r = i ~/ col;
      final c = i % col;
      list[i].position = Offset(x0 + c * dx, y0 + r * dy);
    }

    elements
      ..clear()
      ..addAll(list);
    setState(() {});
    _saveGameState();
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


  Future<void> _loadBalanceConfig() async {
    try {
      final raw = await rootBundle.loadString('assets/config/app1_balance.json');
      final j = jsonDecode(raw) as Map<String, dynamic>;
      passivePointPerSec = (j['passivePointPerSec'] as num?)?.toDouble() ?? passivePointPerSec;
      clickBase = (j['baseClick'] as num?)?.toInt() ?? clickBase;
      finalElementClickBonus = (j['finalElementClickBonus'] as num?)?.toInt() ?? finalElementClickBonus;
      ticketCap = (j['ticketCap'] as num?)?.toInt() ?? ticketCap;
      ticketPointCost = (j['ticketPointCost'] as num?)?.toInt() ?? ticketPointCost;
      final ad = j['ad'] as Map<String, dynamic>?;
      if (ad != null) {
        adDailyClaims = (ad['dailyTicketRewardClaims'] as num?)?.toInt() ?? adDailyClaims;
        adTicketRewardAmount = (ad['dailyTicketRewardAmount'] as num?)?.toInt() ?? adTicketRewardAmount;
        adBuffHours = (ad['buffHours'] as num?)?.toInt() ?? adBuffHours;
        adBuffMultiplier = (ad['buffMultiplier'] as num?)?.toInt() ?? adBuffMultiplier;
      }
      if (mounted) setState(() {});
    } catch (_) {}
  }


  Future<void> _saveGameState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = {
        'page': page,
        'tickets': tickets,
        'ticketCap': ticketCap,
        'elementPoint': elementPoint,
        'clickBase': clickBase,
        'passivePointPerSec': passivePointPerSec,
        'finalElementClickBonus': finalElementClickBonus,
        'ticketPointCost': ticketPointCost,
        'adRewardUsedToday': adRewardUsedToday,
        'adDailyClaims': adDailyClaims,
        'adTicketRewardAmount': adTicketRewardAmount,
        'adBuffHours': adBuffHours,
        'adBuffMultiplier': adBuffMultiplier,
        'adBuffExpiresAtMs': adBuffExpiresAt?.millisecondsSinceEpoch,
        'discovered': discovered.toList(),
        'elements': elements
            .map((e) => {
                  'uid': e.uid,
                  'elementId': e.elementId,
                  'x': e.position.dx,
                  'y': e.position.dy,
                })
            .toList(),
      };
      await prefs.setString(_saveStateKey, jsonEncode(map));
    } catch (_) {}
  }

  Future<void> _loadGameState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_saveStateKey);
      if (raw == null || raw.isEmpty) return;
      final map = jsonDecode(raw) as Map<String, dynamic>;

      final loadedElements = <FieldElement>[];
      final els = map['elements'];
      if (els is List) {
        for (final it in els.whereType<Map>()) {
          loadedElements.add(FieldElement(
            uid: (it['uid'] ?? '').toString(),
            elementId: (it['elementId'] ?? 'fire').toString(),
            position: Offset(
              (it['x'] as num?)?.toDouble() ?? 30,
              (it['y'] as num?)?.toDouble() ?? 100,
            ),
          ));
        }
      }

      if (!mounted) return;
      setState(() {
        page = (map['page'] as num?)?.toInt() ?? page;
        tickets = (map['tickets'] as num?)?.toInt() ?? tickets;
        ticketCap = (map['ticketCap'] as num?)?.toInt() ?? ticketCap;
        elementPoint = (map['elementPoint'] as num?)?.toInt() ?? elementPoint;
        clickBase = (map['clickBase'] as num?)?.toInt() ?? clickBase;
        passivePointPerSec = (map['passivePointPerSec'] as num?)?.toDouble() ?? passivePointPerSec;
        finalElementClickBonus = (map['finalElementClickBonus'] as num?)?.toInt() ?? finalElementClickBonus;
        ticketPointCost = (map['ticketPointCost'] as num?)?.toInt() ?? ticketPointCost;
        adRewardUsedToday = (map['adRewardUsedToday'] as num?)?.toInt() ?? adRewardUsedToday;
        adDailyClaims = (map['adDailyClaims'] as num?)?.toInt() ?? adDailyClaims;
        adTicketRewardAmount = (map['adTicketRewardAmount'] as num?)?.toInt() ?? adTicketRewardAmount;
        adBuffHours = (map['adBuffHours'] as num?)?.toInt() ?? adBuffHours;
        adBuffMultiplier = (map['adBuffMultiplier'] as num?)?.toInt() ?? adBuffMultiplier;
        final expMs = (map['adBuffExpiresAtMs'] as num?)?.toInt();
        adBuffExpiresAt = expMs == null ? adBuffExpiresAt : DateTime.fromMillisecondsSinceEpoch(expMs);

        discovered
          ..clear()
          ..addAll(((map['discovered'] as List?) ?? const []).map((e) => e.toString()));

        if (loadedElements.isNotEmpty) {
          elements
            ..clear()
            ..addAll(loadedElements);
        }
      });
    } catch (_) {}
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
    if (adRewardUsedToday >= adDailyClaims) return;
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
      tickets = (tickets + adTicketRewardAmount).clamp(0, ticketCap);
    });

    await prefs.setInt(_adCountKey, adRewardUsedToday);
    _saveGameState();
  }

  Future<void> _activateAdBuff() async {
    if (_isAdBuffActive) return;
    final prefs = await SharedPreferences.getInstance();
    final exp = DateTime.now().add(Duration(hours: adBuffHours));
    setState(() => adBuffExpiresAt = exp);
    await prefs.setInt(_adExpireKey, exp.millisecondsSinceEpoch);
    _saveGameState();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_pageBgAsset()),
            fit: BoxFit.cover,
            opacity: 0.18,
          ),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xEE0B1220), Color(0xEE111827), Color(0xEE0F172A)],
          ),
        ),
        child: switch (page) {
          0 => _buildTimePage(),
          1 => _buildGachaPage(),
          2 => _buildHome(),
          3 => _buildCodex(),
          _ => _buildMega(),
        },
      ),
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
                    color: const Color(0x66222B3A),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tickets $tickets/$ticketCap  ·  Points $elementPoint', style: const TextStyle(color: Color(0xFFE5E7EB), fontWeight: FontWeight.w700)),
                          Text('필드 ${elements.length}/$maxFieldElements${elements.length >= maxFieldElements ? ' (가득 참)' : ''}', style: const TextStyle(color: Color(0xFFB6C2D1), fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(backgroundColor: const Color(0x3314B8A6)),
                    onPressed: _nextArrangeModeAndApply,
                    icon: const Icon(Icons.auto_fix_high),
                    label: Text('정렬:${_arrangeModeLabel(arrangeMode)}'),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              top: 58,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xAA0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0x552CCFBF)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _homePrimaryHint(),
                        style: const TextStyle(color: Color(0xFFE5E7EB), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: () {
                        setState(() => page = _homeHintTargetPage());
                        _saveGameState();
                      },
                      child: const Text('이동'),
                    ),
                  ],
                ),
              ),
            ),
            if (fxMessage != null)
              Positioned(
                top: 92,
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: fxMessage == null ? 0 : 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: fxColor.withValues(alpha: 0.8)),
                      ),
                      child: Text(fxMessage!, style: TextStyle(color: fxColor, fontWeight: FontWeight.w700)),
                    ),
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
          });
        },
        onPanEnd: (_) {
          setState(() {
            _commitMergeIfReady();
            _commitTrashIfReady();
            if (dragging != null) _pushAwayNearby(dragging!);
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
                boxShadow: [
                  BoxShadow(
                    color: _rarityColor(def.rarity).withValues(alpha: 0.45),
                    blurRadius: def.rarity.index >= Rarity.legendary.index ? 14 : 6,
                    spreadRadius: def.rarity.index >= Rarity.legendary.index ? 1.2 : 0.4,
                  ),
                ],
                border: Border.all(
                  color: isDragging
                      ? Colors.black
                      : (isHoverTarget ? Colors.amber : Colors.white.withValues(alpha: 0.9)),
                  width: isDragging ? 3 : 2,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Image.asset(
                          _rarityAsset(def.rarity),
                          width: 18,
                          height: 18,
                          fit: BoxFit.contain,
                        ),
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(color: _rarityColor(def.rarity), shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1)),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      def.name,
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox.shrink(),
                  ],
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
              Positioned(
                top: -2,
                right: -2,
                child: Icon(Icons.close, color: Colors.redAccent.withValues(alpha: 0.75), size: 12),
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
          _title('시간 페이지'),
          const SizedBox(height: 8),
        ..._recommendedMegaRecipes().map((r) => Text('추천: ${r.id}')).take(3),
          Text('원소 포인트: $elementPoint'),
          Text('클릭 파워: $_clickPower'),
          const SizedBox(height: 12),
          const SizedBox(height: 12),
          Center(
            child: SizedBox(
              width: 260,
              height: 72,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2CCFBF),
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                ),
                onPressed: _clickGain,
                icon: const Icon(Icons.touch_app, size: 28),
                label: const Text('클릭 (+포인트)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('기본: 1초당 포인트 ${passivePointPerSec.toStringAsFixed(1)}개, 클릭 시 +$clickBase (최종원소 보너스 +$finalElementClickBonus)'),
          if (_isAdBuffActive)
            Text('광고 버프 적용 중: ${adBuffExpiresAt!.difference(DateTime.now()).inHours}h 남음'),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 8),
          const Text('광고 버프', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(_isAdBuffActive
              ? '버프 활성: ${adBuffExpiresAt!.difference(DateTime.now()).inHours}h ${(adBuffExpiresAt!.difference(DateTime.now()).inMinutes) % 60}m 남음'
              : '버프 비활성'),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _isAdBuffActive ? null : _activateAdBuff,
            child: Text('광고 시청 ($adBuffHours시간 모든 수치 $adBuffMultiplier배)'),
          ),
          const SizedBox(height: 4),
          const Text('버프 지속 중에는 재시청 누적되지 않습니다.'),
        ],
      ),
    );
  }

  Widget _buildGachaPage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          _title('가챠샵'),
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
          Text('티켓 1장 = 원소포인트 $ticketPointCost'),
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
            onPressed: adRewardUsedToday < adDailyClaims ? _rewardByAdPlaceholder : null,
            child: Text('광고 보고 +가챠권 $adTicketRewardAmount (오늘 $adRewardUsedToday/$adDailyClaims)'),
          ),
          const Text('※ 현재 광고 API 미연동. 보상만 지급'),
        ],
      ),
    );
  }

  Widget _buildCodex() {
    final all = elementDefs.values.toList()..sort((a, b) => a.name.compareTo(b.name));
    final found = all.where((e) => discovered.contains(e.id)).toList();

    final rarityFoundCounts = <Rarity, int>{for (final r in Rarity.values) r: 0};
    final rarityTotalCounts = <Rarity, int>{for (final r in Rarity.values) r: 0};
    for (final e in all) {
      rarityTotalCounts[e.rarity] = (rarityTotalCounts[e.rarity] ?? 0) + 1;
      if (discovered.contains(e.id)) {
        rarityFoundCounts[e.rarity] = (rarityFoundCounts[e.rarity] ?? 0) + 1;
      }
    }

    for (final r in Rarity.values) {
      final done = (rarityFoundCounts[r] ?? 0) > 0 && rarityFoundCounts[r] == rarityTotalCounts[r];
      final key = r.name;
      if (done && !codexRarityRewarded.contains(key)) {
        codexRarityRewarded.add(key);
        elementPoint += 50;
        tickets = (tickets + 1).clamp(0, ticketCap);
        _showFx('${_rarityKorean(r)} 등급 도감 완성 보상!', color: const Color(0xFFFBBF24));
      }
    }

    final filtered = codexFilter == null ? all : all.where((e) => e.rarity == codexFilter).toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _title('도감'),
        Text('발견 ${found.length}/${all.length}'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          children: [
            ChoiceChip(label: const Text('전체'), selected: codexFilter == null, onSelected: (_) => setState(() => codexFilter = null)),
            ...Rarity.values.map((r) => ChoiceChip(
              label: Text('${_rarityKorean(r)} ${(rarityFoundCounts[r] ?? 0)}/${rarityTotalCounts[r] ?? 0}'),
              selected: codexFilter == r,
              onSelected: (_) => setState(() => codexFilter = r),
            )),
          ],
        ),
        const SizedBox(height: 8),
        ...filtered.map((e) {
          final ok = discovered.contains(e.id);
          return ListTile(
            dense: true,
            leading: Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked),
            title: Text(e.name),
            subtitle: Text('등급: ${_rarityKorean(e.rarity)}'),
            trailing: Text(ok ? '발견' : '미발견'),
          );
        }),
      ],
    );
  }

  Widget _buildMega() {
    final normalEntries = mergeRecipes.entries.toList();

    final filteredMega = megaRecipes.where((r) {
      final txt = '${r.ingredients.join(' ')} ${r.rewardMythicId}'.toLowerCase();
      if (megaQuery.isNotEmpty && !txt.contains(megaQuery.toLowerCase())) return false;
      if (megaActiveOnly && !_canMega(r)) return false;
      return true;
    }).toList();

    final activeCount = megaRecipes.where(_canMega).length;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _title('대규모 합성'),
        const SizedBox(height: 8),
        Text('활성 레시피: $activeCount / ${megaRecipes.length}'),
        Text('부족 재료 Top1: ${_missingTopOne()}'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: '레시피 검색',
                  filled: true,
                ),
                onChanged: (v) => setState(() => megaQuery = v),
              ),
            ),
            const SizedBox(width: 8),
            FilterChip(
              label: const Text('활성만'),
              selected: megaActiveOnly,
              onSelected: (v) => setState(() => megaActiveOnly = v),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...filteredMega.map((r) {
          final active = _canMega(r);
          final reward = elementDefs[r.rewardMythicId]!;
          return Card(
            child: ListTile(
              title: Text('${r.ingredients.join(' + ')} => ${reward.name}'),
              subtitle: Text(active ? '활성화됨 (2초 꾹 눌러 발동)' : '재료 부족: ${_megaIngredientStatus(r)}'),
              trailing: _Hold3sButton(
                holdSec: holdSec,
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
        const SizedBox(height: 12),
        const Text('일반 조합 레시피', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ...normalEntries.map((e) {
          final pair = e.key.split('+');
          final a = elementDefs[pair[0]]?.name ?? pair[0];
          final b = elementDefs[pair[1]]?.name ?? pair[1];
          final r = elementDefs[e.value]?.name ?? e.value;
          final unlocked = discovered.contains(e.value);
          return ListTile(
            dense: true,
            title: Text('$a + $b → $r'),
            trailing: Icon(unlocked ? Icons.lock_open : Icons.lock_outline, size: 18),
          );
        }),
      ],
    );
  }


  String _rarityKorean(Rarity r) {
    return switch (r) {
      Rarity.common => '일반',
      Rarity.rare => '희귀',
      Rarity.special => '특수',
      Rarity.legendary => '전설',
      Rarity.finalTier => '최종',
      Rarity.mythic => '신화',
    };
  }

  String _missingTopOne() {
    final miss = <String, int>{};
    for (final r in megaRecipes) {
      for (final ing in r.ingredients) {
        final has = elements.any((e) => e.elementId == ing);
        if (!has) miss[ing] = (miss[ing] ?? 0) + 1;
      }
    }
    if (miss.isEmpty) return '없음';
    final top = miss.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    return elementDefs[top]?.name ?? top;
  }

  List<MegaRecipe> _recommendedMegaRecipes() {
    int missingCount(MegaRecipe r) {
      var m = 0;
      final counts = <String, int>{};
      for (final e in elements) {
        counts[e.elementId] = (counts[e.elementId] ?? 0) + 1;
      }
      for (final ing in r.ingredients) {
        if ((counts[ing] ?? 0) <= 0) {
          m++;
        } else {
          counts[ing] = counts[ing]! - 1;
        }
      }
      return m;
    }

    final list = List<MegaRecipe>.from(megaRecipes);
    list.sort((a, b) => missingCount(a).compareTo(missingCount(b)));
    return list;
  }

  Widget _bottomNav() {
    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          children: [
            Expanded(child: _navBtn('시간', 0, 'assets/art/icons/time.png')),
            Expanded(child: _navBtn('가챠', 1, 'assets/art/icons/gacha.png')),
            Expanded(child: _navBtn('홈', 2, 'assets/art/icons/home.png')),
            Expanded(child: _navBtn('도감', 3, 'assets/art/icons/codex.png')),
            Expanded(child: _navBtn('합성', 4, 'assets/art/icons/mega.png')),
          ],
        ),
      ),
    );
  }

  Widget _navBtn(String label, int idx, String iconAsset) {
    final selected = page == idx;
    return InkWell(
      onTap: () { setState(() => page = idx); _saveGameState(); },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: selected ? const Color(0x332CCFBF) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: selected ? 1.0 : 0.65,
              child: Image.asset(iconAsset, width: 18, height: 18, color: selected ? const Color(0xFF2CCFBF) : Colors.grey),
            ),
            Text(label, style: TextStyle(fontSize: 10, color: selected ? const Color(0xFF2CCFBF) : Colors.grey)),
          ],
        ),
      ),
    );
  }

  int _homeHintTargetPage() {
    if (tickets <= 0) return 1;
    if (elements.length < 2) return 1;
    if (discovered.length < 6) return 2;
    return 4;
  }

  String _homePrimaryHint() {
    if (tickets <= 0) return '가챠 페이지에서 포인트로 티켓을 구매해 원소를 뽑아보세요.';
    if (elements.length < 2) return '원소를 드래그해 다른 원소 위에 2초 유지 후 드랍하면 합성됩니다.';
    if (discovered.length < 6) return '새 조합을 찾아 도감을 채워보세요.';
    return '대규모 합성에서 4재료 조합으로 신화 원소를 획득해보세요.';
  }

  Widget _title(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        shadows: [Shadow(color: Colors.black54, blurRadius: 4, offset: Offset(0, 1))],
      ),
    );
  }

  String _pageBgAsset() {
    return switch (page) {
      0 => 'assets/art/bg/time_bg.png',
      1 => 'assets/art/bg/gacha_bg.png',
      2 => 'assets/art/bg/home_bg.png',
      3 => 'assets/art/bg/codex_bg.png',
      4 => 'assets/art/bg/codex_bg.png',
      _ => 'assets/art/bg/home_bg.png',
    };
  }


  String _rarityAsset(Rarity r) {
    return switch (r) {
      Rarity.common => 'assets/art/coin_1.png',
      Rarity.rare => 'assets/art/coin_3.png',
      Rarity.special || Rarity.legendary || Rarity.finalTier || Rarity.mythic => 'assets/art/coin_9.png',
    };
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
  const _Hold3sButton({required this.enabled, required this.onCommit, this.holdSec = 3});

  final bool enabled;
  final VoidCallback onCommit;
  final double holdSec;

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
      if (sec >= widget.holdSec) {
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
              CircularProgressIndicator(value: (sec / widget.holdSec).clamp(0.0, 1.0), strokeWidth: 3),
          ],
        ),
      ),
    );
  }
}
