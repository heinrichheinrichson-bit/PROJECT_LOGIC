import '../../../core/domain/game_identity.dart';
import 'tents_puzzle.dart';
import 'tents_solver.dart';

class TentsDifficultyRating {
  const TentsDifficultyRating(
      {required this.band,
      required this.score,
      required this.ambiguousTrees,
      required this.searchNodes});
  final PuzzleDifficulty band;
  final int score;
  final int ambiguousTrees;
  final int searchNodes;
}

class TentsDifficultyRater {
  const TentsDifficultyRater({this.solver = const TentsSolver()});
  final TentsSolver solver;

  TentsDifficultyRating rate(TentsPuzzle puzzle) {
    final ambiguousTrees = puzzle.trees
        .where((tree) =>
            _orthogonal(puzzle.size, tree)
                .where((cell) => !puzzle.trees.contains(cell))
                .length >
            2)
        .length;
    final searchNodes = solver.solve(puzzle)?.searchNodes ?? 999;
    final score = puzzle.size * puzzle.size +
        puzzle.solution.length * 2 +
        ambiguousTrees * 2 +
        searchNodes.clamp(0, 100) ~/ 5;
    final band = score < 70
        ? PuzzleDifficulty.easy
        : score < 130
            ? PuzzleDifficulty.medium
            : PuzzleDifficulty.hard;
    return TentsDifficultyRating(
        band: band,
        score: score,
        ambiguousTrees: ambiguousTrees,
        searchNodes: searchNodes);
  }

  Iterable<TentsCell> _orthogonal(int size, TentsCell cell) sync* {
    if (cell.$1 > 0) yield (cell.$1 - 1, cell.$2);
    if (cell.$1 + 1 < size) yield (cell.$1 + 1, cell.$2);
    if (cell.$2 > 0) yield (cell.$1, cell.$2 - 1);
    if (cell.$2 + 1 < size) yield (cell.$1, cell.$2 + 1);
  }
}
