import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_preferences.dart';
import 'core/domain/game_identity.dart';
import 'core/monetization/hint_economy.dart';
import 'core/presentation/confirm_restart_dialog.dart';
import 'game_storage.dart';

enum SlitherEdgeMark { empty, line, blocked }

enum _SlitherDeveloperAction { almostSolved, solve, error, reset }

@immutable
class SlitherEdge {
  const SlitherEdge.horizontal(this.row, this.column) : horizontal = true;
  const SlitherEdge.vertical(this.row, this.column) : horizontal = false;

  final bool horizontal;
  final int row;
  final int column;

  String get id => '${horizontal ? 'h' : 'v'}:$row:$column';
}

@immutable
class SlitherlinkPuzzle {
  const SlitherlinkPuzzle({
    required this.id,
    required this.title,
    required this.rows,
    required this.columns,
    required this.clues,
    required this.solution,
  });

  final String id;
  final String title;
  final int rows;
  final int columns;
  final List<List<int?>> clues;
  final Set<String> solution;
}

const slitherlinkTutorialPuzzle = SlitherlinkPuzzle(
  id: 'slitherlink_tutorial_01',
  title: 'Die erste Schleife',
  rows: 4,
  columns: 4,
  clues: [
    [null, 1, 1, null],
    [1, 2, 2, 1],
    [1, 2, 2, 1],
    [null, 1, 1, null],
  ],
  solution: {
    'h:1:1',
    'h:1:2',
    'h:3:1',
    'h:3:2',
    'v:1:1',
    'v:2:1',
    'v:1:3',
    'v:2:3',
  },
);

class SlitherlinkState {
  const SlitherlinkState({required this.puzzle, this.marks = const {}});

  final SlitherlinkPuzzle puzzle;
  final Map<String, SlitherEdgeMark> marks;

  SlitherEdgeMark markAt(SlitherEdge edge) =>
      marks[edge.id] ?? SlitherEdgeMark.empty;

  SlitherlinkState cycle(SlitherEdge edge) {
    final current = markAt(edge);
    final next = switch (current) {
      SlitherEdgeMark.empty => SlitherEdgeMark.line,
      SlitherEdgeMark.line => SlitherEdgeMark.blocked,
      SlitherEdgeMark.blocked => SlitherEdgeMark.empty,
    };
    final updated = Map<String, SlitherEdgeMark>.from(marks);
    if (next == SlitherEdgeMark.empty) {
      updated.remove(edge.id);
    } else {
      updated[edge.id] = next;
    }
    return SlitherlinkState(puzzle: puzzle, marks: updated);
  }

  Iterable<String> get lineIds => marks.entries
      .where((entry) => entry.value == SlitherEdgeMark.line)
      .map((entry) => entry.key);

  int linesAround(int row, int column) {
    final ids = [
      'h:$row:$column',
      'h:${row + 1}:$column',
      'v:$row:$column',
      'v:$row:${column + 1}',
    ];
    return ids.where((id) => marks[id] == SlitherEdgeMark.line).length;
  }

  bool clueSatisfied(int row, int column) {
    final clue = puzzle.clues[row][column];
    return clue == null || linesAround(row, column) == clue;
  }

  bool get isSolved {
    for (var row = 0; row < puzzle.rows; row++) {
      for (var column = 0; column < puzzle.columns; column++) {
        if (!clueSatisfied(row, column)) return false;
      }
    }
    final lines = lineIds.toSet();
    if (lines.isEmpty) return false;
    final adjacency = <String, Set<String>>{};
    for (final id in lines) {
      final points = _edgePoints(id);
      adjacency.putIfAbsent(points.$1, () => {}).add(points.$2);
      adjacency.putIfAbsent(points.$2, () => {}).add(points.$1);
    }
    if (adjacency.values.any((neighbors) => neighbors.length != 2)) {
      return false;
    }
    final visited = <String>{};
    final pending = <String>[adjacency.keys.first];
    while (pending.isNotEmpty) {
      final point = pending.removeLast();
      if (!visited.add(point)) continue;
      pending
          .addAll(adjacency[point]!.where((next) => !visited.contains(next)));
    }
    return visited.length == adjacency.length;
  }

  static (String, String) _edgePoints(String id) {
    final parts = id.split(':');
    final row = int.parse(parts[1]);
    final column = int.parse(parts[2]);
    return parts[0] == 'h'
        ? ('$row:$column', '$row:${column + 1}')
        : ('$row:$column', '${row + 1}:$column');
  }
}

class SavedSlitherlinkGame {
  const SavedSlitherlinkGame({
    required this.puzzle,
    required this.marks,
    required this.elapsedSeconds,
    required this.moves,
    required this.hintsUsed,
    required this.rewardedHints,
  });

