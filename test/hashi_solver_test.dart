import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/features/hashi/domain/hashi_solver.dart';
import 'package:project_logic_prototype/hashi_foundation.dart';

void main() {
  const solver = HashiSolver();

  test('finds the tutorial solution', () {
    final result = solver.solve(hashiTutorialPuzzle);

    expect(result.solutionCount, greaterThan(0));
    expect(result.firstSolution, isNotNull);
    expect(
      HashiGameState(
        puzzle: hashiTutorialPuzzle,
        bridges: result.firstSolution,
      ).isSolved,
      isTrue,
    );
  });

  test('identifies legacy catalog puzzles that need replacement', () {
    final nonUnique = <String, int>{};
    for (final puzzle in hashiPuzzleCatalog) {
      final result = solver.solve(puzzle);
      if (!result.hasUniqueSolution) {
        nonUnique[puzzle.id] = result.solutionCount;
      }
    }
    expect(nonUnique, {
      'hashi_04': 2,
      'hashi_07': 2,
      'hashi_10': 2,
      'hashi_12': 2,
    });
  });
}
