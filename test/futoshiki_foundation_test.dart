import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/core/domain/game_identity.dart';
import 'package:project_logic_prototype/features/futoshiki/domain/futoshiki_generator.dart';
import 'package:project_logic_prototype/features/futoshiki/domain/futoshiki_puzzle.dart';
import 'package:project_logic_prototype/features/futoshiki/domain/futoshiki_solver.dart';

void main() {
  test('generator creates a deterministic unique puzzle for every difficulty',
      () {
    const generator = FutoshikiGenerator();
    const solver = FutoshikiSolver();
    for (final difficulty in PuzzleDifficulty.values) {
      final first = generator.generate(
          seed: 4400 + difficulty.index, difficulty: difficulty);
      final second = generator.generate(
          seed: 4400 + difficulty.index, difficulty: difficulty);
      expect(first.givens, second.givens);
      expect(first.inequalities.length, second.inequalities.length);
      expect(solver.hasUniqueSolution(first), isTrue, reason: difficulty.name);
      expect(solver.solve(first), first.solution, reason: difficulty.name);
    }
  });

  test('state detects duplicate numbers and broken inequalities', () {
    final puzzle = const FutoshikiGenerator().generate(
      seed: 90210,
      difficulty: PuzzleDifficulty.easy,
    );
    final editable = <(int, int)>[];
    for (var row = 0; row < puzzle.size; row++) {
      for (var column = 0; column < puzzle.size; column++) {
        if (puzzle.givens[row][column] == null) editable.add((row, column));
      }
    }
    var state = FutoshikiState(puzzle: puzzle);
    state = state.setValue(editable[0].$1, editable[0].$2, 1);
    state = state.setValue(editable[1].$1, editable[1].$2, 1);
    expect(state.conflictingCells, isNotEmpty);
    expect(state.isSolved, isFalse);
  });
}
