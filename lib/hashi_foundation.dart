import 'dart:math' as math;

import 'package:flutter/material.dart';

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
    required this.title,
    required this.size,
    required this.islands,
  });

  final String title;
  final int size;
  final List<HashiIsland> islands;
}

const hashiTutorialPuzzle = HashiPuzzle(
  title: 'Erste Brücken',
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
);

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

class HashiHubScreen extends StatelessWidget {
  const HashiHubScreen({super.key});

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
                        'Verbinde alle Inseln, erfülle ihre Zahlen und lasse keine Brücke eine andere kreuzen.',
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
                          'So sieht ein gelöstes Hashi-Rätsel aus.',
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
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const HashiTutorialScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Erste Herausforderung'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
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

class HashiTutorialScreen extends StatefulWidget {
  const HashiTutorialScreen({super.key});

  @override
  State<HashiTutorialScreen> createState() => _HashiTutorialScreenState();
}

class _HashiTutorialScreenState extends State<HashiTutorialScreen> {
  late HashiGameState _game;
  final List<HashiGameState> _history = [];
  int? _selectedIsland;
  bool _completionShown = false;

  @override
  void initState() {
    super.initState();
    _game = HashiGameState(puzzle: hashiTutorialPuzzle);
  }

  void _handleIslandTap(int index) {
    if (_selectedIsland == null) {
      setState(() => _selectedIsland = index);
      return;
    }
    if (_selectedIsland == index) {
      setState(() => _selectedIsland = null);
      return;
    }

    final previous = _game;
    final next = previous.cycleConnection(_selectedIsland!, index);
    setState(() {
      if (!identical(previous, next)) {
        _history.add(previous);
        _game = next;
      }
      _selectedIsland = null;
    });

    if (_game.isSolved && !_completionShown) {
      _completionShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.celebration_rounded),
            title: const Text('Brückennetz vollendet!'),
            content: const Text(
              'Alle Zahlen stimmen und jede Insel gehört zum selben Netz. Dein erstes Hashi ist gelöst.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Geschafft'),
              ),
            ],
          ),
        );
      });
    }
  }

  void _undo() {
    if (_history.isEmpty) return;
    setState(() {
      _game = _history.removeLast();
      _selectedIsland = null;
      _completionShown = false;
    });
  }

  void _restart() {
    setState(() {
      _game = HashiGameState(puzzle: hashiTutorialPuzzle);
      _history.clear();
      _selectedIsland = null;
      _completionShown = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erste Brücken'),
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
                  Text(
                    _selectedIsland == null
                        ? 'Tippe zwei sichtbare Inseln nacheinander an.'
                        : 'Wähle jetzt die zweite Insel.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Erneutes Verbinden: eine → zwei → keine Brücke',
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
                          bridgeCounts: List<int>.generate(
                            _game.puzzle.islands.length,
                            _game.bridgeCountAt,
                          ),
                          onIslandTap: _handleIslandTap,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ziel: Alle Zahlen erfüllen und alle Inseln zu einem Netz verbinden.',
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
    this.bridgeCounts,
    this.onIslandTap,
    super.key,
  });

  final HashiPuzzle puzzle;
  final List<HashiBridge> bridges;
  final int? selectedIsland;
  final List<int>? bridgeCounts;
  final ValueChanged<int>? onIslandTap;

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
                child: CustomPaint(
                  painter: _HashiBoardPainter(
                    puzzle: puzzle,
                    bridges: bridges,
                    selectedIsland: selectedIsland,
                    bridgeCounts: bridgeCounts,
                    colorScheme: Theme.of(context).colorScheme,
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
    required this.bridgeCounts,
    required this.colorScheme,
  });

  final HashiPuzzle puzzle;
  final List<HashiBridge> bridges;
  final int? selectedIsland;
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
            : exceeded
                ? colorScheme.error
                : fulfilled
                    ? colorScheme.primary
                    : colorScheme.secondary
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? cell * 0.09 : cell * 0.05;

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
