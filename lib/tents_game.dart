import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/domain/game_identity.dart';
import 'core/presentation/confirm_restart_dialog.dart';
import 'features/tents/domain/tents_generator.dart';
import 'features/tents/domain/tents_puzzle.dart';
import 'game_storage.dart';

class SavedTentsGame {
  const SavedTentsGame(
      {required this.puzzle,
      required this.marks,
      required this.elapsedSeconds,
      required this.moves});
  final TentsPuzzle puzzle;
  final Map<TentsCell, TentsCellMark> marks;
  final int elapsedSeconds;
  final int moves;

  Map<String, Object?> toJson() => {
        'version': 1,
        'id': puzzle.id,
        'title': puzzle.title,
        'size': puzzle.size,
        'difficulty': puzzle.difficulty.name,
        'trees': [
          for (final c in puzzle.trees) [c.$1, c.$2]
        ],
        'rows': puzzle.rowCounts,
        'columns': puzzle.columnCounts,
        'solution': [
          for (final c in puzzle.solution) [c.$1, c.$2]
        ],
        'marks': [
          for (final e in marks.entries) [e.key.$1, e.key.$2, e.value.name]
        ],
        'elapsedSeconds': elapsedSeconds,
        'moves': moves,
      };

  factory SavedTentsGame.fromJson(Map<String, Object?> json) {
    TentsCell cell(Object? raw) {
      final values = raw! as List;
      return (values[0] as int, values[1] as int);
    }

    final puzzle = TentsPuzzle(
      id: json['id']! as String,
      title: json['title']! as String,
      size: json['size']! as int,
      difficulty: PuzzleDifficulty.values.byName(json['difficulty']! as String),
      trees: (json['trees']! as List).map(cell).toSet(),
      rowCounts: (json['rows']! as List).cast<int>(),
      columnCounts: (json['columns']! as List).cast<int>(),
      solution: (json['solution']! as List).map(cell).toSet(),
    );
    return SavedTentsGame(
      puzzle: puzzle,
      marks: {
        for (final raw in json['marks']! as List)
          ((raw as List)[0] as int, raw[1] as int):
              TentsCellMark.values.byName(raw[2] as String),
      },
      elapsedSeconds: json['elapsedSeconds']! as int,
      moves: json['moves']! as int,
    );
  }
}

class TentsGameStore {
  static const _key = 'active_tents_game_v1';
  Future<void> save(SavedTentsGame game) async =>
      (await SharedPreferences.getInstance())
          .setString(_key, jsonEncode(game.toJson()));
  Future<SavedTentsGame?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null) return null;
    try {
      final saved = SavedTentsGame.fromJson(
          Map<String, Object?>.from(jsonDecode(raw) as Map));
      if (TentsState(puzzle: saved.puzzle, marks: saved.marks).isSolved) {
        await clear();
        return null;
      }
      return saved;
    } on Object {
      await clear();
      return null;
    }
  }

  Future<void> clear() async =>
      (await SharedPreferences.getInstance()).remove(_key);
}

class TentsHubScreen extends StatefulWidget {
  const TentsHubScreen({super.key});
  @override
  State<TentsHubScreen> createState() => _TentsHubScreenState();
}

