import 'dart:async';
import 'dart:math' as math;

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
                  onPressed: () => _openPuzzle(hashiTutorialPuzzle),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    _completed.contains(hashiTutorialPuzzle.id)
                        ? 'Noch einmal spielen'
                        : 'Erste Herausforderung',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hashi-Rätsel')),
      body: Center(
        child: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: hashiPuzzleCatalog.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final puzzle = hashiPuzzleCatalog[index];
            final completed = _completed.contains(puzzle.id);
            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Card(
                child: ListTile(
                  onTap: () => _open(puzzle),
                  leading: CircleAvatar(
                    child: completed
                        ? const Icon(Icons.check_rounded)
                        : Text('${index + 1}'),
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
              ),
            );
          },
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

    if (_game.isSolved && !_completionShown) {
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.puzzle.title),
        actions: [
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
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatusChip(
                        icon: Icons.timer_outlined,
                        label: _timeLabel,
                      ),
                      const SizedBox(width: 10),
                      _StatusChip(
                        icon: Icons.touch_app_outlined,
                        label: '$_moves Züge',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _actionMessage ??
                        (_selectedIsland == null
                            ? 'Wähle eine Insel.'
                            : 'Leuchtende Inseln sind mögliche Ziele.'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Eine → zwei → keine Brücke',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: HashiBoard(
                          puzzle: _game.puzzle,
                          bridges: _game.bridges,
                          selectedIsland: _selectedIsland,
                          possibleTargets: _possibleTargets,
                          bridgeCounts: List<int>.generate(
                            _game.puzzle.islands.length,
                            _game.bridgeCountAt,
                          ),
                          onIslandTap: _handleIslandTap,
                          onBridgeTap: _handleBridgeTap,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tipp: Eine gesetzte Brücke kannst du direkt antippen, um sie zu entfernen.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ziel: Zahlen erfüllen, Kreuzungen vermeiden, alle Inseln verbinden.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
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

    final bridgePaint = Paint()
      ..color = colorScheme.primary
      ..strokeWidth = (cell * 0.07).clamp(2.0, 5.0).toDouble()
      ..strokeCap = StrokeCap.round;

    for (final bridge in bridges) {
      final start = point(puzzle.islands[bridge.from]);
      final end = point(puzzle.islands[bridge.to]);
      if (bridge.count == 1) {
        canvas.drawLine(start, end, bridgePaint);
      } else {
        final horizontal = (start.dy - end.dy).abs() < 0.01;
        final shift = cell * 0.08;
        final delta = horizontal ? Offset(0, shift) : Offset(shift, 0);
        canvas.drawLine(start - delta, end - delta, bridgePaint);
        canvas.drawLine(start + delta, end + delta, bridgePaint);
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
      final radius = cell * 0.31;

      final islandPaint = Paint()
        ..color = exceeded
            ? colorScheme.errorContainer
            : fulfilled
                ? colorScheme.primaryContainer
                : colorScheme.secondaryContainer;
      final outlinePaint = Paint()
        ..color = selected
            ? colorScheme.primary
            : possibleTarget
                ? colorScheme.tertiary
                : exceeded
                ? colorScheme.error
                : fulfilled
                    ? colorScheme.primary
                    : colorScheme.secondary
        ..style = PaintingStyle.stroke
        ..strokeWidth = (selected || possibleTarget) ? cell * 0.09 : cell * 0.05;

      canvas.drawCircle(center, radius, islandPaint);
      canvas.drawCircle(center, radius, outlinePaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${island.bridges}',
          style: TextStyle(
            color: exceeded
                ? colorScheme.onErrorContainer
                : fulfilled
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSecondaryContainer,
            fontSize: cell * 0.32,
            fontWeight: FontWeight.w800,
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
