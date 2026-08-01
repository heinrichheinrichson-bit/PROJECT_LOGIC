import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/domain/game_identity.dart';
import 'core/presentation/confirm_restart_dialog.dart';
import 'features/futoshiki/domain/futoshiki_generator.dart';
import 'features/futoshiki/domain/futoshiki_puzzle.dart';
import 'game_storage.dart';

class SavedFutoshikiGame {
  const SavedFutoshikiGame({
    required this.puzzle,
    required this.values,
    required this.elapsedSeconds,
    required this.moves,
    required this.hintsRemaining,
    this.mode = GameMode.generated,
  });

  final FutoshikiPuzzle puzzle;
  final List<List<int?>> values;
  final int elapsedSeconds;
  final int moves;
  final int hintsRemaining;
  final GameMode mode;

  Map<String, Object?> toJson() => {
        'version': 1,
        'puzzle': {
          'id': puzzle.id,
          'title': puzzle.title,
          'size': puzzle.size,
          'difficulty': puzzle.difficulty.name,
          'givens': puzzle.givens,
          'solution': puzzle.solution,
          'inequalities': [
            for (final item in puzzle.inequalities)
              {
                'firstRow': item.firstRow,
                'firstColumn': item.firstColumn,
                'secondRow': item.secondRow,
                'secondColumn': item.secondColumn,
                'firstIsLess': item.firstIsLess,
              },
          ],
        },
        'values': values,
        'elapsedSeconds': elapsedSeconds,
        'moves': moves,
        'hintsRemaining': hintsRemaining,
        'mode': mode.name,
      };

  factory SavedFutoshikiGame.fromJson(Map<String, Object?> json) {
    if (json['version'] != 1) throw const FormatException('Invalid save.');
    final rawPuzzle = Map<String, Object?>.from(json['puzzle']! as Map);
    final size = rawPuzzle['size']! as int;
    List<List<int?>> nullableGrid(Object? raw) => [
          for (final row in raw! as List)
            [for (final value in row as List) value as int?],
        ];
    List<List<int>> numberGrid(Object? raw) => [
          for (final row in raw! as List)
            [for (final value in row as List) value as int],
        ];
    final puzzle = FutoshikiPuzzle(
      id: rawPuzzle['id']! as String,
      title: rawPuzzle['title']! as String,
      size: size,
      difficulty: PuzzleDifficulty.values.byName(
        rawPuzzle['difficulty']! as String,
      ),
      givens: nullableGrid(rawPuzzle['givens']),
      solution: numberGrid(rawPuzzle['solution']),
      inequalities: [
        for (final raw in rawPuzzle['inequalities']! as List)
          FutoshikiInequality(
            firstRow: (raw as Map)['firstRow']! as int,
            firstColumn: raw['firstColumn']! as int,
            secondRow: raw['secondRow']! as int,
            secondColumn: raw['secondColumn']! as int,
            firstIsLess: raw['firstIsLess']! as bool,
          ),
      ],
    );
    return SavedFutoshikiGame(
      puzzle: puzzle,
      values: nullableGrid(json['values']),
      elapsedSeconds: json['elapsedSeconds']! as int,
      moves: json['moves']! as int,
      hintsRemaining: json['hintsRemaining']! as int,
      mode: GameMode.values.byName(
        json['mode'] as String? ?? GameMode.generated.name,
      ),
    );
  }
}

final List<FutoshikiPuzzle> futoshikiPuzzleCatalog = [
  for (final difficulty in PuzzleDifficulty.values)
    for (var index = 0; index < 8; index++)
      const FutoshikiGenerator().generate(
        seed: 8100 + difficulty.index * 100 + index,
        difficulty: difficulty,
        id: 'futoshiki-${difficulty.name}-${index + 1}',
        title: switch (index) {
          0 => 'Erste Vergleiche',
          1 => 'Klare Reihen',
          2 => 'Kleine Ketten',
          3 => 'Sicher eingeordnet',
          4 => 'Zahlenspiel',
          5 => 'Enger Rahmen',
          6 => 'Logische Ordnung',
          _ => 'Kapitelabschluss',
        },
      ),
];

