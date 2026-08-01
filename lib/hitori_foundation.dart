import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/domain/game_identity.dart';
import 'core/presentation/confirm_restart_dialog.dart';
import 'features/hitori/domain/hitori_generator.dart';
import 'features/hitori/domain/hitori_puzzle.dart';
import 'game_storage.dart';

class SavedHitoriGame {
  const SavedHitoriGame({
    required this.puzzle,
    required this.marks,
    required this.elapsedSeconds,
    required this.moves,
    required this.hintsRemaining,
  });

  final HitoriPuzzle puzzle;
  final Map<HitoriCell, HitoriCellMark> marks;
  final int elapsedSeconds;
  final int moves;
  final int hintsRemaining;

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
  const HitoriHubScreen({super.key});

  @override
  State<HitoriHubScreen> createState() => _HitoriHubScreenState();
}

class _HitoriHubScreenState extends State<HitoriHubScreen> {
  SavedHitoriGame? _saved;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final saved = await HitoriGameStore().load();
    if (mounted) setState(() => _saved = saved);
  }

  Future<void> _open(HitoriPuzzle puzzle, {SavedHitoriGame? saved}) async {
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
        return _open(current.puzzle, saved: current);
      }
      await HitoriGameStore().clear();
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HitoriGameScreen(puzzle: puzzle, savedGame: saved),
      ),
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Hitori')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_saved case final saved?) ...[
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: ListTile(
                  minTileHeight: 86,
                  leading: const Icon(Icons.play_circle_outline_rounded),
                  title: const Text('Rätsel fortsetzen'),
                  subtitle: Text(
                    '${saved.puzzle.difficulty.label} · ${saved.puzzle.size} × '
                    '${saved.puzzle.size} · ${_formatTime(saved.elapsedSeconds)}',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _open(saved.puzzle, saved: saved),
                ),
              ),
              const SizedBox(height: 20),
            ],
            Text('Finde die einzelnen Zahlen',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text(
              'Schwärze doppelte Zahlen, ohne schwarze Nachbarn zu erzeugen. '
              'Alle hellen Felder müssen verbunden bleiben.',
            ),
            const SizedBox(height: 24),
            Text('Zufallsrätsel',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final difficulty in PuzzleDifficulty.values) ...[
              Card(
                child: ListTile(
                  minTileHeight: 82,
                  leading: CircleAvatar(
                    child: Text('${5 + difficulty.index}'),
                  ),
                  title: Text(difficulty.label),
                  subtitle: Text(
                    '${difficulty.description} · ${5 + difficulty.index} × ${5 + difficulty.index}',
                  ),
                  trailing: const Icon(Icons.play_arrow_rounded),
                  onTap: () {
                    final puzzle = const HitoriGenerator().generate(
                      seed: DateTime.now().microsecondsSinceEpoch,
                      difficulty: difficulty,
                    );
                    _open(puzzle);
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      );
}

class HitoriGameScreen extends StatefulWidget {
  const HitoriGameScreen({required this.puzzle, this.savedGame, super.key});

  final HitoriPuzzle puzzle;
  final SavedHitoriGame? savedGame;

  @override
  State<HitoriGameScreen> createState() => _HitoriGameScreenState();
}

class _HitoriGameScreenState extends State<HitoriGameScreen> {
  static const _guideSeenKey = 'hitori_rules_guide_seen_v1';
  late HitoriState _state;
  final _history = <HitoriState>[];
  final _redo = <HitoriState>[];
  final _store = HitoriGameStore();
  Timer? _timer;
  int _elapsedSeconds = 0;
  int _moves = 0;
  int _hintsRemaining = 3;
  bool _completionShown = false;
  bool _showConflicts = true;

  @override
  void initState() {
    super.initState();
    final saved = widget.savedGame;
    _state = HitoriState(puzzle: widget.puzzle, marks: saved?.marks);
    _elapsedSeconds = saved?.elapsedSeconds ?? 0;
    _moves = saved?.moves ?? 0;
    _hintsRemaining = saved?.hintsRemaining ?? 3;
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
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _save() => _store.save(SavedHitoriGame(
        puzzle: widget.puzzle,
        marks: _state.marks,
        elapsedSeconds: _elapsedSeconds,
        moves: _moves,
        hintsRemaining: _hintsRemaining,
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
                'Tippen: unverändert → schwarz → sicher hell → unverändert',
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
    setState(() {
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
    setState(() {
      _redo.add(_state);
      _state = _history.removeLast();
      if (_moves > 0) _moves--;
    });
    unawaited(_save());
  }

  void _redoMove() {
    if (_redo.isEmpty || _completionShown) return;
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
      _state = HitoriState(puzzle: widget.puzzle);
      _redo.clear();
      _elapsedSeconds = 0;
      _moves = 0;
      _hintsRemaining = 3;
    });
    unawaited(_save());
  }

  Future<void> _hint() async {
    if (_hintsRemaining <= 0 || _completionShown) return;
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
    final apply = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.lightbulb_outline_rounded),
        title: Text(shade ? 'Doppelte Zahl betrachten' : 'Helles Feld sichern'),
        content: Text(
          'Prüfe Zeile ${cell.$1 + 1}, Spalte ${cell.$2 + 1}. '
          '${shade ? 'Dieses Feld muss geschwärzt werden.' : 'Dieses Feld muss hell bleiben.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Nur zeigen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hinweis anwenden'),
          ),
        ],
      ),
    );
    if (apply != true || !mounted) return;
    setState(() {
      _history.add(_state);
      final marks = Map<HitoriCell, HitoriCellMark>.from(_state.marks)
        ..[cell] = shade ? HitoriCellMark.shaded : HitoriCellMark.protected;
      _state = HitoriState(puzzle: widget.puzzle, marks: marks);
      _hintsRemaining--;
      _moves++;
      _redo.clear();
    });
    unawaited(_save());
    if (_state.isSolved) unawaited(_complete());
  }

  void _debugSolve({required bool almost}) {
    final solution = widget.puzzle.solution.toList();
    final leave = almost && solution.isNotEmpty ? solution.last : null;
    setState(() {
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
    if (!testCompletion) {
      await GameStorage().recordCompletion(
        puzzleId: widget.puzzle.id,
        elapsedSeconds: _elapsedSeconds,
        source: GameMode.generated,
        difficulty: widget.puzzle.difficulty,
        boardSize: widget.puzzle.size,
        gameType: GameType.hitori,
        moves: _moves,
        hintsUsed: 3 - _hintsRemaining,
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
              const Text('Testabschluss · keine Statistik'),
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
            child: const Text('Hitori verlassen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final duplicate =
        _showConflicts ? _state.duplicateConflicts : <HitoriCell>{};
    final adjacent =
        _showConflicts ? _state.adjacentShadeConflicts : <HitoriCell>{};
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.puzzle.difficulty.label} · Hitori'),
        actions: [
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
            tooltip: 'Regeln',
            onPressed: () => _showRulesGuide(force: true),
            icon: const Icon(Icons.help_outline_rounded),
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
                  Chip(
                    avatar: const Icon(Icons.lightbulb_outline, size: 18),
                    label: Text('$_hintsRemaining Tipps'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Tippen: unverändert → schwarz → sicher hell'),
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
                      final scheme = Theme.of(context).colorScheme;
                      return Padding(
                        padding: const EdgeInsets.all(2),
                        child: Material(
                          color: conflict
                              ? scheme.errorContainer
                              : mark == HitoriCellMark.shaded
                                  ? Colors.black
                                  : mark == HitoriCellMark.protected
                                      ? scheme.primaryContainer
                                      : scheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
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
                                            ? Colors.white24
                                            : null,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                if (mark == HitoriCellMark.protected)
                                  Positioned(
                                    right: 5,
                                    top: 5,
                                    child: Icon(
                                      Icons.circle_outlined,
                                      size: 12,
                                      color: scheme.primary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
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
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Regelfehler markieren'),
                subtitle: Text(
                  !_state.openCellsConnected
                      ? 'Der helle Bereich ist momentan getrennt.'
                      : 'Markiert doppelte Zahlen und benachbarte schwarze Felder.',
                ),
                value: _showConflicts,
                onChanged: (value) => setState(() => _showConflicts = value),
              ),
              Card(
                child: ExpansionTile(
                  leading: const Icon(Icons.menu_book_outlined),
                  title: const Text('So funktioniert es'),
                  childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  children: [
                    const Text(
                      'Schwärze so viele doppelte Zahlen, dass jede Zahl pro '
                      'Zeile und Spalte nur einmal hell bleibt. Schwarze Felder '
                      'dürfen sich nicht seitlich berühren. Die übrigen hellen '
                      'Felder müssen vollständig miteinander verbunden bleiben.',
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => _showRulesGuide(force: true),
                        icon: const Icon(Icons.school_outlined),
                        label: const Text('Regeln Schritt für Schritt'),
                      ),
                    ),
                  ],
                ),
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
