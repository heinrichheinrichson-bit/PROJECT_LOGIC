import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_preferences.dart';
import 'app_theme.dart';
import 'core/domain/game_identity.dart';
import 'core/presentation/confirm_restart_dialog.dart';
import 'core/presentation/puzzle_hub_components.dart';
import 'core/presentation/puzzle_interaction_feedback.dart';
import 'core/presentation/rewarded_hint_dialog.dart';
import 'features/hitori/domain/hitori_generator.dart';
import 'features/hitori/domain/hitori_catalog.dart';
import 'features/hitori/domain/hitori_puzzle.dart';
import 'game_storage.dart';

class SavedHitoriGame {
  const SavedHitoriGame({
    required this.puzzle,
    required this.marks,
    required this.elapsedSeconds,
    required this.moves,
    required this.hintsRemaining,
    this.hintsUsed = 0,
    this.rewardedHints = 0,
    this.mode = GameMode.generated,
  });

  final HitoriPuzzle puzzle;
  final Map<HitoriCell, HitoriCellMark> marks;
  final int elapsedSeconds;
  final int moves;
  final int hintsRemaining;
  final int hintsUsed;
  final int rewardedHints;
  final GameMode mode;

  Map<String, Object?> toJson() => {
        'version': 1,
        'puzzle': {
          'id': puzzle.id,
          'title': puzzle.title,
          'grid': puzzle.grid,
          'difficulty': puzzle.difficulty.name,
          'solution': [
            for (final cell in puzzle.solution) '${cell.$1}:${cell.$2}'
          ],
        },
        'marks': {
          for (final entry in marks.entries)
            '${entry.key.$1}:${entry.key.$2}': entry.value.name,
        },
        'elapsedSeconds': elapsedSeconds,
        'moves': moves,
        'hintsRemaining': hintsRemaining,
        'hintsUsed': hintsUsed,
        'rewardedHints': rewardedHints,
        'mode': mode.name,
      };

  factory SavedHitoriGame.fromJson(Map<String, Object?> json) {
    if (json['version'] != 1) throw const FormatException('Invalid save.');
    HitoriCell cellFrom(String raw) {
      final parts = raw.split(':');
      return (int.parse(parts[0]), int.parse(parts[1]));
    }

    final rawPuzzle = Map<String, Object?>.from(json['puzzle']! as Map);
    final puzzle = HitoriPuzzle(
      id: rawPuzzle['id']! as String,
      title: rawPuzzle['title']! as String,
      grid: [
        for (final row in rawPuzzle['grid']! as List)
          [for (final value in row as List) value as int],
      ],
      solution: {
        for (final raw in rawPuzzle['solution']! as List)
          cellFrom(raw as String),
      },
      difficulty: PuzzleDifficulty.values.byName(
        rawPuzzle['difficulty']! as String,
      ),
    );
    return SavedHitoriGame(
      puzzle: puzzle,
      marks: {
        for (final entry
            in Map<String, Object?>.from(json['marks']! as Map).entries)
          cellFrom(entry.key):
              HitoriCellMark.values.byName(entry.value! as String),
      },
      elapsedSeconds: json['elapsedSeconds']! as int,
      moves: json['moves']! as int,
      hintsRemaining: json['hintsRemaining']! as int,
      hintsUsed: json['hintsUsed'] as int? ?? 0,
      rewardedHints: json['rewardedHints'] as int? ?? 0,
      mode: GameMode.values.byName(
        json['mode'] as String? ?? GameMode.generated.name,
      ),
    );
  }
}

class HitoriGameStore {
  static const _key = 'active_hitori_game_v1';