class FutoshikiGameStore {
  static const _key = 'active_futoshiki_game_v1';

  Future<void> save(SavedFutoshikiGame game) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, jsonEncode(game.toJson()));
  }

  Future<SavedFutoshikiGame?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null) return null;
    try {
      final saved = SavedFutoshikiGame.fromJson(
        Map<String, Object?>.from(jsonDecode(raw) as Map),
      );
      if (FutoshikiState(puzzle: saved.puzzle, values: saved.values).isSolved) {
        await clear();
        return null;
      }
      return saved;
    } on Object {
      await clear();
      return null;
    }
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key);
  }
}

class FutoshikiHubScreen extends StatefulWidget {
  const FutoshikiHubScreen({
    this.onOpenDaily,
    this.onOpenStatistics,
    super.key,
  });

  final void Function(BuildContext context)? onOpenDaily;
  final void Function(BuildContext context)? onOpenStatistics;

  @override
  State<FutoshikiHubScreen> createState() => _FutoshikiHubScreenState();
}

class _FutoshikiHubScreenState extends State<FutoshikiHubScreen> {
  SavedFutoshikiGame? _saved;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final saved = await FutoshikiGameStore().load();
    if (mounted) setState(() => _saved = saved);
  }

  Future<void> _open(FutoshikiPuzzle puzzle,
      {SavedFutoshikiGame? saved}) async {
    if (saved == null && _saved != null) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.save_outlined),
          title: const Text('Offenes Futoshiki-Rätsel'),
          content: const Text(
            'Du hast bereits ein begonnenes Rätsel. Möchtest du es '
            'fortsetzen oder wirklich ein neues beginnen?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Fortsetzen'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Neu beginnen'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (replace != true) {
        final current = _saved!;
        return _open(current.puzzle, saved: current);
      }
      await FutoshikiGameStore().clear();
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FutoshikiGameScreen(
          puzzle: puzzle,
          savedGame: saved,
          mode: saved?.mode ?? GameMode.generated,
        ),
      ),
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Futoshiki')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_saved case final saved?) ...[
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: ListTile(
                minTileHeight: 88,
                leading: const Icon(Icons.play_circle_outline_rounded),
                title: const Text('Rätsel fortsetzen'),
                subtitle: Text(
                  '${saved.puzzle.difficulty.label} · '
                  '${saved.puzzle.size} × ${saved.puzzle.size} · '
                  '${_formatTime(saved.elapsedSeconds)}',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _open(saved.puzzle, saved: saved),
              ),
            ),
            const SizedBox(height: 20),
          ],
          Text(
            'Ungleich, aber logisch',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Fülle jede Zeile und Spalte mit allen Zahlen. Dabei darf keine '
            'Zahl doppelt vorkommen und jedes Ungleichheitszeichen muss stimmen.',
          ),
          const SizedBox(height: 24),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              minTileHeight: 86,
              leading: const CircleAvatar(
                child: Icon(Icons.grid_view_rounded),
              ),
              title: const Text('Rätselsammlung'),
              subtitle: const Text('24 ausgewählte Lern- und Logikrätsel'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const FutoshikiCollectionScreen(),
                  ),
                );
                await _refresh();
              },
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              minTileHeight: 76,
              leading: const CircleAvatar(
                child: Icon(Icons.calendar_today_outlined),
              ),
              title: const Text('Tagesrätsel'),
              subtitle:
                  const Text('Heute spielen oder vergangene Tage nachholen'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: widget.onOpenDaily == null
                  ? null
                  : () => widget.onOpenDaily!(context),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              minTileHeight: 76,
              leading: const CircleAvatar(
                child: Icon(Icons.bar_chart_rounded),
              ),
              title: const Text('Futoshiki-Statistik'),
              subtitle: const Text('Bestzeiten, Spielzeit und Fortschritt'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: widget.onOpenStatistics == null
                  ? null
                  : () => widget.onOpenStatistics!(context),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Zufallsrätsel',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          for (final difficulty in PuzzleDifficulty.values) ...[
            _DifficultyCard(
              difficulty: difficulty,
              onOpen: (puzzle) => _open(puzzle),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class FutoshikiCollectionScreen extends StatefulWidget {
  const FutoshikiCollectionScreen({super.key});

  @override
  State<FutoshikiCollectionScreen> createState() =>
      _FutoshikiCollectionScreenState();
}

class _FutoshikiCollectionScreenState extends State<FutoshikiCollectionScreen> {
  Map<String, PuzzleResult> _results = const {};

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final results = await GameStorage().loadResults();
    if (mounted) setState(() => _results = results);
  }

  Future<void> _openPuzzle(FutoshikiPuzzle puzzle) async {
    final saved = await FutoshikiGameStore().load();
    if (!mounted) return;
    if (saved != null && saved.puzzle.id != puzzle.id) {
      final choice = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.save_outlined),
          title: const Text('Offenes Futoshiki-Rätsel'),
          content: const Text(
            'Dein begonnenes Rätsel bleibt gespeichert. Möchtest du es '
            'fortsetzen oder mit dem ausgewählten Rätsel neu beginnen?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'resume'),
              child: const Text('Fortsetzen'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, 'replace'),
              child: const Text('Neu beginnen'),
            ),
          ],
        ),
      );
      if (!mounted || choice == null) return;
      if (choice == 'resume') {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => FutoshikiGameScreen(
              puzzle: saved.puzzle,
              savedGame: saved,
              mode: saved.mode,
            ),
          ),
        );
        await _refresh();
        return;
      }
      await FutoshikiGameStore().clear();
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FutoshikiGameScreen(
          puzzle: puzzle,
          mode: GameMode.catalog,
        ),
      ),
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Futoshiki-Sammlung')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final difficulty in PuzzleDifficulty.values) ...[
            Builder(builder: (context) {
              final puzzles = futoshikiPuzzleCatalog
                  .where((puzzle) => puzzle.difficulty == difficulty)
                  .toList(growable: false);
              final solved = puzzles
                  .where((puzzle) =>
                      _results.containsKey('futoshiki:${puzzle.id}'))
                  .length;
              return Card(
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  initiallyExpanded: difficulty == PuzzleDifficulty.easy,
                  leading: CircleAvatar(child: Text('${difficulty.index + 1}')),
                  title: Text(difficulty.label),
                  subtitle: Text('$solved von ${puzzles.length} gelöst'),
                  children: [
                    for (var index = 0; index < puzzles.length; index++)
                      ListTile(
                        leading: CircleAvatar(
                          child: _results.containsKey(
                            'futoshiki:${puzzles[index].id}',
                          )
                              ? const Icon(Icons.check_rounded)
                              : Text('${index + 1}'),
                        ),
                        title: Text(puzzles[index].title),
                        subtitle: Text(
                          '${puzzles[index].size} × ${puzzles[index].size}',
                        ),
                        trailing: const Icon(Icons.play_arrow_rounded),
                        onTap: () => _openPuzzle(puzzles[index]),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  const _DifficultyCard({required this.difficulty, required this.onOpen});

  final PuzzleDifficulty difficulty;
  final ValueChanged<FutoshikiPuzzle> onOpen;

  @override
  Widget build(BuildContext context) {
    final size = switch (difficulty) {
      PuzzleDifficulty.easy => 4,
      PuzzleDifficulty.medium => 5,
      PuzzleDifficulty.hard => 6,
    };
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        minTileHeight: 86,
        leading: CircleAvatar(child: Text('$size')),
        title: Text(difficulty.label),
        subtitle: Text('${difficulty.description} · $size × $size'),
        trailing: const Icon(Icons.play_arrow_rounded),
        onTap: () {
          final seed = DateTime.now().microsecondsSinceEpoch;
          final puzzle = const FutoshikiGenerator().generate(
            seed: seed,
            difficulty: difficulty,
          );
          onOpen(puzzle);
        },
      ),
    );
  }
}

class FutoshikiGameScreen extends StatefulWidget {
  const FutoshikiGameScreen({
    required this.puzzle,
    this.savedGame,
    this.mode = GameMode.generated,
    super.key,
  });

  final FutoshikiPuzzle puzzle;
  final SavedFutoshikiGame? savedGame;
  final GameMode mode;

  @override
  State<FutoshikiGameScreen> createState() => _FutoshikiGameScreenState();
}

class _FutoshikiGameScreenState extends State<FutoshikiGameScreen> {
  static const _guideSeenKey = 'futoshiki_inequality_guide_seen_v1';
  late FutoshikiState _state;
  final _history = <FutoshikiState>[];
  final _redo = <FutoshikiState>[];
  Timer? _timer;
  (int, int)? _selected;
  int _elapsedSeconds = 0;
  int _moves = 0;
  int _hintsRemaining = 3;
  bool _showConflicts = true;
  bool _completionShown = false;
  final _saveStore = FutoshikiGameStore();

  @override
  void initState() {
    super.initState();
    final saved = widget.savedGame;
    _state = FutoshikiState(
      puzzle: widget.puzzle,
      values: saved?.values,
    );
    _selected = _firstEditableCell();
    _elapsedSeconds = saved?.elapsedSeconds ?? 0;
    _moves = saved?.moves ?? 0;
    _hintsRemaining = saved?.hintsRemaining ?? 3;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_completionShown) {
        setState(() => _elapsedSeconds++);
        if (_elapsedSeconds % 5 == 0) unawaited(_saveGame());
      }
    });
    unawaited(_saveGame());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_showFirstRunGuide());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  (int, int)? _firstEditableCell() {
    for (var row = 0; row < widget.puzzle.size; row++) {
      for (var column = 0; column < widget.puzzle.size; column++) {
        if (widget.puzzle.givens[row][column] == null) return (row, column);
      }
    }
    return null;
  }

  Future<void> _saveGame() => _saveStore.save(
        SavedFutoshikiGame(
          puzzle: widget.puzzle,
          values: _state.values,
          elapsedSeconds: _elapsedSeconds,
          moves: _moves,
          hintsRemaining: _hintsRemaining,
          mode: widget.mode,
        ),
      );

  Future<void> _showFirstRunGuide() async {
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getBool(_guideSeenKey) ?? false) return;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.compare_arrows_rounded),
        title: const Text('So liest du die Zeichen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _InequalityExample(),
            const SizedBox(height: 18),
            const Text(
              'Die offene Seite zeigt immer zur größeren Zahl. '
              'Die Spitze zeigt zur kleineren Zahl.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Horizontal und vertikal gilt genau dieselbe Regel.',
              textAlign: TextAlign.center,
              style: Theme.of(dialogContext).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Verstanden'),
          ),
        ],
      ),
    );
    await preferences.setBool(_guideSeenKey, true);
  }

  void _setValue(int? value) {
    final selected = _selected;
    if (selected == null || _completionShown) return;
    final next = _state.setValue(selected.$1, selected.$2, value);
    if (identical(next, _state) ||
        next.values[selected.$1][selected.$2] ==
            _state.values[selected.$1][selected.$2]) {
      return;
    }
    setState(() {
      _history.add(_state);
      _state = next;
      _redo.clear();
      _moves++;
    });
    unawaited(_saveGame());
    if (_state.isSolved) unawaited(_showCompletion());
  }

  void _undo() {
    if (_history.isEmpty || _completionShown) return;
    setState(() {
      _redo.add(_state);
      _state = _history.removeLast();
      if (_moves > 0) _moves--;
    });
    unawaited(_saveGame());
  }

  void _redoMove() {
    if (_redo.isEmpty || _completionShown) return;
    setState(() {
      _history.add(_state);
      _state = _redo.removeLast();
      _moves++;
    });
    unawaited(_saveGame());
  }

  Future<void> _restart() async {
    if (!await confirmPuzzleRestart(context) || !mounted) return;
    setState(() {
      _history.add(_state);
      _state = FutoshikiState(puzzle: widget.puzzle);
      _redo.clear();
      _elapsedSeconds = 0;
      _moves = 0;
      _hintsRemaining = 3;
      _completionShown = false;
      _selected = _firstEditableCell();
    });
    unawaited(_saveGame());
  }

  Future<void> _hint() async {
    if (_hintsRemaining <= 0 || _completionShown) return;
    (int, int)? cell;
    for (var row = 0; row < widget.puzzle.size && cell == null; row++) {
      for (var column = 0; column < widget.puzzle.size; column++) {
        if (widget.puzzle.givens[row][column] != null) continue;
        if (_state.values[row][column] != widget.puzzle.solution[row][column]) {
          cell = (row, column);
          break;
        }
      }
    }
    if (cell == null) return;
    final target = cell;
    final apply = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.lightbulb_outline_rounded),
        title: const Text('Logischer Hinweis'),
        content: Text(
          'Betrachte Zeile ${target.$1 + 1}, Spalte ${target.$2 + 1}. '
          'Dort bleibt unter Beachtung der Zeile, Spalte und angrenzenden '
          'Ungleichheiten nur eine passende Zahl.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Nur markieren'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hinweis anwenden'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _selected = target);
    if (apply == true) {
      _setValue(widget.puzzle.solution[target.$1][target.$2]);
      setState(() => _hintsRemaining--);
      unawaited(_saveGame());
    }
  }

  Future<void> _showCompletion({bool testCompletion = false}) async {
    if (_completionShown) return;
    setState(() => _completionShown = true);
    final countsForTesting = testCompletion && widget.mode == GameMode.daily;
    if (!testCompletion || countsForTesting) {
      await GameStorage().recordCompletion(
        puzzleId: widget.puzzle.id,
        elapsedSeconds: _elapsedSeconds,
        source: widget.mode,
        difficulty: widget.puzzle.difficulty,
        boardSize: widget.puzzle.size,
        gameType: GameType.futoshiki,
        moves: _moves,
        hintsUsed: 3 - _hintsRemaining,
      );
    }
    await _saveStore.clear();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.emoji_events_outlined),
        title: const Text('Ungleichungen gelöst!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Alle Zahlen und Ungleichheiten stimmen.'),
            const SizedBox(height: 16),
            Text('${_formatTime(_elapsedSeconds)} · $_moves Züge'),
            if (testCompletion) ...[
              const SizedBox(height: 12),
              Text(
                countsForTesting
                    ? 'Testabschluss · im Kalender gewertet'
                    : 'Testabschluss · keine Statistik',
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  if (widget.mode == GameMode.daily) {
                    Navigator.pop(context);
                  } else {
                    _openNextPuzzle();
                  }
                },
                child: Text(
                  widget.mode == GameMode.daily ? 'Zum Kalender' : 'Noch eins',
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 4,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Brett ansehen'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    Navigator.pop(context);
                  },
                  child: const Text('Futoshiki verlassen'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openNextPuzzle() {
    final sameDifficulty = futoshikiPuzzleCatalog
        .where((puzzle) => puzzle.difficulty == widget.puzzle.difficulty)
        .toList(growable: false);
    final currentIndex =
        sameDifficulty.indexWhere((puzzle) => puzzle.id == widget.puzzle.id);
    final puzzle = widget.mode == GameMode.catalog && currentIndex >= 0
        ? sameDifficulty[(currentIndex + 1) % sameDifficulty.length]
        : const FutoshikiGenerator().generate(
            seed: DateTime.now().microsecondsSinceEpoch,
            difficulty: widget.puzzle.difficulty,
          );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => FutoshikiGameScreen(
          puzzle: puzzle,
          mode: widget.mode,
        ),
      ),
    );
  }

  void _debugSolve({required bool almost}) {
    final editable = <(int, int)>[
      for (var row = 0; row < widget.puzzle.size; row++)
        for (var column = 0; column < widget.puzzle.size; column++)
          if (widget.puzzle.givens[row][column] == null) (row, column),
    ];
    final leaveEmpty = almost && editable.isNotEmpty ? editable.last : null;
    setState(() {
      _history.add(_state);
      var next = _state;
      for (final cell in editable) {
        if (cell == leaveEmpty) continue;
        next = next.setValue(
          cell.$1,
          cell.$2,
          widget.puzzle.solution[cell.$1][cell.$2],
        );
      }
      _state = next;
      _selected = leaveEmpty;
      _redo.clear();
    });
    if (!almost) unawaited(_showCompletion(testCompletion: true));
  }

  @override
  Widget build(BuildContext context) {
    final conflicts = _showConflicts ? _state.conflictingCells : <(int, int)>{};
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.puzzle.difficulty.label} · Futoshiki'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Testwerkzeuge',
            icon: const Icon(Icons.bug_report_outlined),
            onSelected: (value) {
              if (value == 'almost') _debugSolve(almost: true);
              if (value == 'solve') _debugSolve(almost: false);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'almost', child: Text('Fast lösen')),
              PopupMenuItem(value: 'solve', child: Text('Sofort lösen')),
            ],
          ),
          IconButton(
            tooltip: 'Hinweis',
            onPressed: _hint,
            icon: const Icon(Icons.lightbulb_outline),
          ),
          IconButton(
            tooltip: 'Neu starten',
            onPressed: _restart,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minHeight: constraints.maxHeight - 32),
              child: Column(
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Status(
                          icon: Icons.timer_outlined,
                          text: _formatTime(_elapsedSeconds)),
                      _Status(
                          icon: Icons.touch_app_outlined, text: '$_moves Züge'),
                      _Status(
                          icon: Icons.lightbulb_outline,
                          text: '$_hintsRemaining Tipps'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Jede Zahl genau einmal pro Zeile und Spalte.'),
                  const SizedBox(height: 20),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerLowest,
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: FutoshikiBoard(
                            state: _state,
                            selected: _selected,
                            conflicts: conflicts,
                            onSelect: (row, column) {
                              if (!_state.isGiven(row, column)) {
                                setState(() => _selected = (row, column));
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var value = 1; value <= widget.puzzle.size; value++)
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: FilledButton.tonal(
                            onPressed: () => _setValue(value),
                            child: Text('$value'),
                          ),
                        ),
                      IconButton.outlined(
                        tooltip: 'Feld leeren',
                        onPressed: () => _setValue(null),
                        icon: const Icon(Icons.backspace_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _history.isEmpty ? null : _undo,
                          icon: const Icon(Icons.undo_rounded),
                          label: const Text('Rückgängig'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _redo.isEmpty ? null : _redoMove,
                          icon: const Icon(Icons.redo_rounded),
                          label: const Text('Wiederholen'),
                        ),
                      ),
                    ],
                  ),
                  if (_completionShown) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: widget.mode == GameMode.daily
                            ? () => Navigator.pop(context)
                            : _openNextPuzzle,
                        icon: Icon(
                          widget.mode == GameMode.daily
                              ? Icons.calendar_today_outlined
                              : Icons.auto_awesome_rounded,
                        ),
                        label: Text(
                          widget.mode == GameMode.daily
                              ? 'Zum Kalender'
                              : 'Noch ein Futoshiki',
                        ),
                      ),
                    ),
                  ],
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Regelfehler markieren'),
                    subtitle: const Text(
                        'Zeigt doppelte Zahlen und falsche Ungleichheiten.'),
                    value: _showConflicts,
                    onChanged: (value) =>
                        setState(() => _showConflicts = value),
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

