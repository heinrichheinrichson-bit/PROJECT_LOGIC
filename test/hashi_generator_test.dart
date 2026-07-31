import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/features/hashi/domain/hashi_generator.dart';
import 'package:project_logic_prototype/features/hashi/domain/hashi_solver.dart';
import 'package:project_logic_prototype/hashi_foundation.dart';

void main() {
  const generator = HashiGenerator();
  const solver = HashiSolver();

  for (final difficulty in [1, 2, 3]) {
    test('generates a unique connected difficulty $difficulty puzzle', () {
      final generated = generator.generate(
        seed: 20260731 + difficulty,
        number: difficulty,
        difficulty: difficulty,
      );

      expect(generated.puzzle.difficulty, difficulty);
      expect(
        HashiGameState(
          puzzle: generated.puzzle,
          bridges: generated.puzzle.solution,
        ).isSolved,
        isTrue,
      );
      expect(solver.solve(generated.puzzle).hasUniqueSolution, isTrue);
    });
  }

  test('is deterministic for the same seed', () {
    final first = generator.generate(seed: 42, number: 1, difficulty: 1);
    final second = generator.generate(seed: 42, number: 1, difficulty: 1);

    expect(first.attempts, second.attempts);
    expect(first.puzzle.islands.length, second.puzzle.islands.length);
    expect(first.puzzle.solution.length, second.puzzle.solution.length);
  });
}
