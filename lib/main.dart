import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'game_logic.dart';
import 'game_storage.dart';

void main() {
  runApp(const ProjectLogicApp());
}

class ProjectLogicApp extends StatelessWidget {
  const ProjectLogicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Project Logic',
      themeMode: ThemeMode.system,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF365A7A),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF83B8E3),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GameStorage _storage = GameStorage();
  SavedGame? _savedGame;
  Map<String, PuzzleResult> _results = const {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final savedGame = await _storage.loadActiveGame();
    final results = await _storage.loadResults();
    if (!mounted) return;
    setState(() {
      _savedGame = savedGame;
      _results = results;
      _loading = false;
    });
  }

  BinaryPuzzleDefinition? get _savedDefinition {
    final game = _savedGame;
    if (game == null) return null;
    for (final definition in binaryPuzzleCatalog) {
      if (definition.id == game.puzzleId) return definition;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  Icon(Icons.grid_view_rounded,
                      size: 68, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 18),
                  Text('PROJECT LOGIC',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  Text('Ruhige Logikspiele. Klare Regeln. Kein Zeitdruck.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 40),
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    if (_savedGame != null && _savedDefinition != null) ...[
                      _HomeAction(
                        icon: Icons.play_circle_outline_rounded,
                        title: 'Spiel fortsetzen',
                        subtitle:
                            '${_savedDefinition!.difficulty.label} · ${_savedDefinition!.displayName} · ${_formatHomeTime(_savedGame!.elapsedSeconds)}',
                        enabled: true,
                        onTap: () async {
                          await Navigator.of(context).push(MaterialPageRoute<void>(
                            builder: (_) => BinaryPuzzleScreen(
                              definition: _savedDefinition!,
                              savedGame: _savedGame,
                            ),
                          ));
                          await _refresh();
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    _HomeAction(
                      icon: Icons.play_arrow_rounded,
                      title: 'Neues Spiel',
                      subtitle: 'Spiel und Schwierigkeit auswählen',
                      enabled: true,
                      onTap: () async {
                        await Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => const GameSelectionScreen(),
                        ));
                        await _refresh();
                      },
                    ),
                    const SizedBox(height: 12),
                    const _HomeAction(
                      icon: Icons.calendar_today_outlined,
                      title: 'Tagesrätsel',
                      subtitle: 'Kommt mit dem Generator',
                    ),
                    const SizedBox(height: 12),
                    _HomeAction(
                      icon: Icons.bar_chart_rounded,
                      title: 'Statistik',
                      subtitle:
                          '${_results.length} von ${binaryPuzzleCatalog.length} Rätseln gelöst',
                      enabled: true,
                      onTap: () async {
                        await Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => StatisticsScreen(results: _results),
                        ));
                        await _refresh();
                      },
                    ),
                    const SizedBox(height: 12),
                    const _HomeAction(
                      icon: Icons.settings_outlined,
                      title: 'Einstellungen',
                      subtitle: 'In Vorbereitung',
                    ),
                  ],
                  const SizedBox(height: 28),
                  Text('Version 0.3.1 · Entwicklungsstand', textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


String _formatHomeTime(int seconds) {
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  return '$minutes:${rest.toString().padLeft(2, '0')}';
}

class _HomeAction extends StatelessWidget {
  const _HomeAction({required this.icon, required this.title, required this.subtitle,
      this.enabled = false, this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: enabled ? colors.primaryContainer : colors.surfaceContainerLow,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Icon(icon, size: 30),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ])),
            if (enabled) const Icon(Icons.arrow_forward_ios_rounded, size: 17)
            else const Text('BALD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ]),
        ),
      ),
    );
  }
}

class GameSelectionScreen extends StatelessWidget {
  const GameSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spiel auswählen')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Welches Spiel?', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              _GameChoice(
                icon: Icons.grid_4x4_rounded,
                title: 'Binärpuzzle',
                subtitle: 'Balance aus 0 und 1',
                enabled: true,
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const DifficultyScreen())),
              ),
              const SizedBox(height: 12),
              const _GameChoice(icon: Icons.filter_none_rounded, title: 'Hitori', subtitle: 'Zahlen schwärzen und verbinden'),
              const SizedBox(height: 12),
              const _GameChoice(icon: Icons.hub_outlined, title: 'Hashi', subtitle: 'Inseln mit Brücken verbinden'),
            ]),
          ),
        ),
      ),
    );
  }
}

