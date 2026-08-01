import 'futoshiki_puzzle.dart';

class FutoshikiSolver {
  const FutoshikiSolver();

  List<List<int>>? solve(FutoshikiPuzzle puzzle) =>
      _solutions(puzzle, limit: 1).firstOrNull;

  bool hasUniqueSolution(FutoshikiPuzzle puzzle) =>
      _solutions(puzzle, limit: 2).length == 1;

  List<List<List<int>>> _solutions(
    FutoshikiPuzzle puzzle, {
    required int limit,
  }) {
    final board = [
      for (final row in puzzle.givens) [...row]
    ];
    final solutions = <List<List<int>>>[];

    void search() {
      if (solutions.length >= limit) return;
      final next = _bestEmpty(puzzle, board);
      if (next == null) {
        solutions.add([
          for (final row in board) [for (final value in row) value!],
        ]);
        return;
      }
      for (final value in next.candidates) {
        board[next.row][next.column] = value;
        search();
        board[next.row][next.column] = null;
        if (solutions.length >= limit) return;
      }
    }

    search();
    return solutions;
  }

  ({int row, int column, List<int> candidates})? _bestEmpty(
    FutoshikiPuzzle puzzle,
    List<List<int?>> board,
  ) {
    ({int row, int column, List<int> candidates})? best;
    for (var row = 0; row < puzzle.size; row++) {
      for (var column = 0; column < puzzle.size; column++) {
        if (board[row][column] != null) continue;
        final candidates = <int>[
          for (var value = 1; value <= puzzle.size; value++)
            if (_canPlace(puzzle, board, row, column, value)) value,
        ];
        if (candidates.isEmpty) {
          return (row: row, column: column, candidates: []);
        }
        if (best == null || candidates.length < best.candidates.length) {
          best = (row: row, column: column, candidates: candidates);
        }
      }
    }
    return best;
  }

  bool _canPlace(
    FutoshikiPuzzle puzzle,
    List<List<int?>> board,
    int row,
    int column,
    int value,
  ) {
    if (board[row].contains(value)) return false;
    for (var otherRow = 0; otherRow < puzzle.size; otherRow++) {
      if (board[otherRow][column] == value) return false;
    }
    for (final inequality
        in puzzle.inequalities.where((item) => item.touches(row, column))) {
      final isFirst =
          inequality.firstRow == row && inequality.firstColumn == column;
      final other = isFirst
          ? board[inequality.secondRow][inequality.secondColumn]
          : board[inequality.firstRow][inequality.firstColumn];
      if (other == null) continue;
      final valid = isFirst
          ? inequality.isSatisfiedBy(value, other)
          : inequality.isSatisfiedBy(other, value);
      if (!valid) return false;
    }
    return true;
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