  static const schemaVersion = 1;
  final SlitherlinkPuzzle puzzle;
  final Map<String, SlitherEdgeMark> marks;
  final int elapsedSeconds;
  final int moves;
  final int hintsUsed;
  final int rewardedHints;

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'puzzle': {
          'id': puzzle.id,
          'title': puzzle.title,
          'rows': puzzle.rows,
          'columns': puzzle.columns,
          'clues': puzzle.clues,
          'solution': puzzle.solution.toList()..sort(),
        },
        'marks': {
          for (final entry in marks.entries) entry.key: entry.value.name
        },
        'elapsedSeconds': elapsedSeconds,
        'moves': moves,
        'hintsUsed': hintsUsed,
        'rewardedHints': rewardedHints,
      };

  factory SavedSlitherlinkGame.fromJson(Map<String, Object?> json) {
    if (json['schemaVersion'] != schemaVersion) {
      throw const FormatException('Unsupported Slitherlink save version.');
    }
    final puzzleJson = Map<String, Object?>.from(json['puzzle']! as Map);
    final puzzle = SlitherlinkPuzzle(
      id: puzzleJson['id']! as String,
      title: puzzleJson['title']! as String,
      rows: puzzleJson['rows']! as int,
      columns: puzzleJson['columns']! as int,
      clues: (puzzleJson['clues']! as List)
          .map((row) => (row as List).map((value) => value as int?).toList())
          .toList(),
      solution: (puzzleJson['solution']! as List).cast<String>().toSet(),
    );
    final rawMarks = Map<String, Object?>.from(json['marks']! as Map);
    return SavedSlitherlinkGame(
      puzzle: puzzle,
      marks: {
        for (final entry in rawMarks.entries)
          entry.key: SlitherEdgeMark.values.byName(entry.value! as String),
      },
      elapsedSeconds: json['elapsedSeconds']! as int,
      moves: json['moves']! as int,
      hintsUsed: json['hintsUsed']! as int,
      rewardedHints: json['rewardedHints']! as int,
    );
  }
}

class SlitherlinkGameStore {
  static const _key = 'active_slitherlink_game_v1';

  Future<SavedSlitherlinkGame?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null) return null;
    try {
      return SavedSlitherlinkGame.fromJson(
        Map<String, Object?>.from(jsonDecode(raw) as Map),
      );
    } on Object {
      await preferences.remove(_key);
      return null;
    }
  }

  Future<void> save(SavedSlitherlinkGame game) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, jsonEncode(game.toJson()));
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key);
  }
}