class FutoshikiBoard extends StatelessWidget {
  const FutoshikiBoard({
    required this.state,
    required this.selected,
    required this.conflicts,
    required this.onSelect,
    super.key,
  });

  final FutoshikiState state;
  final (int, int)? selected;
  final Set<(int, int)> conflicts;
  final void Function(int row, int column) onSelect;

  @override
  Widget build(BuildContext context) {
    final size = state.puzzle.size;
    return Column(
      children: [
        for (var row = 0; row < size; row++) ...[
          Expanded(child: _numberRow(context, row)),
          if (row < size - 1)
            SizedBox(height: 22, child: _verticalSigns(context, row)),
        ],
      ],
    );
  }

  Widget _numberRow(BuildContext context, int row) => Row(
        children: [
          for (var column = 0; column < state.puzzle.size; column++) ...[
            Expanded(child: _cell(context, row, column)),
            if (column < state.puzzle.size - 1)
              SizedBox(
                width: 22,
                child: _horizontalSign(context, row, column),
              ),
          ],
        ],
      );

  Widget _verticalSigns(BuildContext context, int row) => Row(
        children: [
          for (var column = 0; column < state.puzzle.size; column++) ...[
            Expanded(
              child: Center(child: _verticalSign(context, row, column)),
            ),
            if (column < state.puzzle.size - 1) const SizedBox(width: 22),
          ],
        ],
      );

