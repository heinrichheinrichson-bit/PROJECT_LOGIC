import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

@immutable
class HashiIsland {
  const HashiIsland({
    required this.row,
    required this.column,
    required this.bridges,
  });

  final int row;
  final int column;
  final int bridges;
}

@immutable
class HashiBridge {
  const HashiBridge({
    required this.from,
    required this.to,
    this.count = 1,
  }) : assert(count == 1 || count == 2);

  final int from;
  final int to;
  final int count;

  HashiBridge copyWith({int? count}) => HashiBridge(
        from: from,
        to: to,
        count: count ?? this.count,
      );
}

@immutable
class HashiPuzzle {
  const HashiPuzzle({
    this.id = '',
    required this.title,
    required this.size,
    required this.islands,
    this.solution = const [],
    this.difficulty = 1,
  });

  final String id;
  final String title;
  final int size;
  final int difficulty;
  final List<HashiIsland> islands;
  final List<HashiBridge> solution;
}


const hashiPreviewBridges = [
  HashiBridge(from: 0, to: 1),
  HashiBridge(from: 0, to: 2),
  HashiBridge(from: 1, to: 4),
  HashiBridge(from: 2, to: 3),
  HashiBridge(from: 2, to: 5),
  HashiBridge(from: 3, to: 4),
  HashiBridge(from: 4, to: 6),
  HashiBridge(from: 5, to: 6),
];

const hashiTutorialPuzzle = HashiPuzzle(
  id: 'hashi_01',
  title: 'Erste Brücken',
  difficulty: 1,
  size: 7,
  islands: [
    HashiIsland(row: 0, column: 1, bridges: 2),
    HashiIsland(row: 0, column: 5, bridges: 2),
    HashiIsland(row: 3, column: 1, bridges: 3),
    HashiIsland(row: 3, column: 3, bridges: 2),
    HashiIsland(row: 3, column: 5, bridges: 3),
    HashiIsland(row: 6, column: 1, bridges: 2),
    HashiIsland(row: 6, column: 5, bridges: 2),
  ],
  solution: hashiPreviewBridges,
);

