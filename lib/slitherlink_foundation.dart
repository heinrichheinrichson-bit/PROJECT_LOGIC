import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

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
    this.difficulty = PuzzleDifficulty.easy,
  });

  final String id;
  final String title;
  final int rows;
  final int columns;
  final List<List<int?>> clues;
  final Set<String> solution;
  final PuzzleDifficulty difficulty;
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

final slitherlinkPuzzleCatalog = <SlitherlinkPuzzle>[
  _rectanglePuzzle(
    id: 'slither_easy_01',
    title: 'Rundherum',
    rows: 4,
    columns: 4,
    top: 0,
    left: 0,
    bottom: 4,
    right: 4,
    difficulty: PuzzleDifficulty.easy,
  ),
  _rectanglePuzzle(
    id: 'slither_easy_02',
    title: 'Kleiner Rahmen',
    rows: 4,
    columns: 4,
    top: 1,
    left: 1,
    bottom: 3,
    right: 3,
    difficulty: PuzzleDifficulty.easy,
  ),
  _rectanglePuzzle(
    id: 'slither_easy_03',
    title: 'Breiter Weg',
    rows: 5,
    columns: 5,
    top: 1,
    left: 0,
    bottom: 4,
    right: 5,
    difficulty: PuzzleDifficulty.easy,
  ),
  _rectanglePuzzle(
    id: 'slither_medium_01',
    title: 'Im Zentrum',
    rows: 5,
    columns: 5,
    top: 1,
    left: 1,
    bottom: 4,
    right: 4,
    difficulty: PuzzleDifficulty.medium,
  ),
  _rectanglePuzzle(
    id: 'slither_medium_02',
    title: 'Große Runde',
    rows: 6,
    columns: 6,
    top: 0,
    left: 1,
    bottom: 6,
    right: 5,
    difficulty: PuzzleDifficulty.medium,
  ),
  _rectanglePuzzle(
    id: 'slither_hard_01',
    title: 'Weiter Rahmen',
    rows: 7,
    columns: 7,
    top: 1,
    left: 1,
    bottom: 6,
    right: 6,
    difficulty: PuzzleDifficulty.hard,
  ),
];

SlitherlinkPuzzle _rectanglePuzzle({
  required String id,
  required String title,
  required int rows,
  required int columns,
  required int top,
  required int left,
  required int bottom,
  required int right,
  required PuzzleDifficulty difficulty,
}) {
  final solution = <String>{};
  for (var column = left; column < right; column++) {
    solution.add('h:$top:$column');
    solution.add('h:$bottom:$column');
  }
  for (var row = top; row < bottom; row++) {
    solution.add('v:$row:$left');
    solution.add('v:$row:$right');
  }
  final clues = List.generate(rows, (row) {
    return List<int?>.generate(columns, (column) {
      final ids = [
        'h:$row:$column',
        'h:${row + 1}:$column',
        'v:$row:$column',
        'v:$row:${column + 1}',
      ];
      return ids.where(solution.contains).length;
    });
  });
  return SlitherlinkPuzzle(
    id: id,
    title: title,
    rows: rows,
    columns: columns,
    clues: clues,
    solution: solution,
    difficulty: difficulty,
  );
}

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

class SlitherlinkSolver {
  const SlitherlinkSolver();

