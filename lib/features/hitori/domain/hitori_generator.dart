import 'dart:math';

import '../../../core/domain/game_identity.dart';
import 'hitori_puzzle.dart';
import 'hitori_solver.dart';

class HitoriGenerator {
  const HitoriGenerator({this.solver = const HitoriSolver()});

  final HitoriSolver solver;

  HitoriPuzzle generate({
    required int seed,
    required PuzzleDifficulty difficulty,
    String? id,
    String? title,
  }) {
    final size = switch (difficulty) {
      PuzzleDifficulty.easy => 5,
      PuzzleDifficulty.medium => 6,
      PuzzleDifficulty.hard => 7,
    };
    final targetShaded = switch (difficulty) {
      PuzzleDifficulty.easy => 5,
      PuzzleDifficulty.medium => 7,
      PuzzleDifficulty.hard => 9,
    };
    final random = Random(seed);
    for (var attempt = 0; attempt < 800; attempt++) {
      final solutionGrid = _latinSquare(size, random);
      final shaded = _shadedPattern(size, targetShaded, random);
      if (shaded.length != targetShaded) continue;
      final grid = [
        for (final row in solutionGrid) [...row]
      ];
      var valid = true;
      for (final cell in shaded) {
        final sources = <HitoriCell>[
          for (var column = 0; column < size; column++)
            if (column != cell.$2 && !shaded.contains((cell.$1, column)))
              (cell.$1, column),
          for (var row = 0; row < size; row++)
            if (row != cell.$1 && !shaded.contains((row, cell.$2)))
              (row, cell.$2),
        ]..shuffle(random);
        if (sources.isEmpty) {
          valid = false;
          break;
        }
        final source = sources.first;
        grid[cell.$1][cell.$2] = grid[source.$1][source.$2];
      }
      if (!valid) continue;
      final candidate = HitoriPuzzle(
        id: id ?? 'hitori-generated-${difficulty.name}-$seed',
        title: title ?? '${difficulty.label} · Erstelltes Rätsel',
        grid: grid,
        solution: shaded,
        difficulty: difficulty,
      );
      final solved = solver.solve(candidate);
      if (solved != null &&
          solver.hasUniqueSolution(candidate) &&
          solved.length == shaded.length &&
          solved.containsAll(shaded)) {
        return candidate;
      }
    }
    throw StateError('No unique Hitori puzzle found for seed $seed.');
  }

  List<List<int>> _latinSquare(int size, Random random) {
    final symbols = [for (var value = 1; value <= size; value++) value]
      ..shuffle(random);
    final rows = [for (var index = 0; index < size; index++) index]
      ..shuffle(random);
    final columns = [for (var index = 0; index < size; index++) index]
      ..shuffle(random);
    return [
      for (final row in rows)
        [
          for (final column in columns) symbols[(row + column) % size],
        ],
    ];
  }

  Set<HitoriCell> _shadedPattern(int size, int target, Random random) {
    final cells = <HitoriCell>[
      for (var row = 0; row < size; row++)
        for (var column = 0; column < size; column++) (row, column),
    ]..shuffle(random);
    final shaded = <HitoriCell>{};
    for (final cell in cells) {
      if (shaded.length >= target) break;
      if (_neighbors(size, cell).any(shaded.contains)) continue;
      shaded.add(cell);
      final state = HitoriState(
        puzzle: HitoriPuzzle(
          id: 'pattern',
          title: 'pattern',
          grid: [
            for (var row = 0; row < size; row++)
              [for (var column = 0; column < size; column++) column + 1],
          ],
          solution: shaded,
          difficulty: PuzzleDifficulty.easy,
        ),
        marks: {for (final item in shaded) item: HitoriCellMark.shaded},
      );
      if (!state.openCellsConnected) shaded.remove(cell);
    }
    return shaded;
  }

  Iterable<HitoriCell> _neighbors(int size, HitoriCell cell) sync* {
    if (cell.$1 > 0) yield (cell.$1 - 1, cell.$2);
    if (cell.$1 + 1 < size) yield (cell.$1 + 1, cell.$2);
    if (cell.$2 > 0) yield (cell.$1, cell.$2 - 1);
    if (cell.$2 + 1 < size) yield (cell.$1, cell.$2 + 1);
  }
}
