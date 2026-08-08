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
import 'features/tents/domain/tents_generator.dart';
import 'features/tents/domain/tents_catalog.dart';
import 'features/tents/domain/tents_puzzle.dart';
import 'features/tents/domain/tents_solver.dart';
import 'game_storage.dart';

class SavedTentsGame {
  const SavedTentsGame({
    required this.puzzle,
    required this.marks,
    required this.elapsedSeconds,
    required this.moves,
    this.hintsRemaining = 3,
    this.hintsUsed = 0,
    this.rewardedHints = 0,
    this.autoGrass = false,
    this.mode = GameMode.generated,
  });
  final TentsPuzzle puzzle;
  final Map<TentsCell, TentsCellMark> marks;
  final int elapsedSeconds;
  final int moves;
  final int hintsRemaining;
  final int hintsUsed;
  final int rewardedHints;
  final bool autoGrass;
  final GameMode mode;

  Map<String, Object?> toJson() => {
        'version': 1,
        'id': puzzle.id,
        'title': puzzle.title,
        'size': puzzle.size,
        'difficulty': puzzle.difficulty.name,
        'trees': [
          for (final c in puzzle.trees) [c.$1, c.$2]
        ],
        'rows': puzzle.rowCounts,
        'columns': puzzle.columnCounts,
        'solution': [
          for (final c in puzzle.solution) [c.$1, c.$2]
        ],
        'marks': [
          for (final e in marks.entries) [e.key.$1, e.key.$2, e.value.name]
        ],
        'elapsedSeconds': elapsedSeconds,
        'moves': moves,
        'hintsRemaining': hintsRemaining,
        'hintsUsed': hintsUsed,
        'rewardedHints': rewardedHints,
        'autoGrass': autoGrass,
        'mode': mode.name,
      };

  factory SavedTentsGame.fromJson(Map<String, Object?> json) {
    TentsCell cell(Object? raw) {
      final values = raw! as List;
      return (values[0] as int, values[1] as int);
    }

    final puzzle = TentsPuzzle(
      id: json['id']! as String,
      title: json['title']! as String,
      size: json['size']! as int,
      difficulty: PuzzleDifficulty.values.byName(json['difficulty']! as String),
      trees: (json['trees']! as List).map(cell).toSet(),
      rowCounts: (json['rows']! as List).cast<int>(),
      columnCounts: (json['columns']! as List).cast<int>(),
      solution: (json['solution']! as List).map(cell).toSet(),
    );
    return SavedTentsGame(
      puzzle: puzzle,
      marks: {
        for (final raw in json['marks']! as List)
          ((raw as List)[0] as int, raw[1] as int):
              TentsCellMark.values.byName(raw[2] as String),
      },
      elapsedSeconds: json['elapsedSeconds']! as int,
      moves: json['moves']! as int,
      hintsRemaining: json['hintsRemaining'] as int? ?? 3,
      hintsUsed: json['hintsUsed'] as int? ?? 0,
      rewardedHints: json['rewardedHints'] as int? ?? 0,
      autoGrass: json['autoGrass'] as bool? ?? false,
      mode: GameMode.values
          .byName(json['mode'] as String? ?? GameMode.generated.name),
    );
  }
}

class TentsGameStore {
  static const _key = 'active_tents_game_v1';
  Future<void> save(SavedTentsGame game) async =>
      (await SharedPreferences.getInstance())
          .setString(_key, jsonEncode(game.toJson()));
  Future<SavedTentsGame?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null) return null;
    try {
      final saved = SavedTentsGame.fromJson(
          Map<String, Object?>.from(jsonDecode(raw) as Map));
      if (TentsState(puzzle: saved.puzzle, marks: saved.marks).isSolved) {
        await clear();
        return null;
      }
      return saved;
    } on Object {
      await clear();
      return null;
    }
  }

  Future<void> clear() async =>
      (await SharedPreferences.getInstance()).remove(_key);
}

class TentsHubScreen extends StatefulWidget {
  const TentsHubScreen({this.onOpenDaily, this.onOpenStatistics, super.key});
  final void Function(BuildContext context)? onOpenDaily;
  final void Function(BuildContext context)? onOpenStatistics;
  @override
  State<TentsHubScreen> createState() => _TentsHubScreenState();
}