  int countSolutions(SlitherlinkPuzzle puzzle, {int limit = 2}) {
    final edges = _allEdges(puzzle).toList(growable: false);
    final indexById = <String, int>{
      for (var index = 0; index < edges.length; index++) edges[index].id: index,
    };
    final clues = <(int, List<int>)>[];
    for (var row = 0; row < puzzle.rows; row++) {
      for (var column = 0; column < puzzle.columns; column++) {
        final clue = puzzle.clues[row][column];
        if (clue == null) continue;
        clues.add((
          clue,
          [
            indexById['h:$row:$column']!,
            indexById['h:${row + 1}:$column']!,
            indexById['v:$row:$column']!,
            indexById['v:$row:${column + 1}']!,
          ]
        ));
      }
    }
    final vertices = <List<int>>[];
    for (var row = 0; row <= puzzle.rows; row++) {
      for (var column = 0; column <= puzzle.columns; column++) {
        final touching = <int>[];
        if (column > 0) touching.add(indexById['h:$row:${column - 1}']!);
        if (column < puzzle.columns) touching.add(indexById['h:$row:$column']!);
        if (row > 0) touching.add(indexById['v:${row - 1}:$column']!);
        if (row < puzzle.rows) touching.add(indexById['v:$row:$column']!);
        vertices.add(touching);
      }
    }
    var solutions = 0;

    void search(List<int> values) {
      if (solutions >= limit) return;
      final working = List<int>.from(values);
      if (!_propagate(working, clues, vertices)) return;
      final undecided = working.indexOf(-1);
      if (undecided < 0) {
        final state = SlitherlinkState(
          puzzle: puzzle,
          marks: {
            for (var index = 0; index < edges.length; index++)
              if (working[index] == 1) edges[index].id: SlitherEdgeMark.line,
          },
        );
        if (state.isSolved) solutions++;
        return;
      }
      final preferred = _preferredEdge(working, clues) ?? undecided;
      final off = List<int>.from(working)..[preferred] = 0;
      search(off);
      if (solutions >= limit) return;
      final on = List<int>.from(working)..[preferred] = 1;
      search(on);
    }

    search(List<int>.filled(edges.length, -1));
    return solutions;
  }

  bool hasUniqueSolution(SlitherlinkPuzzle puzzle) =>
      countSolutions(puzzle) == 1;

  static int? _preferredEdge(
    List<int> values,
    List<(int, List<int>)> clues,
  ) {
    for (final (_, edges) in clues) {
      for (final edge in edges) {
        if (values[edge] == -1) return edge;
      }
    }
    return null;
  }

  static bool _propagate(
    List<int> values,
    List<(int, List<int>)> clues,
    List<List<int>> vertices,
  ) {
    var changed = true;
    while (changed) {
      changed = false;
      for (final (target, edges) in clues) {
        final on = edges.where((edge) => values[edge] == 1).length;
        final unknown = edges.where((edge) => values[edge] == -1).toList();
        if (on > target || on + unknown.length < target) return false;
        if (on == target) {
          for (final edge in unknown) {
            values[edge] = 0;
            changed = true;
          }
        } else if (on + unknown.length == target) {
          for (final edge in unknown) {
            values[edge] = 1;
            changed = true;
          }
        }
      }
      for (final edges in vertices) {
        final on = edges.where((edge) => values[edge] == 1).length;
        final unknown = edges.where((edge) => values[edge] == -1).toList();
        if (on > 2 || (on == 1 && unknown.isEmpty)) return false;
        if (on == 2) {
          for (final edge in unknown) {
            values[edge] = 0;
            changed = true;
          }
        } else if (on == 1 && unknown.length == 1) {
          values[unknown.single] = 1;
          changed = true;
        } else if (on == 0 && unknown.length == 1) {
          values[unknown.single] = 0;
          changed = true;
        }
      }
    }
    return true;
  }
}

class SlitherlinkGenerator {
  const SlitherlinkGenerator({this.solver = const SlitherlinkSolver()});

  final SlitherlinkSolver solver;