const hashiPuzzleCatalog = <HashiPuzzle>[
  hashiTutorialPuzzle,
  HashiPuzzle(
    id: 'hashi_02',
    title: 'Kleine Runde',
    difficulty: 1,
    size: 6,
    islands: [
      HashiIsland(row: 1, column: 1, bridges: 2),
      HashiIsland(row: 1, column: 4, bridges: 2),
      HashiIsland(row: 4, column: 1, bridges: 2),
      HashiIsland(row: 4, column: 4, bridges: 2),
    ],
    solution: [
      HashiBridge(from: 0, to: 1),
      HashiBridge(from: 0, to: 2),
      HashiBridge(from: 1, to: 3),
      HashiBridge(from: 2, to: 3),
    ],
  ),
  HashiPuzzle(
    id: 'hashi_03',
    title: 'Zwei Ufer',
    difficulty: 1,
    size: 7,
    islands: [
      HashiIsland(row: 1, column: 0, bridges: 2),
      HashiIsland(row: 1, column: 3, bridges: 2),
      HashiIsland(row: 1, column: 6, bridges: 2),
      HashiIsland(row: 5, column: 0, bridges: 2),
      HashiIsland(row: 5, column: 3, bridges: 2),
      HashiIsland(row: 5, column: 6, bridges: 2),
    ],
    solution: [
      HashiBridge(from: 0, to: 1),
      HashiBridge(from: 1, to: 2),
      HashiBridge(from: 3, to: 4),
      HashiBridge(from: 4, to: 5),
      HashiBridge(from: 0, to: 3),
      HashiBridge(from: 2, to: 5),
    ],
  ),
  HashiPuzzle(
    id: 'hashi_04',
    title: 'Doppelte Kante',
    difficulty: 2,
    size: 7,
    islands: [
      HashiIsland(row: 1, column: 1, bridges: 3),
      HashiIsland(row: 1, column: 5, bridges: 3),
      HashiIsland(row: 5, column: 1, bridges: 3),
      HashiIsland(row: 5, column: 5, bridges: 3),
    ],
    solution: [
      HashiBridge(from: 0, to: 1, count: 2),
      HashiBridge(from: 0, to: 2),
      HashiBridge(from: 1, to: 3),
      HashiBridge(from: 2, to: 3, count: 2),
    ],
  ),
  HashiPuzzle(
    id: 'hashi_05',
    title: 'Mittelpunkt',
    difficulty: 2,
    size: 7,
    islands: [
      HashiIsland(row: 0, column: 3, bridges: 1),
      HashiIsland(row: 3, column: 0, bridges: 1),
      HashiIsland(row: 3, column: 3, bridges: 4),
      HashiIsland(row: 3, column: 6, bridges: 1),
      HashiIsland(row: 6, column: 3, bridges: 1),
    ],
    solution: [
      HashiBridge(from: 0, to: 2),
      HashiBridge(from: 1, to: 2),
      HashiBridge(from: 2, to: 3),
      HashiBridge(from: 2, to: 4),
    ],
  ),
  HashiPuzzle(
    id: 'hashi_06',
    title: 'Inselring',
    difficulty: 3,
    size: 8,
    islands: [
      HashiIsland(row: 0, column: 1, bridges: 2),
      HashiIsland(row: 0, column: 6, bridges: 2),
      HashiIsland(row: 3, column: 1, bridges: 2),
      HashiIsland(row: 3, column: 6, bridges: 2),
      HashiIsland(row: 7, column: 1, bridges: 2),
      HashiIsland(row: 7, column: 6, bridges: 2),
    ],
    solution: [
      HashiBridge(from: 0, to: 1),
      HashiBridge(from: 0, to: 2),
      HashiBridge(from: 1, to: 3),
      HashiBridge(from: 2, to: 4),
      HashiBridge(from: 3, to: 5),
      HashiBridge(from: 4, to: 5),
    ],
  ),
  HashiPuzzle(
    id: 'hashi_07',
    title: 'Brückenleiter',
    difficulty: 2,
    size: 7,
    islands: [
      HashiIsland(row: 0, column: 1, bridges: 2),
      HashiIsland(row: 0, column: 5, bridges: 2),
      HashiIsland(row: 3, column: 1, bridges: 4),
      HashiIsland(row: 3, column: 5, bridges: 4),
      HashiIsland(row: 6, column: 1, bridges: 2),
      HashiIsland(row: 6, column: 5, bridges: 2),
    ],
    solution: [
      HashiBridge(from: 0, to: 1),
      HashiBridge(from: 0, to: 2),
      HashiBridge(from: 1, to: 3),
      HashiBridge(from: 2, to: 3, count: 2),
      HashiBridge(from: 2, to: 4),
      HashiBridge(from: 3, to: 5),
      HashiBridge(from: 4, to: 5),
    ],
  ),
  HashiPuzzle(
    id: 'hashi_08',
    title: 'Doppelkreuz',
    difficulty: 2,
    size: 7,
    islands: [
      HashiIsland(row: 0, column: 3, bridges: 2),
      HashiIsland(row: 3, column: 0, bridges: 1),
      HashiIsland(row: 3, column: 3, bridges: 6),
      HashiIsland(row: 3, column: 6, bridges: 1),
      HashiIsland(row: 6, column: 3, bridges: 2),
    ],
    solution: [
      HashiBridge(from: 0, to: 2, count: 2),
      HashiBridge(from: 1, to: 2),
      HashiBridge(from: 2, to: 3),
      HashiBridge(from: 2, to: 4, count: 2),
    ],
  ),
  HashiPuzzle(
    id: 'hashi_09',
    title: 'Der Rahmen',
    difficulty: 3,
    size: 9,
    islands: [
      HashiIsland(row: 0, column: 1, bridges: 4),
      HashiIsland(row: 0, column: 4, bridges: 3),
      HashiIsland(row: 0, column: 7, bridges: 2),
      HashiIsland(row: 4, column: 1, bridges: 3),
      HashiIsland(row: 4, column: 7, bridges: 3),
      HashiIsland(row: 8, column: 1, bridges: 3),
      HashiIsland(row: 8, column: 4, bridges: 3),
      HashiIsland(row: 8, column: 7, bridges: 3),
    ],
    solution: [
      HashiBridge(from: 0, to: 1, count: 2),
      HashiBridge(from: 1, to: 2),
      HashiBridge(from: 2, to: 4),
      HashiBridge(from: 4, to: 7, count: 2),
      HashiBridge(from: 7, to: 6),
      HashiBridge(from: 6, to: 5, count: 2),
      HashiBridge(from: 5, to: 3),
      HashiBridge(from: 3, to: 0, count: 2),
    ],
  ),
  HashiPuzzle(
    id: 'hashi_10',
    title: 'Neun Inseln',
    difficulty: 3,
    size: 9,
    islands: [
      HashiIsland(row: 0, column: 0, bridges: 2),
      HashiIsland(row: 0, column: 4, bridges: 3),
      HashiIsland(row: 0, column: 8, bridges: 2),
      HashiIsland(row: 4, column: 0, bridges: 3),
      HashiIsland(row: 4, column: 4, bridges: 4),
      HashiIsland(row: 4, column: 8, bridges: 3),
      HashiIsland(row: 8, column: 0, bridges: 2),
      HashiIsland(row: 8, column: 4, bridges: 3),
      HashiIsland(row: 8, column: 8, bridges: 2),
    ],
    solution: [
      HashiBridge(from: 0, to: 1),
      HashiBridge(from: 1, to: 2),
      HashiBridge(from: 3, to: 4),
      HashiBridge(from: 4, to: 5),
      HashiBridge(from: 6, to: 7),
      HashiBridge(from: 7, to: 8),
      HashiBridge(from: 0, to: 3),
      HashiBridge(from: 3, to: 6),
      HashiBridge(from: 1, to: 4),
      HashiBridge(from: 4, to: 7),
      HashiBridge(from: 2, to: 5),
      HashiBridge(from: 5, to: 8),
    ],
  ),
  HashiPuzzle(
    id: 'hashi_11',
    title: 'Schmale Pfade',
    difficulty: 2,
    size: 9,
    islands: [
      HashiIsland(row: 0, column: 0, bridges: 1),
      HashiIsland(row: 0, column: 4, bridges: 3),
      HashiIsland(row: 2, column: 4, bridges: 3),
      HashiIsland(row: 2, column: 1, bridges: 2),
      HashiIsland(row: 5, column: 1, bridges: 3),
      HashiIsland(row: 5, column: 6, bridges: 3),
      HashiIsland(row: 8, column: 6, bridges: 1),
    ],
    solution: [
      HashiBridge(from: 0, to: 1),
      HashiBridge(from: 1, to: 2, count: 2),
      HashiBridge(from: 2, to: 3),
      HashiBridge(from: 3, to: 4),
      HashiBridge(from: 4, to: 5, count: 2),
      HashiBridge(from: 5, to: 6),
    ],
  ),
  HashiPuzzle(
    id: 'hashi_12',
    title: 'Vier Tore',
    difficulty: 3,
    size: 9,
    islands: [
      HashiIsland(row: 0, column: 0, bridges: 3),
      HashiIsland(row: 0, column: 4, bridges: 5),
      HashiIsland(row: 0, column: 8, bridges: 3),
      HashiIsland(row: 4, column: 0, bridges: 3),
      HashiIsland(row: 4, column: 4, bridges: 4),
      HashiIsland(row: 4, column: 8, bridges: 3),
      HashiIsland(row: 8, column: 0, bridges: 3),
      HashiIsland(row: 8, column: 4, bridges: 5),
      HashiIsland(row: 8, column: 8, bridges: 3),
    ],
    solution: [
      HashiBridge(from: 0, to: 1, count: 2),
      HashiBridge(from: 1, to: 2, count: 2),
      HashiBridge(from: 3, to: 4),
      HashiBridge(from: 4, to: 5),
      HashiBridge(from: 6, to: 7, count: 2),
      HashiBridge(from: 7, to: 8, count: 2),
      HashiBridge(from: 0, to: 3),
      HashiBridge(from: 3, to: 6),
      HashiBridge(from: 1, to: 4),
      HashiBridge(from: 4, to: 7),
      HashiBridge(from: 2, to: 5),
      HashiBridge(from: 5, to: 8),
    ],
  ),
];

