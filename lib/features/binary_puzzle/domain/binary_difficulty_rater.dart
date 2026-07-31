import '../../../game_logic.dart';
import '../../../hint_engine.dart';

class BinaryDifficultyAnalysis {
  const BinaryDifficultyAnalysis({
    required this.inferredDifficulty,
    required this.totalSteps,
    required this.tripleSteps,
    required this.countSteps,
    required this.uniqueLineSteps,
    required this.combinedSteps,
    required this.solvedLogically,
  });

  final PuzzleDifficulty inferredDifficulty;
  final int totalSteps;
  final int tripleSteps;
  final int countSteps;
  final int uniqueLineSteps;
  final int combinedSteps;
  final bool solvedLogically;

  double get combinedStepRatio =>
      totalSteps == 0 ? 0 : combinedSteps / totalSteps;
}

/// Rates a puzzle by replaying the same explainable techniques available to
/// the player. Clue count remains useful generation input, but no longer acts
/// as the sole description of difficulty.
class BinaryDifficultyRater {
  const BinaryDifficultyRater({this.hintEngine = const BinaryHintEngine()});

  final BinaryHintEngine hintEngine;

  BinaryDifficultyAnalysis analyze(BinaryPuzzleDefinition definition) {
    final puzzle = definition.createPuzzle();
    var tripleSteps = 0;
    var countSteps = 0;
    var uniqueLineSteps = 0;
    var combinedSteps = 0;

    while (!puzzle.isSolved) {
      final hint = hintEngine.findHint(puzzle);
      if (hint == null) break;
      switch (hint.type) {
        case BinaryHintType.triple:
          tripleSteps++;
        case BinaryHintType.count:
          countSteps++;
        case BinaryHintType.uniqueLine:
          uniqueLineSteps++;
        case BinaryHintType.solver:
          combinedSteps++;
      }
      puzzle.setCell(hint.position.row, hint.position.column, hint.value);
    }

    final totalSteps =
        tripleSteps + countSteps + uniqueLineSteps + combinedSteps;
    final inferredDifficulty = _inferDifficulty(
      totalSteps: totalSteps,
      uniqueLineSteps: uniqueLineSteps,
      combinedSteps: combinedSteps,
    );
    return BinaryDifficultyAnalysis(
      inferredDifficulty: inferredDifficulty,
      totalSteps: totalSteps,
      tripleSteps: tripleSteps,
      countSteps: countSteps,
      uniqueLineSteps: uniqueLineSteps,
      combinedSteps: combinedSteps,
      solvedLogically: puzzle.isSolved,
    );
  }

  PuzzleDifficulty _inferDifficulty({
    required int totalSteps,
    required int uniqueLineSteps,
    required int combinedSteps,
  }) {
    if (combinedSteps == 0 && uniqueLineSteps == 0) {
      return PuzzleDifficulty.easy;
    }
    if (combinedSteps == 0 ||
        (totalSteps > 0 && combinedSteps / totalSteps <= 0.15)) {
      return PuzzleDifficulty.medium;
    }
    return PuzzleDifficulty.hard;
  }
}