class _TentsHubScreenState extends State<TentsHubScreen> {
  SavedTentsGame? _saved;
  Set<String> _completedIds = const {};
  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final saved = await TentsGameStore().load();
    final results = await GameStorage().loadResults();
    if (mounted) {
      setState(() {
        _saved = saved;
        _completedIds = results.keys
            .where((key) => key.startsWith('${GameType.tents.name}:'))
            .map((key) => key.substring('${GameType.tents.name}:'.length))
            .toSet();
      });
    }
  }

  Future<void> _open(PuzzleDifficulty difficulty,
      {SavedTentsGame? saved,
      TentsPuzzle? selectedPuzzle,
      GameMode mode = GameMode.generated}) async {
    if (saved == null && _saved != null) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          icon: const Icon(Icons.save_outlined),
          title: const Text('Offenes R\u00e4tsel'),
          content: const Text(
            'Du hast bereits ein begonnenes Lager. M\u00f6chtest du es '
            'fortsetzen oder wirklich ein neues beginnen?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Fortsetzen'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Neu beginnen'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (replace != true) {
        return _open(_saved!.puzzle.difficulty,
            saved: _saved, mode: _saved!.mode);
      }
      await TentsGameStore().clear();
    }
    final puzzle = saved?.puzzle ??
        selectedPuzzle ??
        const TentsGenerator().generate(
            seed: DateTime.now().microsecondsSinceEpoch,
            difficulty: difficulty);
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => TentsGameScreen(
            puzzle: puzzle, savedGame: saved, mode: saved?.mode ?? mode)));
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppTheme.gameColors['tents']!;
    return Scaffold(
      appBar: AppBar(title: const Text('Zelte & B\u00e4ume')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (_saved case final saved?) ...[
            PuzzleHubAction(
              icon: Icons.play_circle_outline_rounded,
              title: 'Rätsel fortsetzen',
              subtitle:
                  '${saved.puzzle.difficulty.label} · ${saved.puzzle.size} × ${saved.puzzle.size}',
              accent: accent,
              prominent: true,
              onTap: () => _open(saved.puzzle.difficulty,
                  saved: saved, mode: saved.mode),
            ),
            const SizedBox(height: 16),
          ],
          PuzzleHubHeader(
            icon: Icons.park_rounded,
            title: 'Plane ein ruhiges Waldlager',
            description: 'Ordne jedem Baum genau ein Zelt zu. Jeder Start '
                'erzeugt ein neues, eindeutig lösbares Brett.',
            accent: accent,
            progress: _completedIds.length / tentsPuzzleCatalog.length,
            progressLabel:
                '${_completedIds.length} von ${tentsPuzzleCatalog.length} Expeditionen gelöst',
          ),
          const SizedBox(height: 20),
          if (widget.onOpenDaily != null) ...[
            PuzzleHubAction(
              icon: Icons.calendar_today_outlined,
              title: 'Tagesrätsel & Kalender',
              subtitle: 'Heute spielen oder vergangene Tage nachholen',
              accent: accent,
              onTap: () => widget.onOpenDaily!(context),
            ),
            const SizedBox(height: 12),
          ],
          PuzzleHubAction(
            icon: Icons.apps_rounded,
            title: 'Rätselsammlung',
            subtitle:
                '${tentsPuzzleCatalog.length} feste Expeditionen entdecken',
            accent: accent,
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => _TentsCollectionScreen(
                  completedIds: _completedIds,
                  onOpen: (puzzle) => _open(puzzle.difficulty,
                      selectedPuzzle: puzzle, mode: GameMode.catalog),
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
              builder: (_) => _TentsRandomScreen(onOpen: _open),
            )),
          ),
          if (widget.onOpenStatistics != null) ...[
            const SizedBox(height: 12),
            PuzzleHubAction(
              icon: Icons.query_stats_outlined,
              title: 'Zelte-&-Bäume-Statistik',
              subtitle: 'Bestzeiten, Spielzeit und Expeditionen',
              accent: accent,
              onTap: () => widget.onOpenStatistics!(context),
            ),
          ],
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => const PuzzleRulesScreen(
                title: 'Zelte & Bäume',
                introduction:
                    'Bilde eindeutige Paare aus jeweils einem Baum und einem Zelt.',
                rules: [
                  'Jeder Baum erhält genau ein Zelt auf einem direkt waagerecht oder senkrecht benachbarten Feld.',
                  'Jedes Zelt gehört genau zu einem Baum. Zelte dürfen sich auch diagonal nicht berühren.',
                  'Die Zahlen am Rand geben die genaue Zahl der Zelte in jeder Zeile und Spalte an.',
                ],
                interaction:
                    'Tippen wechselt ein freies Feld von leer zu Zelt, zu Gras und wieder zu leer.',
              ),
            )),
            icon: const Icon(Icons.menu_book_rounded),
            label: const Text('Regeln ansehen'),
          ),
        ]),
      ),
    );
  }
}

