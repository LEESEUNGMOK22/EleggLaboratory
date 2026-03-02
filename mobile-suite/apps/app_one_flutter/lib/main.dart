import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

import 'core/board_game_state.dart';
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

class _IdleMergeBoardPageState extends State<IdleMergeBoardPage> {
  final game = BoardGameState();
  Timer? timer;
  int? selected;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      setState(() => game.tick(0.2));
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App One · Board Prototype')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _hud(),
            const SizedBox(height: 8),
            _actions(),
            const SizedBox(height: 12),
            Expanded(child: _board()),
            const SizedBox(height: 8),
            _recentLogs(),
          ],
        ),
      ),
    );
  }

  Widget _hud() {
    final nextTicketSec = game.ticketIntervalSec - game.ticketRemainderSec;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Essence: ${game.essence.toStringAsFixed(1)}'),
            Text('Residue: ${game.residue}'),
            Text('Tickets: ${game.tickets}/${game.ticketCap} · next in ${nextTicketSec}s'),
            Text('Board: ${game.filledCount}/${BoardGameState.size}'),
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
            onPressed: () => setState(() {
              game.summonOne();
            }),
            child: const Text('Summon x1'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: () => setState(() {
              for (var i = 0; i < 10; i++) {
                if (!game.summonOne()) break;
              }
            }),
            child: const Text('Summon x10'),
          ),
        ),
      ],
    );
  }

  Widget _board() {
    return GridView.builder(
      itemCount: BoardGameState.size,
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

  Widget _recentLogs() {
    final list = game.logs.reversed.take(3).toList();
    if (list.isEmpty) {
      return const Text('Logs: 없음');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Logs', style: TextStyle(fontWeight: FontWeight.bold)),
        ...list.map((e) => Text('- ${e.type.name} ${e.payload}')),
      ],
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
}
