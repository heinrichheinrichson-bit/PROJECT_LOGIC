import 'package:flutter/foundation.dart';

import '../../../core/domain/game_identity.dart';

typedef HitoriCell = (int, int);

enum HitoriCellMark { open, shaded, protected }

@immutable
class HitoriPuzzle {
  const HitoriPuzzle({
    required this.id,
    required this.title,
    required this.grid,
    required this.solution,
    required this.difficulty,
  });

  final String id;
  final String title;
  final List<List<int>> grid;
  final Set<HitoriCell> solution;
  final PuzzleDifficulty difficulty;

  int get size => grid.length;
}

@immutable
class HitoriState {
  HitoriState({
    required this.puzzle,
    Map<HitoriCell, HitoriCellMark>? marks,
  }) : marks = Map.unmodifiable(marks ?? const {});

  final HitoriPuzzle puzzle;
  final Map<HitoriCell, HitoriCellMark> marks;

  HitoriCellMark markAt(int row, int column) =>
      marks[(row, column)] ?? HitoriCellMark.open;

  bool isShaded(int row, int column) =>
      markAt(row, column) == HitoriCellMark.shaded;

  HitoriState cycle(int row, int column) {
    final cell = (row, column);
    final next = switch (markAt(row, column)) {
      HitoriCellMark.open => HitoriCellMark.shaded,
      HitoriCellMark.shaded => HitoriCellMark.protected,
      HitoriCellMark.protected => HitoriCellMark.open,
    };
    final updated = Map<HitoriCell, HitoriCellMark>.from(marks);
    if (next == HitoriCellMark.open) {
      updated.remove(cell);
    } else {
      updated[cell] = next;
    }
    return HitoriState(puzzle: puzzle, marks: updated);
  }

  Set<HitoriCell> get duplicateConflicts {
    final conflicts = <HitoriCell>{};
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
    return conflicts;
  }

  void _markDuplicates(
    List<HitoriCell> cells,
    Set<HitoriCell> conflicts,
  ) {
    final positions = <int, List<HitoriCell>>{};
    for (final cell in cells) {
      if (isShaded(cell.$1, cell.$2)) continue;
      positions.putIfAbsent(puzzle.grid[cell.$1][cell.$2], () => []).add(cell);
    }
    for (final duplicates
        in positions.values.where((list) => list.length > 1)) {
      conflicts.addAll(duplicates);
    }
  }

  Set<HitoriCell> get adjacentShadeConflicts {
    final conflicts = <HitoriCell>{};
    for (var row = 0; row < puzzle.size; row++) {
      for (var column = 0; column < puzzle.size; column++) {
        if (!isShaded(row, column)) continue;
        for (final neighbor in _neighbors(row, column)) {
          if (isShaded(neighbor.$1, neighbor.$2)) {
            conflicts
              ..add((row, column))
              ..add(neighbor);
          }
        }
      }
    }
    return conflicts;
  }

  bool get openCellsConnected {
    HitoriCell? start;
    for (var row = 0; row < puzzle.size && start == null; row++) {
      for (var column = 0; column < puzzle.size; column++) {
        if (!isShaded(row, column)) {
          start = (row, column);
          break;
        }
      }
    }
    if (start == null) return false;
    final reached = <HitoriCell>{start};
    final queue = <HitoriCell>[start];
    while (queue.isNotEmpty) {
      final cell = queue.removeLast();
      for (final neighbor in _neighbors(cell.$1, cell.$2)) {
        if (!isShaded(neighbor.$1, neighbor.$2) && reached.add(neighbor)) {
          queue.add(neighbor);
        }
      }
    }
    final openCount = puzzle.size * puzzle.size -
        marks.values.where((mark) => mark == HitoriCellMark.shaded).length;
    return reached.length == openCount;
  }

  Iterable<HitoriCell> _neighbors(int row, int column) sync* {
    if (row > 0) yield (row - 1, column);
    if (row + 1 < puzzle.size) yield (row + 1, column);
    if (column > 0) yield (row, column - 1);
    if (column + 1 < puzzle.size) yield (row, column + 1);
  }

  bool get isSolved =>
      duplicateConflicts.isEmpty &&
      adjacentShadeConflicts.isEmpty &&
      openCellsConnected;
}