class _TentsCollectionScreen extends StatelessWidget {
  const _TentsCollectionScreen(
      {required this.completedIds, required this.onOpen});
  final Set<String> completedIds;
  final Future<void> Function(TentsPuzzle puzzle) onOpen;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Zelte-&-Bäume-Sammlung')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            for (final difficulty in PuzzleDifficulty.values)
              Card(
                child: ExpansionTile(
                  leading: CircleAvatar(child: Text('${difficulty.index + 1}')),
                  title: Text(tentsChapterTitles[difficulty]!),
                  subtitle: Text(
                    '${tentsPuzzleCatalog.where((p) => p.difficulty == difficulty && completedIds.contains(p.id)).length} von '
                    '${tentsPuzzleCatalog.where((p) => p.difficulty == difficulty).length} gelöst',
                  ),
                  children: [
                    for (final puzzle in tentsPuzzleCatalog
                        .where((p) => p.difficulty == difficulty))
                      ListTile(
                        leading: Icon(completedIds.contains(puzzle.id)
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded),
                        title: Text(puzzle.title),
                        subtitle: Text('${puzzle.size} × ${puzzle.size}'),
                        trailing: const Icon(Icons.play_arrow_rounded),
                        onTap: () => onOpen(puzzle),
                      ),
                  ],
                ),
              ),
          ],
        ),
      );
}

class _TentsRandomScreen extends StatelessWidget {
  const _TentsRandomScreen({required this.onOpen});
  final Future<void> Function(PuzzleDifficulty difficulty) onOpen;

  int _size(PuzzleDifficulty difficulty) => switch (difficulty) {
        PuzzleDifficulty.easy => 6,
        PuzzleDifficulty.medium => 8,
        PuzzleDifficulty.hard => 10,
      };

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Zelte-&-Bäume-Zufallsrätsel')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            for (final difficulty in PuzzleDifficulty.values)
              Card(
                child: ListTile(
                  minTileHeight: 82,
                  leading: Icon(switch (difficulty) {
                    PuzzleDifficulty.easy => Icons.eco_outlined,
                    PuzzleDifficulty.medium => Icons.park_outlined,
                    PuzzleDifficulty.hard => Icons.forest_outlined,
                  }),
                  title: Text(difficulty.label),
                  subtitle: Text('${_size(difficulty)} × ${_size(difficulty)}'),
                  trailing: const Icon(Icons.play_arrow_rounded),
                  onTap: () => onOpen(difficulty),
                ),
              ),
          ],
        ),
      );
}

class TentsGameScreen extends StatefulWidget {
  const TentsGameScreen({
    required this.puzzle,
    this.savedGame,
    this.mode = GameMode.generated,
    super.key,
  });
  final TentsPuzzle puzzle;
  final SavedTentsGame? savedGame;
  final GameMode mode;
  @override
  State<TentsGameScreen> createState() => _TentsGameScreenState();
}