class _GameChoice extends StatelessWidget {
  const _GameChoice({required this.icon, required this.title, required this.subtitle,
      this.enabled = false, this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Icon(icon, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: enabled ? const Icon(Icons.arrow_forward_ios_rounded, size: 17) : const Text('IN ARBEIT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        onTap: enabled ? onTap : null,
      ),
    );
  }
}

class DifficultyScreen extends StatelessWidget {
  const DifficultyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Binärpuzzle')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Schwierigkeit', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('Jede Stufe enthält drei spielbare Rätsel.', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 20),
                for (final difficulty in PuzzleDifficulty.values) ...[
                  Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      leading: Icon(switch (difficulty) {
                        PuzzleDifficulty.easy => Icons.eco_outlined,
                        PuzzleDifficulty.medium => Icons.psychology_alt_outlined,
                        PuzzleDifficulty.hard => Icons.local_fire_department_outlined,
                      }, size: 32),
                      title: Text(difficulty.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${difficulty.description} · ${puzzlesFor(difficulty).length} Rätsel'),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 17),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => PuzzleSelectionScreen(difficulty: difficulty),
                      )),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PuzzleSelectionScreen extends StatefulWidget {
  const PuzzleSelectionScreen({required this.difficulty, super.key});

  final PuzzleDifficulty difficulty;

  @override
  State<PuzzleSelectionScreen> createState() => _PuzzleSelectionScreenState();
}

class _PuzzleSelectionScreenState extends State<PuzzleSelectionScreen> {
  final GameStorage _storage = GameStorage();
  Map<String, PuzzleResult> _results = const {};

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    final results = await _storage.loadResults();
    if (mounted) setState(() => _results = results);
  }

