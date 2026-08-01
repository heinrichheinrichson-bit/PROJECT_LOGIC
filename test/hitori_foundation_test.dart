import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/core/domain/game_identity.dart';
import 'package:project_logic_prototype/features/hitori/domain/hitori_generator.dart';
import 'package:project_logic_prototype/features/hitori/domain/hitori_puzzle.dart';
import 'package:project_logic_prototype/features/hitori/domain/hitori_solver.dart';

void main() {
  test('state enforces all three Hitori rules', () {
    const puzzle = HitoriPuzzle(
      id: 'rules',
      title: 'Rules',
      grid: [
        [1, 1, 2],
        [2, 3, 1],
        [3, 2, 3],
      ],
      solution: {(0, 0), (2, 2)},
      difficulty: PuzzleDifficulty.easy,
    );
    final open = HitoriState(puzzle: puzzle);
    expect(open.duplicateConflicts, isNotEmpty);

    final solved = HitoriState(
      puzzle: puzzle,
      marks: const {
        (0, 0): HitoriCellMark.shaded,
        (2, 2): HitoriCellMark.shaded,
      },
    );
    expect(solved.adjacentShadeConflicts, isEmpty);
    expect(solved.openCellsConnected, isTrue);
    expect(solved.isSolved, isTrue);
  });

  test('generator creates a deterministic unique puzzle for each difficulty',
      () {
    const generator = HitoriGenerator();
    const solver = HitoriSolver();
    for (final difficulty in PuzzleDifficulty.values) {
      final first = generator.generate(
        seed: 9100 + difficulty.index,
        difficulty: difficulty,
      );
      final second = generator.generate(
        seed: 9100 + difficulty.index,
        difficulty: difficulty,
      );
      expect(first.grid, second.grid);
      expect(first.solution, second.solution);
      expect(solver.hasUniqueSolution(first), isTrue);
      expect(solver.solve(first), first.solution);
    }
  });
}
