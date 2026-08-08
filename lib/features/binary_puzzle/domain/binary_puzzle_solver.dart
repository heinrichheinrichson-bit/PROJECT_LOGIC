import '../../../game_logic.dart';
import 'binary_board_validator.dart';

class BinarySolverResult {
  const BinarySolverResult({
    required this.solutions,
    required this.exploredStates,
    required this.wasLimited,
  });

  final List<List<List<CellValue>>> solutions;
  final int exploredStates;
  final bool wasLimited;

  int get solutionCount => solutions.length;
  bool get isSolvable => solutions.isNotEmpty;
  bool get hasUniqueSolution => solutions.length == 1 && !wasLimited;
  List<List<CellValue>>? get firstSolution =>
      solutions.isEmpty ? null : solutions.first;
}

class BinaryPuzzleSolver {
  const BinaryPuzzleSolver({
    this.validator = const BinaryBoardValidator(),
  });

  final BinaryBoardValidator validator;

  BinarySolverResult solve(
    List<List<CellValue?>> initialBoard, {
    int solutionLimit = 2,
  }) {
    if (solutionLimit < 1) {
      throw ArgumentError.value(
        solutionLimit,
        'solutionLimit',
        'Must be at least 1.',
      );
    }

    final board = [
      for (final row in initialBoard) [...row],
    ];

    if (!validator.isValidPartial(board)) {
      return const BinarySolverResult(
        solutions: [],
        exploredStates: 1,
        wasLimited: false,
      );
    }

    final solutions = <List<List<CellValue>>>[];
    var exploredStates = 0;
    var reachedLimit = false;

    void search() {
      if (solutions.length >= solutionLimit) {
        reachedLimit = true;
        return;
      }

      exploredStates++;

      if (!validator.isValidPartial(board)) return;

      final empty = _chooseNextEmptyCell(board);
      if (empty == null) {
        solutions.add([
          for (final row in board) [for (final value in row) value!],
        ]);
        return;
      }

      for (final candidate in CellValue.values) {
        board[empty.row][empty.column] = candidate;
        search();
        board[empty.row][empty.column] = null;

        if (solutions.length >= solutionLimit) {
          reachedLimit = true;
          return;
        }
      }
    }

    search();

    return BinarySolverResult(
      solutions: solutions,
      exploredStates: exploredStates,
      wasLimited: reachedLimit,
    );
  }

  CellPosition? _chooseNextEmptyCell(
    List<List<CellValue?>> board,
  ) {
    CellPosition? bestPosition;
    var bestScore = -1;

    for (var row = 0; row < board.length; row++) {
      for (var column = 0; column < board.length; column++) {
        if (board[row][column] != null) continue;

        final rowScore = board[row].where((value) => value != null).length;
        final columnScore = board
            .map((line) => line[column])
            .where((value) => value != null)
            .length;
        final score = rowScore + columnScore;

        if (score > bestScore) {
          bestPosition = CellPosition(row, column);
          bestScore = score;
        }
      }
    }

    return bestPosition;
  }
}