  @override
  Widget build(BuildContext context) {
    final puzzles = puzzlesFor(widget.difficulty);
    return Scaffold(
      appBar: AppBar(
        title: Text('Binärpuzzle · ${widget.difficulty.label}'),
      ),
      body: Center(
        child: ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: puzzles.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final definition = puzzles[index];
            final result = _results[definition.id];
            return Card(
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                leading: CircleAvatar(
                  child: result == null
                      ? Text('${definition.number}')
                      : const Icon(Icons.check_rounded),
                ),
                title: Text(
                  definition.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  result == null
                      ? '6 × 6 · ${definition.clueCount} Vorgaben'
                      : 'Bestzeit ${_formatHomeTime(result.bestSeconds)} · ${definition.clueCount} Vorgaben',
                ),
                trailing: Icon(
                  result == null
                      ? Icons.play_arrow_rounded
                      : Icons.replay_rounded,
                ),
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) =>
                        BinaryPuzzleScreen(definition: definition),
                  ));
                  await _loadResults();
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

enum _DeveloperAction { almostSolved, solve, error, reset }

class BinaryPuzzleScreen extends StatefulWidget {
  const BinaryPuzzleScreen({
    required this.definition,
    this.savedGame,
    super.key,
  });

  final BinaryPuzzleDefinition definition;
  final SavedGame? savedGame;

  @override
  State<BinaryPuzzleScreen> createState() => _BinaryPuzzleScreenState();
}

class _BinaryPuzzleScreenState extends State<BinaryPuzzleScreen> {
  final GameStorage _storage = GameStorage();
  late BinaryPuzzle puzzle;
  bool showIssues = true;
  late final Timer _timer;
  int elapsedSeconds = 0;
  bool _completionRecorded = false;

  @override
  void initState() {
    super.initState();
    puzzle = widget.definition.createPuzzle();
    final savedGame = widget.savedGame;
    if (savedGame != null && savedGame.puzzleId == widget.definition.id) {
      puzzle.restoreEditableValues(savedGame.values);
      elapsedSeconds = savedGame.elapsedSeconds;
    } else {
      _saveGame();
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !puzzle.isSolved) {
        setState(() => elapsedSeconds++);
        if (elapsedSeconds % 5 == 0) _saveGame();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final issues = puzzle.validate();
    final issueCells = {
      for (final issue in issues) ...issue.cells,
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _saveGame();
        if (context.mounted) {
          Navigator.of(context).pop(result);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.definition.difficulty.label} · ${widget.definition.displayName}'),
        actions: [
          if (kDebugMode)
            PopupMenuButton<_DeveloperAction>(
              tooltip: 'Testwerkzeuge',
              icon: const Icon(Icons.bug_report_outlined),
              onSelected: _runDeveloperAction,
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _DeveloperAction.almostSolved,
                  child: Text('Bis auf 1 Feld lösen'),
                ),
                PopupMenuItem(
                  value: _DeveloperAction.solve,
                  child: Text('Sofort lösen'),
                ),
                PopupMenuItem(
                  value: _DeveloperAction.error,
                  child: Text('Regelfehler erzeugen'),
                ),
                PopupMenuItem(
                  value: _DeveloperAction.reset,
                  child: Text('Testzustand löschen'),
                ),
              ],
            ),
          IconButton(
            tooltip: 'Zurücksetzen',
            onPressed: _reset,
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _GameInfoBar(
                    elapsedSeconds: elapsedSeconds,
                    filled: puzzle.filledEditableCellCount,
                    total: puzzle.editableCellCount,
                    progress: puzzle.progress,
                  ),
                  const SizedBox(height: 12),
                  _StatusCard(
                    isSolved: puzzle.isSolved,
                    isComplete: puzzle.isComplete,
                    issueCount: issues.length,
                  ),
                  const SizedBox(height: 18),
                  AspectRatio(
                    aspectRatio: 1,
                    child: _PuzzleBoard(
                      puzzle: puzzle,
                      issueCells: showIssues ? issueCells : const {},
                      onCellPressed: _cycleCell,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: puzzle.canUndo ? _undo : null,
                          icon: const Icon(Icons.undo),
                          label: const Text('Rückgängig'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          onPressed: puzzle.canRedo ? _redo : null,
                          icon: const Icon(Icons.redo),
                          label: const Text('Wiederholen'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Regelfehler markieren'),
                    subtitle: const Text(
                      'Markiert direkte Widersprüche, ohne die Lösung zu verraten.',
                    ),
                    value: showIssues,
                    onChanged: (value) => setState(() => showIssues = value),
                  ),
                  const SizedBox(height: 10),
                  _RulesPanel(issues: showIssues ? issues : const []),
                ],
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }

  void _cycleCell(int row, int column) {
    setState(() {
      puzzle.cycleCell(row, column);
    });
    _saveGame();

    if (puzzle.isSolved) {
      _showSolvedDialog();
    }
  }

  void _runDeveloperAction(_DeveloperAction action) {
    setState(() {
      switch (action) {
        case _DeveloperAction.almostSolved:
          puzzle.fillWithSolution(leaveOneEmpty: true);
          break;
        case _DeveloperAction.solve:
          puzzle.fillWithSolution();
          break;
        case _DeveloperAction.error:
          puzzle.createTestError();
          break;
        case _DeveloperAction.reset:
          puzzle.reset();
          break;
      }
    });

    if (action == _DeveloperAction.solve) {
      _showSolvedDialog();
    } else {
      _saveGame();
    }
  }

  void _showSolvedDialog() {
    if (!_completionRecorded) {
      _completionRecorded = true;
      _storage.recordCompletion(
        puzzleId: widget.definition.id,
        elapsedSeconds: elapsedSeconds,
      );
      _storage.clearActiveGame();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.check_circle_outline),
          title: const Text('Gelöst!'),
          content: Text('Alle Regeln sind erfüllt. Zeit: ${_formatTime(elapsedSeconds)}.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Weiter ansehen'),
            ),
            FilledButton.tonal(
              onPressed: _hasNextPuzzle ? () {
                Navigator.of(context).pop();
                Navigator.of(this.context).pushReplacement(MaterialPageRoute<void>(
                  builder: (_) => BinaryPuzzleScreen(definition: _nextPuzzle!),
                ));
              } : null,
              child: const Text('Nächstes Rätsel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                _reset();
              },
              child: const Text('Neu starten'),
            ),
          ],
        ),
      );
    });
  }