class HashiProgressStore {
  static const _key = 'hashi_completed_puzzles';

  Future<Set<String>> loadCompleted() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(_key)?.toSet() ?? <String>{};
  }

  Future<void> markCompleted(String puzzleId) async {
    final preferences = await SharedPreferences.getInstance();
    final completed = preferences.getStringList(_key)?.toSet() ?? <String>{};
    completed.add(puzzleId);
    await preferences.setStringList(_key, completed.toList()..sort());
  }
}

class HashiGameState {
  HashiGameState({required this.puzzle, List<HashiBridge>? bridges})
      : bridges = List<HashiBridge>.unmodifiable(bridges ?? const []);

  final HashiPuzzle puzzle;
  final List<HashiBridge> bridges;

  int bridgeCountAt(int islandIndex) {
    return bridges
        .where((bridge) =>
            bridge.from == islandIndex || bridge.to == islandIndex)
        .fold(0, (total, bridge) => total + bridge.count);
  }

  int bridgeCountBetween(int first, int second) {
    for (final bridge in bridges) {
      if (_sameConnection(bridge, first, second)) return bridge.count;
    }
    return 0;
  }

  bool canConnect(int first, int second) {
    if (first == second ||
        first < 0 ||
        second < 0 ||
        first >= puzzle.islands.length ||
        second >= puzzle.islands.length) {
      return false;
    }

    final a = puzzle.islands[first];
    final b = puzzle.islands[second];
    final aligned = a.row == b.row || a.column == b.column;
    if (!aligned || _islandBetween(first, second)) return false;

    return !bridges.any(
      (bridge) =>
          !_sameConnection(bridge, first, second) &&
          _connectionsCross(first, second, bridge.from, bridge.to),
    );
  }

  HashiGameState cycleConnection(int first, int second) {
    if (!canConnect(first, second)) return this;

    final current = bridgeCountBetween(first, second);
    final next = (current + 1) % 3;
    final updated = bridges
        .where((bridge) => !_sameConnection(bridge, first, second))
        .toList();
    if (next > 0) {
      updated.add(HashiBridge(from: first, to: second, count: next));
    }
    return HashiGameState(puzzle: puzzle, bridges: updated);
  }

  HashiGameState removeConnection(int first, int second) {
    if (bridgeCountBetween(first, second) == 0) return this;
    return HashiGameState(
      puzzle: puzzle,
      bridges: bridges
          .where((bridge) => !_sameConnection(bridge, first, second))
          .toList(),
    );
  }

  bool get numbersAreSatisfied {
    for (var index = 0; index < puzzle.islands.length; index++) {
      if (bridgeCountAt(index) != puzzle.islands[index].bridges) return false;
    }
    return true;
  }

  bool get allIslandsConnected {
    if (puzzle.islands.isEmpty) return true;
    final visited = <int>{0};
    final pending = <int>[0];
    while (pending.isNotEmpty) {
      final current = pending.removeLast();
      for (final bridge in bridges) {
        final neighbor = bridge.from == current
            ? bridge.to
            : bridge.to == current
                ? bridge.from
                : null;
        if (neighbor != null && visited.add(neighbor)) pending.add(neighbor);
      }
    }
    return visited.length == puzzle.islands.length;
  }

  bool get isSolved => numbersAreSatisfied && allIslandsConnected;