class _TentsGameScreenState extends State<TentsGameScreen>
    with WidgetsBindingObserver {
  late TentsState _state;
  final _history = <TentsState>[];
  final _redo = <TentsState>[];
  Timer? _timer;
  int _elapsed = 0;
  int _moves = 0;
  bool _completed = false;
  bool _showConflicts = true;
  bool _autoGrass = false;
  int _hintsRemaining = 3;
  int _hintsUsed = 0;
  int _rewardedHints = 0;
  TentsCell? _hintHighlight;
  Timer? _hintHighlightTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _state = TentsState(puzzle: widget.puzzle, marks: widget.savedGame?.marks);
    _elapsed = widget.savedGame?.elapsedSeconds ?? 0;
    _moves = widget.savedGame?.moves ?? 0;
    _autoGrass = widget.savedGame?.autoGrass ?? false;
    _hintsRemaining = widget.savedGame?.hintsRemaining ?? 3;
    _hintsUsed = widget.savedGame?.hintsUsed ?? 0;
    _rewardedHints = widget.savedGame?.rewardedHints ?? 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_completed) {
        setState(() => _elapsed++);
        if (_elapsed % 5 == 0) unawaited(_save());
      }
    });
    unawaited(_save());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!_completed) unawaited(_save());
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
      if (!_completed) unawaited(_save());
    }
  }

  Future<void> _save() => TentsGameStore().save(SavedTentsGame(
      puzzle: widget.puzzle,
      marks: _state.marks,
      elapsedSeconds: _elapsed,
      moves: _moves,
      hintsRemaining: _hintsRemaining,
      hintsUsed: _hintsUsed,
      rewardedHints: _rewardedHints,
      autoGrass: _autoGrass,
      mode: widget.mode));
  void _tap(int row, int column) {
    if (_completed || widget.puzzle.trees.contains((row, column))) return;
    PuzzleInteractionFeedback.selection(context);
    setState(() {
      _history.add(_state);
      _state = _state.cycle(row, column);
      _redo.clear();
      _moves++;
    });
    unawaited(_save());
    if (_state.isSolved) unawaited(_finish(test: false));
  }

  void _undo() {
    if (_history.isEmpty) return;
    setState(() {
      _redo.add(_state);
      _state = _history.removeLast();
      _moves++;
    });
    unawaited(_save());
  }

  void _redoMove() {
    if (_redo.isEmpty) return;
    setState(() {
      _history.add(_state);
      _state = _redo.removeLast();
      _moves++;
    });
    unawaited(_save());
  }

  Future<void> _restart() async {
    if (!await confirmPuzzleRestart(context) || !mounted) return;
    setState(() {
      _history.add(_state);
      _state = TentsState(puzzle: widget.puzzle);
      _redo.clear();
      _elapsed = 0;
      _moves = 0;
      _completed = false;
      _hintsRemaining = 3;
      _hintsUsed = 0;
      _rewardedHints = 0;
      _hintHighlight = null;
    });
    await _save();
  }

  Set<TentsCell> _automaticGrassFor(TentsState state) {
    final grass = <TentsCell>{};
    final size = widget.puzzle.size;
    for (final tent in state.tents) {
      for (var row = tent.$1 - 1; row <= tent.$1 + 1; row++) {
        for (var column = tent.$2 - 1; column <= tent.$2 + 1; column++) {
          final cell = (row, column);
          if (row >= 0 &&
              row < size &&
              column >= 0 &&
              column < size &&
              cell != tent &&
              !widget.puzzle.trees.contains(cell) &&
              state.markAt(row, column) == TentsCellMark.unknown) {
            grass.add(cell);
          }
        }
      }
    }
    for (var index = 0; index < size; index++) {
      final rowFull = state.tents.where((cell) => cell.$1 == index).length ==
          widget.puzzle.rowCounts[index];
      final columnFull = state.tents.where((cell) => cell.$2 == index).length ==
          widget.puzzle.columnCounts[index];
      for (var other = 0; other < size; other++) {
        final rowCell = (index, other);
        final columnCell = (other, index);
        if (rowFull &&
            !widget.puzzle.trees.contains(rowCell) &&
            state.markAt(rowCell.$1, rowCell.$2) == TentsCellMark.unknown) {
          grass.add(rowCell);
        }
        if (columnFull &&
            !widget.puzzle.trees.contains(columnCell) &&
            state.markAt(columnCell.$1, columnCell.$2) ==
                TentsCellMark.unknown) {
          grass.add(columnCell);
        }
      }
    }
    return grass;
  }

  Future<void> _hint() async {
    if (_completed) return;
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
        const SnackBar(
            content: Text('Ein zus\u00e4tzlicher Tipp ist verf\u00fcgbar.')),
      );
      return;
    }
    final hint = _findHint();
    if (hint == null) return;
    final apply = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        icon: const Icon(Icons.lightbulb_outline_rounded),
        title: Text(hint.title),
        content: Text(hint.explanation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Auf dem Brett zeigen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Hinweis anwenden'),
          ),
        ],
      ),
    );
    if (apply == null || !mounted) return;
    _hintHighlightTimer?.cancel();
    setState(() {
      if (!premium) _hintsRemaining--;
      _hintsUsed++;
      PuzzleInteractionFeedback.hint(context);
      _hintHighlight = hint.cell;
      if (apply) {
        _history.add(_state);
        final marks = Map<TentsCell, TentsCellMark>.from(_state.marks)
          ..[hint.cell] = hint.mark;
        _state = TentsState(puzzle: widget.puzzle, marks: marks);
        _redo.clear();
        _moves++;
      }
    });
    if (!apply) {
      _hintHighlightTimer = Timer(const Duration(seconds: 5), () {
        if (mounted && _hintHighlight == hint.cell) {
          setState(() => _hintHighlight = null);
        }
      });
    }
    unawaited(_save());
    if (_state.isSolved) unawaited(_finish(test: false));
  }

  ({TentsCell cell, TentsCellMark mark, String title, String explanation})?
      _findHint() {
    final size = widget.puzzle.size;
    bool unresolved(TentsCell cell) =>
        !widget.puzzle.trees.contains(cell) &&
        _state.markAt(cell.$1, cell.$2) == TentsCellMark.unknown;
    for (final tent in _state.tents) {
      if (!widget.puzzle.solution.contains(tent)) {
        return (
          cell: tent,
          mark: TentsCellMark.grass,
          title: 'Widerspruch aufl\u00f6sen',
          explanation: 'Das Zelt auf Feld ${tent.$1 + 1}/${tent.$2 + 1} '
              'passt nicht zu allen B\u00e4umen und Randzahlen. Markiere das '
              'Feld stattdessen als Gras.',
        );
      }
    }
    for (var index = 0; index < size; index++) {
      for (final isRow in [true, false]) {
        final cells = [
          for (var other = 0; other < size; other++)
            isRow ? (index, other) : (other, index),
        ];
        final target = isRow
            ? widget.puzzle.rowCounts[index]
            : widget.puzzle.columnCounts[index];
        final placed = cells.where(_state.tents.contains).length;
        final open = cells.where(unresolved).toList();
        final line = isRow ? 'Zeile' : 'Spalte';
        if (placed == target && open.isNotEmpty) {
          return (
            cell: open.first,
            mark: TentsCellMark.grass,
            title: '$line bereits erf\u00fcllt',
            explanation: '$line ${index + 1} enth\u00e4lt bereits alle '
                '$target Zelte. Feld ${open.first.$1 + 1}/'
                '${open.first.$2 + 1} kann Gras werden.',
          );
        }
        if (target - placed == open.length && open.isNotEmpty) {
          return (
            cell: open.first,
            mark: TentsCellMark.tent,
            title: 'Alle freien Felder werden gebraucht',
            explanation: 'In $line ${index + 1} fehlen noch '
                '${target - placed} Zelte und genau so viele Felder sind '
                'offen. Setze ein Zelt auf ${open.first.$1 + 1}/'
                '${open.first.$2 + 1}.',
          );
        }
      }
    }
    for (final tent in _state.tents) {
      for (var row = tent.$1 - 1; row <= tent.$1 + 1; row++) {
        for (var column = tent.$2 - 1; column <= tent.$2 + 1; column++) {
          final cell = (row, column);
          if (row >= 0 &&
              row < size &&
              column >= 0 &&
              column < size &&
              unresolved(cell)) {
            return (
              cell: cell,
              mark: TentsCellMark.grass,
              title: 'Zelte d\u00fcrfen sich nicht ber\u00fchren',
              explanation: 'Feld ${row + 1}/${column + 1} liegt direkt '
                  'neben einem Zelt und kann deshalb Gras werden.',
            );
          }
        }
      }
    }
    for (final cell in widget.puzzle.solution) {
      if (_state.markAt(cell.$1, cell.$2) != TentsCellMark.tent) {
        return (
          cell: cell,
          mark: TentsCellMark.tent,
          title: 'Kombinierter Schluss',
          explanation: 'Betrachte B\u00e4ume, Randzahlen und ausgeschlossene '
              'Nachbarfelder gemeinsam. Auf Feld ${cell.$1 + 1}/'
              '${cell.$2 + 1} bleibt nur ein Zelt m\u00f6glich.',
        );
      }
    }
    return null;
  }

  void _debugSolve(bool almost) {
    final solution = widget.puzzle.solution.toList();
    final leave = almost ? solution.last : null;
    final marks = {
      for (final cell in solution)
        if (cell != leave) cell: TentsCellMark.tent
    };
    setState(() {
      _history.add(_state);
      _state = TentsState(puzzle: widget.puzzle, marks: marks);
      _redo.clear();
    });
    if (!almost) unawaited(_finish(test: true));
  }

  Future<void> _finish({required bool test}) async {
    if (_completed) return;
    setState(() => _completed = true);
    PuzzleInteractionFeedback.success(context);
    await TentsGameStore().clear();
    final countsForTesting = test && widget.mode == GameMode.daily;
    if (!test || countsForTesting) {
      await GameStorage().recordCompletion(
          puzzleId: widget.puzzle.id,
          elapsedSeconds: _elapsed,
          source: widget.mode,
          difficulty: widget.puzzle.difficulty,
          boardSize: widget.puzzle.size,
          gameType: GameType.tents,
          moves: _moves,
          hintsUsed: _hintsUsed,
          rewardedHints: _rewardedHints,
          dailyPuzzleData: widget.mode == GameMode.daily
              ? {
                  'kind': 'tents',
                  'trees': [
                    for (final cell in widget.puzzle.trees) [cell.$1, cell.$2],
                  ],
                  'rowCounts': widget.puzzle.rowCounts,
                  'columnCounts': widget.puzzle.columnCounts,
                  'tents': [
                    for (final cell in widget.puzzle.solution)
                      [cell.$1, cell.$2],
                  ],
                }
              : null);
    }
    if (!mounted) return;
    await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialog) => AlertDialog(
                icon: const Icon(Icons.emoji_events_outlined),
                title: const Text('Lager vollst\u00e4ndig!'),
                content: Text(
                    '${_time(_elapsed)} \u00b7 $_moves Z\u00fcge${test ? countsForTesting ? '\nTestabschluss \u00b7 im Kalender gewertet' : '\nTestabschluss \u00b7 keine Statistik' : ''}'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialog),
                      child: const Text('Brett ansehen')),
                  TextButton(
                      onPressed: () {
                        Navigator.pop(dialog);
                        Navigator.pop(context);
                      },
                      child: const Text('Verlassen')),
                  FilledButton(
                      onPressed: () {
                        Navigator.pop(dialog);
                        if (widget.mode == GameMode.daily) {
                          Navigator.pop(context);
                        } else {
                          _next();
                        }
                      },
                      child: Text(widget.mode == GameMode.daily
                          ? 'Zum Kalender'
                          : 'Noch eins'))
                ]));
  }

  void _next() {
    final sameDifficulty = tentsPuzzleCatalog
        .where((puzzle) => puzzle.difficulty == widget.puzzle.difficulty)
        .toList(growable: false);
    final index =
        sameDifficulty.indexWhere((puzzle) => puzzle.id == widget.puzzle.id);
    final puzzle = widget.mode == GameMode.catalog && index >= 0
        ? sameDifficulty[(index + 1) % sameDifficulty.length]
        : const TentsGenerator().generate(
            seed: DateTime.now().microsecondsSinceEpoch,
            difficulty: widget.puzzle.difficulty,
            size: widget.puzzle.size,
          );
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
        builder: (_) => TentsGameScreen(puzzle: puzzle, mode: widget.mode)));
  }

  @override
  Widget build(BuildContext context) {
    final conflicts = _showConflicts
        ? {
            ..._state.touchingTentConflicts,
            ..._state.countConflicts,
            ..._state.orphanTentConflicts
          }
        : <TentsCell>{};
    final automaticGrass =
        _autoGrass ? _automaticGrassFor(_state) : const <TentsCell>{};
    return Scaffold(
        appBar: AppBar(
            title: Text(
                '${widget.puzzle.difficulty.label} \u00b7 Zelte & B\u00e4ume'),
            actions: [
              if (kDebugMode)
                PopupMenuButton<String>(
                    tooltip: 'Testwerkzeuge',
                    icon: const Icon(Icons.bug_report_outlined),
                    onSelected: (v) => _debugSolve(v == 'almost'),
                    itemBuilder: (_) => const [
                          PopupMenuItem(
                              value: 'almost', child: Text('Fast l\u00f6sen')),
                          PopupMenuItem(
                              value: 'solve', child: Text('Sofort l\u00f6sen'))
                        ]),
              IconButton(
                  onPressed: _history.isEmpty ? null : _undo,
                  tooltip: 'Rückgängig',
                  icon: const Icon(Icons.undo_rounded)),
              IconButton(
                  onPressed: _redo.isEmpty ? null : _redoMove,
                  tooltip: 'Wiederholen',
                  icon: const Icon(Icons.redo_rounded)),
              IconButton(
                  onPressed: _restart,
                  tooltip: 'Neu starten',
                  icon: const Icon(Icons.restart_alt_rounded)),
              IconButton(
                  onPressed: () => showPuzzleGameOptions(context, children: [
                        SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Hilfsgras automatisch anzeigen'),
                            subtitle: const Text(
                                'Blendet sichere Ausschlussfelder dynamisch ein.'),
                            value: _autoGrass,
                            onChanged: (value) {
                              setState(() => _autoGrass = value);
                              unawaited(_save());
                              Navigator.pop(context);
                            }),
                        SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Regelfehler markieren'),
                            subtitle: const Text(
                                'Zeigt sich berührende Zelte und falsche Anzahlen.'),
                            value: _showConflicts,
                            onChanged: (value) {
                              setState(() => _showConflicts = value);
                              Navigator.pop(context);
                            })
                      ]),
                  tooltip: 'Spielhilfen',
                  icon: const Icon(Icons.tune_rounded))
            ]),
        body: SafeArea(
            child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      Wrap(spacing: 8, children: [
                        Chip(
                            avatar: const Icon(Icons.timer_outlined, size: 18),
                            label: Text(_time(_elapsed))),
                        Chip(
                            avatar:
                                const Icon(Icons.touch_app_outlined, size: 18),
                            label: Text('$_moves Z\u00fcge')),
                        PuzzleGameStatusChip(
                            icon: Icons.lightbulb_outline,
                            label: (PreferencesScope.maybeOf(context)
                                        ?.premiumSimulationEnabled ??
                                    false)
                                ? 'Premium'
                                : '$_hintsRemaining Tipps',
                            onTap: _hint)
                      ]),
                      const SizedBox(height: 12),
                      const Text('Tippen: leer \u2192 Zelt \u2192 Gras'),
                      const SizedBox(height: 6),
                      const Text(
                        'Ziel: Bilde Paare aus genau 1 Baum und 1 Zelt.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: AspectRatio(
                              aspectRatio: 1,
                              child: _TentsBoard(
                                  state: _state,
                                  completed: _completed,
                                  automaticGrass: automaticGrass,
                                  conflicts: conflicts,
                                  hintHighlight: _hintHighlight,
                                  onTap: _tap))),
                      if (_completed) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Feine Rahmen zeigen die g\u00fcltigen Baum-Zelt-Paare.',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                      if (_completed)
                        Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: SizedBox(
                                width: double.infinity,
                                child: FilledButton.tonalIcon(
                                    onPressed: widget.mode == GameMode.daily
                                        ? () => Navigator.pop(context)
                                        : _next,
                                    icon: Icon(widget.mode == GameMode.daily
                                        ? Icons.calendar_today_outlined
                                        : Icons.auto_awesome),
                                    label: Text(widget.mode == GameMode.daily
                                        ? 'Zum Kalender'
                                        : 'Noch ein R\u00e4tsel')))),
                      PuzzleGameRulesButton(
                          onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                  builder: (_) => const PuzzleRulesScreen(
                                      title: 'Zelte & B\u00e4ume',
                                      introduction:
                                          'Ordne jedem Baum genau ein Zelt zu.',
                                      rules: [
                                        'Ein Zelt steht direkt waagerecht oder senkrecht neben seinem Baum.',
                                        'Alle B\u00e4ume und Zelte m\u00fcssen sich zu eindeutigen 1:1-Paaren verbinden lassen.',
                                        'Zelte d\u00fcrfen sich weder seitlich noch diagonal ber\u00fchren.',
                                        'Die Randzahlen nennen die Zelte pro Zeile und Spalte.'
                                      ],
                                      interaction:
                                          'Tippe ein Feld: leer \u2192 Zelt \u2192 Gras. Gras ist eine freiwillige Ausschlussnotiz.')))),
                    ])))));
  }
}