  Future<void> save(SavedHitoriGame game) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, jsonEncode(game.toJson()));
  }

  Future<SavedHitoriGame?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null) return null;
    try {
      final saved = SavedHitoriGame.fromJson(
        Map<String, Object?>.from(jsonDecode(raw) as Map),
      );
      if (HitoriState(puzzle: saved.puzzle, marks: saved.marks).isSolved) {
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

class HitoriHubScreen extends StatefulWidget {
  const HitoriHubScreen({
    this.onOpenDaily,
    this.onOpenStatistics,
    super.key,
  });

  final void Function(BuildContext context)? onOpenDaily;
  final void Function(BuildContext context)? onOpenStatistics;

  @override
  State<HitoriHubScreen> createState() => _HitoriHubScreenState();
}

class _HitoriHubScreenState extends State<HitoriHubScreen> {
  SavedHitoriGame? _saved;
  Map<String, PuzzleResult> _results = const {};

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final saved = await HitoriGameStore().load();
    final results = await GameStorage().loadResults();
    if (mounted) {
      setState(() {
        _saved = saved;
        _results = results;
      });
    }
  }

  bool _isSolved(HitoriPuzzle puzzle) =>
      _results.containsKey('${GameType.hitori.name}:${puzzle.id}');

  Future<void> _open(
    HitoriPuzzle puzzle, {
    SavedHitoriGame? saved,
    GameMode mode = GameMode.generated,
  }) async {
    if (saved == null && _saved != null) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.save_outlined),
          title: const Text('Offenes Hitori-Rätsel'),
          content: const Text(
            'Möchtest du dein begonnenes Rätsel fortsetzen oder ein neues beginnen?',
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
        return _open(current.puzzle, saved: current, mode: current.mode);
      }
      await HitoriGameStore().clear();
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HitoriGameScreen(
          puzzle: puzzle,
          savedGame: saved,
          mode: saved?.mode ?? mode,
        ),
      ),
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.gameColors['hitori']!;
    final solved = hitoriPuzzleCatalog.where(_isSolved).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Hitori')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_saved case final saved?) ...[
              PuzzleHubAction(
                icon: Icons.play_circle_outline_rounded,
                title: 'Rätsel fortsetzen',
                subtitle:
                    '${saved.puzzle.difficulty.label} · ${saved.puzzle.size} × '
                    '${saved.puzzle.size} · ${_formatTime(saved.elapsedSeconds)}',
                accent: accent,
                prominent: true,
                onTap: () => _open(saved.puzzle, saved: saved),
              ),
              const SizedBox(height: 20),
            ],
            PuzzleHubHeader(
              icon: Icons.filter_b_and_w_rounded,
              title: 'Finde die einzelnen Zahlen',
              description:
                  'Schwärze doppelte Zahlen. Schwarze Felder dürfen sich nicht '
                  'berühren und alle hellen Felder bleiben verbunden.',
              accent: accent,
              progress: solved / hitoriPuzzleCatalog.length,
              progressLabel:
                  'Sammlungsfortschritt: $solved von ${hitoriPuzzleCatalog.length}',
            ),
            if (widget.onOpenDaily != null) ...[
              const SizedBox(height: 20),
              PuzzleHubAction(
                icon: Icons.calendar_month_outlined,
                title: 'Tagesrätsel & Kalender',
                subtitle: 'Heute lösen oder verpasste Tage nachholen',
                accent: accent,
                onTap: () => widget.onOpenDaily!(context),
              ),
            ],
            if (widget.onOpenStatistics != null) ...[
              const SizedBox(height: 12),
            ],
            PuzzleHubAction(
              icon: Icons.apps_rounded,
              title: 'Rätselsammlung',
              subtitle:
                  '${hitoriPuzzleCatalog.length} handverlesene Hitori-Rätsel',
              accent: accent,
              onTap: () async {
                await Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => _HitoriCollectionScreen(
                    isSolved: _isSolved,
                    onOpen: (puzzle) => _open(puzzle, mode: GameMode.catalog),
                  ),
                ));
                await _refresh();
              },
            ),
            const SizedBox(height: 12),
            PuzzleHubAction(
              icon: Icons.auto_awesome_rounded,
              title: 'Zufallsrätsel',
              subtitle: 'Größe und Schwierigkeit auswählen',
              accent: accent,
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => _HitoriRandomScreen(onOpen: _open),
              )),
            ),
            if (widget.onOpenStatistics != null) ...[
              const SizedBox(height: 12),
              PuzzleHubAction(
                icon: Icons.query_stats_rounded,
                title: 'Hitori-Statistik',
                subtitle: 'Bestzeiten, Spielzeit und Lösungswege',
                accent: accent,
                onTap: () => widget.onOpenStatistics!(context),
              ),
            ],
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () =>
                  Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const HitoriRulesScreen(),
              )),
              icon: const Icon(Icons.menu_book_rounded),
              label: const Text('Regeln ansehen'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HitoriCollectionScreen extends StatelessWidget {
  const _HitoriCollectionScreen({required this.isSolved, required this.onOpen});
  final bool Function(HitoriPuzzle puzzle) isSolved;
  final Future<void> Function(HitoriPuzzle puzzle) onOpen;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Hitori-Rätselsammlung')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            for (final chapter in hitoriChapters)
              Card(
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  leading: CircleAvatar(child: Text('${chapter.number}')),
                  title: Text(chapter.title),
                  subtitle: Text('${chapter.subtitle}\n'
                      '${chapter.puzzles.where(isSolved).length} von ${chapter.puzzles.length} gelöst'),
                  children: [
                    for (var index = 0; index < chapter.puzzles.length; index++)
                      ListTile(
                        leading: CircleAvatar(
                          child: isSolved(chapter.puzzles[index])
                              ? const Icon(Icons.check_rounded)
                              : Text('${index + 1}'),
                        ),
                        title: Text(chapter.puzzles[index].title),
                        subtitle: Text(
                            '${chapter.puzzles[index].size} × ${chapter.puzzles[index].size}'),
                        trailing: const Icon(Icons.play_arrow_rounded),
                        onTap: () => onOpen(chapter.puzzles[index]),
                      ),
                  ],
                ),
              ),
          ],
        ),
      );
}

