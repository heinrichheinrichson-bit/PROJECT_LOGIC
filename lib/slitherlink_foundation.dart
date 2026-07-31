import 'package:flutter/material.dart';

import 'core/presentation/confirm_restart_dialog.dart';

enum SlitherEdgeMark { empty, line, blocked }

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
  const SlitherlinkGameScreen({required this.puzzle, super.key});

  final SlitherlinkPuzzle puzzle;

  @override
  State<SlitherlinkGameScreen> createState() => _SlitherlinkGameScreenState();
}

class _SlitherlinkGameScreenState extends State<SlitherlinkGameScreen> {
  late SlitherlinkState _state;
  final List<SlitherlinkState> _history = [];
  final List<SlitherlinkState> _redo = [];
  bool _completionShown = false;

  @override
  void initState() {
    super.initState();
    _state = SlitherlinkState(puzzle: widget.puzzle);
  }

  void _cycle(SlitherEdge edge) {
    if (_completionShown) return;
    setState(() {
      _history.add(_state);
      _state = _state.cycle(edge);
      _redo.clear();
    });
    if (_state.isSolved) _showCompletion();
  }

  void _undo() {
    if (_history.isEmpty || _completionShown) return;
    setState(() {
      _redo.add(_state);
      _state = _history.removeLast();
    });
  }

  void _redoMove() {
    if (_redo.isEmpty || _completionShown) return;
    setState(() {
      _history.add(_state);
      _state = _redo.removeLast();
    });
    if (_state.isSolved) _showCompletion();
  }

  void _hint() {
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
      });
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
    });
  }

  Future<void> _showCompletion() async {
    if (_completionShown) return;
    _completionShown = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.celebration_rounded),
        title: const Text('Schleife vollendet!'),
        content: const Text(
          'Alle Zahlen stimmen und die Linie bildet genau eine geschlossene Schleife.',
          textAlign: TextAlign.center,
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

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.puzzle.title),
          actions: [
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