class _TentsHubScreenState extends State<TentsHubScreen> {
  SavedTentsGame? _saved;
  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final saved = await TentsGameStore().load();
    if (mounted) setState(() => _saved = saved);
  }

  Future<void> _open(PuzzleDifficulty difficulty,
      {SavedTentsGame? saved}) async {
    if (saved == null && _saved != null) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          icon: const Icon(Icons.save_outlined),
          title: const Text('Offenes R\u00e4tsel'),
          content: const Text(
            'Du hast bereits ein begonnenes Lager. M\u00f6chtest du es '
            'fortsetzen oder wirklich ein neues beginnen?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Fortsetzen'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Neu beginnen'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (replace != true) {
        return _open(_saved!.puzzle.difficulty, saved: _saved);
      }
      await TentsGameStore().clear();
    }
    final puzzle = saved?.puzzle ??
        const TentsGenerator().generate(
            seed: DateTime.now().microsecondsSinceEpoch,
            difficulty: difficulty);
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => TentsGameScreen(puzzle: puzzle, savedGame: saved)));
    await _refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Zelte & B\u00e4ume')),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          if (_saved case final saved?) ...[
            Card(
                child: ListTile(
                    leading: const Icon(Icons.play_circle_outline),
                    title: const Text('R\u00e4tsel fortsetzen'),
                    subtitle: Text(
                        '${saved.puzzle.difficulty.label} \u00b7 ${saved.puzzle.size}\u00d7${saved.puzzle.size}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _open(saved.puzzle.difficulty, saved: saved))),
            const SizedBox(height: 16),
          ],
          Text('Zufallsr\u00e4tsel',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text(
              'Finde zu jedem Baum genau ein Zelt. Zelte d\u00fcrfen sich nicht ber\u00fchren.'),
          const SizedBox(height: 16),
          for (final difficulty in PuzzleDifficulty.values)
            Card(
                child: ListTile(
              leading: Icon(switch (difficulty) {
                PuzzleDifficulty.easy => Icons.eco_outlined,
                PuzzleDifficulty.medium => Icons.park_outlined,
                PuzzleDifficulty.hard => Icons.forest_outlined,
              }),
              title: Text(difficulty.label),
              subtitle: Text('${switch (difficulty) {
                PuzzleDifficulty.easy => 6,
                PuzzleDifficulty.medium => 8,
                PuzzleDifficulty.hard => 10
              }} \u00d7 ${switch (difficulty) {
                PuzzleDifficulty.easy => 6,
                PuzzleDifficulty.medium => 8,
                PuzzleDifficulty.hard => 10
              }}'),
              trailing: const Icon(Icons.play_arrow_rounded),
              onTap: () => _open(difficulty),
            )),
        ]),
      );
}

class TentsGameScreen extends StatefulWidget {
  const TentsGameScreen({required this.puzzle, this.savedGame, super.key});
  final TentsPuzzle puzzle;
  final SavedTentsGame? savedGame;
  @override
  State<TentsGameScreen> createState() => _TentsGameScreenState();
}

class _TentsGameScreenState extends State<TentsGameScreen> {
  late TentsState _state;
  final _history = <TentsState>[];
  final _redo = <TentsState>[];
  Timer? _timer;
  int _elapsed = 0;
  int _moves = 0;
  bool _completed = false;
  bool _showConflicts = true;