  SlitherlinkPuzzle generate({
    required int seed,
    required PuzzleDifficulty difficulty,
  }) {
    final random = math.Random(seed);
    final size = switch (difficulty) {
      PuzzleDifficulty.easy => 5,
      PuzzleDifficulty.medium => 6,
      PuzzleDifficulty.hard => 7,
    };
    final targetCells = switch (difficulty) {
      PuzzleDifficulty.easy => 8,
      PuzzleDifficulty.medium => 13,
      PuzzleDifficulty.hard => 19,
    };
    final cells = <(int, int)>{(size ~/ 2, size ~/ 2)};
    while (cells.length < targetCells) {
      final base = cells.elementAt(random.nextInt(cells.length));
      final direction =
          const [(1, 0), (-1, 0), (0, 1), (0, -1)][random.nextInt(4)];
      final candidate = (base.$1 + direction.$1, base.$2 + direction.$2);
      if (candidate.$1 >= 0 &&
          candidate.$1 < size &&
          candidate.$2 >= 0 &&
          candidate.$2 < size) {
        cells.add(candidate);
      }
    }
    final solution = _boundaryForCells(cells);
    final completeClues = _cluesForSolution(size, size, solution);
    var clues = completeClues;
    final positions = [
      for (var row = 0; row < size; row++)
        for (var column = 0; column < size; column++) (row, column),
    ]..shuffle(random);
    final removalTarget = switch (difficulty) {
      PuzzleDifficulty.easy => size * size ~/ 5,
      PuzzleDifficulty.medium => size * size ~/ 3,
      PuzzleDifficulty.hard => size * size * 2 ~/ 5,
    };
    var removed = 0;
    for (final position in positions) {
      if (removed >= removalTarget) break;
      final candidate = [for (final row in clues) List<int?>.from(row)];
      candidate[position.$1][position.$2] = null;
      final puzzle = SlitherlinkPuzzle(
        id: 'slither-generated-$seed',
        title: 'Zufallsrätsel',
        rows: size,
        columns: size,
        clues: candidate,
        solution: solution,
        difficulty: difficulty,
      );
      if (solver.hasUniqueSolution(puzzle)) {
        clues = candidate;
        removed++;
      }
    }
    return SlitherlinkPuzzle(
      id: 'slither-generated-$seed',
      title: 'Zufallsrätsel',
      rows: size,
      columns: size,
      clues: clues,
      solution: solution,
      difficulty: difficulty,
    );
  }

  static Set<String> _boundaryForCells(Set<(int, int)> cells) {
    final edges = <String>{};
    void toggle(String id) => edges.remove(id) ? null : edges.add(id);
    for (final (row, column) in cells) {
      toggle('h:$row:$column');
      toggle('h:${row + 1}:$column');
      toggle('v:$row:$column');
      toggle('v:$row:${column + 1}');
    }
    return edges;
  }

  static List<List<int?>> _cluesForSolution(
    int rows,
    int columns,
    Set<String> solution,
  ) =>
      List.generate(rows, (row) {
        return List<int?>.generate(columns, (column) {
          return [
            'h:$row:$column',
            'h:${row + 1}:$column',
            'v:$row:$column',
            'v:$row:${column + 1}',
          ].where(solution.contains).length;
        });
      });
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
          'difficulty': puzzle.difficulty.name,
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
      difficulty: PuzzleDifficulty.values.byName(
        puzzleJson['difficulty'] as String? ?? PuzzleDifficulty.easy.name,
      ),
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
                    Text(
                      'Rätselsammlung',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Erste Kapitel zum Kennenlernen verschiedener Rastergrößen.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 10),
                    for (final difficulty in PuzzleDifficulty.values)
                      _SlitherCollectionChapter(difficulty: difficulty),
                    const SizedBox(height: 18),
                    Text(
                      'Zufallsrätsel',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Neu erzeugt und vor dem Start auf eine eindeutige Lösung geprüft.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final difficulty in PuzzleDifficulty.values)
                              FilledButton.tonalIcon(
                                onPressed: () => _startRandom(
                                  context,
                                  difficulty,
                                ),
                                icon: Icon(switch (difficulty) {
                                  PuzzleDifficulty.easy => Icons.eco_outlined,
                                  PuzzleDifficulty.medium =>
                                    Icons.psychology_alt_outlined,
                                  PuzzleDifficulty.hard =>
                                    Icons.local_fire_department_outlined,
                                }),
                                label: Text(difficulty.label),
                              ),
                          ],
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

  Future<void> _startRandom(
    BuildContext context,
    PuzzleDifficulty difficulty,
  ) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 18),
            Expanded(child: Text('Eindeutiges Rätsel wird erstellt …')),
          ],
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));
    try {
      final puzzle = const SlitherlinkGenerator().generate(
        seed: DateTime.now().microsecondsSinceEpoch & 0x7fffffff,
        difficulty: difficulty,
      );
      if (!context.mounted) return;
      Navigator.of(context).pop();
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SlitherlinkGameScreen(puzzle: puzzle),
        ),
      );
    } on Object {
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Das Zufallsrätsel konnte nicht erstellt werden.'),
        ),
      );
    }
  }
}

class _SlitherCollectionChapter extends StatelessWidget {
  const _SlitherCollectionChapter({required this.difficulty});

