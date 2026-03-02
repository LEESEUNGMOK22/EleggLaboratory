import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_ui/shared_ui.dart';

import 'core/board_game_state.dart';
import 'core/logbook.dart';
import 'core/offline_summary.dart';
import 'core/upgrades.dart';
import 'data/element_tables.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App One',
      theme: SharedUiTheme.light(),
      home: const IdleMergeBoardPage(),
    );
  }
}

class IdleMergeBoardPage extends StatefulWidget {
  const IdleMergeBoardPage({super.key});

  @override
  State<IdleMergeBoardPage> createState() => _IdleMergeBoardPageState();
}

class _IdleMergeBoardPageState extends State<IdleMergeBoardPage>
    with WidgetsBindingObserver {
  static const _saveKey = 'app_one_state_v1';

  BoardGameState game = BoardGameState();
  Timer? timer;
  int? selected;
  int tabIndex = 0;
  DateTime? pausedAt;
  LogType? logFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadState();
    timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      setState(() => game.tick(0.2));
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      pausedAt = DateTime.now();
      _saveState();
      return;
    }

    if (state == AppLifecycleState.resumed && pausedAt != null) {
      final sec = DateTime.now().difference(pausedAt!).inSeconds;
      pausedAt = null;
      if (sec > 1) {
        final summary = game.applyOffline(sec);
        _saveState();
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showOfflineSummary(summary);
          });
        }
      }
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    _saveState();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App One · Idle Merge')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _hud(),
            const SizedBox(height: 8),
            Expanded(child: _tabBody()),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabIndex,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grid_on), label: 'Board'),
          NavigationDestination(icon: Icon(Icons.trending_up), label: 'Upgrades'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Logs'),
        ],
        onDestinationSelected: (i) => setState(() => tabIndex = i),
      ),
    );
  }

  Widget _tabBody() {
    return switch (tabIndex) {
      0 => Column(children: [_actions(), const SizedBox(height: 10), Expanded(child: _board())]),
      1 => _upgrades(),
      _ => _logs(),
    };
  }

  Widget _hud() {
    final nextTicketSec = game.tickets >= game.ticketCap
        ? 0
        : (game.ticketIntervalSec - game.ticketRemainderSec);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Essence: ${game.essence.toStringAsFixed(1)}'),
            Text('Residue: ${game.residue}'),
            Text('Tap: ${game.tapValue.toStringAsFixed(1)} ${game.clickBurstSec > 0 ? '(Burst ${game.clickBurstSec.toStringAsFixed(1)}s)' : ''}'),
            Text('AutoTap: ${game.autoTapEnabled ? 'ON' : 'OFF'}'),
            Text('Tickets: ${game.tickets}/${game.ticketCap} · next in ${nextTicketSec}s'),
            Text('Board: ${game.filledCount}/${game.boardSlots}'),
          ],
        ),
      ),
    );
  }

  Widget _actions() {
    return Row(
      children: [
        Expanded(
          child: FilledButton(
            onPressed: () {
              setState(() {
                game.summonOne();
              });
              _saveState();
            },
            child: const Text('Summon x1'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                for (var i = 0; i < 10; i++) {
                  if (!game.summonOne()) break;
                }
              });
              _saveState();
            },
            child: const Text('Summon x10'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              setState(() {
                game.tap();
              });
              _saveState();
            },
            child: const Text('Tap'),
          ),
        ),
      ],
    );
  }

  Widget _board() {
    return GridView.builder(
      itemCount: game.boardSlots,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: BoardGameState.cols,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemBuilder: (context, index) {
        final tile = game.board[index];
        final isSelected = selected == index;
        return InkWell(
          onTap: () => setState(() {
            if (tile == null) {
              selected = null;
              return;
            }
            if (selected == null) {
              selected = index;
              return;
            }
            if (selected != null && selected != index) {
              final merged = game.merge(selected!, index);
              selected = merged ? null : index;
              if (merged) {
                _saveState();
              }
            }
          }),
          child: Container(
            decoration: BoxDecoration(
              color: tile == null ? Colors.black12 : _colorFor(tile.form),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Colors.amber : Colors.black26,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: tile == null
                ? const SizedBox.shrink()
                : Center(
                    child: Text(
                      '${tile.form.name}\nT${tile.tier}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _upgrades() {
    return ListView(
      children: [
        const Text('Upgrades (v1)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...kUpgradeDefs.map((u) {
          final purchased = (game.purchased[u.id] ?? 0) > 0;
          return Card(
            child: ListTile(
              title: Text(u.name),
              subtitle: Text('${u.category.name} · cost ${u.cost.toStringAsFixed(0)}'),
              trailing: FilledButton(
                onPressed: purchased
                    ? null
                    : () {
                        setState(() {
                          game.buyUpgrade(u);
                        });
                        _saveState();
                      },
                child: Text(purchased ? 'Done' : 'Buy'),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _logs() {
    final items = game.getRecentLogs(type: logFilter, limit: 80);
    final byType = <LogType, int>{};
    for (final e in game.logs) {
      byType[e.type] = (byType[e.type] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Logbook', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: [
            ChoiceChip(
              label: const Text('전체'),
              selected: logFilter == null,
              onSelected: (_) => setState(() => logFilter = null),
            ),
            ...LogType.values.map(
              (t) => ChoiceChip(
                label: Text('${t.name} (${byType[t] ?? 0})'),
                selected: logFilter == t,
                onSelected: (_) => setState(() => logFilter = t),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final e = items[i];
              return ListTile(
                dense: true,
                title: Text(e.type.name),
                subtitle: Text(e.payload.toString()),
                trailing: Text(
                  e.isOffline ? 'offline' : '',
                  style: const TextStyle(fontSize: 11),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showOfflineSummary(OfflineSummary s) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('오프라인 정산'),
        content: Text(
          '경과: ${s.elapsedSec}s\n'
          'Essence: +${s.essenceGained.toStringAsFixed(1)}\n'
          'Residue: +${s.residueGained}\n'
          'Tickets: +${s.ticketsGained}\n'
          'Transform: ${s.transformCount}회',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('확인')),
        ],
      ),
    );
  }

  Color _colorFor(ElementForm form) {
    return switch (form) {
      ElementForm.flame || ElementForm.smoke || ElementForm.ash || ElementForm.soot => Colors.deepOrange.shade200,
      ElementForm.water || ElementForm.vapor || ElementForm.cloud || ElementForm.dew => Colors.blue.shade200,
      ElementForm.soil || ElementForm.mud || ElementForm.clay || ElementForm.stone => Colors.brown.shade200,
      _ => Colors.cyan.shade200,
    };
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_saveKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        game = BoardGameState.fromMap(map);
      });
    } catch (_) {
      // ignore broken save
    }
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_saveKey, jsonEncode(game.toMap()));
  }
}
