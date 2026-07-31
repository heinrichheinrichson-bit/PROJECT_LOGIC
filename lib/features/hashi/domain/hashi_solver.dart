import '../../../hashi_foundation.dart';

class HashiSolveResult {
  const HashiSolveResult({required this.solutionCount, this.firstSolution});

  final int solutionCount;
  final List<HashiBridge>? firstSolution;

  bool get hasUniqueSolution => solutionCount == 1;
}

class HashiSolver {
  const HashiSolver();

  HashiSolveResult solve(HashiPuzzle puzzle, {int solutionLimit = 2}) {
    if (solutionLimit <= 0) {
      throw ArgumentError.value(solutionLimit, 'solutionLimit');
    }
    final edges = _candidateEdges(puzzle);
    final degrees = List<int>.filled(puzzle.islands.length, 0);
    final counts = List<int>.filled(edges.length, 0);
    var solutions = 0;
    List<HashiBridge>? firstSolution;

    void search(int edgeIndex) {
      if (solutions >= solutionLimit) return;
      if (!_degreesCanStillMatch(puzzle, edges, degrees, edgeIndex)) return;
      if (edgeIndex == edges.length) {
        if (!_allDegreesMatch(puzzle, degrees)) return;
        final bridges = <HashiBridge>[
          for (var index = 0; index < edges.length; index++)
            if (counts[index] > 0)
              HashiBridge(
                from: edges[index].from,
                to: edges[index].to,
                count: counts[index],
              ),
        ];
        if (!HashiGameState(puzzle: puzzle, bridges: bridges).isSolved) return;
        solutions++;
        firstSolution ??= List.unmodifiable(bridges);
        return;
      }

      final edge = edges[edgeIndex];
      for (var count = 0; count <= 2; count++) {
        if (degrees[edge.from] + count > puzzle.islands[edge.from].bridges ||
            degrees[edge.to] + count > puzzle.islands[edge.to].bridges ||
            (count > 0 &&
                _crossesSelected(puzzle, edge, edges, counts, edgeIndex))) {
          continue;
        }
        counts[edgeIndex] = count;
        degrees[edge.from] += count;
        degrees[edge.to] += count;
        search(edgeIndex + 1);
        degrees[edge.from] -= count;
        degrees[edge.to] -= count;
        counts[edgeIndex] = 0;
      }
    }

    search(0);
    return HashiSolveResult(
      solutionCount: solutions,
      firstSolution: firstSolution,
    );
  }

  List<HashiBridge> _candidateEdges(HashiPuzzle puzzle) {
    final edges = <HashiBridge>[];
    for (var first = 0; first < puzzle.islands.length; first++) {
      final a = puzzle.islands[first];
      int? right;
      int? below;
      for (var second = 0; second < puzzle.islands.length; second++) {
        if (first == second) continue;
        final b = puzzle.islands[second];
        if (a.row == b.row && b.column > a.column) {
          if (right == null || b.column < puzzle.islands[right].column) {
            right = second;
          }
        }
        if (a.column == b.column && b.row > a.row) {
          if (below == null || b.row < puzzle.islands[below].row) {
            below = second;
          }
        }
      }
      if (right != null) edges.add(HashiBridge(from: first, to: right));
      if (below != null) edges.add(HashiBridge(from: first, to: below));
    }
    return edges;
  }

  bool _degreesCanStillMatch(
    HashiPuzzle puzzle,
    List<HashiBridge> edges,
    List<int> degrees,
    int edgeIndex,
  ) {
    for (var island = 0; island < puzzle.islands.length; island++) {
      final target = puzzle.islands[island].bridges;
      if (degrees[island] > target) return false;
      var remainingCapacity = 0;
      for (var index = edgeIndex; index < edges.length; index++) {
        if (edges[index].from == island || edges[index].to == island) {
          remainingCapacity += 2;
        }
      }
      if (degrees[island] + remainingCapacity < target) return false;
    }
    return true;
  }

  bool _allDegreesMatch(HashiPuzzle puzzle, List<int> degrees) {
    for (var index = 0; index < degrees.length; index++) {
      if (degrees[index] != puzzle.islands[index].bridges) return false;
    }
    return true;
  }

  bool _crossesSelected(
    HashiPuzzle puzzle,
    HashiBridge candidate,
    List<HashiBridge> edges,
    List<int> counts,
    int beforeIndex,
  ) {
    for (var index = 0; index < beforeIndex; index++) {
      if (counts[index] > 0 && _crosses(puzzle, candidate, edges[index])) {
        return true;
      }
    }
    return false;
  }

  bool _crosses(
    HashiPuzzle puzzle,
    HashiBridge first,
    HashiBridge second,
  ) {
    // HashiGameState already contains the canonical geometry check.
    final state = HashiGameState(puzzle: puzzle, bridges: [second]);
    return !state.canConnect(first.from, first.to);
  }
}
