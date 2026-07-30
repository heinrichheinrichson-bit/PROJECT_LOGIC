import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/features/binary_puzzle/domain/binary_puzzle_generator.dart';
import 'package:project_logic_prototype/game_logic.dart';

void main() {
  group('BinaryPuzzleGenerator', () {
    test('generates a 4x4 puzzle with exactly one missing cell', () {
      const generator = BinaryPuzzleGenerator();

      final result = generator.generate(
        size: 4,
        seed: 12345,
      );

      final definition = result.definition;
      final puzzle = definition.createPuzzle();

      expect(definition.size, 4);
      expect(definition.clueCount, 15);
      expect(
        puzzle.board[result.removedPosition.row]
            [result.removedPosition.column],
        isNull,
      );

      for (var row = 0; row < definition.size; row++) {
        for (var column = 0; column < definition.size; column++) {
          final position = CellPosition(row, column);

          if (position == result.removedPosition) {
            expect(definition.clues.contains(position), isFalse);
          } else {
            expect(definition.clues.contains(position), isTrue);
            expect(
              puzzle.board[row][column],
              definition.solution[row][column],
            );
          }
        }
      }
    });

    test('is deterministic for the same seed', () {
      const generator = BinaryPuzzleGenerator();

      final first = generator.generate(
        size: 4,
        seed: 12345,
      );

      final second = generator.generate(
        size: 4,
        seed: 12345,
      );

      expect(first.definition.solution, second.definition.solution);
      expect(first.definition.clues, second.definition.clues);
      expect(first.removedPosition, second.removedPosition);
      expect(first.seed, second.seed);
    });
  });
}
