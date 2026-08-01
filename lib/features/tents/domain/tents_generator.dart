import 'dart:math';

import '../../../core/domain/game_identity.dart';
import 'tents_puzzle.dart';
import 'tents_solver.dart';

class TentsGenerator {
  const TentsGenerator({this.solver = const TentsSolver()});

  final TentsSolver solver;

  TentsPuzzle generate({
    required int seed,
    required PuzzleDifficulty difficulty,
    int? size,
    String? id,
    String? title,
  }) {
    final boardSize = size ??
        switch (difficulty) {
          PuzzleDifficulty.easy => 6,
          PuzzleDifficulty.medium => 8,
          PuzzleDifficulty.hard => 10,
        };
    if (boardSize < 5 || boardSize > 12) {
      throw ArgumentError.value(boardSize, 'size', 'Must be between 5 and 12.');
    }
    final tentTarget = switch (difficulty) {
      PuzzleDifficulty.easy => max(5, (boardSize * boardSize * .17).round()),
      PuzzleDifficulty.medium => max(7, (boardSize * boardSize * .19).round()),
      PuzzleDifficulty.hard => max(9, (boardSize * boardSize * .20).round()),
    };
    final random = Random(seed);
    for (var attempt = 0; attempt < 4000; attempt++) {
      final tents = _placeTents(boardSize, tentTarget, random);
      if (tents.length != tentTarget) continue;
      final trees = _placeTrees(boardSize, tents, difficulty, random);
      if (trees == null) continue;
      final rowCounts = List<int>.generate(
        boardSize,
        (row) => tents.where((cell) => cell.$1 == row).length,
      );
      final columnCounts = List<int>.generate(
        boardSize,
        (column) => tents.where((cell) => cell.$2 == column).length,
      );
      final puzzle = TentsPuzzle(
        id: id ?? 'tents-generated-${difficulty.name}-$seed',
        title: title ?? '${difficulty.label} \u00b7 Zufallsr\u00e4tsel',
        size: boardSize,
        trees: trees,
        rowCounts: rowCounts,
        columnCounts: columnCounts,
        solution: tents,
        difficulty: difficulty,
      );
      final solved = solver.solve(puzzle);
      if (solved != null &&
          solved.solution.length == tents.length &&
          solved.solution.containsAll(tents) &&
          solver.hasUniqueSolution(puzzle)) {
        return puzzle;
      }
    }
    throw StateError('No unique Tents puzzle found for seed $seed.');
  }

  Set<TentsCell> _placeTents(int size, int target, Random random) {
    final cells = <TentsCell>[
      for (var row = 0; row < size; row++)
        for (var column = 0; column < size; column++) (row, column),
    ]..shuffle(random);
    final tents = <TentsCell>{};
    for (final cell in cells) {
      if (tents.length == target) break;
      if (_surrounding(size, cell).any(tents.contains)) continue;
      tents.add(cell);
    }
    return tents;
  }

  Set<TentsCell>? _placeTrees(
    int size,
    Set<TentsCell> tents,
    PuzzleDifficulty difficulty,
    Random random,
  ) {
    final orderedTents = tents.toList()..shuffle(random);
    final trees = <TentsCell>{};

    bool search(int index) {
      if (index == orderedTents.length) return true;
      final tent = orderedTents[index];
      final candidates = _orthogonal(size, tent)
          .where((cell) => !tents.contains(cell) && !trees.contains(cell))
          .toList()
        ..shuffle(random);
      // Prefer trees that do not also touch another tent. Easy boards become
      // approachable, while the fallback still permits richer deductions.
      if (difficulty == PuzzleDifficulty.easy) {
        candidates.sort((a, b) => _adjacentTentCount(size, a, tents)
            .compareTo(_adjacentTentCount(size, b, tents)));
      } else if (difficulty == PuzzleDifficulty.hard) {
        candidates.sort((a, b) => _adjacentTentCount(size, b, tents)
            .compareTo(_adjacentTentCount(size, a, tents)));
      }
      for (final tree in candidates) {
        trees.add(tree);
        if (search(index + 1)) return true;
        trees.remove(tree);
      }
      return false;
    }

    return search(0) ? trees : null;
  }

  int _adjacentTentCount(int size, TentsCell cell, Set<TentsCell> tents) =>
      _orthogonal(size, cell).where(tents.contains).length;

  Iterable<TentsCell> _orthogonal(int size, TentsCell cell) sync* {
    if (cell.$1 > 0) yield (cell.$1 - 1, cell.$2);
    if (cell.$1 + 1 < size) yield (cell.$1 + 1, cell.$2);
    if (cell.$2 > 0) yield (cell.$1, cell.$2 - 1);
    if (cell.$2 + 1 < size) yield (cell.$1, cell.$2 + 1);
  }

  Iterable<TentsCell> _surrounding(int size, TentsCell cell) sync* {
    for (var row = cell.$1 - 1; row <= cell.$1 + 1; row++) {
      for (var column = cell.$2 - 1; column <= cell.$2 + 1; column++) {
        if ((row, column) == cell) continue;
        if (row >= 0 && row < size && column >= 0 && column < size) {
          yield (row, column);
        }
      }
    }
  }
}