  bool _islandBetween(int first, int second) {
    final a = puzzle.islands[first];
    final b = puzzle.islands[second];
    for (var index = 0; index < puzzle.islands.length; index++) {
      if (index == first || index == second) continue;
      final candidate = puzzle.islands[index];
      if (a.row == b.row &&
          candidate.row == a.row &&
          _strictlyBetween(candidate.column, a.column, b.column)) {
        return true;
      }
      if (a.column == b.column &&
          candidate.column == a.column &&
          _strictlyBetween(candidate.row, a.row, b.row)) {
        return true;
      }
    }
    return false;
  }

  bool _connectionsCross(int aIndex, int bIndex, int cIndex, int dIndex) {
    final a = puzzle.islands[aIndex];
    final b = puzzle.islands[bIndex];
    final c = puzzle.islands[cIndex];
    final d = puzzle.islands[dIndex];
    final firstHorizontal = a.row == b.row;
    final secondHorizontal = c.row == d.row;
    if (firstHorizontal == secondHorizontal) return false;

    final horizontalA = firstHorizontal ? a : c;
    final horizontalB = firstHorizontal ? b : d;
    final verticalA = firstHorizontal ? c : a;
    final verticalB = firstHorizontal ? d : b;

    return _strictlyBetween(
          verticalA.column,
          horizontalA.column,
          horizontalB.column,
        ) &&
        _strictlyBetween(
          horizontalA.row,
          verticalA.row,
          verticalB.row,
        );
  }

  static bool _sameConnection(HashiBridge bridge, int first, int second) {
    return (bridge.from == first && bridge.to == second) ||
        (bridge.from == second && bridge.to == first);
  }

  static bool _strictlyBetween(int value, int edgeA, int edgeB) {
    return value > math.min(edgeA, edgeB) && value < math.max(edgeA, edgeB);
  }
}

class HashiHubScreen extends StatefulWidget {
  const HashiHubScreen({super.key});

  @override
  State<HashiHubScreen> createState() => _HashiHubScreenState();
}

class _HashiHubScreenState extends State<HashiHubScreen> {
  final HashiProgressStore _progressStore = HashiProgressStore();
  Set<String> _completed = <String>{};

  @override
  void initState() {
    super.initState();
    _refreshProgress();
  }

  Future<void> _refreshProgress() async {
    final completed = await _progressStore.loadCompleted();
    if (!mounted) return;
    setState(() => _completed = completed);
  }