  Widget _cell(BuildContext context, int row, int column) {
    final value = state.values[row][column];
    final isSelected = selected == (row, column);
    final isConflict = conflicts.contains((row, column));
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: isConflict
          ? scheme.errorContainer
          : isSelected
              ? Color.alphaBlend(
                  scheme.primary.withValues(alpha: 0.16),
                  scheme.surfaceContainer,
                )
              : state.isGiven(row, column)
                  ? scheme.surfaceContainerHighest
                  : scheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isSelected ? scheme.primary : scheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => onSelect(row, column),
        child: Center(
          child: Text(
            value?.toString() ?? '',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: state.isGiven(row, column)
                      ? FontWeight.w800
                      : FontWeight.w500,
                  color: isConflict ? scheme.onErrorContainer : null,
                ),
          ),
        ),
      ),
    );
  }

  Widget _horizontalSign(BuildContext context, int row, int column) {
    final inequality = state.puzzle.inequalities
        .where((item) =>
            item.firstRow == row &&
            item.firstColumn == column &&
            item.secondRow == row &&
            item.secondColumn == column + 1)
        .firstOrNull;
    if (inequality == null) return const SizedBox.shrink();
    return Center(child: _inequalitySign(context, inequality));
  }

  Widget _verticalSign(BuildContext context, int row, int column) {
    final inequality = state.puzzle.inequalities
        .where((item) =>
            item.firstRow == row &&
            item.firstColumn == column &&
            item.secondRow == row + 1 &&
            item.secondColumn == column)
        .firstOrNull;
    if (inequality == null) return const SizedBox.shrink();
    return RotatedBox(
      quarterTurns: 1,
      child: _inequalitySign(context, inequality),
    );
  }

  Widget _inequalitySign(
    BuildContext context,
    FutoshikiInequality inequality,
  ) {
    final first = state.values[inequality.firstRow][inequality.firstColumn];
    final second = state.values[inequality.secondRow][inequality.secondColumn];
    final invalid = first != null &&
        second != null &&
        !inequality.isSatisfiedBy(first, second) &&
        conflicts.contains((inequality.firstRow, inequality.firstColumn)) &&
        conflicts.contains((inequality.secondRow, inequality.secondColumn));
    final scheme = Theme.of(context).colorScheme;
    return Text(
      inequality.firstIsLess ? '<' : '>',
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            height: 1,
            fontWeight: FontWeight.w900,
            color: invalid ? scheme.error : scheme.onSurfaceVariant,
          ),
    );
  }
}

class _InequalityExample extends StatelessWidget {
  const _InequalityExample();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget number(String value, {required bool larger}) => Container(
          width: 58,
          height: 58,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: larger
                ? scheme.primaryContainer
                : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        number('2', larger: false),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            '<',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: scheme.primary,
                ),
          ),
        ),
        number('5', larger: true),
      ],
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Chip(
        avatar: Icon(icon, size: 18),
        label: Text(text),
      );
}

String _formatTime(int seconds) {
  final minutes = seconds ~/ 60;
  final remaining = seconds % 60;
  return '$minutes:${remaining.toString().padLeft(2, '0')}';
}
