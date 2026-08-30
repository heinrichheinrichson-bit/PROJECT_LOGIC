import 'dart:math';

import '../../../core/domain/game_identity.dart';
import 'futoshiki_puzzle.dart';
import 'futoshiki_solver.dart';

class FutoshikiGenerator {
  const FutoshikiGenerator({this.solver = const FutoshikiSolver()});

  final FutoshikiSolver solver;

  FutoshikiPuzzle generate({
    required int seed,
    required PuzzleDifficulty difficulty,
    int? size,
    String? id,
    String? title,
  }) {
    final random = Random(seed);
    final boardSize = size ??
        switch (difficulty) {
          PuzzleDifficulty.easy => 4,
          PuzzleDifficulty.medium => 5,
          PuzzleDifficulty.hard => 6,
        };
    if (boardSize < 4 || boardSize > 7) {
      throw ArgumentError.value(boardSize, 'size', 'must be between 4 and 7');
    }
    final symbols = [for (var value = 1; value <= boardSize; value++) value]
      ..shuffle(random);
    final rowOrder = [for (var index = 0; index < boardSize; index++) index]
      ..shuffle(random);
    final columnOrder = [for (var index = 0; index < boardSize; index++) index]
      ..shuffle(random);
    final solution = [
      for (final row in rowOrder)
        [
          for (final column in columnOrder) symbols[(row + column) % boardSize],
        ],
    ];

    final adjacent = <((int, int), (int, int))>[];
    for (var row = 0; row < boardSize; row++) {
      for (var column = 0; column < boardSize; column++) {
        if (column + 1 < boardSize) {
          adjacent.add(((row, column), (row, column + 1)));
        }
        if (row + 1 < boardSize) {
          adjacent.add(((row, column), (row + 1, column)));
        }
      }
    }
    adjacent.shuffle(random);
    final inequalityTarget = switch (difficulty) {
      PuzzleDifficulty.easy => boardSize + 3,
      PuzzleDifficulty.medium => boardSize + 4,
      PuzzleDifficulty.hard => boardSize + 5,
    };
    final inequalities = <FutoshikiInequality>[
      for (final pair in adjacent.take(inequalityTarget))
        FutoshikiInequality(
          firstRow: pair.$1.$1,
          firstColumn: pair.$1.$2,
          secondRow: pair.$2.$1,
          secondColumn: pair.$2.$2,
          firstIsLess: solution[pair.$1.$1][pair.$1.$2] <
              solution[pair.$2.$1][pair.$2.$2],
        ),
    ];
    final givens = <List<int?>>[
      for (final row in solution) [for (final value in row) value],
    ];
    final positions = <(int, int)>[
      for (var row = 0; row < boardSize; row++)
        for (var column = 0; column < boardSize; column++) (row, column),
    ]..shuffle(random);
    final minimumGivens = switch (difficulty) {
      PuzzleDifficulty.easy => boardSize + 2,
      PuzzleDifficulty.medium => boardSize,
      PuzzleDifficulty.hard => boardSize - 2,
    };
    var givenCount = boardSize * boardSize;
    for (final position in positions) {
      if (givenCount <= minimumGivens) break;
      final previous = givens[position.$1][position.$2];
      givens[position.$1][position.$2] = null;
      final candidate = FutoshikiPuzzle(
        id: 'candidate',
        title: 'candidate',
        size: boardSize,
        givens: givens,
        inequalities: inequalities,
        solution: solution,
        difficulty: difficulty,
      );
      if (solver.hasUniqueSolution(candidate)) {
        givenCount--;
      } else {
        givens[position.$1][position.$2] = previous;
      }
    }
    return FutoshikiPuzzle(
      id: id ?? 'futoshiki-generated-${difficulty.name}-$seed',
      title: title ?? '${difficulty.label} · Erstelltes Rätsel',
      size: boardSize,
      givens: givens,
      inequalities: inequalities,
      solution: solution,
      difficulty: difficulty,
    );
  }
}
