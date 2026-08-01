import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/core/domain/game_identity.dart';
import 'package:project_logic_prototype/features/tents/domain/tents_difficulty_rater.dart';
import 'package:project_logic_prototype/features/tents/domain/tents_generator.dart';
import 'package:project_logic_prototype/features/tents/domain/tents_puzzle.dart';
import 'package:project_logic_prototype/features/tents/domain/tents_solver.dart';

void main() {
  test('generator is deterministic and uniquely solvable for all difficulties',
      () {
    const generator = TentsGenerator();
    const solver = TentsSolver();
    for (final difficulty in PuzzleDifficulty.values) {
      final first = generator.generate(
        seed: 7300 + difficulty.index,
        difficulty: difficulty,
      );
      final second = generator.generate(
        seed: 7300 + difficulty.index,
        difficulty: difficulty,
      );
      expect(first.trees, second.trees, reason: difficulty.name);
      expect(first.rowCounts, second.rowCounts, reason: difficulty.name);
      expect(first.columnCounts, second.columnCounts, reason: difficulty.name);
      expect(first.isStructurallyValid, isTrue, reason: difficulty.name);
      expect(solver.hasUniqueSolution(first), isTrue, reason: difficulty.name);
      expect(solver.solve(first)!.solution, first.solution,
          reason: difficulty.name);
    }
  });

  test('generated solutions obey every tents rule across representative seeds',
      () {
    const generator = TentsGenerator();
    for (final difficulty in PuzzleDifficulty.values) {
      for (var index = 0; index < 4; index++) {
        final puzzle = generator.generate(
          seed: 9100 + difficulty.index * 100 + index,
          difficulty: difficulty,
        );
        final state = TentsState(
          puzzle: puzzle,
          marks: {
            for (final tent in puzzle.solution) tent: TentsCellMark.tent,
          },
        );
        expect(state.isSolved, isTrue,
            reason: '${difficulty.name} seed $index');
        expect(state.touchingTentConflicts, isEmpty);
        expect(state.orphanTentConflicts, isEmpty);
      }
    }
  });

  test('state rejects touching tents and overflowing line counts', () {
    const puzzle = TentsPuzzle(
      id: 'invalid-state-test',
      title: 'Test',
      size: 5,
      trees: {(0, 0), (1, 2)},
      rowCounts: [1, 0, 1, 0, 0],
      columnCounts: [0, 1, 0, 1, 0],
      solution: {(0, 1), (2, 3)},
      difficulty: PuzzleDifficulty.easy,
    );
    final state = TentsState(
      puzzle: puzzle,
      marks: const {
        (0, 1): TentsCellMark.tent,
        (1, 1): TentsCellMark.tent,
      },
    );
    expect(state.touchingTentConflicts, {(0, 1), (1, 1)});
    expect(state.countConflicts, isNotEmpty);
    expect(state.isSolved, isFalse);
  });

  test('custom sizes stay uniquely solvable', () {
    const generator = TentsGenerator();
    const solver = TentsSolver();
    for (final configuration in const [
      (size: 6, difficulty: PuzzleDifficulty.easy),
      (size: 8, difficulty: PuzzleDifficulty.medium),
      (size: 10, difficulty: PuzzleDifficulty.hard),
    ]) {
      final puzzle = generator.generate(
        seed: 12000 + configuration.size,
        size: configuration.size,
        difficulty: configuration.difficulty,
      );
      expect(puzzle.size, configuration.size);
      expect(solver.countSolutions(puzzle), 1);
    }
  });

  test('default board sizes form clearly separated difficulty bands', () {
    const generator = TentsGenerator();
    const rater = TentsDifficultyRater();
    final ratings = [
      for (final difficulty in PuzzleDifficulty.values)
        rater.rate(generator.generate(
            seed: 15000 + difficulty.index, difficulty: difficulty)),
    ];
    expect(ratings.map((rating) => rating.band), PuzzleDifficulty.values);
    expect(ratings[0].score, lessThan(ratings[1].score));
    expect(ratings[1].score, lessThan(ratings[2].score));
  });
}