class _TentsBoard extends StatelessWidget {
  const _TentsBoard(
      {required this.state,
      required this.completed,
      required this.automaticGrass,
      required this.conflicts,
      required this.hintHighlight,
      required this.onTap});
  final TentsState state;
  final bool completed;
  final Set<TentsCell> automaticGrass;
  final Set<TentsCell> conflicts;
  final TentsCell? hintHighlight;
  final void Function(int, int) onTap;
  @override
  Widget build(BuildContext context) {
    final size = state.puzzle.size;
    final scheme = Theme.of(context).colorScheme;
    final darkMode = Theme.of(context).brightness == Brightness.dark;
    final palette =
        AppTheme.boardPalette('tents', Theme.of(context).brightness);
    final treeBackground = palette.cellStrong;
    final treeForeground =
        darkMode ? const Color(0xFF72F0A3) : const Color(0xFF176A38);
    final pairings = completed
        ? const TentsSolver().pairTrees(state.puzzle, state.tents)
        : const <TentsCell, TentsCell>{};
    return LayoutBuilder(builder: (context, constraints) {
      final grid = GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: size + 1),
          itemCount: (size + 1) * (size + 1),
          itemBuilder: (context, index) {
            final row = index ~/ (size + 1), column = index % (size + 1);
            if (row == 0 && column == 0) return const SizedBox.shrink();
            if (row == 0) {
              final columnIndex = column - 1;
              final fulfilled =
                  state.tents.where((cell) => cell.$2 == columnIndex).length ==
                      state.puzzle.columnCounts[columnIndex];
              return Center(
                  child: Text('${state.puzzle.columnCounts[columnIndex]}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: fulfilled ? palette.accent : null)));
            }
            if (column == 0) {
              final rowIndex = row - 1;
              final fulfilled =
                  state.tents.where((cell) => cell.$1 == rowIndex).length ==
                      state.puzzle.rowCounts[rowIndex];
              return Center(
                  child: Text('${state.puzzle.rowCounts[rowIndex]}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: fulfilled ? palette.accent : null)));
            }
            final cell = (row - 1, column - 1),
                tree = state.puzzle.trees.contains(cell),
                mark = state.markAt(cell.$1, cell.$2);
            final automaticallyExcluded = automaticGrass.contains(cell);
            final conflict = conflicts.contains(cell);
            final highlighted = hintHighlight == cell;
            return Padding(
                padding: const EdgeInsets.all(1.5),
                child: Material(
                    color: conflict
                        ? scheme.errorContainer
                        : tree
                            ? treeBackground
                            : mark == TentsCellMark.grass
                                ? scheme.surfaceContainerLowest
                                : automaticallyExcluded
                                    ? scheme.surfaceContainerLow
                                    : scheme.surfaceContainer,
                    shape: RoundedRectangleBorder(
                        side: BorderSide(
                            color: highlighted
                                ? palette.accent
                                : palette.muted.withValues(alpha: .62),
                            width: highlighted ? 3 : 1),
                        borderRadius: BorderRadius.circular(7)),
                    child: InkWell(
                        onTap: tree ? null : () => onTap(cell.$1, cell.$2),
                        borderRadius: BorderRadius.circular(7),
                        child: Center(
                          child: mark == TentsCellMark.tent && !tree
                              ? _TentIcon(
                                  size: size >= 10 ? 22 : 30,
                                  color: conflict
                                      ? scheme.onErrorContainer
                                      : palette.accent,
                                  accentColor: conflict
                                      ? scheme.errorContainer
                                      : palette.foreground,
                                )
                              : Icon(
                                  tree
                                      ? Icons.park_rounded
                                      : mark == TentsCellMark.grass
                                          ? Icons.grass_rounded
                                          : automaticallyExcluded
                                              ? Icons.grass_outlined
                                              : null,
                                  size: size >= 10 ? 20 : 28,
                                  color: conflict
                                      ? scheme.onErrorContainer
                                      : tree
                                          ? treeForeground
                                          : automaticallyExcluded
                                              ? scheme.onSurfaceVariant
                                                  .withValues(alpha: 0.48)
                                              : null,
                                ),
                        ))));
          });
      if (pairings.isEmpty) return grid;
      return Stack(children: [
        grid,
        Positioned.fill(
            child: IgnorePointer(
                child: CustomPaint(
                    painter: _TreeTentPairingPainter(
                        size: size,
                        pairings: pairings,
                        color: palette.accent))))
      ]);
    });
  }
}

class _TreeTentPairingPainter extends CustomPainter {
  const _TreeTentPairingPainter({
    required this.size,
    required this.pairings,
    required this.color,
  });

  final int size;
  final Map<TentsCell, TentsCell> pairings;
  final Color color;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final cellWidth = canvasSize.width / (size + 1);
    final cellHeight = canvasSize.height / (size + 1);
    final paint = Paint()
      ..color = color.withValues(alpha: 0.82)
      ..strokeWidth = size >= 10 ? 1.6 : 2
      ..style = PaintingStyle.stroke;
    for (final entry in pairings.entries) {
      final minimumRow =
          entry.key.$1 < entry.value.$1 ? entry.key.$1 : entry.value.$1;
      final maximumRow =
          entry.key.$1 > entry.value.$1 ? entry.key.$1 : entry.value.$1;
      final minimumColumn =
          entry.key.$2 < entry.value.$2 ? entry.key.$2 : entry.value.$2;
      final maximumColumn =
          entry.key.$2 > entry.value.$2 ? entry.key.$2 : entry.value.$2;
      final rect = Rect.fromLTRB(
        (minimumColumn + 1) * cellWidth + 2.5,
        (minimumRow + 1) * cellHeight + 2.5,
        (maximumColumn + 2) * cellWidth - 2.5,
        (maximumRow + 2) * cellHeight - 2.5,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(9)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_TreeTentPairingPainter oldDelegate) =>
      oldDelegate.size != size ||
      oldDelegate.pairings != pairings ||
      oldDelegate.color != color;
}

class _TentIcon extends StatelessWidget {
  const _TentIcon({
    required this.size,
    required this.color,
    required this.accentColor,
  });

  final double size;
  final Color color;
  final Color accentColor;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _TentPainter(color, accentColor),
      );
}

class _TentPainter extends CustomPainter {
  const _TentPainter(this.color, this.accentColor);

  final Color color;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final left = Offset(size.width * .06, size.height * .88);
    final peak = Offset(size.width * .48, size.height * .08);
    final right = Offset(size.width * .95, size.height * .88);
    final tent = Path()
      ..moveTo(left.dx, left.dy)
      ..lineTo(peak.dx, peak.dy)
      ..lineTo(right.dx, right.dy)
      ..close();
    canvas.drawPath(tent, Paint()..color = color);

    canvas.drawPath(
      Path()
        ..moveTo(peak.dx, peak.dy)
        ..lineTo(right.dx, right.dy)
        ..lineTo(size.width * .68, size.height * .88)
        ..close(),
      Paint()..color = accentColor.withValues(alpha: .24),
    );
    canvas.drawPath(
      Path()
        ..moveTo(size.width * .34, size.height * .88)
        ..lineTo(size.width * .5, size.height * .55)
        ..lineTo(size.width * .7, size.height * .88)
        ..close(),
      Paint()..color = accentColor,
    );
  }

  @override
  bool shouldRepaint(_TentPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.accentColor != accentColor;
}

String _time(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