  void _undo() {
    setState(puzzle.undo);
    _saveGame();
  }

  void _redo() {
    setState(puzzle.redo);
    _saveGame();
  }

  bool get _hasNextPuzzle => _nextPuzzle != null;

  BinaryPuzzleDefinition? get _nextPuzzle {
    final list = puzzlesFor(widget.definition.difficulty);
    final index = list.indexWhere((item) => item.id == widget.definition.id);
    return index >= 0 && index + 1 < list.length ? list[index + 1] : null;
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    return '$minutes:${rest.toString().padLeft(2, '0')}';
  }

  void _reset() {
    setState(() {
      puzzle.reset();
      elapsedSeconds = 0;
      _completionRecorded = false;
    });
    _saveGame();
  }

  Future<void> _saveGame() {
    return _storage.saveActiveGame(
      SavedGame(
        puzzleId: widget.definition.id,
        elapsedSeconds: elapsedSeconds,
        values: puzzle.exportEditableValues(),
        savedAt: DateTime.now(),
      ),
    );
  }
}

class _GameInfoBar extends StatelessWidget {
  const _GameInfoBar({
    required this.elapsedSeconds,
    required this.filled,
    required this.total,
    required this.progress,
  });

  final int elapsedSeconds;
  final int filled;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final minutes = elapsedSeconds ~/ 60;
    final seconds = elapsedSeconds % 60;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 20),
                const SizedBox(width: 7),
                Text('$minutes:${seconds.toString().padLeft(2, '0')}'),
                const Spacer(),
                Text('$filled von $total Feldern gelöst'),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: progress),
          ],
        ),
      ),
    );
  }
}


class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({required this.results, super.key});

  final Map<String, PuzzleResult> results;

  @override
  Widget build(BuildContext context) {
    final completed = results.length;
    final total = binaryPuzzleCatalog.length;
    final totalBestSeconds = results.values.fold<int>(
      0,
      (sum, result) => sum + result.bestSeconds,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Statistik')),
      body: Center(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            '$completed / $total',
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          const Text('Rätsel abgeschlossen'),
                          const SizedBox(height: 14),
                          LinearProgressIndicator(
                            value: total == 0 ? 0 : completed / total,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.timer_outlined),
                      title: const Text('Summe deiner Bestzeiten'),
                      subtitle: Text(_formatLongTime(totalBestSeconds)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Nach Schwierigkeit',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  for (final difficulty in PuzzleDifficulty.values)
                    _DifficultyStatistic(
                      difficulty: difficulty,
                      results: results,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatLongTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final rest = seconds % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${rest.toString().padLeft(2, '0')}';
    }
    return '$minutes:${rest.toString().padLeft(2, '0')}';
  }
}

class _DifficultyStatistic extends StatelessWidget {
  const _DifficultyStatistic({
    required this.difficulty,
    required this.results,
  });

  final PuzzleDifficulty difficulty;
  final Map<String, PuzzleResult> results;

  @override
  Widget build(BuildContext context) {
    final puzzles = puzzlesFor(difficulty);
    final completed =
        puzzles.where((puzzle) => results.containsKey(puzzle.id)).length;

    return Card(
      child: ListTile(
        leading: Icon(switch (difficulty) {
          PuzzleDifficulty.easy => Icons.eco_outlined,
          PuzzleDifficulty.medium => Icons.psychology_alt_outlined,
          PuzzleDifficulty.hard => Icons.local_fire_department_outlined,
        }),
        title: Text(difficulty.label),
        subtitle: Text('$completed von ${puzzles.length} gelöst'),
        trailing: Text('${((completed / puzzles.length) * 100).round()} %'),
      ),
    );
  }
}

class _PuzzleBoard extends StatelessWidget {
  const _PuzzleBoard({
    required this.puzzle,
    required this.issueCells,
    required this.onCellPressed,
  });

  final BinaryPuzzle puzzle;
  final Set<CellPosition> issueCells;
  final void Function(int row, int column) onCellPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.outline, width: 2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: puzzle.size * puzzle.size,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: puzzle.size,
          ),
          itemBuilder: (context, index) {
            final row = index ~/ puzzle.size;
            final column = index % puzzle.size;
            final value = puzzle.board[row][column];
            final clue = puzzle.isClue(row, column);
            final hasIssue = issueCells.contains(CellPosition(row, column));

            return _PuzzleCell(
              value: value,
              clue: clue,
              hasIssue: hasIssue,
              onPressed: clue ? null : () => onCellPressed(row, column),
            );
          },
        ),
      ),
    );
  }
}

