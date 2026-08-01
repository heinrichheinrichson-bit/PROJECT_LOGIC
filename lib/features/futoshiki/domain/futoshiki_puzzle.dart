import 'package:flutter/foundation.dart';

import '../../../core/domain/game_identity.dart';

@immutable
class FutoshikiInequality {
  const FutoshikiInequality({
    required this.firstRow,
    required this.firstColumn,
    required this.secondRow,
    required this.secondColumn,
    required this.firstIsLess,
  });

  final int firstRow;
  final int firstColumn;
  final int secondRow;
  final int secondColumn;
  final bool firstIsLess;

  bool isSatisfiedBy(int first, int second) =>
      firstIsLess ? first < second : first > second;

  bool touches(int row, int column) =>
      (firstRow == row && firstColumn == column) ||
      (secondRow == row && secondColumn == column);
}

@immutable
class FutoshikiPuzzle {
  const FutoshikiPuzzle({
    required this.id,
    required this.title,
    required this.size,
    required this.givens,
    required this.inequalities,
    required this.solution,
    this.difficulty = PuzzleDifficulty.easy,
  });

  final String id;
  final String title;
  final int size;
  final List<List<int?>> givens;
  final List<FutoshikiInequality> inequalities;
  final List<List<int>> solution;
  final PuzzleDifficulty difficulty;
}

@immutable
class FutoshikiState {
  FutoshikiState({
    required this.puzzle,
    List<List<int?>>? values,
  }) : values = values == null
            ? [
                for (final row in puzzle.givens) [...row]
              ]
            : [
                for (final row in values) [...row]
              ];

  final FutoshikiPuzzle puzzle;
  final List<List<int?>> values;

  bool isGiven(int row, int column) => puzzle.givens[row][column] != null;

  FutoshikiState setValue(int row, int column, int? value) {
    if (isGiven(row, column)) return this;
    final updated = [
      for (final line in values) [...line]
    ];
    updated[row][column] = value;
    return FutoshikiState(puzzle: puzzle, values: updated);
  }

  Set<(int, int)> get conflictingCells {
    final conflicts = <(int, int)>{};
    for (var row = 0; row < puzzle.size; row++) {
      _markDuplicates(
        [for (var column = 0; column < puzzle.size; column++) (row, column)],
        conflicts,
      );
    }
    for (var column = 0; column < puzzle.size; column++) {
      _markDuplicates(
        [for (var row = 0; row < puzzle.size; row++) (row, column)],
        conflicts,
      );
    }
    for (final inequality in puzzle.inequalities) {
      final first = values[inequality.firstRow][inequality.firstColumn];
      final second = values[inequality.secondRow][inequality.secondColumn];
      if (first != null &&
          second != null &&
          !inequality.isSatisfiedBy(first, second)) {
        conflicts
          ..add((inequality.firstRow, inequality.firstColumn))
          ..add((inequality.secondRow, inequality.secondColumn));
      }
    }
    return conflicts;
  }

  void _markDuplicates(
    List<(int, int)> cells,
    Set<(int, int)> conflicts,
  ) {
    final positions = <int, List<(int, int)>>{};
    for (final cell in cells) {
      final value = values[cell.$1][cell.$2];
      if (value != null) positions.putIfAbsent(value, () => []).add(cell);
    }
    for (final duplicates
        in positions.values.where((items) => items.length > 1)) {
      conflicts.addAll(duplicates);
    }
  }

  bool get isSolved =>
      values.every((row) => row.every((value) => value != null)) &&
      conflictingCells.isEmpty;
}
