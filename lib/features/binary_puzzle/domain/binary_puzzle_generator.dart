import 'dart:math';

import '../../../game_logic.dart';
import 'binary_board_generator.dart';
import 'binary_puzzle_solver.dart';

class BinaryPuzzleGenerationResult {
  const BinaryPuzzleGenerationResult({
    required this.definition,
    required this.seed,
    required this.attemptedRemovals,
    required this.successfulRemovals,
    required this.targetClueCount,
  });

  final BinaryPuzzleDefinition definition;
  final int seed;
  final int attemptedRemovals;
  final int successfulRemovals;
  final int targetClueCount;

  bool get reachedTarget => definition.clueCount <= targetClueCount;
}

/// Generates a playable Binary Puzzle from a complete solution board.
///
/// Cells are considered in a deterministic shuffled order. A clue is removed
/// only when the remaining puzzle still has exactly one solution. Generation
/// stops once the clue target for the selected difficulty has been reached or
/// every cell has been considered once.
class BinaryPuzzleGenerator {
  const BinaryPuzzleGenerator({
    this.boardGenerator = const BinaryBoardGenerator(),
    this.solver = const BinaryPuzzleSolver(),
  });

  final BinaryBoardGenerator boardGenerator;
  final BinaryPuzzleSolver solver;

  BinaryPuzzleGenerationResult generate({
    required int size,
    int? seed,
    int number = 1,
    PuzzleDifficulty difficulty = PuzzleDifficulty.easy,
  }) {
    final boardResult = boardGenerator.generate(
      size: size,
      seed: seed,
    );

    final solution = [
      for (final row in boardResult.board) [...row],
    ];
    final puzzleBoard = <List<CellValue?>>[
      for (final row in solution) [...row],
    ];

    final positions = <CellPosition>[
      for (var row = 0; row < size; row++)
        for (var column = 0; column < size; column++)
          CellPosition(row, column),
    ];
    positions.shuffle(Random(boardResult.seed));

    final targetClueCount = _targetClueCount(size, difficulty);
    var clueCount = size * size;
    var attemptedRemovals = 0;
    var successfulRemovals = 0;

    for (final position in positions) {
      if (clueCount <= targetClueCount) break;

      attemptedRemovals++;
      final previous = puzzleBoard[position.row][position.column];
      puzzleBoard[position.row][position.column] = null;

      final result = solver.solve(puzzleBoard, solutionLimit: 2);
      if (result.hasUniqueSolution) {
        clueCount--;
        successfulRemovals++;
      } else {
        puzzleBoard[position.row][position.column] = previous;
      }
    }

    final clues = <CellPosition>{
      for (var row = 0; row < size; row++)
        for (var column = 0; column < size; column++)
          if (puzzleBoard[row][column] != null) CellPosition(row, column),
    };

    final definition = BinaryPuzzleDefinition(
      id: 'binary-$size-${difficulty.name}-${boardResult.seed}',
      number: number,
      difficulty: difficulty,
      solution: solution,
      clues: clues,
    );

    return BinaryPuzzleGenerationResult(
      definition: definition,
      seed: boardResult.seed,
      attemptedRemovals: attemptedRemovals,
      successfulRemovals: successfulRemovals,
      targetClueCount: targetClueCount,
    );
  }

  int _targetClueCount(int size, PuzzleDifficulty difficulty) {
    final cellCount = size * size;
    final ratio = switch (difficulty) {
      PuzzleDifficulty.easy => 0.62,
      PuzzleDifficulty.medium => 0.52,
      PuzzleDifficulty.hard => 0.42,
    };

    return max(size, (cellCount * ratio).ceil());
  }
}
