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

  test('every current catalog puzzle has exactly one solution', () {
    final nonUnique = <String, int>{};
    for (final puzzle in hashiPuzzleCatalog) {
      final result = solver.solve(puzzle);
      if (!result.hasUniqueSolution) {
        nonUnique[puzzle.id] = result.solutionCount;
      }
    }
    expect(nonUnique, isEmpty);
  });
}