  @override
  void initState() {
    super.initState();
    _state = TentsState(puzzle: widget.puzzle, marks: widget.savedGame?.marks);
    _elapsed = widget.savedGame?.elapsedSeconds ?? 0;
    _moves = widget.savedGame?.moves ?? 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_completed) {
        setState(() => _elapsed++);
        unawaited(_save());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _save() => TentsGameStore().save(SavedTentsGame(
      puzzle: widget.puzzle,
      marks: _state.marks,
      elapsedSeconds: _elapsed,
      moves: _moves));
  void _tap(int row, int column) {
    if (_completed || widget.puzzle.trees.contains((row, column))) return;
    setState(() {
      _history.add(_state);
      _state = _state.cycle(row, column);
      _redo.clear();
      _moves++;
    });
    unawaited(_save());
    if (_state.isSolved) unawaited(_finish(test: false));
  }

  void _undo() {
    if (_history.isEmpty) return;
    setState(() {
      _redo.add(_state);
      _state = _history.removeLast();
      _moves++;
    });
    unawaited(_save());
  }

  void _redoMove() {
    if (_redo.isEmpty) return;
    setState(() {
      _history.add(_state);
      _state = _redo.removeLast();
      _moves++;
    });
    unawaited(_save());
  }

  Future<void> _restart() async {
    if (!await confirmPuzzleRestart(context) || !mounted) return;
    setState(() {
      _history.add(_state);
      _state = TentsState(puzzle: widget.puzzle);
      _redo.clear();
      _elapsed = 0;
      _moves = 0;
      _completed = false;
    });
    await _save();
  }

  void _debugSolve(bool almost) {
    final solution = widget.puzzle.solution.toList();
    final leave = almost ? solution.last : null;
    final marks = {
      for (final cell in solution)
        if (cell != leave) cell: TentsCellMark.tent
    };
    setState(() {
      _history.add(_state);
      _state = TentsState(puzzle: widget.puzzle, marks: marks);
      _redo.clear();
    });
    if (!almost) unawaited(_finish(test: true));
  }

  Future<void> _finish({required bool test}) async {
    if (_completed) return;
    setState(() => _completed = true);
    await TentsGameStore().clear();
    if (!test) {
      await GameStorage().recordCompletion(
          puzzleId: widget.puzzle.id,
          elapsedSeconds: _elapsed,
          source: GameMode.generated,
          difficulty: widget.puzzle.difficulty,
          boardSize: widget.puzzle.size,
          gameType: GameType.tents,
          moves: _moves);
    }
    if (!mounted) return;
    await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialog) => AlertDialog(
                icon: const Icon(Icons.emoji_events_outlined),
                title: const Text('Lager vollst\u00e4ndig!'),
                content: Text(
                    '${_time(_elapsed)} \u00b7 $_moves Z\u00fcge${test ? '\nTestabschluss \u00b7 keine Statistik' : ''}'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialog),
                      child: const Text('Brett ansehen')),
                  TextButton(
                      onPressed: () {
                        Navigator.pop(dialog);
                        Navigator.pop(context);
                      },
                      child: const Text('Verlassen')),
                  FilledButton(
                      onPressed: () {
                        Navigator.pop(dialog);
                        _next();
                      },
                      child: const Text('Noch eins'))
                ]));
  }

  void _next() => Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
      builder: (_) => TentsGameScreen(
          puzzle: const TentsGenerator().generate(
              seed: DateTime.now().microsecondsSinceEpoch,
              difficulty: widget.puzzle.difficulty,
              size: widget.puzzle.size))));

  @override
  Widget build(BuildContext context) {
    final conflicts = _showConflicts
        ? {
            ..._state.touchingTentConflicts,
            ..._state.countConflicts,
            ..._state.orphanTentConflicts
          }
        : <TentsCell>{};
    return Scaffold(
        appBar: AppBar(
            title: Text(
                '${widget.puzzle.difficulty.label} \u00b7 Zelte & B\u00e4ume'),
            actions: [
              PopupMenuButton<String>(
                  tooltip: 'Testwerkzeuge',
                  icon: const Icon(Icons.bug_report_outlined),
                  onSelected: (v) => _debugSolve(v == 'almost'),
                  itemBuilder: (_) => const [
                        PopupMenuItem(
                            value: 'almost', child: Text('Fast l\u00f6sen')),
                        PopupMenuItem(
                            value: 'solve', child: Text('Sofort l\u00f6sen'))
                      ]),
              IconButton(
                  onPressed: _restart,
                  tooltip: 'Neu starten',
                  icon: const Icon(Icons.restart_alt_rounded))
            ]),
        body: SafeArea(
            child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      Wrap(spacing: 8, children: [
                        Chip(
                            avatar: const Icon(Icons.timer_outlined, size: 18),
                            label: Text(_time(_elapsed))),
                        Chip(
                            avatar:
                                const Icon(Icons.touch_app_outlined, size: 18),
                            label: Text('$_moves Z\u00fcge'))
                      ]),
                      const SizedBox(height: 12),
                      const Text('Tippen: leer \u2192 Zelt \u2192 Gras'),
                      const SizedBox(height: 16),
                      ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: AspectRatio(
                              aspectRatio: 1,
                              child: _TentsBoard(
                                  state: _state,
                                  conflicts: conflicts,
                                  onTap: _tap))),
                      const SizedBox(height: 16),
                      Row(children: [
                        Expanded(
                            child: OutlinedButton.icon(
                                onPressed: _history.isEmpty ? null : _undo,
                                icon: const Icon(Icons.undo_rounded),
                                label: const Text('R\u00fcckg\u00e4ngig'))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: OutlinedButton.icon(
                                onPressed: _redo.isEmpty ? null : _redoMove,
                                icon: const Icon(Icons.redo_rounded),
                                label: const Text('Wiederholen')))
                      ]),
                      if (_completed)
                        Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: SizedBox(
                                width: double.infinity,
                                child: FilledButton.tonalIcon(
                                    onPressed: _next,
                                    icon: const Icon(Icons.auto_awesome),
                                    label:
                                        const Text('Noch ein R\u00e4tsel')))),
                      SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Regelfehler markieren'),
                          subtitle: const Text(
                              'Zeigt sich ber\u00fchrende Zelte und falsche Anzahlen.'),
                          value: _showConflicts,
                          onChanged: (v) => setState(() => _showConflicts = v)),
                      const ExpansionTile(
                          leading: Icon(Icons.menu_book_outlined),
                          title: Text('So funktioniert es'),
                          childrenPadding: EdgeInsets.all(16),
                          children: [
                            Text(
                                'Neben jedem Baum steht genau ein Zelt. Zelte ber\u00fchren sich weder seitlich noch diagonal. Die Zahlen am Rand zeigen die Zelte pro Zeile und Spalte.'),
                            SizedBox(height: 10),
                            Text(
                                'Gras ist eine freiwillige Notiz: Damit markierst du Felder, auf denen sicher kein Zelt stehen kann.')
                          ]),
                    ])))));
  }
}

