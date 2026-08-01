import 'hitori_puzzle.dart';

class HitoriSolver {
  const HitoriSolver();

  Set<HitoriCell>? solve(HitoriPuzzle puzzle) =>
      _solutions(puzzle, limit: 1).firstOrNull;

  bool hasUniqueSolution(HitoriPuzzle puzzle) =>
      _solutions(puzzle, limit: 2).length == 1;

  List<Set<HitoriCell>> _solutions(HitoriPuzzle puzzle, {required int limit}) {
    final groups = _duplicateGroups(puzzle);
    final candidates = groups.expand((group) => group).toSet().toList();
    final assignment = <HitoriCell, bool>{};
    final solutions = <Set<HitoriCell>>[];

    void search() {
      if (solutions.length >= limit ||
          !_partialValid(puzzle, groups, assignment)) {
        return;
      }
      HitoriCell? next;
      for (final cell in candidates) {
        if (!assignment.containsKey(cell)) {
          next = cell;
          break;
        }
      }
      if (next == null) {
        final shaded = assignment.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toSet();
        final state = HitoriState(
          puzzle: puzzle,
          marks: {
            for (final cell in shaded) cell: HitoriCellMark.shaded,
          },
        );
        if (state.isSolved) solutions.add(shaded);
        return;
      }
      assignment[next] = false;
      search();
      assignment[next] = true;
      search();
      assignment.remove(next);
    }

    search();
    return solutions;
  }

  bool _partialValid(
    HitoriPuzzle puzzle,
    List<Set<HitoriCell>> groups,
    Map<HitoriCell, bool> assignment,
  ) {
    for (final entry in assignment.entries.where((entry) => entry.value)) {
      final cell = entry.key;
      for (final neighbor in _neighbors(puzzle.size, cell)) {
        if (assignment[neighbor] == true) return false;
      }
    }
    for (final group in groups) {
      final definitelyOpen =
          group.where((cell) => assignment[cell] == false).length;
      if (definitelyOpen > 1) return false;
      final canStayOpen = group.any((cell) => assignment[cell] != true);
      if (!canStayOpen) return false;
    }
    return _possibleOpenAreaConnected(puzzle, assignment);
  }

  bool _possibleOpenAreaConnected(
    HitoriPuzzle puzzle,
    Map<HitoriCell, bool> assignment,
  ) {
    final requiredOpen = assignment.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toSet();
    if (requiredOpen.length < 2) return true;
    final start = requiredOpen.first;
    final reached = <HitoriCell>{start};
    final queue = <HitoriCell>[start];
    while (queue.isNotEmpty) {
      final cell = queue.removeLast();
      for (final neighbor in _neighbors(puzzle.size, cell)) {
        if (assignment[neighbor] != true && reached.add(neighbor)) {
          queue.add(neighbor);
        }
      }
    }
    return reached.containsAll(requiredOpen);
  }

  List<Set<HitoriCell>> _duplicateGroups(HitoriPuzzle puzzle) {
    final groups = <Set<HitoriCell>>[];
    for (var row = 0; row < puzzle.size; row++) {
      _addGroups(
        puzzle,
        [for (var column = 0; column < puzzle.size; column++) (row, column)],
        groups,
      );
    }
    for (var column = 0; column < puzzle.size; column++) {
      _addGroups(
        puzzle,
        [for (var row = 0; row < puzzle.size; row++) (row, column)],
        groups,
      );
    }
    return groups;
  }

  void _addGroups(
    HitoriPuzzle puzzle,
    List<HitoriCell> cells,
    List<Set<HitoriCell>> groups,
  ) {
    final byValue = <int, Set<HitoriCell>>{};
    for (final cell in cells) {
      byValue.putIfAbsent(puzzle.grid[cell.$1][cell.$2], () => {}).add(cell);
    }
    groups.addAll(byValue.values.where((group) => group.length > 1));
  }

  Iterable<HitoriCell> _neighbors(int size, HitoriCell cell) sync* {
    if (cell.$1 > 0) yield (cell.$1 - 1, cell.$2);
    if (cell.$1 + 1 < size) yield (cell.$1 + 1, cell.$2);
    if (cell.$2 > 0) yield (cell.$1, cell.$2 - 1);
    if (cell.$2 + 1 < size) yield (cell.$1, cell.$2 + 1);
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