class SlitherlinkHubScreen extends StatelessWidget {
  const SlitherlinkHubScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Slitherlink')),
        body: Center(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: const Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(Icons.gesture_rounded, size: 44),
                            SizedBox(height: 12),
                            Text(
                              'Eine einzige Schleife',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Verbinde die Punkte zu einer geschlossenen Schleife. Zahlen verraten, wie viele Seiten eines Feldes dazugehören.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.school_outlined),
                        ),
                        title: const Text('Die erste Schleife'),
                        subtitle: const Text('Interaktiver Einstieg · 4 × 4'),
                        trailing: const Icon(Icons.play_arrow_rounded),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SlitherlinkGameScreen(
                              puzzle: slitherlinkTutorialPuzzle,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Card(
                      child: ListTile(
                        leading: Icon(Icons.construction_outlined),
                        title: Text('Rätselsammlung im Aufbau'),
                        subtitle: Text(
                          'Als Nächstes folgen Kapitel, Schwierigkeitsgrade und Zufallsrätsel.',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class SlitherlinkGameScreen extends StatefulWidget {
  const SlitherlinkGameScreen({
    required this.puzzle,
    this.savedGame,
    super.key,
  });

  final SlitherlinkPuzzle puzzle;
  final SavedSlitherlinkGame? savedGame;

  @override
  State<SlitherlinkGameScreen> createState() => _SlitherlinkGameScreenState();
}

class _SlitherlinkGameScreenState extends State<SlitherlinkGameScreen> {
  late SlitherlinkState _state;
  final List<SlitherlinkState> _history = [];
  final List<SlitherlinkState> _redo = [];
  bool _completionShown = false;
  bool _developerCompletion = false;
  Timer? _timer;
  int _elapsedSeconds = 0;
  int _moves = 0;
  int _hintsUsed = 0;
  HintBudget _hintBudget = const HintBudget();
  final SlitherlinkGameStore _saveStore = SlitherlinkGameStore();

  @override
  void initState() {
    super.initState();
    final saved = widget.savedGame;
    _state = SlitherlinkState(
      puzzle: widget.puzzle,
      marks: saved?.marks ?? const {},
    );
    if (saved != null) {
      _elapsedSeconds = saved.elapsedSeconds;
      _moves = saved.moves;
      _hintsUsed = saved.hintsUsed;
      _hintBudget = HintBudget(
        usedHints: saved.hintsUsed,
        rewardedHints: saved.rewardedHints,
      );
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_completionShown) {
        setState(() => _elapsedSeconds++);
        if (_elapsedSeconds % 10 == 0) unawaited(_saveGame());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (!_completionShown) unawaited(_saveGame());
    super.dispose();
  }

  Future<void> _saveGame() => _saveStore.save(SavedSlitherlinkGame(
        puzzle: widget.puzzle,
        marks: _state.marks,
        elapsedSeconds: _elapsedSeconds,
        moves: _moves,
        hintsUsed: _hintsUsed,
        rewardedHints: _hintBudget.rewardedHints,
      ));

  void _cycle(SlitherEdge edge) {
    if (_completionShown) return;
    setState(() {
      _history.add(_state);
      _state = _state.cycle(edge);
      _redo.clear();
      _moves++;
    });
    unawaited(_saveGame());
    if (_state.isSolved) _showCompletion();
  }

  void _undo() {
    if (_history.isEmpty || _completionShown) return;
    setState(() {
      _redo.add(_state);
      _state = _history.removeLast();
      if (_moves > 0) _moves--;
    });
    unawaited(_saveGame());
  }

  void _redoMove() {
    if (_redo.isEmpty || _completionShown) return;
    setState(() {
      _history.add(_state);
      _state = _redo.removeLast();
      _moves++;
    });
    unawaited(_saveGame());
    if (_state.isSolved) _showCompletion();
  }

  void _hint() {
    final premium = PreferencesScope.of(context).premiumSimulationEnabled;
    if (!premium && !_hintBudget.canUseHint) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keine Hinweise mehr verfügbar.')),
      );
      return;
    }
    for (final edge in _allEdges(widget.puzzle)) {
      final expected = widget.puzzle.solution.contains(edge.id)
          ? SlitherEdgeMark.line
          : SlitherEdgeMark.blocked;
      if (_state.markAt(edge) == expected) continue;
      setState(() {
        _history.add(_state);
        final updated = Map<String, SlitherEdgeMark>.from(_state.marks)
          ..[edge.id] = expected;
        _state = SlitherlinkState(puzzle: widget.puzzle, marks: updated);
        _redo.clear();
        _moves++;
        _hintsUsed++;
        if (!premium) _hintBudget = _hintBudget.useHint();
      });
      unawaited(_saveGame());
      if (_state.isSolved) _showCompletion();
      return;
    }
  }

  Future<void> _restart() async {
    if (!await confirmPuzzleRestart(context) || !mounted) return;
    setState(() {
      _history.add(_state);
      _state = SlitherlinkState(puzzle: widget.puzzle);
      _redo.clear();
      _completionShown = false;
      _elapsedSeconds = 0;
      _moves = 0;
      _hintsUsed = 0;
      _hintBudget = const HintBudget();
    });
    unawaited(_saveGame());
  }

  Future<void> _showCompletion() async {
    if (_completionShown) return;
    _completionShown = true;
    if (!_developerCompletion) {
      await GameStorage().recordCompletion(
        puzzleId: widget.puzzle.id,
        elapsedSeconds: _elapsedSeconds,
        source: GameMode.tutorial,
        difficulty: PuzzleDifficulty.easy,
        boardSize: widget.puzzle.rows,
        gameType: GameType.slitherlink,
        moves: _moves,
        hintsUsed: _hintsUsed,
        rewardedHints: _hintBudget.rewardedHints,
      );
      await _saveStore.clear();
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.celebration_rounded),
        title: const Text('Schleife vollendet!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Alle Zahlen stimmen und die Linie bildet genau eine geschlossene Schleife.',
              textAlign: TextAlign.center,
            ),
            if (_developerCompletion) ...[
              const SizedBox(height: 14),
              const Chip(
                avatar: Icon(Icons.science_outlined),
                label: Text('Testabschluss · keine Statistik'),
              ),
            ] else ...[
              const SizedBox(height: 16),
              Text(
                '${_formatTime(_elapsedSeconds)} · $_moves Züge · $_hintsUsed Hinweise',
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Brett ansehen'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Slitherlink verlassen'),
          ),
        ],
      ),
    );
  }

  Future<void> _runDeveloperAction(_SlitherDeveloperAction action) async {
    switch (action) {
      case _SlitherDeveloperAction.almostSolved:
        final solution = widget.puzzle.solution.toList()..sort();
        setState(() {
          _state = SlitherlinkState(
            puzzle: widget.puzzle,
            marks: {
              for (final id in solution.take(solution.length - 1))
                id: SlitherEdgeMark.line,
            },
          );
          _history.clear();
          _redo.clear();
          _completionShown = false;
          _developerCompletion = true;
          _moves = 0;
        });
        return;
      case _SlitherDeveloperAction.solve:
        setState(() {
          _state = SlitherlinkState(
            puzzle: widget.puzzle,
            marks: {
              for (final edge in _allEdges(widget.puzzle))
                edge.id: widget.puzzle.solution.contains(edge.id)
                    ? SlitherEdgeMark.line
                    : SlitherEdgeMark.blocked,
            },
          );
          _history.clear();
          _redo.clear();
          _completionShown = false;
          _developerCompletion = true;
          _moves = 0;
        });
        await _showCompletion();
        return;
      case _SlitherDeveloperAction.error:
        final wrongEdge = _allEdges(widget.puzzle).firstWhere(
          (edge) => !widget.puzzle.solution.contains(edge.id),
        );
        setState(() {
          _state = SlitherlinkState(
            puzzle: widget.puzzle,
            marks: {
              for (final id in widget.puzzle.solution) id: SlitherEdgeMark.line,
              wrongEdge.id: SlitherEdgeMark.line,
            },
          );
          _history.clear();
          _redo.clear();
          _completionShown = false;
          _developerCompletion = true;
          _moves = 0;
        });
        return;
      case _SlitherDeveloperAction.reset:
        setState(() {
          _state = SlitherlinkState(puzzle: widget.puzzle);
          _history.clear();
          _redo.clear();
          _completionShown = false;
          _developerCompletion = false;
          _elapsedSeconds = 0;
          _moves = 0;
          _hintsUsed = 0;
          _hintBudget = const HintBudget();
        });
        return;
    }
  }

  static String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    return '$minutes:${rest.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.puzzle.title),
          actions: [
            if (kDebugMode)
              PopupMenuButton<_SlitherDeveloperAction>(
                tooltip: 'Testfunktionen',
                icon: const Icon(Icons.bug_report_outlined),
                onSelected: _runDeveloperAction,
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: _SlitherDeveloperAction.almostSolved,
                    child: Text('Fast lösen'),
                  ),
                  PopupMenuItem(
                    value: _SlitherDeveloperAction.solve,
                    child: Text('Sofort lösen'),
                  ),
                  PopupMenuItem(
                    value: _SlitherDeveloperAction.error,
                    child: Text('Fehler erzeugen'),
                  ),
                  PopupMenuItem(
                    value: _SlitherDeveloperAction.reset,
                    child: Text('Testzustand leeren'),
                  ),
                ],
              ),
            IconButton(
              tooltip: 'Hinweis',
              onPressed: _completionShown ? null : _hint,
              icon: const Icon(Icons.lightbulb_outline),
            ),
            IconButton(
              tooltip: 'Neu starten',
              onPressed: _restart,
              icon: const Icon(Icons.restart_alt_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SlitherStatus(
                      icon: Icons.timer_outlined,
                      label: _formatTime(_elapsedSeconds),
                    ),
                    const SizedBox(width: 8),
                    _SlitherStatus(
                      icon: Icons.touch_app_outlined,
                      label: '$_moves Züge',
                    ),
                    const SizedBox(width: 8),
                    _SlitherStatus(
                      icon: Icons.lightbulb_outline,
                      label:
                          PreferencesScope.of(context).premiumSimulationEnabled
                              ? 'Premium'
                              : '${_hintBudget.remainingHints} Tipps',
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Tippen: leer → Linie → ausgeschlossen',
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: AspectRatio(
                      aspectRatio: widget.puzzle.columns / widget.puzzle.rows,
                      child: SlitherlinkBoard(
                        state: _state,
                        enabled: !_completionShown,
                        onEdgeTap: _cycle,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _history.isEmpty ? null : _undo,
                        icon: const Icon(Icons.undo_rounded),
                        label: const Text('Rückgängig'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: _redo.isEmpty ? null : _redoMove,
                        icon: const Icon(Icons.redo_rounded),
                        label: const Text('Wiederholen'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class _SlitherStatus extends StatelessWidget {
  const _SlitherStatus({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 5),
            Text(label),
          ],
        ),
      );
}

class SlitherlinkBoard extends StatelessWidget {
  const SlitherlinkBoard({
    required this.state,
    required this.enabled,
    required this.onEdgeTap,
    super.key,
  });

  final SlitherlinkState state;
  final bool enabled;
  final ValueChanged<SlitherEdge> onEdgeTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: enabled
                ? (details) => onEdgeTap(_nearestEdge(
                      details.localPosition,
                      size,
                      state.puzzle,
                    ))
                : null,
            child: CustomPaint(
              painter: _SlitherlinkPainter(
                state: state,
                colors: Theme.of(context).colorScheme,
              ),
              size: Size.infinite,
            ),
          );
        },
      );

  static SlitherEdge _nearestEdge(
    Offset position,
    Size size,
    SlitherlinkPuzzle puzzle,
  ) {
    final cellWidth = size.width / puzzle.columns;
    final cellHeight = size.height / puzzle.rows;
    final gridX = position.dx / cellWidth;
    final gridY = position.dy / cellHeight;
    final nearestColumn = gridX.round().clamp(0, puzzle.columns);
    final nearestRow = gridY.round().clamp(0, puzzle.rows);
    final horizontalDistance = (gridY - nearestRow).abs();
    final verticalDistance = (gridX - nearestColumn).abs();
    if (horizontalDistance <= verticalDistance) {
      return SlitherEdge.horizontal(
        nearestRow,
        gridX.floor().clamp(0, puzzle.columns - 1),
      );
    }
    return SlitherEdge.vertical(
      gridY.floor().clamp(0, puzzle.rows - 1),
      nearestColumn,
    );
  }
}

class _SlitherlinkPainter extends CustomPainter {
  const _SlitherlinkPainter({required this.state, required this.colors});

  final SlitherlinkState state;
  final ColorScheme colors;

  @override
  void paint(Canvas canvas, Size size) {
    final puzzle = state.puzzle;
    final dx = size.width / puzzle.columns;
    final dy = size.height / puzzle.rows;
    final faint = Paint()
      ..color = colors.outlineVariant.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    final line = Paint()
      ..color = colors.primary
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final blocked = Paint()
      ..color = colors.onSurfaceVariant
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final dot = Paint()..color = colors.onSurface;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var row = 0; row < puzzle.rows; row++) {
      for (var column = 0; column < puzzle.columns; column++) {
        final clue = puzzle.clues[row][column];
        if (clue != null) {
          final satisfied = state.clueSatisfied(row, column);
          textPainter.text = TextSpan(
            text: '$clue',
            style: TextStyle(
              color: satisfied && state.lineIds.isNotEmpty
                  ? colors.primary
                  : colors.onSurface,
              fontSize: (dx < dy ? dx : dy) * 0.38,
              fontWeight: FontWeight.w700,
            ),
          );
          textPainter.layout();
          textPainter.paint(
            canvas,
            Offset(
              (column + 0.5) * dx - textPainter.width / 2,
              (row + 0.5) * dy - textPainter.height / 2,
            ),
          );
        }
      }
    }

    for (final edge in _allEdges(puzzle)) {
      final start = edge.horizontal
          ? Offset(edge.column * dx, edge.row * dy)
          : Offset(edge.column * dx, edge.row * dy);
      final end = edge.horizontal
          ? Offset((edge.column + 1) * dx, edge.row * dy)
          : Offset(edge.column * dx, (edge.row + 1) * dy);
      final mark = state.markAt(edge);
      if (mark == SlitherEdgeMark.line) {
        canvas.drawLine(start, end, line);
      } else {
        canvas.drawLine(start, end, faint);
        if (mark == SlitherEdgeMark.blocked) {
          final center =
              Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
          const radius = 5.0;
          canvas.drawLine(
            center.translate(-radius, -radius),
            center.translate(radius, radius),
            blocked,
          );
          canvas.drawLine(
            center.translate(radius, -radius),
            center.translate(-radius, radius),
            blocked,
          );
        }
      }
    }
    for (var row = 0; row <= puzzle.rows; row++) {
      for (var column = 0; column <= puzzle.columns; column++) {
        canvas.drawCircle(Offset(column * dx, row * dy), 3.5, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SlitherlinkPainter oldDelegate) =>
      oldDelegate.state != state || oldDelegate.colors != colors;
}

Iterable<SlitherEdge> _allEdges(SlitherlinkPuzzle puzzle) sync* {
  for (var row = 0; row <= puzzle.rows; row++) {
    for (var column = 0; column < puzzle.columns; column++) {
      yield SlitherEdge.horizontal(row, column);
    }
  }
  for (var row = 0; row < puzzle.rows; row++) {
    for (var column = 0; column <= puzzle.columns; column++) {
      yield SlitherEdge.vertical(row, column);
    }
  }
}
