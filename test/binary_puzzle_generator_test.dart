import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/features/binary_puzzle/domain/binary_puzzle_generator.dart';
import 'package:project_logic_prototype/features/binary_puzzle/domain/binary_puzzle_solver.dart';
import 'package:project_logic_prototype/game_logic.dart';

void main() {
  const generator = BinaryPuzzleGenerator();
  const solver = BinaryPuzzleSolver();

  group('BinaryPuzzleGenerator', () {
    test('generates a uniquely solvable 4x4 puzzle', () {
      final result = generator.generate(
        size: 4,
        seed: 12345,
      );

      final definition = result.definition;
      final puzzle = definition.createPuzzle();
      final solverResult = solver.solve(puzzle.board, solutionLimit: 2);

      expect(definition.size, 4);
      expect(definition.clueCount, lessThan(16));
      expect(result.successfulRemovals, 16 - definition.clueCount);
      expect(
        result.attemptedRemovals,
        greaterThanOrEqualTo(result.successfulRemovals),
      );
      expect(result.solverCalls, result.attemptedRemovals);
      expect(
        result.rejectedRemovals,
        result.attemptedRemovals - result.successfulRemovals,
      );
      expect(solverResult.hasUniqueSolution, isTrue);
      expect(solverResult.firstSolution, definition.solution);
    });

    test('is deterministic for the same seed and difficulty', () {
      final first = generator.generate(
        size: 4,
        seed: 12345,
        difficulty: PuzzleDifficulty.medium,
      );

      final second = generator.generate(
        size: 4,
        seed: 12345,
        difficulty: PuzzleDifficulty.medium,
      );

      expect(first.definition.solution, second.definition.solution);
      expect(first.definition.clues, second.definition.clues);
      expect(first.seed, second.seed);
      expect(first.attemptedRemovals, second.attemptedRemovals);
      expect(first.successfulRemovals, second.successfulRemovals);
      expect(first.rowClueCounts, second.rowClueCounts);
      expect(first.columnClueCounts, second.columnClueCounts);
    });

    test('difficulty targets use progressively fewer clues', () {
      final easy = generator.generate(
        size: 4,
        seed: 67890,
        difficulty: PuzzleDifficulty.easy,
      );
      final medium = generator.generate(
        size: 4,
        seed: 67890,
        difficulty: PuzzleDifficulty.medium,
      );
      final hard = generator.generate(
        size: 4,
        seed: 67890,
        difficulty: PuzzleDifficulty.hard,
      );

      expect(easy.targetClueCount, greaterThan(medium.targetClueCount));
      expect(medium.targetClueCount, greaterThan(hard.targetClueCount));
      expect(
        easy.definition.clueCount,
        greaterThanOrEqualTo(medium.definition.clueCount),
      );
      expect(
        medium.definition.clueCount,
        greaterThanOrEqualTo(hard.definition.clueCount),
      );

      for (final result in [easy, medium, hard]) {
        final puzzle = result.definition.createPuzzle();
        expect(
          solver.solve(puzzle.board, solutionLimit: 2).hasUniqueSolution,
          isTrue,
        );
      }
    });


    test('reports consistent generation diagnostics', () {
      final result = generator.generate(
        size: 6,
        seed: 13579,
        difficulty: PuzzleDifficulty.medium,
      );

      expect(result.generationDuration, isNot(lessThan(Duration.zero)));
      expect(result.solverCalls, result.attemptedRemovals);
      expect(
        result.successfulRemovals + result.rejectedRemovals,
        result.attemptedRemovals,
      );
      expect(result.rowClueCounts, hasLength(6));
      expect(result.columnClueCounts, hasLength(6));
      expect(
        result.rowClueCounts.reduce((a, b) => a + b),
        result.definition.clueCount,
      );
      expect(
        result.columnClueCounts.reduce((a, b) => a + b),
        result.definition.clueCount,
      );
    });

    test('keeps clue distribution balanced across rows and columns', () {
      final result = generator.generate(
        size: 8,
        seed: 86420,
        difficulty: PuzzleDifficulty.hard,
      );

      expect(result.clueDistributionSpread, lessThanOrEqualTo(3));
      expect(result.rowClueCounts.every((count) => count > 0), isTrue);
      expect(result.columnClueCounts.every((count) => count > 0), isTrue);
    });

    test('keeps metadata in the generated definition', () {
      final result = generator.generate(
        size: 4,
        seed: 24680,
        number: 7,
        difficulty: PuzzleDifficulty.hard,
      );

      expect(result.definition.number, 7);
      expect(result.definition.difficulty, PuzzleDifficulty.hard);
      expect(result.definition.id, 'binary-4-hard-24680');
    });
  });
}