class _HitoriRandomScreen extends StatelessWidget {
  const _HitoriRandomScreen({required this.onOpen});
  final Future<void> Function(HitoriPuzzle puzzle) onOpen;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Hitori-Zufallsrätsel')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            for (final difficulty in PuzzleDifficulty.values)
              Card(
                child: ListTile(
                  minTileHeight: 82,
                  leading: CircleAvatar(child: Text('${5 + difficulty.index}')),
                  title: Text(difficulty.label),
                  subtitle: Text(
                      '${difficulty.description} · ${5 + difficulty.index} × ${5 + difficulty.index}'),
                  trailing: const Icon(Icons.play_arrow_rounded),
                  onTap: () => onOpen(const HitoriGenerator().generate(
                    seed: DateTime.now().microsecondsSinceEpoch,
                    difficulty: difficulty,
                  )),
                ),
              ),
          ],
        ),
      );
}

class HitoriRulesScreen extends StatelessWidget {
  const HitoriRulesScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Hitori-Regeln')),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: const [
            _HitoriRule(
                number: '1',
                title: 'Doppelte Zahlen entfernen',
                text:
                    'In jeder Zeile und Spalte darf jede Zahl nur einmal hell bleiben.'),
            SizedBox(height: 18),
            _HitoriRule(
                number: '2',
                title: 'Schwarze Felder trennen',
                text:
                    'Zwei schwarze Felder dürfen sich niemals oben, unten, links oder rechts berühren.'),
            SizedBox(height: 18),
            _HitoriRule(
                number: '3',
                title: 'Helle Fläche verbinden',
                text:
                    'Alle hell gebliebenen Felder müssen einen einzigen zusammenhängenden Bereich bilden.'),
            SizedBox(height: 24),
            Text('Tippen: offen → schwärzen → als sicher markieren → offen'),
          ],
        ),
      );
}

