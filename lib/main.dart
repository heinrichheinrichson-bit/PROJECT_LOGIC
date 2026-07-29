import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'game_logic.dart';

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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
                  _HomeAction(
                    icon: Icons.play_arrow_rounded,
                    title: 'Neues Spiel',
                    subtitle: 'Spiel und Schwierigkeit auswählen',
                    enabled: true,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => const GameSelectionScreen())),
                  ),
                  const SizedBox(height: 12),
                  const _HomeAction(icon: Icons.calendar_today_outlined, title: 'Tagesrätsel', subtitle: 'Kommt mit dem Generator'),
                  const SizedBox(height: 12),
                  const _HomeAction(icon: Icons.bar_chart_rounded, title: 'Statistik', subtitle: 'Kommt mit der Speicherung'),
                  const SizedBox(height: 12),
                  const _HomeAction(icon: Icons.settings_outlined, title: 'Einstellungen', subtitle: 'In Vorbereitung'),
                  const SizedBox(height: 28),
                  Text('Version 0.3 · Testmodus', textAlign: TextAlign.center,
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Schwierigkeit', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              Card(child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                leading: const Icon(Icons.eco_outlined, size: 32),
                title: const Text('Leicht', style: TextStyle(fontWeight: FontWeight.w700)),
                subtitle: const Text('6 × 6 · festes Prototyp-Rätsel'),
                trailing: const Icon(Icons.play_arrow_rounded),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const BinaryPuzzleScreen())),
              )),
              const SizedBox(height: 12),
              const Card(child: ListTile(title: Text('Mittel'), subtitle: Text('Später verfügbar'), trailing: Text('BALD'))),
              const SizedBox(height: 12),
              const Card(child: ListTile(title: Text('Schwer'), subtitle: Text('Später verfügbar'), trailing: Text('BALD'))),
            ]),
          ),
        ),
      ),
    );
  }
}


enum _DeveloperAction { almostSolved, solve, error, reset }

class BinaryPuzzleScreen extends StatefulWidget {
  const BinaryPuzzleScreen({super.key});

  @override
  State<BinaryPuzzleScreen> createState() => _BinaryPuzzleScreenState();
}

class _BinaryPuzzleScreenState extends State<BinaryPuzzleScreen> {
  late BinaryPuzzle puzzle;
  bool showIssues = true;

  @override
  void initState() {
    super.initState();
    puzzle = createPrototypePuzzle();
  }

  @override
  Widget build(BuildContext context) {
    final issues = puzzle.validate();
    final issueCells = {
      for (final issue in issues) ...issue.cells,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Binärpuzzle · Leicht'),
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
    );
  }

  void _cycleCell(int row, int column) {
    setState(() {
      puzzle.cycleCell(row, column);
    });

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
    }
  }

  void _showSolvedDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.check_circle_outline),
          title: const Text('Gelöst!'),
          content: const Text(
            'Alle Regeln sind erfüllt. Der Abschlussablauf funktioniert.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Weiter ansehen'),
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

  void _undo() => setState(puzzle.undo);

  void _redo() => setState(puzzle.redo);

  void _reset() {
    setState(puzzle.reset);
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
