import 'package:flutter/foundation.dart';

import '../../../core/domain/game_identity.dart';

typedef TentsCell = (int, int);

enum TentsCellMark { unknown, tent, grass }

@immutable
class TentsPuzzle {
  const TentsPuzzle({
    required this.id,
    required this.title,
    required this.size,
    required this.trees,
    required this.rowCounts,
    required this.columnCounts,
    required this.solution,
    required this.difficulty,
  });

  final String id;
  final String title;
  final int size;
  final Set<TentsCell> trees;
  final List<int> rowCounts;
  final List<int> columnCounts;
  final Set<TentsCell> solution;
  final PuzzleDifficulty difficulty;

  bool get isStructurallyValid =>
      size >= 4 &&
      rowCounts.length == size &&
      columnCounts.length == size &&
      rowCounts.fold(0, (sum, value) => sum + value) == trees.length &&
      columnCounts.fold(0, (sum, value) => sum + value) == trees.length &&
      solution.length == trees.length &&
      trees.every(_inside) &&
      solution.every(_inside) &&
      trees.intersection(solution).isEmpty;

  bool _inside(TentsCell cell) =>
      cell.$1 >= 0 && cell.$1 < size && cell.$2 >= 0 && cell.$2 < size;
}

@immutable
class TentsState {
  TentsState({required this.puzzle, Map<TentsCell, TentsCellMark>? marks})
      : marks = Map.unmodifiable(marks ?? const {});

  final TentsPuzzle puzzle;
  final Map<TentsCell, TentsCellMark> marks;

  TentsCellMark markAt(int row, int column) =>
      marks[(row, column)] ?? TentsCellMark.unknown;

  bool isTent(int row, int column) => markAt(row, column) == TentsCellMark.tent;

  TentsState cycle(int row, int column) {
    final cell = (row, column);
    if (puzzle.trees.contains(cell)) return this;
    final next = switch (markAt(row, column)) {
      TentsCellMark.unknown => TentsCellMark.tent,
      TentsCellMark.tent => TentsCellMark.grass,
      TentsCellMark.grass => TentsCellMark.unknown,
    };
    final updated = Map<TentsCell, TentsCellMark>.from(marks);
    if (next == TentsCellMark.unknown) {
      updated.remove(cell);
    } else {
      updated[cell] = next;
    }
    return TentsState(puzzle: puzzle, marks: updated);
  }

  Set<TentsCell> get tents => {
        for (final entry in marks.entries)
          if (entry.value == TentsCellMark.tent) entry.key,
      };

  Set<TentsCell> get touchingTentConflicts {
    final result = <TentsCell>{};
    for (final tent in tents) {
      for (final other in _neighbors(tent, diagonal: true)) {
        if (tents.contains(other)) {
          result
            ..add(tent)
            ..add(other);
        }
      }
    }
    return result;
  }

  Set<TentsCell> get countConflicts {
    final result = <TentsCell>{};
    for (var row = 0; row < puzzle.size; row++) {
      final inRow = tents.where((cell) => cell.$1 == row).toList();
      if (inRow.length > puzzle.rowCounts[row]) result.addAll(inRow);
    }
    for (var column = 0; column < puzzle.size; column++) {
      final inColumn = tents.where((cell) => cell.$2 == column).toList();
      if (inColumn.length > puzzle.columnCounts[column]) {
        result.addAll(inColumn);
      }
    }
    return result;
  }

  Set<TentsCell> get orphanTentConflicts => {
        for (final tent in tents)
          if (!_neighbors(tent).any(puzzle.trees.contains)) tent,
      };

  bool get isSolved {
    if (tents.length != puzzle.trees.length ||
        touchingTentConflicts.isNotEmpty ||
        orphanTentConflicts.isNotEmpty) {
      return false;
    }
    for (var index = 0; index < puzzle.size; index++) {
      if (tents.where((cell) => cell.$1 == index).length !=
              puzzle.rowCounts[index] ||
          tents.where((cell) => cell.$2 == index).length !=
              puzzle.columnCounts[index]) {
        return false;
      }
    }
    return _hasPerfectTreeMatching(tents);
  }

  bool _hasPerfectTreeMatching(Set<TentsCell> placedTents) {
    final trees = puzzle.trees.toList(growable: false);
    final used = <TentsCell>{};
    bool search(int index) {
      if (index == trees.length) return true;
      for (final cell in _neighbors(trees[index])) {
        if (placedTents.contains(cell) && used.add(cell)) {
          if (search(index + 1)) return true;
          used.remove(cell);
        }
      }
      return false;
    }

    return search(0);
  }

  Iterable<TentsCell> _neighbors(TentsCell cell,
      {bool diagonal = false}) sync* {
    for (var rowDelta = -1; rowDelta <= 1; rowDelta++) {
      for (var columnDelta = -1; columnDelta <= 1; columnDelta++) {
        if (rowDelta == 0 && columnDelta == 0) continue;
        if (!diagonal && rowDelta.abs() + columnDelta.abs() != 1) continue;
        final row = cell.$1 + rowDelta;
        final column = cell.$2 + columnDelta;
        if (row >= 0 &&
            row < puzzle.size &&
            column >= 0 &&
            column < puzzle.size) {
          yield (row, column);
        }
      }
    }
  }
}
