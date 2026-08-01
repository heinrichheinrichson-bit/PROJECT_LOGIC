import 'tents_puzzle.dart';

class TentsSolveResult {
  const TentsSolveResult({
    required this.solution,
    required this.searchNodes,
    required this.forcedPlacements,
  });

  final Set<TentsCell> solution;
  final int searchNodes;
  final int forcedPlacements;
}

class TentsSolver {
  const TentsSolver();

  TentsSolveResult? solve(TentsPuzzle puzzle) =>
      _search(puzzle, limit: 1).results.firstOrNull;

  bool hasUniqueSolution(TentsPuzzle puzzle) =>
      _search(puzzle, limit: 2).results.length == 1;

  int countSolutions(TentsPuzzle puzzle, {int limit = 2}) =>
      _search(puzzle, limit: limit).results.length;

  _SearchOutput _search(TentsPuzzle puzzle, {required int limit}) {
    if (!puzzle.isStructurallyValid) return const _SearchOutput([], 0);
    final trees = puzzle.trees.toList(growable: false);
    final candidates = {
      for (final tree in trees)
        tree: _orthogonal(puzzle.size, tree)
            .where((cell) => !puzzle.trees.contains(cell))
            .toList(growable: false),
    };
    if (candidates.values.any((items) => items.isEmpty)) {
      return const _SearchOutput([], 0);
    }
    final found = <String, TentsSolveResult>{};
    final usedTents = <TentsCell>{};
    final assignedTrees = <TentsCell>{};
    final rowUsed = List<int>.filled(puzzle.size, 0);
    final columnUsed = List<int>.filled(puzzle.size, 0);
    var nodes = 0;
    var forced = 0;

    void search() {
      if (found.length >= limit) return;
      nodes++;
      TentsCell? nextTree;
      List<TentsCell>? options;
      for (final tree in trees.where((tree) => !assignedTrees.contains(tree))) {
        final available = candidates[tree]!
            .where((cell) => _canPlace(
                  puzzle,
                  cell,
                  usedTents,
                  rowUsed,
                  columnUsed,
                ))
            .toList(growable: false);
        if (available.isEmpty) return;
        if (options == null || available.length < options.length) {
          nextTree = tree;
          options = available;
        }
      }
      if (nextTree == null) {
        if (!_countsMatch(puzzle, rowUsed, columnUsed)) return;
        final solution = Set<TentsCell>.from(usedTents);
        final key = solution.toList()
          ..sort((a, b) =>
              a.$1 == b.$1 ? a.$2.compareTo(b.$2) : a.$1.compareTo(b.$1));
        final encoded = key.map((cell) => '${cell.$1}:${cell.$2}').join('|');
        found.putIfAbsent(
          encoded,
          () => TentsSolveResult(
            solution: solution,
            searchNodes: nodes,
            forcedPlacements: forced,
          ),
        );
        return;
      }
      assignedTrees.add(nextTree);
      if (options!.length == 1) forced++;
      for (final tent in options) {
        usedTents.add(tent);
        rowUsed[tent.$1]++;
        columnUsed[tent.$2]++;
        if (_remainingCountsPossible(
            puzzle, trees.length - assignedTrees.length, rowUsed, columnUsed)) {
          search();
        }
        columnUsed[tent.$2]--;
        rowUsed[tent.$1]--;
        usedTents.remove(tent);
      }
      assignedTrees.remove(nextTree);
    }

    search();
    return _SearchOutput(found.values.toList(growable: false), nodes);
  }

  bool _canPlace(
    TentsPuzzle puzzle,
    TentsCell cell,
    Set<TentsCell> used,
    List<int> rowUsed,
    List<int> columnUsed,
  ) {
    if (used.contains(cell) ||
        rowUsed[cell.$1] >= puzzle.rowCounts[cell.$1] ||
        columnUsed[cell.$2] >= puzzle.columnCounts[cell.$2]) {
      return false;
    }
    return _surrounding(puzzle.size, cell)
        .every((other) => !used.contains(other));
  }

  bool _remainingCountsPossible(
      TentsPuzzle puzzle, int remaining, List<int> rows, List<int> columns) {
    final rowMissing = [
      for (var i = 0; i < puzzle.size; i++) puzzle.rowCounts[i] - rows[i],
    ];
    final columnMissing = [
      for (var i = 0; i < puzzle.size; i++) puzzle.columnCounts[i] - columns[i],
    ];
    return rowMissing.every((value) => value >= 0) &&
        columnMissing.every((value) => value >= 0) &&
        rowMissing.fold(0, (sum, value) => sum + value) == remaining &&
        columnMissing.fold(0, (sum, value) => sum + value) == remaining;
  }

  bool _countsMatch(TentsPuzzle puzzle, List<int> rows, List<int> columns) =>
      _remainingCountsPossible(puzzle, 0, rows, columns);

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

class _SearchOutput {
  const _SearchOutput(this.results, this.nodes);
  final List<TentsSolveResult> results;
  final int nodes;
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