  Future<void> _openPuzzle(HashiPuzzle puzzle) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HashiGameScreen(puzzle: puzzle),
      ),
    );
    await _refreshProgress();
  }

  HashiPuzzle get _nextPuzzle => hashiPuzzleCatalog.firstWhere(
        (puzzle) => !_completed.contains(puzzle.id),
        orElse: () => hashiTutorialPuzzle,
      );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Hashi')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.hub_rounded,
                        size: 54,
                        color: colors.onSecondaryContainer,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Baue ein gemeinsames Brückennetz',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_completed.length} von ${hashiPuzzleCatalog.length} Rätseln gelöst',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          minHeight: 8,
                          value: _completed.length / hashiPuzzleCatalog.length,
                          backgroundColor: colors.surface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Eine kleine Inselwelt',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Verbinde sichtbare Inseln – ohne Kreuzungen.',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 16),
                        const AspectRatio(
                          aspectRatio: 1,
                          child: HashiBoard(
                            puzzle: hashiTutorialPuzzle,
                            bridges: hashiPreviewBridges,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => _openPuzzle(_nextPuzzle),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    _completed.isEmpty
                        ? 'Erste Herausforderung'
                        : _completed.length == hashiPuzzleCatalog.length
                            ? 'Noch einmal spielen'
                            : 'Nächstes ungelöstes Rätsel',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const HashiCatalogScreen(),
                      ),
                    );
                    await _refreshProgress();
                  },
                  icon: const Icon(Icons.apps_rounded),
                  label: const Text('Rätselkatalog'),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const HashiRulesScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.menu_book_rounded),
                  label: const Text('Regeln ansehen'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HashiCatalogScreen extends StatefulWidget {
  const HashiCatalogScreen({super.key});

  @override
  State<HashiCatalogScreen> createState() => _HashiCatalogScreenState();
}

class _HashiCatalogScreenState extends State<HashiCatalogScreen> {
  final HashiProgressStore _progressStore = HashiProgressStore();
  Set<String> _completed = <String>{};
  int _difficultyFilter = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final completed = await _progressStore.loadCompleted();
    if (!mounted) return;
    setState(() => _completed = completed);
  }

  Future<void> _open(HashiPuzzle puzzle) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HashiGameScreen(puzzle: puzzle),
      ),
    );
    await _refresh();
  }

  List<HashiPuzzle> get _visiblePuzzles => _difficultyFilter == 0
      ? hashiPuzzleCatalog
      : hashiPuzzleCatalog
          .where((puzzle) => puzzle.difficulty == _difficultyFilter)
          .toList();

  String _difficultyName(int difficulty) => switch (difficulty) {
        1 => 'Leicht',
        2 => 'Mittel',
        3 => 'Schwer',
        _ => 'Alle',
      };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final visiblePuzzles = _visiblePuzzles;
    return Scaffold(
      appBar: AppBar(title: const Text('Hashi-Rätsel')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: visiblePuzzles.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '${_completed.length} von ${hashiPuzzleCatalog.length} geschafft',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              minHeight: 8,
                              value:
                                  _completed.length / hashiPuzzleCatalog.length,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(4, (difficulty) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              selected: _difficultyFilter == difficulty,
                              onSelected: (_) => setState(
                                () => _difficultyFilter = difficulty,
                              ),
                              label: Text(_difficultyName(difficulty)),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                );
              }

              final puzzle = visiblePuzzles[index - 1];
              final catalogIndex = hashiPuzzleCatalog.indexOf(puzzle);
              final completed = _completed.contains(puzzle.id);
              return Card(
                child: ListTile(
                  onTap: () => _open(puzzle),
                  leading: CircleAvatar(
                    backgroundColor: completed
                        ? colors.primaryContainer
                        : colors.surfaceContainerHighest,
                    child: completed
                        ? Icon(Icons.check_rounded, color: colors.primary)
                        : Text('${catalogIndex + 1}'),
                  ),
                  title: Text(
                    puzzle.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${List.filled(puzzle.difficulty, '★').join()}${List.filled(3 - puzzle.difficulty, '☆').join()}  ·  ${puzzle.islands.length} Inseln',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class HashiTutorialScreen extends StatelessWidget {
  const HashiTutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HashiGameScreen(puzzle: hashiTutorialPuzzle);
  }
}


enum _HashiDeveloperAction {
  almostSolved,
  solve,
  error,
  reset,
}

class HashiGameScreen extends StatefulWidget {
  const HashiGameScreen({required this.puzzle, super.key});

  final HashiPuzzle puzzle;

  @override
  State<HashiGameScreen> createState() => _HashiGameScreenState();
}

class _HashiGameScreenState extends State<HashiGameScreen> {
  final HashiProgressStore _progressStore = HashiProgressStore();
  late HashiGameState _game;
  final List<HashiGameState> _history = [];
  Timer? _timer;
  Timer? _messageTimer;
  int? _selectedIsland;
  String? _actionMessage;
  int _elapsedSeconds = 0;
  int _moves = 0;
  bool _completionShown = false;

  @override
  void initState() {
    super.initState();
    _game = HashiGameState(puzzle: widget.puzzle);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_completionShown) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _messageTimer?.cancel();
    super.dispose();
  }

  List<int> get _possibleTargets {
    final selected = _selectedIsland;
    if (selected == null) return const [];
    return List<int>.generate(_game.puzzle.islands.length, (index) => index)
        .where((index) => _game.canConnect(selected, index))
        .toList();
  }

  String get _timeLabel {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _handleIslandTap(int index) async {
    if (_selectedIsland == null) {
      setState(() => _selectedIsland = index);
      return;
    }
    if (_selectedIsland == index) {
      setState(() => _selectedIsland = null);
      return;
    }

    final first = _selectedIsland!;
    final previous = _game;
    final previousCount = previous.bridgeCountBetween(first, index);
    final next = previous.cycleConnection(first, index);
    setState(() {
      if (!identical(previous, next)) {
        _history.add(previous);
        _game = next;
        _moves++;
      }
      _selectedIsland = null;
    });
    if (!identical(previous, next)) {
      final nextCount = next.bridgeCountBetween(first, index);
      _showActionMessage(
        nextCount == 0
            ? 'Brücke entfernt'
            : nextCount == 2 && previousCount == 1
                ? 'Doppelte Brücke'
                : 'Brücke gesetzt',
      );
    }

    await _showCompletionIfSolved();
  }


  Future<void> _showCompletionIfSolved() async {
    if (!_game.isSolved || _completionShown) return;
    _completionShown = true;
    await _progressStore.markCompleted(widget.puzzle.id);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.celebration_rounded),
        title: const Text('Brückennetz vollendet!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Alle Zahlen stimmen und jede Insel gehört zum selben Netz.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ResultValue(icon: Icons.timer_outlined, value: _timeLabel),
                _ResultValue(
                  icon: Icons.touch_app_outlined,
                  value: '$_moves Züge',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Zum Katalog'),
          ),
          if (_nextPuzzle != null)
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => HashiGameScreen(puzzle: _nextPuzzle!),
                  ),
                );
              },
              child: const Text('Nächstes Rätsel'),
            )
          else
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Geschafft'),
            ),
        ],
      ),
    );
  }

  Future<void> _runDeveloperAction(_HashiDeveloperAction action) async {
    switch (action) {
      case _HashiDeveloperAction.almostSolved:
        final solution = widget.puzzle.solution;
        setState(() {
          final almostSolved = solution.isEmpty
              ? const <HashiBridge>[]
              : <HashiBridge>[
                  ...solution.take(solution.length - 1),
                  if (solution.last.count == 2)
                    solution.last.copyWith(count: 1),
                ];
          _game = HashiGameState(
            puzzle: widget.puzzle,
            bridges: almostSolved,
          );
          _history.clear();
          _selectedIsland = null;
          _completionShown = false;
          _moves = 0;
        });
        _showActionMessage('Bis auf eine Brücke gelöst');
        return;
      case _HashiDeveloperAction.solve:
        setState(() {
          _game = HashiGameState(
            puzzle: widget.puzzle,
            bridges: widget.puzzle.solution,
          );
          _history.clear();
          _selectedIsland = null;
          _completionShown = false;
          _moves = 0;
        });
        await _showCompletionIfSolved();
        return;
      case _HashiDeveloperAction.error:
        final solution = widget.puzzle.solution;
        final invalid = solution.isEmpty
            ? const <HashiBridge>[]
            : <HashiBridge>[
                solution.first.copyWith(
                  count: solution.first.count == 1 ? 2 : 1,
                ),
                ...solution.skip(1),
              ];
        setState(() {
          _game = HashiGameState(puzzle: widget.puzzle, bridges: invalid);
          _history.clear();
          _selectedIsland = null;
          _completionShown = false;
          _moves = 0;
        });
        _showActionMessage('Fehlerzustand erzeugt');
        return;
      case _HashiDeveloperAction.reset:
        _restart();
        _showActionMessage('Testzustand gelöscht');
        return;
    }
  }


  void _showActionMessage(String message) {
    _messageTimer?.cancel();
    if (mounted) setState(() => _actionMessage = message);
    _messageTimer = Timer(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _actionMessage = null);
    });
  }

  void _handleBridgeTap(HashiBridge bridge) {
    final previous = _game;
    final next = previous.removeConnection(bridge.from, bridge.to);
    if (identical(previous, next)) return;
    setState(() {
      _history.add(previous);
      _game = next;
      _moves++;
      _selectedIsland = null;
    });
    _showActionMessage('Brücke entfernt');
  }

  HashiPuzzle? get _nextPuzzle {
    final index = hashiPuzzleCatalog.indexOf(widget.puzzle);
    if (index < 0 || index + 1 >= hashiPuzzleCatalog.length) return null;
    return hashiPuzzleCatalog[index + 1];
  }

  void _undo() {
    if (_history.isEmpty) return;
    setState(() {
      _game = _history.removeLast();
      _selectedIsland = null;
      _actionMessage = null;
      _completionShown = false;
      if (_moves > 0) _moves--;
    });
  }

  void _restart() {
    setState(() {
      _game = HashiGameState(puzzle: widget.puzzle);
      _history.clear();
      _selectedIsland = null;
      _actionMessage = null;
      _completionShown = false;
      _elapsedSeconds = 0;
      _moves = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bridgeCounts = List<int>.generate(
      _game.puzzle.islands.length,
      _game.bridgeCountAt,
    );
    final fulfilledIslands = List<int>.generate(
      _game.puzzle.islands.length,
      (index) => index,
    ).where((index) =>
        bridgeCounts[index] == _game.puzzle.islands[index].bridges).length;
    final instruction = _actionMessage ??
        (_selectedIsland == null
            ? 'Wähle eine Insel.'
            : 'Wähle eine leuchtende Zielinsel.');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.puzzle.title),
        actions: [
          if (kDebugMode)
            PopupMenuButton<_HashiDeveloperAction>(
              tooltip: 'Testwerkzeuge',
              icon: const Icon(Icons.bug_report_outlined),
              onSelected: _runDeveloperAction,
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _HashiDeveloperAction.almostSolved,
                  child: Text('Bis auf 1 Brücke lösen'),
                ),
                PopupMenuItem(
                  value: _HashiDeveloperAction.solve,
                  child: Text('Sofort lösen'),
                ),
                PopupMenuItem(
                  value: _HashiDeveloperAction.error,
                  child: Text('Fehlerzustand erzeugen'),
                ),
                PopupMenuItem(
                  value: _HashiDeveloperAction.reset,
                  child: Text('Testzustand löschen'),
                ),
              ],
            ),
          IconButton(
            tooltip: 'Rückgängig',
            onPressed: _history.isEmpty ? null : _undo,
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            tooltip: 'Neu starten',
            onPressed: _restart,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              child: Column(
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatusChip(
                        icon: Icons.timer_outlined,
                        label: _timeLabel,
                      ),
                      _StatusChip(
                        icon: Icons.touch_app_outlined,
                        label: '$_moves Züge',
                      ),
                      _StatusChip(
                        icon: Icons.hub_outlined,
                        label:
                            '$fulfilledIslands/${_game.puzzle.islands.length} Inseln',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.15),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: Container(
                      key: ValueKey(instruction),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _actionMessage == null
                            ? colors.surfaceContainerHighest
                            : colors.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        instruction,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: _actionMessage == null
                                  ? colors.onSurfaceVariant
                                  : colors.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: colors.outlineVariant.withValues(alpha: 0.7),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colors.shadow.withValues(alpha: 0.08),
                              blurRadius: 22,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: HashiBoard(
                              puzzle: _game.puzzle,
                              bridges: _game.bridges,
                              selectedIsland: _selectedIsland,
                              possibleTargets: _possibleTargets,
                              bridgeCounts: bridgeCounts,
                              onIslandTap: _handleIslandTap,
                              onBridgeTap: _handleBridgeTap,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 20,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '1× verbinden, 2× doppeln, 3× entfernen. Eine Brücke kannst du auch direkt antippen.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _ResultValue extends StatelessWidget {
  const _ResultValue({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class HashiRulesScreen extends StatelessWidget {
  const HashiRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('So funktioniert Hashi')),
      body: Center(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _RuleSection(
                    number: '1',
                    title: 'Inseln verbinden',
                    text:
                        'Verbinde Inseln, die sich in derselben Zeile oder Spalte direkt sehen können.',
                  ),
                  _RuleSection(
                    number: '2',
                    title: 'Zahlen erfüllen',
                    text:
                        'Die Zahl einer Insel entspricht der Summe aller einfachen und doppelten Brücken an dieser Insel.',
                  ),
                  _RuleSection(
                    number: '3',
                    title: 'Keine Kreuzungen',
                    text:
                        'Brücken verlaufen waagerecht oder senkrecht. Sie dürfen weder Inseln durchqueren noch andere Brücken kreuzen.',
                  ),
                  _RuleSection(
                    number: '4',
                    title: 'Brücken korrigieren',
                    text:
                        'Wähle dieselben zwei Inseln erneut: eine, zwei, keine Brücke. Eine gesetzte Brücke kannst du außerdem direkt antippen, um sie zu entfernen.',
                  ),
                  _RuleSection(
                    number: '5',
                    title: 'Ein gemeinsames Netz',
                    text:
                        'Alle Inseln müssen miteinander verbunden sein. Mehrere getrennte Gruppen sind keine gültige Lösung.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HashiBoard extends StatelessWidget {
  const HashiBoard({
    required this.puzzle,
    required this.bridges,
    this.selectedIsland,
    this.possibleTargets = const [],
    this.bridgeCounts,
    this.onIslandTap,
    this.onBridgeTap,
    super.key,
  });

  final HashiPuzzle puzzle;
  final List<HashiBridge> bridges;
  final int? selectedIsland;
  final List<int> possibleTargets;
  final List<int>? bridgeCounts;
  final ValueChanged<int>? onIslandTap;
  final ValueChanged<HashiBridge>? onBridgeTap;

  HashiBridge? _bridgeAtPosition(Offset position, Size size) {
    if (bridges.isEmpty) return null;
    final cell = size.shortestSide / puzzle.size;
    final offsetX = (size.width - cell * puzzle.size) / 2;
    final offsetY = (size.height - cell * puzzle.size) / 2;
    final threshold = math.max(14.0, cell * 0.22);
    final islandRadius = cell * 0.34;

    Offset point(HashiIsland island) => Offset(
          offsetX + (island.column + 0.5) * cell,
          offsetY + (island.row + 0.5) * cell,
        );

    HashiBridge? closest;
    var closestDistance = double.infinity;
    for (final bridge in bridges) {
      final start = point(puzzle.islands[bridge.from]);
      final end = point(puzzle.islands[bridge.to]);
      if ((position - start).distance <= islandRadius ||
          (position - end).distance <= islandRadius) {
        continue;
      }
      final distance = _distanceToSegment(position, start, end);
      if (distance <= threshold && distance < closestDistance) {
        closest = bridge;
        closestDistance = distance;
      }
    }
    return closest;
  }

  static double _distanceToSegment(Offset point, Offset start, Offset end) {
    final segment = end - start;
    final lengthSquared = segment.dx * segment.dx + segment.dy * segment.dy;
    if (lengthSquared == 0) return (point - start).distance;
    final projection = ((point.dx - start.dx) * segment.dx +
            (point.dy - start.dy) * segment.dy) /
        lengthSquared;
    final t = projection.clamp(0.0, 1.0).toDouble();
    final nearest = Offset(start.dx + segment.dx * t, start.dy + segment.dy * t);
    return (point - nearest).distance;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, constraints.maxHeight);
        return SizedBox.square(
          dimension: side,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: onBridgeTap == null
                      ? null
                      : (details) {
                          final bridge = _bridgeAtPosition(
                            details.localPosition,
                            Size.square(side),
                          );
                          if (bridge != null) onBridgeTap!(bridge);
                        },
                  child: CustomPaint(
                    painter: _HashiBoardPainter(
                      puzzle: puzzle,
                      bridges: bridges,
                      selectedIsland: selectedIsland,
                      possibleTargets: possibleTargets,
                      bridgeCounts: bridgeCounts,
                      colorScheme: Theme.of(context).colorScheme,
                    ),
                  ),
                ),
              ),
              if (onIslandTap != null)
                ...List.generate(puzzle.islands.length, (index) {
                  final island = puzzle.islands[index];
                  final cell = side / puzzle.size;
                  final diameter = cell * 0.72;
                  return Positioned(
                    left: (island.column + 0.5) * cell - diameter / 2,
                    top: (island.row + 0.5) * cell - diameter / 2,
                    width: diameter,
                    height: diameter,
                    child: Semantics(
                      button: true,
                      label: 'Insel ${island.bridges}',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => onIslandTap!(index),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _HashiBoardPainter extends CustomPainter {
  const _HashiBoardPainter({
    required this.puzzle,
    required this.bridges,
    required this.selectedIsland,
    required this.possibleTargets,
    required this.bridgeCounts,
    required this.colorScheme,
  });

  final HashiPuzzle puzzle;
  final List<HashiBridge> bridges;
  final int? selectedIsland;
  final List<int> possibleTargets;
  final List<int>? bridgeCounts;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.shortestSide / puzzle.size;
    final offsetX = (size.width - cell * puzzle.size) / 2;
    final offsetY = (size.height - cell * puzzle.size) / 2;

    Offset point(HashiIsland island) => Offset(
          offsetX + (island.column + 0.5) * cell,
          offsetY + (island.row + 0.5) * cell,
        );

    final guidePaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    final guideRadius = (cell * 0.018).clamp(0.8, 1.6).toDouble();
    for (var row = 0; row < puzzle.size; row++) {
      for (var column = 0; column < puzzle.size; column++) {
        canvas.drawCircle(
          Offset(
            offsetX + (column + 0.5) * cell,
            offsetY + (row + 0.5) * cell,
          ),
          guideRadius,
          guidePaint,
        );
      }
    }

    final bridgeWidth = (cell * 0.075).clamp(2.4, 5.2).toDouble();
    final bridgeUnderlay = Paint()
      ..color = colorScheme.surfaceContainerLowest
      ..strokeWidth = bridgeWidth +
          (cell * 0.075).clamp(2.0, 4.5).toDouble()
      ..strokeCap = StrokeCap.round;
    final bridgePaint = Paint()
      ..color = colorScheme.primary
      ..strokeWidth = bridgeWidth
      ..strokeCap = StrokeCap.round;

    void drawBridgeLine(Offset start, Offset end) {
      canvas.drawLine(start, end, bridgeUnderlay);
      canvas.drawLine(start, end, bridgePaint);
    }

    for (final bridge in bridges) {
      final start = point(puzzle.islands[bridge.from]);
      final end = point(puzzle.islands[bridge.to]);
      if (bridge.count == 1) {
        drawBridgeLine(start, end);
      } else {
        final horizontal = (start.dy - end.dy).abs() < 0.01;
        final shift = cell * 0.095;
        final delta = horizontal ? Offset(0, shift) : Offset(shift, 0);
        drawBridgeLine(start - delta, end - delta);
        drawBridgeLine(start + delta, end + delta);
      }
    }

    for (var index = 0; index < puzzle.islands.length; index++) {
      final island = puzzle.islands[index];
      final center = point(island);
      final current = bridgeCounts?[index];
      final fulfilled = current == island.bridges;
      final exceeded = current != null && current > island.bridges;
      final selected = selectedIsland == index;
      final possibleTarget = possibleTargets.contains(index);
      final radius = cell * 0.32;

      if (selected || possibleTarget) {
        final haloPaint = Paint()
          ..color = (selected ? colorScheme.primary : colorScheme.tertiary)
              .withValues(alpha: selected ? 0.18 : 0.13);
        canvas.drawCircle(center, radius + cell * 0.14, haloPaint);
      }

      final shadowPath = Path()
        ..addOval(Rect.fromCircle(
          center: center + Offset(0, cell * 0.045),
          radius: radius,
        ));
      canvas.drawShadow(
        shadowPath,
        colorScheme.shadow.withValues(alpha: 0.28),
        cell * 0.07,
        false,
      );

      final islandPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.25, -0.35),
          radius: 1.15,
          colors: exceeded
              ? [colorScheme.errorContainer, colorScheme.errorContainer]
              : fulfilled
                  ? [
                      colorScheme.primaryContainer,
                      colorScheme.primaryContainer.withValues(alpha: 0.82),
                    ]
                  : [
                      colorScheme.secondaryContainer,
                      colorScheme.secondaryContainer.withValues(alpha: 0.82),
                    ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      final outlinePaint = Paint()
        ..color = selected
            ? colorScheme.primary
            : possibleTarget
                ? colorScheme.tertiary
                : exceeded
                    ? colorScheme.error
                    : fulfilled
                        ? colorScheme.primary
                        : colorScheme.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = (selected || possibleTarget)
            ? (cell * 0.085).clamp(3.0, 6.0).toDouble()
            : (cell * 0.045).clamp(1.6, 3.4).toDouble();

      canvas.drawCircle(center, radius, islandPaint);
      canvas.drawCircle(center, radius, outlinePaint);

      if (fulfilled && !exceeded) {
        final checkPaint = Paint()
          ..color = colorScheme.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = (cell * 0.04).clamp(1.6, 3.0).toDouble()
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        final checkCenter = center + Offset(radius * 0.68, -radius * 0.68);
        canvas.drawCircle(
          checkCenter,
          cell * 0.105,
          Paint()..color = colorScheme.surfaceContainerLowest,
        );
        final checkPath = Path()
          ..moveTo(checkCenter.dx - cell * 0.045, checkCenter.dy)
          ..lineTo(checkCenter.dx - cell * 0.01, checkCenter.dy + cell * 0.035)
          ..lineTo(checkCenter.dx + cell * 0.055, checkCenter.dy - cell * 0.04);
        canvas.drawPath(checkPath, checkPaint);
      }

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${island.bridges}',
          style: TextStyle(
            color: exceeded
                ? colorScheme.onErrorContainer
                : fulfilled
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSecondaryContainer,
            fontSize: cell * 0.33,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        center - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HashiBoardPainter oldDelegate) {
    return oldDelegate.puzzle != puzzle ||
        oldDelegate.bridges != bridges ||
        oldDelegate.selectedIsland != selectedIsland ||
        oldDelegate.possibleTargets != possibleTargets ||
        oldDelegate.bridgeCounts != bridgeCounts ||
        oldDelegate.colorScheme != colorScheme;
  }
}

class _RuleSection extends StatelessWidget {
  const _RuleSection({
    required this.number,
    required this.title,
    required this.text,
  });

  final String number;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(child: Text(number)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 5),
                  Text(text),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
