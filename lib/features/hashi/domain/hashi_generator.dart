import 'dart:math';

import '../../../hashi_foundation.dart';
import 'hashi_solver.dart';

class HashiGenerationResult {
  const HashiGenerationResult({
    required this.puzzle,
    required this.seed,
    required this.attempts,
  });

  final HashiPuzzle puzzle;
  final int seed;
  final int attempts;
}

class HashiGenerator {
  const HashiGenerator({this.solver = const HashiSolver()});

  final HashiSolver solver;

  HashiGenerationResult generate({
    required int seed,
    required int number,
    required int difficulty,
  }) {
    if (difficulty < 1 || difficulty > 3) {
      throw ArgumentError.value(difficulty, 'difficulty');
    }
    final random = Random(seed);
    final size = switch (difficulty) { 1 => 6, 2 => 8, _ => 9 };
    final islandRange = switch (difficulty) {
      1 => (min: 6, max: 8),
      2 => (min: 9, max: 12),
      _ => (min: 12, max: 16),
    };

    for (var attempt = 1; attempt <= 600; attempt++) {
      final islandCount = islandRange.min +
          random.nextInt(islandRange.max - islandRange.min + 1);
      final positions = _randomPositions(random, size, islandCount);
      final candidateEdges = _candidateEdges(positions)..shuffle(random);
      final solutionEdges = _buildConnectedSolution(
        random,
        positions,
        candidateEdges,
      );
      if (solutionEdges == null) continue;

      final bridges = <HashiBridge>[
        for (final edge in solutionEdges)
          HashiBridge(
            from: edge.from,
            to: edge.to,
            count: random.nextDouble() < 0.28 ? 2 : 1,
          ),
      ];
      final degrees = List<int>.filled(positions.length, 0);
      for (final bridge in bridges) {
        degrees[bridge.from] += bridge.count;
        degrees[bridge.to] += bridge.count;
      }
      if (degrees.any((degree) => degree == 0 || degree > 8)) continue;

      final puzzle = HashiPuzzle(
        id: 'hashi-generated-$difficulty-$seed-$attempt',
        title: 'Hashi $number',
        size: size,
        difficulty: difficulty,
        islands: [
          for (var index = 0; index < positions.length; index++)
            HashiIsland(
              row: positions[index].row,
              column: positions[index].column,
              bridges: degrees[index],
            ),
        ],
        solution: bridges,
      );
      if (solver.solve(puzzle).hasUniqueSolution) {
        return HashiGenerationResult(
          puzzle: puzzle,
          seed: seed,
          attempts: attempt,
        );
      }
    }
    throw StateError('No unique Hashi puzzle found for seed $seed.');
  }

  List<_GridPoint> _randomPositions(Random random, int size, int count) {
    final all = <_GridPoint>[
      for (var row = 0; row < size; row++)
        for (var column = 0; column < size; column++) _GridPoint(row, column),
    ]..shuffle(random);
    return all.take(count).toList(growable: false);
  }

  List<_Edge> _candidateEdges(List<_GridPoint> positions) {
    final edges = <_Edge>[];
    for (var first = 0; first < positions.length; first++) {
      final a = positions[first];
      int? right;
      int? below;
      for (var second = 0; second < positions.length; second++) {
        if (first == second) continue;
        final b = positions[second];
        if (a.row == b.row && b.column > a.column) {
          if (right == null || b.column < positions[right].column) {
            right = second;
          }
        }
        if (a.column == b.column && b.row > a.row) {
          if (below == null || b.row < positions[below].row) {
            below = second;
          }
        }
      }
      if (right != null) edges.add(_Edge(first, right));
      if (below != null) edges.add(_Edge(first, below));
    }
    return edges;
  }

  List<_Edge>? _buildConnectedSolution(
    Random random,
    List<_GridPoint> positions,
    List<_Edge> candidates,
  ) {
    final sets = _DisjointSets(positions.length);
    final selected = <_Edge>[];
    for (final edge in candidates) {
      if (sets.connected(edge.from, edge.to) ||
          selected.any((other) => _crosses(positions, edge, other))) {
        continue;
      }
      selected.add(edge);
      sets.union(edge.from, edge.to);
    }
    if (sets.componentCount != 1) return null;

    for (final edge in candidates) {
      if (selected.contains(edge) || random.nextDouble() > 0.28) continue;
      if (selected.any((other) => _crosses(positions, edge, other))) continue;
      selected.add(edge);
    }
    return selected;
  }

  bool _crosses(List<_GridPoint> points, _Edge first, _Edge second) {
    final a = points[first.from];
    final b = points[first.to];
    final c = points[second.from];
    final d = points[second.to];
    final firstHorizontal = a.row == b.row;
    final secondHorizontal = c.row == d.row;
    if (firstHorizontal == secondHorizontal) return false;
    final h1 = firstHorizontal ? a : c;
    final h2 = firstHorizontal ? b : d;
    final v1 = firstHorizontal ? c : a;
    final v2 = firstHorizontal ? d : b;
    return _between(v1.column, h1.column, h2.column) &&
        _between(h1.row, v1.row, v2.row);
  }

  bool _between(int value, int first, int second) =>
      value > min(first, second) && value < max(first, second);
}

class _GridPoint {
  const _GridPoint(this.row, this.column);
  final int row;
  final int column;
}

class _Edge {
  const _Edge(this.from, this.to);
  final int from;
  final int to;

  @override
  bool operator ==(Object other) =>
      other is _Edge && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

class _DisjointSets {
  _DisjointSets(int size)
      : _parents = List<int>.generate(size, (index) => index),
        componentCount = size;

  final List<int> _parents;
  int componentCount;

  int _find(int value) {
    if (_parents[value] != value) _parents[value] = _find(_parents[value]);
    return _parents[value];
  }

  bool connected(int first, int second) => _find(first) == _find(second);

  void union(int first, int second) {
    final firstRoot = _find(first);
    final secondRoot = _find(second);
    if (firstRoot == secondRoot) return;
    _parents[secondRoot] = firstRoot;
    componentCount--;
  }
}
