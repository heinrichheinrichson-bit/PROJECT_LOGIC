import 'dart:math';

import '../../../game_logic.dart';
import 'binary_board_generator.dart';
import 'binary_difficulty_rater.dart';
import 'binary_puzzle_solver.dart';

class BinaryPuzzleGenerationResult {
  const BinaryPuzzleGenerationResult({
    required this.definition,
    required this.seed,
    required this.attemptedRemovals,
    required this.successfulRemovals,
    required this.targetClueCount,
    required this.solverCalls,
    required this.rejectedRemovals,
    required this.generationDuration,
    required this.rowClueCounts,
    required this.columnClueCounts,
    required this.difficultyAnalysis,
  });

  final BinaryPuzzleDefinition definition;
  final int seed;
  final int attemptedRemovals;
  final int successfulRemovals;
  final int targetClueCount;
  final int solverCalls;
  final int rejectedRemovals;
  final Duration generationDuration;
  final List<int> rowClueCounts;
  final List<int> columnClueCounts;
  final BinaryDifficultyAnalysis difficultyAnalysis;

  bool get reachedTarget => definition.clueCount <= targetClueCount;

  int get clueDistributionSpread {
    final counts = [...rowClueCounts, ...columnClueCounts];
    if (counts.isEmpty) return 0;
    return counts.reduce(max) - counts.reduce(min);
  }
}

/// Generates a playable Binary Puzzle from a complete solution board.
///
/// Clues are removed in a deterministic, distribution-aware order. Cells in
/// rows and columns that still contain many clues are considered first. A clue
/// is removed only when the remaining puzzle still has exactly one solution.
/// Generation stops once the clue target for the selected difficulty has been
/// reached or every cell has been considered once.
class BinaryPuzzleGenerator {
  const BinaryPuzzleGenerator({
    this.boardGenerator = const BinaryBoardGenerator(),
    this.solver = const BinaryPuzzleSolver(),
    this.difficultyRater = const BinaryDifficultyRater(),
  });

  final BinaryBoardGenerator boardGenerator;
  final BinaryPuzzleSolver solver;
  final BinaryDifficultyRater difficultyRater;

  BinaryPuzzleGenerationResult generate({
    required int size,
    int? seed,
    int number = 1,
    PuzzleDifficulty difficulty = PuzzleDifficulty.easy,
  }) {
    final stopwatch = Stopwatch()..start();
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

    final random = Random(boardResult.seed);
    final positions = <CellPosition>[
      for (var row = 0; row < size; row++)
        for (var column = 0; column < size; column++) CellPosition(row, column),
    ]..shuffle(random);

    final randomRank = <CellPosition, int>{
      for (var index = 0; index < positions.length; index++)
        positions[index]: index,
    };
    final rowClueCounts = List<int>.filled(size, size);
    final columnClueCounts = List<int>.filled(size, size);
    final targetClueCount = _targetClueCount(size, difficulty);
    var clueCount = size * size;
    var attemptedRemovals = 0;
    var successfulRemovals = 0;
    var solverCalls = 0;

    while (positions.isNotEmpty && clueCount > targetClueCount) {
      positions.sort((first, second) {
        final firstScore =
            rowClueCounts[first.row] + columnClueCounts[first.column];
        final secondScore =
            rowClueCounts[second.row] + columnClueCounts[second.column];
        final scoreComparison = secondScore.compareTo(firstScore);
        if (scoreComparison != 0) return scoreComparison;
        return randomRank[first]!.compareTo(randomRank[second]!);
      });

      final position = positions.removeAt(0);
      attemptedRemovals++;
      final previous = puzzleBoard[position.row][position.column];
      puzzleBoard[position.row][position.column] = null;

      solverCalls++;
      final result = solver.solve(puzzleBoard, solutionLimit: 2);
      if (result.hasUniqueSolution) {
        clueCount--;
        successfulRemovals++;
        rowClueCounts[position.row]--;
        columnClueCounts[position.column]--;
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

    stopwatch.stop();
    return BinaryPuzzleGenerationResult(
      definition: definition,
      seed: boardResult.seed,
      attemptedRemovals: attemptedRemovals,
      successfulRemovals: successfulRemovals,
      targetClueCount: targetClueCount,
      solverCalls: solverCalls,
      rejectedRemovals: attemptedRemovals - successfulRemovals,
      generationDuration: stopwatch.elapsed,
      rowClueCounts: List<int>.unmodifiable(rowClueCounts),
      columnClueCounts: List<int>.unmodifiable(columnClueCounts),
      difficultyAnalysis: difficultyRater.analyze(definition),
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