class _PuzzleCell extends StatelessWidget {
  const _PuzzleCell({
    required this.value,
    required this.clue,
    required this.hasIssue,
    required this.onPressed,
  });

  final CellValue? value;
  final bool clue;
  final bool hasIssue;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final background = switch ((value, clue, hasIssue)) {
      (_, _, true) => colors.errorContainer,
      (null, _, false) => colors.surface,
      (_, true, false) => colors.secondaryContainer,
      (CellValue.zero, false, false) => colors.primaryContainer,
      (CellValue.one, false, false) => colors.tertiaryContainer,
    };

    final foreground = hasIssue
        ? colors.onErrorContainer
        : clue
            ? colors.onSecondaryContainer
            : value == CellValue.one
                ? colors.onTertiaryContainer
                : colors.onPrimaryContainer;

    return Semantics(
      button: !clue,
      label: clue
          ? 'Vorgabe ${value?.label}'
          : value == null
              ? 'Leeres Feld'
              : 'Feld ${value!.label}',
      hint: clue ? null : 'Antippen, um den Wert zu ändern',
      child: Material(
        color: background,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: colors.outlineVariant,
                width: 0.6,
              ),
            ),
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 140),
              child: Text(
                value?.label ?? '',
                key: ValueKey(value),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: foreground,
                      fontWeight: clue ? FontWeight.w800 : FontWeight.w600,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.isSolved,
    required this.isComplete,
    required this.issueCount,
  });

  final bool isSolved;
  final bool isComplete;
  final int issueCount;

  @override
  Widget build(BuildContext context) {
    final (icon, title, text) = switch ((isSolved, isComplete, issueCount)) {
      (true, _, _) => (
          Icons.check_circle_outline,
          'Rätsel gelöst',
          'Alle Regeln sind erfüllt.',
        ),
      (false, true, 0) => (
          Icons.hourglass_bottom,
          'Fast geschafft',
          'Das Raster ist vollständig und wird geprüft.',
        ),
      (false, _, > 0) => (
          Icons.info_outline,
          '$issueCount Regelhinweis${issueCount == 1 ? '' : 'e'}',
          'Korrigiere die markierten Felder.',
        ),
      _ => (
          Icons.touch_app_outlined,
          'Tippen: leer → 0 → 1',
          'Vorgaben sind stärker hervorgehoben.',
        ),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 30),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
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

class _RulesPanel extends StatelessWidget {
  const _RulesPanel({required this.issues});

  final List<RuleIssue> issues;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: issues.isNotEmpty,
      tilePadding: EdgeInsets.zero,
      title: const Text('Regeln und Hinweise'),
      childrenPadding: const EdgeInsets.only(bottom: 12),
      children: [
        const _RuleLine('Jede Zeile und Spalte enthält drei 0 und drei 1.'),
        const _RuleLine('Nie drei gleiche Zahlen direkt nebeneinander.'),
        const _RuleLine('Keine zwei vollständigen Zeilen oder Spalten sind gleich.'),
        if (issues.isNotEmpty) ...[
          const Divider(height: 24),
          for (final issue in issues)
            _RuleLine(issue.message, icon: Icons.warning_amber_rounded),
        ],
      ],
    );
  }
}

class _RuleLine extends StatelessWidget {
  const _RuleLine(this.text, {this.icon = Icons.check});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
