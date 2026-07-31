import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/features/binary_puzzle/domain/binary_difficulty_rater.dart';
import 'package:project_logic_prototype/game_logic.dart';

void main() {
  const rater = BinaryDifficultyRater();

  test('rates a direct-rule puzzle as easy', () {
    final definition = BinaryPuzzleDefinition(
      id: 'rating-easy',
      number: 1,
      difficulty: PuzzleDifficulty.easy,
      solution: const [
        [CellValue.zero, CellValue.zero, CellValue.one, CellValue.one],
        [CellValue.zero, CellValue.one, CellValue.zero, CellValue.one],
        [CellValue.one, CellValue.zero, CellValue.one, CellValue.zero],
        [CellValue.one, CellValue.one, CellValue.zero, CellValue.zero],
      ],
      clues: {
        const CellPosition(0, 0),
        const CellPosition(0, 1),
        const CellPosition(1, 0),
        const CellPosition(1, 1),
        const CellPosition(1, 2),
        const CellPosition(2, 0),
        const CellPosition(2, 1),
        const CellPosition(2, 2),
        const CellPosition(3, 0),
        const CellPosition(3, 1),
        const CellPosition(3, 2),
      },
    );

    final analysis = rater.analyze(definition);

    expect(analysis.solvedLogically, isTrue);
    expect(analysis.inferredDifficulty, PuzzleDifficulty.easy);
    expect(analysis.combinedSteps, 0);
  });

  test('every generated collection puzzle matches its displayed difficulty',
      () {
    for (final definition in generatedBinaryPuzzleCatalog) {
      final analysis = rater.analyze(definition);
      expect(analysis.solvedLogically, isTrue, reason: definition.id);
      expect(
        analysis.inferredDifficulty,
        definition.difficulty,
        reason: definition.id,
      );
    }
  });
}
