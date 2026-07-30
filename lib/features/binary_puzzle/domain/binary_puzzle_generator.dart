import 'dart:math';

import '../../../game_logic.dart';
import 'binary_board_generator.dart';

class BinaryPuzzleGenerationResult {
  const BinaryPuzzleGenerationResult({
    required this.definition,
    required this.seed,
    required this.removedPosition,
  });

  final BinaryPuzzleDefinition definition;
  final int seed;
  final CellPosition removedPosition;
}

/// Generates a simple Binary Puzzle from a complete solution board.
///
/// This first version removes exactly one cell. It intentionally performs no
/// uniqueness or difficulty check yet, so generation stays small and fast.
class BinaryPuzzleGenerator {
  const BinaryPuzzleGenerator({
    this.boardGenerator = const BinaryBoardGenerator(),
  });

  final BinaryBoardGenerator boardGenerator;

  BinaryPuzzleGenerationResult generate({
    required int size,
    int? seed,
    int number = 1,
    PuzzleDifficulty difficulty = PuzzleDifficulty.easy,
  }) {
    final boardResult = boardGenerator.generate(
      size: size,
      seed: seed,
    );

    final random = Random(boardResult.seed);
    final removedIndex = random.nextInt(size * size);
    final removedPosition = CellPosition(
      removedIndex ~/ size,
      removedIndex % size,
    );

    final solution = [
      for (final row in boardResult.board) [...row],
    ];

    final clues = <CellPosition>{
      for (var row = 0; row < size; row++)
        for (var column = 0; column < size; column++)
          if (row != removedPosition.row ||
              column != removedPosition.column)
            CellPosition(row, column),
    };

    final definition = BinaryPuzzleDefinition(
      id: 'binary-$size-${difficulty.name}-${boardResult.seed}',
      number: number,
      difficulty: difficulty,
      solution: solution,
      clues: clues,
    );

    return BinaryPuzzleGenerationResult(
      definition: definition,
      seed: boardResult.seed,
      removedPosition: removedPosition,
    );
  }
}