class HitoriGameScreen extends StatefulWidget {
  const HitoriGameScreen({
    required this.puzzle,
    this.savedGame,
    this.mode = GameMode.generated,
    super.key,
  });

  final HitoriPuzzle puzzle;
  final SavedHitoriGame? savedGame;
  final GameMode mode;

  @override
  State<HitoriGameScreen> createState() => _HitoriGameScreenState();
}

class _HitoriGameScreenState extends State<HitoriGameScreen>
    with WidgetsBindingObserver {
  static const _guideSeenKey = 'hitori_rules_guide_seen_v1';
  late HitoriState _state;
  final _history = <HitoriState>[];
  final _redo = <HitoriState>[];
  final _store = HitoriGameStore();
  Timer? _timer;
  Timer? _hintHighlightTimer;
  int _elapsedSeconds = 0;
  int _moves = 0;
  int _hintsRemaining = 3;
  int _hintsUsed = 0;
  int _rewardedHints = 0;
  bool _completionShown = false;
  bool _showConflicts = true;
  HitoriCell? _hintHighlight;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final saved = widget.savedGame;
    _state = HitoriState(puzzle: widget.puzzle, marks: saved?.marks);
    _elapsedSeconds = saved?.elapsedSeconds ?? 0;
    _moves = saved?.moves ?? 0;
    _hintsRemaining = saved?.hintsRemaining ?? 3;
    _hintsUsed = saved?.hintsUsed ?? 0;
    _rewardedHints = saved?.rewardedHints ?? 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_completionShown) {
        setState(() => _elapsedSeconds++);
        if (_elapsedSeconds % 5 == 0) unawaited(_save());
      }
    });
    unawaited(_save());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_showRulesGuide());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!_completionShown) unawaited(_save());
    _timer?.cancel();
    _hintHighlightTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      if (!_completionShown) unawaited(_save());
    }
  }

  Future<void> _save() => _store.save(SavedHitoriGame(
        puzzle: widget.puzzle,
        marks: _state.marks,
        elapsedSeconds: _elapsedSeconds,
        moves: _moves,
        hintsRemaining: _hintsRemaining,
        hintsUsed: _hintsUsed,
        rewardedHints: _rewardedHints,
        mode: widget.mode,
      ));

  Future<void> _showRulesGuide({bool force = false}) async {
    final preferences = await SharedPreferences.getInstance();
    if (!force && (preferences.getBool(_guideSeenKey) ?? false)) return;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.school_outlined),
        title: const Text('So funktioniert Hitori'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HitoriRule(
                number: '1',
                title: 'Doppelte Zahlen entfernen',
                text:
                    'In jeder Zeile und Spalte darf jede Zahl nur einmal hell bleiben.',
              ),
              SizedBox(height: 14),
              _HitoriRule(
                number: '2',
                title: 'Schwarze Felder trennen',
                text:
                    'Zwei schwarze Felder dürfen sich niemals oben, unten, links oder rechts berühren.',
              ),
              SizedBox(height: 14),
              _HitoriRule(
                number: '3',
                title: 'Helle Fläche verbinden',
                text:
                    'Alle hell gebliebenen Felder müssen einen einzigen zusammenhängenden Bereich bilden.',
              ),
              SizedBox(height: 18),
              Text(
                'Tippen: offen → schwärzen → als sicher markieren → offen',
              ),
            ],
          ),
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

  void _cycle(int row, int column) {
    if (_completionShown) return;
    PuzzleInteractionFeedback.selection(context);
    _hintHighlightTimer?.cancel();
    setState(() {
      _hintHighlight = null;
      _history.add(_state);
      _state = _state.cycle(row, column);
      _redo.clear();
      _moves++;
    });
    unawaited(_save());
    if (_state.isSolved) unawaited(_complete());
  }

  void _undo() {
    if (_history.isEmpty || _completionShown) return;
    _hintHighlightTimer?.cancel();
    setState(() {
      _hintHighlight = null;
      _redo.add(_state);
      _state = _history.removeLast();
      if (_moves > 0) _moves--;
    });
    unawaited(_save());
  }

  void _redoMove() {
    if (_redo.isEmpty || _completionShown) return;
    _hintHighlightTimer?.cancel();
    setState(() {
      _hintHighlight = null;
      _history.add(_state);
      _state = _redo.removeLast();
      _moves++;
    });
    unawaited(_save());
  }

  Future<void> _restart() async {
    if (!await confirmPuzzleRestart(context) || !mounted) return;
    _hintHighlightTimer?.cancel();
    setState(() {
      _history.add(_state);
      _state = HitoriState(puzzle: widget.puzzle);
      _redo.clear();
      _elapsedSeconds = 0;
      _moves = 0;
      _hintsRemaining = 3;
      _hintsUsed = 0;
      _rewardedHints = 0;
      _completionShown = false;
      _hintHighlight = null;
    });
    unawaited(_save());
  }

  Future<void> _hint() async {
    if (_completionShown) return;
    final premium =
        PreferencesScope.maybeOf(context)?.premiumSimulationEnabled ?? false;
    if (!premium && _hintsRemaining <= 0) {
      if (!await showRewardedHintSimulation(context) || !mounted) return;
      setState(() {
        _hintsRemaining++;
        _rewardedHints++;
      });
      unawaited(_save());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ein zusätzlicher Tipp ist verfügbar.')),
      );
      return;
    }
    HitoriCell? target;
    for (var row = 0; row < widget.puzzle.size && target == null; row++) {
      for (var column = 0; column < widget.puzzle.size; column++) {
        final shouldShade = widget.puzzle.solution.contains((row, column));
        if (_state.isShaded(row, column) != shouldShade) {
          target = (row, column);
          break;
        }
      }
    }
    if (target == null) return;
    final cell = target;
    final shade = widget.puzzle.solution.contains(cell);
    final hintText = _hintExplanation(cell, shade: shade);
    final apply = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.lightbulb_outline_rounded),
        title: Text(hintText.title),
        content: Text(hintText.explanation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Auf dem Brett zeigen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hinweis anwenden'),
          ),
        ],
      ),
    );
    if (apply == null || !mounted) return;
    if (!apply) {
      _hintHighlightTimer?.cancel();
      setState(() {
        _hintHighlight = cell;
        if (!premium) _hintsRemaining--;
        _hintsUsed++;
        PuzzleInteractionFeedback.hint(context);
      });
      _hintHighlightTimer = Timer(const Duration(seconds: 5), () {
        if (mounted && _hintHighlight == cell) {
          setState(() => _hintHighlight = null);
        }
      });
      unawaited(_save());
      return;
    }
    _hintHighlightTimer?.cancel();
    setState(() {
      _hintHighlight = null;
      _history.add(_state);
      final marks = Map<HitoriCell, HitoriCellMark>.from(_state.marks)
        ..[cell] = shade ? HitoriCellMark.shaded : HitoriCellMark.protected;
      _state = HitoriState(puzzle: widget.puzzle, marks: marks);
      if (!premium) _hintsRemaining--;
      _hintsUsed++;
      PuzzleInteractionFeedback.hint(context);
      _moves++;
      _redo.clear();
    });
    unawaited(_save());
    if (_state.isSolved) unawaited(_complete());
  }

  ({String title, String explanation}) _hintExplanation(
    HitoriCell cell, {
    required bool shade,
  }) {
    final value = widget.puzzle.grid[cell.$1][cell.$2];
    if (!shade) {
      return (
        title: 'Helles Feld sichern',
        explanation: 'Feld ${cell.$1 + 1}/${cell.$2 + 1} darf nicht schwarz '
            'bleiben. Andernfalls würden sich schwarze Felder berühren oder '
            'der helle Bereich getrennt. Markiere es als sicher.',
      );
    }
    final sameRow = <int>[
      for (var column = 0; column < widget.puzzle.size; column++)
        if (column != cell.$2 && widget.puzzle.grid[cell.$1][column] == value)
          column,
    ];
    final sameColumn = <int>[
      for (var row = 0; row < widget.puzzle.size; row++)
        if (row != cell.$1 && widget.puzzle.grid[row][cell.$2] == value) row,
    ];
    final location = sameRow.isNotEmpty
        ? 'Zeile ${cell.$1 + 1}'
        : sameColumn.isNotEmpty
            ? 'Spalte ${cell.$2 + 1}'
            : 'diesem Bereich';
    return (
      title: 'Doppelte $value in $location',
      explanation: 'Die Zahl $value kommt in $location mehrfach vor. Prüfe '
          'zusätzlich die benachbarten Felder und die Verbindung der hellen '
          'Fläche: Feld ${cell.$1 + 1}/${cell.$2 + 1} muss geschwärzt werden.',
    );
  }

  void _debugSolve({required bool almost}) {
    final solution = widget.puzzle.solution.toList();
    final leave = almost && solution.isNotEmpty ? solution.last : null;
    setState(() {
      _hintHighlight = null;
      _history.add(_state);
      _state = HitoriState(
        puzzle: widget.puzzle,
        marks: {
          for (final cell in solution)
            if (cell != leave) cell: HitoriCellMark.shaded,
        },
      );
      _redo.clear();
    });
    if (!almost) unawaited(_complete(testCompletion: true));
  }

  Future<void> _complete({bool testCompletion = false}) async {
    if (_completionShown) return;
    setState(() => _completionShown = true);
    PuzzleInteractionFeedback.success(context);
    final countsForTesting = testCompletion && widget.mode == GameMode.daily;
    if (!testCompletion || countsForTesting) {
      await GameStorage().recordCompletion(
        puzzleId: widget.puzzle.id,
        elapsedSeconds: _elapsedSeconds,
        source: widget.mode,
        difficulty: widget.puzzle.difficulty,
        boardSize: widget.puzzle.size,
        gameType: GameType.hitori,
        moves: _moves,
        hintsUsed: _hintsUsed,
        rewardedHints: _rewardedHints,
        dailyPuzzleData: widget.mode == GameMode.daily
            ? {
                'kind': 'hitori',
                'grid': widget.puzzle.grid,
                'shaded': [
                  for (final cell in widget.puzzle.solution) [cell.$1, cell.$2],
                ],
              }
            : null,
      );
    }
    await _store.clear();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.emoji_events_outlined),
        title: const Text('Hitori gelöst!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Alle Zahlen und Flächenregeln stimmen.'),
            const SizedBox(height: 12),
            Text('${_formatTime(_elapsedSeconds)} · $_moves Züge'),
            if (testCompletion) ...[
              const SizedBox(height: 8),
              Text(
                countsForTesting
                    ? 'Testabschluss · im Kalender gewertet'
                    : 'Testabschluss · keine Statistik',
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Brett ansehen'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: Text(
              widget.mode == GameMode.daily
                  ? 'Zum Kalender'
                  : 'Hitori verlassen',
            ),
          ),
          if (widget.mode != GameMode.daily)
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _openNextPuzzle();
              },
              child: Text(
                _nextActionLabel,
              ),
            ),
        ],
      ),
    );
  }

  HitoriPuzzle? get _nextCatalogPuzzle {
    final index = hitoriPuzzleCatalog
        .indexWhere((puzzle) => puzzle.id == widget.puzzle.id);
    if (index < 0 || index + 1 >= hitoriPuzzleCatalog.length) return null;
    return hitoriPuzzleCatalog[index + 1];
  }

  String get _nextActionLabel {
    if (widget.mode == GameMode.generated) return 'Noch eins';
    final next = _nextCatalogPuzzle;
    if (next == null) return 'Zur Sammlung';
    return next.difficulty == widget.puzzle.difficulty
        ? 'Nächstes Rätsel'
        : 'Nächstes Kapitel';
  }

  String get _screenTitle => switch (widget.mode) {
        GameMode.catalog =>
          '${widget.puzzle.difficulty.label} · ${widget.puzzle.title}',
        GameMode.daily => 'Tagesrätsel · ${widget.puzzle.difficulty.label}',
        _ => '${widget.puzzle.difficulty.label} · Hitori',
      };

  void _openNextPuzzle() {
    if (widget.mode == GameMode.catalog && _nextCatalogPuzzle == null) {
      Navigator.pop(context);
      return;
    }
    final puzzle = widget.mode == GameMode.catalog
        ? _nextCatalogPuzzle!
        : const HitoriGenerator().generate(
            seed: DateTime.now().microsecondsSinceEpoch,
            difficulty: widget.puzzle.difficulty,
          );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => HitoriGameScreen(puzzle: puzzle, mode: widget.mode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final premium =
        PreferencesScope.maybeOf(context)?.premiumSimulationEnabled ?? false;
    final duplicate =
        _showConflicts ? _state.protectedDuplicateConflicts : <HitoriCell>{};
    final adjacent =
        _showConflicts ? _state.adjacentShadeConflicts : <HitoriCell>{};
    return Scaffold(
      appBar: AppBar(
        title: Text(_screenTitle),
        actions: [
          if (kDebugMode)
            PopupMenuButton<String>(
              tooltip: 'Testwerkzeuge',
              icon: const Icon(Icons.bug_report_outlined),
              onSelected: (value) => _debugSolve(almost: value == 'almost'),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'almost', child: Text('Fast lösen')),
                PopupMenuItem(value: 'solve', child: Text('Sofort lösen')),
              ],
            ),
          IconButton(
            tooltip: 'Rückgängig',
            onPressed: _history.isEmpty ? null : _undo,
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            tooltip: 'Wiederholen',
            onPressed: _redo.isEmpty ? null : _redoMove,
            icon: const Icon(Icons.redo_rounded),
          ),
          IconButton(
            tooltip: 'Neu starten',
            onPressed: _restart,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
          IconButton(
            tooltip: 'Spielhilfen',
            onPressed: () => showPuzzleGameOptions(context, children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Regelfehler markieren'),
                subtitle: const Text(
                    'Markiert doppelte Zahlen und benachbarte schwarze Felder.'),
                value: _showConflicts,
                onChanged: (value) {
                  setState(() => _showConflicts = value);
                  Navigator.pop(context);
                },
              ),
            ]),
            icon: const Icon(Icons.tune_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(Icons.timer_outlined, size: 18),
                    label: Text(_formatTime(_elapsedSeconds)),
                  ),
                  Chip(
                    avatar: const Icon(Icons.touch_app_outlined, size: 18),
                    label: Text('$_moves Züge'),
                  ),
                  PuzzleGameStatusChip(
                    icon: Icons.lightbulb_outline,
                    label: premium ? 'Premium' : '$_hintsRemaining Tipps',
                    onTap: _hint,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Tippen: offen → schwärzen → als sicher markieren'),
              const SizedBox(height: 18),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: widget.puzzle.size,
                    ),
                    itemCount: widget.puzzle.size * widget.puzzle.size,
                    itemBuilder: (context, index) {
                      final row = index ~/ widget.puzzle.size;
                      final column = index % widget.puzzle.size;
                      final mark = _state.markAt(row, column);
                      final conflict = duplicate.contains((row, column)) ||
                          adjacent.contains((row, column));
                      final isHintTarget = _hintHighlight == (row, column);
                      final scheme = Theme.of(context).colorScheme;
                      final isDark =
                          Theme.of(context).brightness == Brightness.dark;
                      final palette = AppTheme.boardPalette(
                        'hitori',
                        Theme.of(context).brightness,
                      );
                      final cellColor = conflict
                          ? scheme.errorContainer
                          : switch (mark) {
                              HitoriCellMark.shaded => isDark
                                  ? const Color(0xFF020204)
                                  : const Color(0xFF111015),
                              HitoriCellMark.protected => Color.alphaBlend(
                                  palette.accent.withValues(alpha: 0.24),
                                  palette.cellStrong,
                                ),
                              HitoriCellMark.open => palette.cell,
                            };
                      final borderColor = isHintTarget
                          ? palette.accentAlt
                          : conflict
                              ? scheme.error
                              : switch (mark) {
                                  HitoriCellMark.shaded => isDark
                                      ? palette.muted
                                      : const Color(0xFF303840),
                                  HitoriCellMark.protected => palette.accent,
                                  HitoriCellMark.open => palette.muted
                                      .withValues(alpha: isDark ? 0.68 : 0.48),
                                };
                      return Padding(
                        padding: const EdgeInsets.all(2),
                        child: Semantics(
                          key: ValueKey(
                            'hitori-cell-state-$row-$column-${mark.name}',
                          ),
                          label: '${switch (mark) {
                            HitoriCellMark.open => 'Feld offen',
                            HitoriCellMark.shaded => 'Feld geschwärzt',
                            HitoriCellMark.protected =>
                              'Feld als sicher markiert',
                          }}${isHintTarget ? ', Hinweisziel' : ''}',
                          button: true,
                          child: DecoratedBox(
                            key: isHintTarget
                                ? ValueKey(
                                    'hitori-hint-highlight-$row-$column',
                                  )
                                : null,
                            decoration: BoxDecoration(
                              color: cellColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: borderColor,
                                width: isHintTarget
                                    ? 3
                                    : mark == HitoriCellMark.open
                                        ? 1
                                        : 1.5,
                              ),
                              boxShadow: isHintTarget
                                  ? [
                                      BoxShadow(
                                        color: palette.accentAlt
                                            .withValues(alpha: 0.45),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                key: ValueKey('hitori-cell-$row-$column'),
                                onTap: () => _cycle(row, column),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Text(
                                      '${widget.puzzle.grid[row][column]}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: mark == HitoriCellMark.shaded
                                                ? Colors.white54
                                                : palette.foreground,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    if (mark == HitoriCellMark.protected)
                                      Positioned(
                                        right: 5,
                                        top: 5,
                                        child: Icon(
                                          Icons.check_circle_outline_rounded,
                                          size: 14,
                                          color: palette.accent,
                                        ),
                                      ),
                                    if (isHintTarget)
                                      Positioned(
                                        left: 5,
                                        top: 5,
                                        child: Icon(
                                          Icons.lightbulb_rounded,
                                          size: 15,
                                          color: palette.accentAlt,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (_completionShown) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: widget.mode == GameMode.daily
                        ? () => Navigator.pop(context)
                        : _openNextPuzzle,
                    icon: Icon(widget.mode == GameMode.daily
                        ? Icons.calendar_month_outlined
                        : widget.mode == GameMode.catalog
                            ? Icons.skip_next_rounded
                            : Icons.auto_awesome_rounded),
                    label: Text(widget.mode == GameMode.daily
                        ? 'Zum Kalender'
                        : widget.mode == GameMode.catalog
                            ? _nextActionLabel
                            : 'Noch ein Hitori'),
                  ),
                ),
              ],
              PuzzleGameRulesButton(
                onPressed: () => _showRulesGuide(force: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HitoriRule extends StatelessWidget {
  const _HitoriRule({
    required this.number,
    required this.title,
    required this.text,
  });

  final String number;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 15, child: Text(number)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(text),
              ],
            ),
          ),
        ],
      );
}

String _formatTime(int seconds) {
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  return '$minutes:${rest.toString().padLeft(2, '0')}';
}