  final PuzzleDifficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final puzzles = slitherlinkPuzzleCatalog
        .where((puzzle) => puzzle.difficulty == difficulty)
        .toList(growable: false);
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          child: Icon(switch (difficulty) {
            PuzzleDifficulty.easy => Icons.eco_outlined,
            PuzzleDifficulty.medium => Icons.psychology_alt_outlined,
            PuzzleDifficulty.hard => Icons.local_fire_department_outlined,
          }),
        ),
        title: Text(difficulty.label),
        subtitle: Text('${puzzles.length} Rätsel'),
        children: [
          for (var index = 0; index < puzzles.length; index++) ...[
            if (index > 0) const Divider(height: 1),
            ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text(puzzles[index].title),
              subtitle: Text(
                '${puzzles[index].rows} × ${puzzles[index].columns}',
              ),
              trailing: const Icon(Icons.play_arrow_rounded),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SlitherlinkGameScreen(puzzle: puzzles[index]),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
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
  bool _checkingExistingGame = false;

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
    } else {
      _checkingExistingGame = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_protectExistingGame());
      });
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_completionShown && !_checkingExistingGame) {
        setState(() => _elapsedSeconds++);
        if (_elapsedSeconds % 10 == 0) unawaited(_saveGame());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (!_completionShown && !_checkingExistingGame) unawaited(_saveGame());
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

  Future<void> _protectExistingGame() async {
    final existing = await _saveStore.load();
    if (!mounted) return;
    if (existing == null) {
      _checkingExistingGame = false;
      await _saveGame();
      return;
    }
    final resume = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.save_outlined),
        title: const Text('Offenes Slitherlink-Rätsel'),
        content: const Text(
          'Du hast bereits ein begonnenes Slitherlink-Rätsel. Möchtest du es fortsetzen oder mit dem neuen Rätsel beginnen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Neu beginnen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Fortsetzen'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (resume == true) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => SlitherlinkGameScreen(
            puzzle: existing.puzzle,
            savedGame: existing,
          ),
        ),
      );
      return;
    }
    _checkingExistingGame = false;
    await _saveStore.clear();
    await _saveGame();
  }

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
      _developerCompletion = false;
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
        source: widget.puzzle.id == slitherlinkTutorialPuzzle.id
            ? GameMode.tutorial
            : widget.puzzle.id.startsWith('slither-generated-')
                ? GameMode.generated
                : GameMode.catalog,
        difficulty: widget.puzzle.difficulty,
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

  bool get _isGenerated => widget.puzzle.id.startsWith('slither-generated-');

  SlitherlinkPuzzle? get _nextCollectionPuzzle {
    final group = slitherlinkPuzzleCatalog
        .where((puzzle) => puzzle.difficulty == widget.puzzle.difficulty)
        .toList(growable: false);
    final index = group.indexWhere((puzzle) => puzzle.id == widget.puzzle.id);
    if (index < 0 || index + 1 >= group.length) return null;
    return group[index + 1];
  }

  Future<void> _startNextRandomPuzzle() async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 18),
            Expanded(child: Text('Neues Rätsel wird geprüft …')),
          ],
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));
    try {
      final puzzle = const SlitherlinkGenerator().generate(
        seed: DateTime.now().microsecondsSinceEpoch & 0x7fffffff,
        difficulty: widget.puzzle.difficulty,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => SlitherlinkGameScreen(puzzle: puzzle),
        ),
      );
    } on Object {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Neues Rätsel konnte nicht erstellt werden.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        bottomNavigationBar: _completionShown
            ? SafeArea(
                minimum: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (_isGenerated)
                          FilledButton.icon(
                            onPressed: _startNextRandomPuzzle,
                            icon: const Icon(Icons.auto_awesome_rounded),
                            label: const Text('Noch eins'),
                          )
                        else if (_nextCollectionPuzzle != null)
                          FilledButton.icon(
                            onPressed: () =>
                                Navigator.of(context).pushReplacement(
                              MaterialPageRoute<void>(
                                builder: (_) => SlitherlinkGameScreen(
                                  puzzle: _nextCollectionPuzzle!,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: const Text('Nächstes Rätsel'),
                          ),
                        OutlinedButton.icon(
                          onPressed: _restart,
                          icon: const Icon(Icons.replay_rounded),
                          label: const Text('Noch einmal'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : null,
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