class _TentsBoard extends StatelessWidget {
  const _TentsBoard(
      {required this.state, required this.conflicts, required this.onTap});
  final TentsState state;
  final Set<TentsCell> conflicts;
  final void Function(int, int) onTap;
  @override
  Widget build(BuildContext context) {
    final size = state.puzzle.size;
    final scheme = Theme.of(context).colorScheme;
    final darkMode = Theme.of(context).brightness == Brightness.dark;
    final treeBackground =
        darkMode ? const Color(0xFF174D32) : const Color(0xFFCDEBD6);
    final treeForeground =
        darkMode ? const Color(0xFFB8F2C9) : const Color(0xFF175C35);
    return GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate:
            SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: size + 1),
        itemCount: (size + 1) * (size + 1),
        itemBuilder: (context, index) {
          final row = index ~/ (size + 1), column = index % (size + 1);
          if (row == 0 && column == 0) return const SizedBox.shrink();
          if (row == 0) {
            return Center(
                child: Text('${state.puzzle.columnCounts[column - 1]}',
                    style: const TextStyle(fontWeight: FontWeight.bold)));
          }
          if (column == 0) {
            return Center(
                child: Text('${state.puzzle.rowCounts[row - 1]}',
                    style: const TextStyle(fontWeight: FontWeight.bold)));
          }
          final cell = (row - 1, column - 1),
              tree = state.puzzle.trees.contains(cell),
              mark = state.markAt(cell.$1, cell.$2);
          final conflict = conflicts.contains(cell);
          return Padding(
              padding: const EdgeInsets.all(1.5),
              child: Material(
                  color: conflict
                      ? scheme.errorContainer
                      : tree
                          ? treeBackground
                          : mark == TentsCellMark.grass
                              ? scheme.surfaceContainerLowest
                              : scheme.surfaceContainer,
                  shape: RoundedRectangleBorder(
                      side: BorderSide(color: scheme.outlineVariant),
                      borderRadius: BorderRadius.circular(7)),
                  child: InkWell(
                      onTap: tree ? null : () => onTap(cell.$1, cell.$2),
                      borderRadius: BorderRadius.circular(7),
                      child: Center(
                        child: mark == TentsCellMark.tent && !tree
                            ? _TentIcon(
                                size: size >= 10 ? 22 : 30,
                                color: conflict
                                    ? scheme.onErrorContainer
                                    : scheme.primary,
                                accentColor: conflict
                                    ? scheme.errorContainer
                                    : scheme.onPrimary,
                              )
                            : Icon(
                                tree
                                    ? Icons.park_rounded
                                    : mark == TentsCellMark.grass
                                        ? Icons.grass_rounded
                                        : null,
                                size: size >= 10 ? 20 : 28,
                                color: conflict
                                    ? scheme.onErrorContainer
                                    : tree
                                        ? treeForeground
                                        : null,
                              ),
                      ))));
        });
  }
}

class _TentIcon extends StatelessWidget {
  const _TentIcon({
    required this.size,
    required this.color,
    required this.accentColor,
  });

  final double size;
  final Color color;
  final Color accentColor;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _TentPainter(color, accentColor),
      );
}

class _TentPainter extends CustomPainter {
  const _TentPainter(this.color, this.accentColor);

  final Color color;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final left = Offset(size.width * .06, size.height * .88);
    final peak = Offset(size.width * .48, size.height * .08);
    final right = Offset(size.width * .95, size.height * .88);
    final tent = Path()
      ..moveTo(left.dx, left.dy)
      ..lineTo(peak.dx, peak.dy)
      ..lineTo(right.dx, right.dy)
      ..close();
    canvas.drawPath(tent, Paint()..color = color);

    canvas.drawPath(
      Path()
        ..moveTo(peak.dx, peak.dy)
        ..lineTo(right.dx, right.dy)
        ..lineTo(size.width * .68, size.height * .88)
        ..close(),
      Paint()..color = accentColor.withValues(alpha: .24),
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * .34, size.height * .88)
        ..lineTo(size.width * .5, size.height * .55)
        ..lineTo(size.width * .7, size.height * .88)
        ..close(),
      Paint()..color = accentColor,
    );
  }

  @override
  bool shouldRepaint(_TentPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.accentColor != accentColor;
}

String _time(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
