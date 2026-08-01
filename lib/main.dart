import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_preferences.dart';
import 'core/monetization/hint_economy.dart';
import 'core/presentation/confirm_restart_dialog.dart';
import 'core/statistics/game_statistics.dart';
import 'core/statistics/puzzle_attempt.dart';
import 'daily_challenge.dart';
import 'data_backup.dart';
import 'game_logic.dart';
import 'game_storage.dart';
import 'hint_engine.dart';
import 'hashi_foundation.dart';
import 'player_progress_system.dart';
import 'slitherlink_foundation.dart';
import 'features/binary_puzzle/domain/binary_puzzle_generator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await AppPreferences.load();
  runApp(ProjectLogicApp(preferences: preferences));
}

class ProjectLogicApp extends StatelessWidget {
  const ProjectLogicApp({required this.preferences, super.key});

  final AppPreferences preferences;

  @override
  Widget build(BuildContext context) {
    return PreferencesScope(
      preferences: preferences,
      child: AnimatedBuilder(
        animation: preferences,
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Project Logic',
          themeMode: preferences.themePreference.themeMode,
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
        ),
      ),
    );
  }
}

int _catalogCompletedCount(Map<String, PuzzleResult> results) {
  final catalogIds = binaryPuzzleCatalog.map((puzzle) => puzzle.id).toSet();
  return results.keys.where(catalogIds.contains).length;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GameStorage _storage = GameStorage();
  Map<String, PuzzleResult> _results = const {};
  PlayerProgress _progress = const PlayerProgress.empty();
  SavedHashiGame? _savedHashiGame;
  SavedSlitherlinkGame? _savedSlitherlinkGame;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final results = await _storage.loadResults();
    final progress = await _storage.loadPlayerProgress();
    final savedHashiGame = await HashiGameStore().load();
    final savedSlitherlinkGame = await SlitherlinkGameStore().load();
    if (!mounted) return;
    setState(() {
      _results = results;
      _progress = progress;
      _savedHashiGame = savedHashiGame;
      _savedSlitherlinkGame = savedSlitherlinkGame;
      _loading = false;
    });
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
                  Icon(
                    Icons.grid_view_rounded,
                    size: 68,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'PROJECT LOGIC',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ruhige Logikspiele. Klare Regeln. Kein Zeitdruck.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 40),
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    if (_savedHashiGame case final saved?) ...[
                      _HomeAction(
                        icon: Icons.play_circle_outline_rounded,
                        title: 'Hashi fortsetzen',
                        subtitle:
                            '${saved.puzzle.sharedDifficulty.label} · ${saved.moves} Züge · ${_shortTime(saved.elapsedSeconds)}',
                        enabled: true,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => HashiGameScreen(
                                puzzle: saved.puzzle,
                                mode: saved.mode,
                                savedGame: saved,
                              ),
                            ),
                          );
                          await _refresh();
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_savedSlitherlinkGame case final saved?) ...[
                      _HomeAction(
                        icon: Icons.play_circle_outline_rounded,
                        title: 'Slitherlink fortsetzen',
                        subtitle:
                            '${saved.puzzle.rows} × ${saved.puzzle.columns} · ${saved.moves} Züge · ${_shortTime(saved.elapsedSeconds)}',
                        enabled: true,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => SlitherlinkGameScreen(
                                puzzle: saved.puzzle,
                                savedGame: saved,
                              ),
                            ),
                          );
                          await _refresh();
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    _StreakCard(progress: _progress),
                    const SizedBox(height: 12),
                    _HomeAction(
                      icon: Icons.grid_4x4_rounded,
                      title: 'Binärpuzzle',
                      subtitle:
                          '${_catalogCompletedCount(_results)} von ${binaryPuzzleCatalog.length} Rätseln gelöst',
                      enabled: true,
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const BinaryPuzzleHubScreen(),
                          ),
                        );
                        await _refresh();
                      },
                    ),
                    const SizedBox(height: 12),
                    _HomeAction(
                      icon: Icons.hub_rounded,
                      title: 'Hashi',
                      subtitle:
                          'Entdecke Inseln, Brücken und das neue Spielgefühl',
                      enabled: true,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => HashiHubScreen(
                            onOpenStatistics: () async {
                              final storage = GameStorage();
                              final results = await storage.loadResults();
                              final progress =
                                  await storage.loadPlayerProgress();
                              if (!context.mounted) return;
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => StatisticsScreen(
                                    results: results,
                                    progress: progress,
                                    gameType: GameType.hashi,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _HomeAction(
                      icon: Icons.gesture_rounded,
                      title: 'Slitherlink',
                      subtitle:
                          'Neu · Zeichne eine einzige geschlossene Schleife',
                      enabled: true,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SlitherlinkHubScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _HomeAction(
                      icon: Icons.person_outline_rounded,
                      title: 'Dein Fortschritt',
                      subtitle: 'Level, Ziele und Erfolge auf einen Blick',
                      enabled: true,
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => PlayerProfileScreen(
                              results: _results,
                              progress: _progress,
                            ),
                          ),
                        );
                        await _refresh();
                      },
                    ),
                    const SizedBox(height: 12),
                    _HomeAction(
                      icon: Icons.bar_chart_rounded,
                      title: 'Statistik',
                      subtitle: 'Deine bisherigen Partien und Bestleistungen',
                      enabled: true,
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => StatisticsScreen(
                              results: _results,
                              progress: _progress,
                            ),
                          ),
                        );
                        await _refresh();
                      },
                    ),
                    const SizedBox(height: 12),
                    _HomeAction(
                      icon: Icons.settings_outlined,
                      title: 'Einstellungen',
                      subtitle: 'Aussehen, Spielhilfen und gespeicherte Daten',
                      enabled: true,
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                        await _refresh();
                      },
                    ),
                  ],
                  const SizedBox(height: 28),
                  Text(
                    'Version 0.8.2 · Hashi-Rätselkatalog',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _shortTime(int seconds) {
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    return '$minutes:${rest.toString().padLeft(2, '0')}';
  }
}

class BinaryPuzzleHubScreen extends StatefulWidget {
  const BinaryPuzzleHubScreen({super.key});

  @override
  State<BinaryPuzzleHubScreen> createState() => _BinaryPuzzleHubScreenState();
}

class _BinaryPuzzleHubScreenState extends State<BinaryPuzzleHubScreen> {
  final GameStorage _storage = GameStorage();
  SavedGame? _savedGame;
  Map<String, PuzzleResult> _results = const {};
  PlayerProgress _progress = const PlayerProgress.empty();
  DailyBinaryChallenge? _dailyChallenge;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final savedGame = await _storage.loadActiveGame();
    final results = await _storage.loadResults();
    final progress = await _storage.loadPlayerProgress();
    final dailyChallenge = const DailyChallengeService().today();
    if (!mounted) return;
    setState(() {
      _savedGame = savedGame;
      _results = results;
      _progress = progress;
      _dailyChallenge = dailyChallenge;
      _loading = false;
    });
  }

  BinaryPuzzleDefinition? get _savedDefinition {
    final game = _savedGame;
    if (game == null) return null;
    if (game.definition != null) return game.definition;
    for (final definition in binaryPuzzleCatalog) {
      if (definition.id == game.puzzleId) return definition;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final savedDefinition = _savedDefinition;
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
                Text(
                  'Binärpuzzle',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Setze 0 und 1 so, dass jede Reihe und Spalte aufgeht.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  if (_savedGame != null && savedDefinition != null) ...[
                    _HomeAction(
                      icon: Icons.play_circle_outline_rounded,
                      title: 'Weiterspielen',
                      subtitle:
                          '${_savedGame!.titleOverride ?? '${savedDefinition.difficulty.label} · ${savedDefinition.displayName}'} · ${_formatHomeTime(_savedGame!.elapsedSeconds)}',
                      enabled: true,
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => BinaryPuzzleScreen(
                              definition: savedDefinition,
                              savedGame: _savedGame,
                              titleOverride: _savedGame!.titleOverride,
                              storeDefinition: _savedGame!.isGenerated,
                              source: _savedGame!.source,
                            ),
                          ),
                        );
                        await _refresh();
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  _HomeAction(
                    icon: Icons.play_arrow_rounded,
                    title: 'Rätselsammlung',
                    subtitle: 'Wähle ein handverlesenes Rätsel',
                    enabled: true,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DifficultyScreen(),
                        ),
                      );
                      await _refresh();
                    },
                  ),
                  const SizedBox(height: 12),
                  _HomeAction(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Zufallsrätsel',
                    subtitle: 'Erstelle ein neues Rätsel nach deinen Wünschen',
                    enabled: true,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const GeneratedPuzzleSetupScreen(),
                        ),
                      );
                      await _refresh();
                    },
                  ),
                  const SizedBox(height: 12),
                  _HomeAction(
                    icon: Icons.calendar_today_outlined,
                    title: 'Tagesrätsel',
                    subtitle: _results.containsKey(_dailyChallenge!.puzzleId)
                        ? 'Heute gelöst · ${_dailyChallenge!.difficulty.label} · ${_dailyChallenge!.size} × ${_dailyChallenge!.size}'
                        : 'Heute offen · ${_dailyChallenge!.difficulty.label} · ${_dailyChallenge!.size} × ${_dailyChallenge!.size}',
                    enabled: true,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const DailyArchiveScreen(),
                        ),
                      );
                      await _refresh();
                    },
                  ),
                  const SizedBox(height: 12),
                  _HomeAction(
                    icon: Icons.bar_chart_rounded,
                    title: 'Deine Binärpuzzle-Statistik',
                    subtitle:
                        '${_catalogCompletedCount(_results)} von ${binaryPuzzleCatalog.length} Rätseln gelöst',
                    enabled: true,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => StatisticsScreen(
                            results: _results,
                            progress: _progress,
                            gameType: GameType.binairo,
                          ),
                        ),
                      );
                      await _refresh();
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DailyArchiveScreen extends StatefulWidget {
  const DailyArchiveScreen({super.key});

  @override
  State<DailyArchiveScreen> createState() => _DailyArchiveScreenState();
}

class _DailyArchiveScreenState extends State<DailyArchiveScreen> {
  static const _archiveDays = 30;
  final GameStorage _storage = GameStorage();
  final DailyChallengeService _service = const DailyChallengeService();
  Map<String, PuzzleResult> _results = const {};
  bool _loading = true;

  Future<void> _refresh() async {
    final results = await _storage.loadResults();
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _openChallenge(DailyChallengeSummary summary) async {
    final challenge = _service.challengeFor(summary.day);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BinaryPuzzleScreen(
          definition: challenge.definition,
          storeDefinition: true,
          source: PuzzleSource.daily,
          titleOverride: challenge.title,
        ),
      ),
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final challenges = _service.archiveSummaries(days: _archiveDays);
    final today = challenges.first;
    final todayCompleted = _results.containsKey(today.puzzleId);
    return Scaffold(
      appBar: AppBar(title: const Text('Tagesrätsel')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      todayCompleted
                                          ? Icons.check_circle_rounded
                                          : Icons.today_rounded,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        todayCompleted
                                            ? 'Heute bereits gelöst'
                                            : 'Dein heutiges Rätsel wartet',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                                fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${today.difficulty.label} · ${today.size} × ${today.size}',
                                ),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: () => _openChallenge(today),
                                  icon: Icon(
                                    todayCompleted
                                        ? Icons.replay_rounded
                                        : Icons.play_arrow_rounded,
                                  ),
                                  label: Text(
                                    todayCompleted
                                        ? 'Heute erneut spielen'
                                        : 'Tagesrätsel starten',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Kalender der letzten $_archiveDays Tage',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Vergangene Rätsel können nachgeholt werden. Das füllt den Kalender, repariert aber keinen verlorenen Spiel-Streak.',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: challenges.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.92,
                          ),
                          itemBuilder: (context, index) {
                            final challenge = challenges[index];
                            final completed =
                                _results.containsKey(challenge.puzzleId);
                            return _DailyCalendarTile(
                              challenge: challenge,
                              completed: completed,
                              isToday: index == 0,
                              onTap: () => _openChallenge(challenge),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        const Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            _CalendarLegend(
                              icon: Icons.check_circle_rounded,
                              label: 'Gelöst',
                            ),
                            _CalendarLegend(
                              icon: Icons.radio_button_unchecked_rounded,
                              label: 'Offen',
                            ),
                            _CalendarLegend(
                              icon: Icons.today_rounded,
                              label: 'Heute',
                            ),
                          ],
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

class _DailyCalendarTile extends StatelessWidget {
  const _DailyCalendarTile({
    required this.challenge,
    required this.completed,
    required this.isToday,
    required this.onTap,
  });

  final DailyChallengeSummary challenge;
  final bool completed;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: completed
          ? colors.primaryContainer
          : isToday
              ? colors.secondaryContainer
              : colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                completed
                    ? Icons.check_circle_rounded
                    : isToday
                        ? Icons.today_rounded
                        : Icons.radio_button_unchecked_rounded,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                '${challenge.day.day}.${challenge.day.month}.',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Text(
                '${challenge.size}×${challenge.size}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 5),
          Text(label),
        ],
      );
}

String _formatHomeTime(int seconds) {
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  return '$minutes:${rest.toString().padLeft(2, '0')}';
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.progress});

  final PlayerProgress progress;

  @override
  Widget build(BuildContext context) {
    final streak = progress.currentStreak;
    final secured = progress.completedToday;
    return Card(
      child: ListTile(
        leading: Icon(
          secured
              ? Icons.local_fire_department_rounded
              : Icons.local_fire_department_outlined,
          size: 32,
          color: secured ? Theme.of(context).colorScheme.primary : null,
        ),
        title: Text(
          streak == 1 ? '1 Tag Spielserie' : '$streak Tage Spielserie',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          secured
              ? 'Deine Serie ist für heute gesichert.'
              : streak == 0
                  ? 'Löse heute ein Rätsel und starte deine Serie.'
                  : 'Löse heute ein Rätsel, damit deine Serie weiterläuft.',
        ),
        trailing:
            secured ? const Icon(Icons.check_circle_outline_rounded) : null,
      ),
    );
  }
}

class _HomeAction extends StatelessWidget {
  const _HomeAction(
      {required this.icon,
      required this.title,
      required this.subtitle,
      this.enabled = false,
      this.onTap});
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
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ])),
            if (enabled)
              const Icon(Icons.arrow_forward_ios_rounded, size: 17)
            else
              const Text('BALD',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Welches Spiel?',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  _GameChoice(
                    icon: Icons.grid_4x4_rounded,
                    title: 'Binärpuzzle',
                    subtitle: 'Balance aus 0 und 1',
                    enabled: true,
                    onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                            builder: (_) => const DifficultyScreen())),
                  ),
                  const SizedBox(height: 12),
                  const _GameChoice(
                      icon: Icons.filter_none_rounded,
                      title: 'Hitori',
                      subtitle: 'Zahlen schwärzen und verbinden'),
                  const SizedBox(height: 12),
                  const _GameChoice(
                      icon: Icons.hub_outlined,
                      title: 'Hashi',
                      subtitle: 'Inseln mit Brücken verbinden'),
                ]),
          ),
        ),
      ),
    );
  }
}

class _GameChoice extends StatelessWidget {
  const _GameChoice(
      {required this.icon,
      required this.title,
      required this.subtitle,
      this.enabled = false,
      this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Icon(icon, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: enabled
            ? const Icon(Icons.arrow_forward_ios_rounded, size: 17)
            : const Text('IN ARBEIT',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
                Text('Schwierigkeit',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('Wähle die Schwierigkeit, die heute zu dir passt.',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 20),
                for (final difficulty in PuzzleDifficulty.values) ...[
                  Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      leading: Icon(
                          switch (difficulty) {
                            PuzzleDifficulty.easy => Icons.eco_outlined,
                            PuzzleDifficulty.medium =>
                              Icons.psychology_alt_outlined,
                            PuzzleDifficulty.hard =>
                              Icons.local_fire_department_outlined,
                          },
                          size: 32),
                      title: Text(difficulty.label,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(
                          '${difficulty.description} · ${puzzlesFor(difficulty).length} Rätsel'),
                      trailing:
                          const Icon(Icons.arrow_forward_ios_rounded, size: 17),
                      onTap: () =>
                          Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) =>
                            PuzzleSelectionScreen(difficulty: difficulty),
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
    final chapters = chaptersFor(widget.difficulty);
    final completed = puzzles
        .where((definition) => _results.containsKey(definition.id))
        .length;
    return Scaffold(
      appBar: AppBar(
        title: Text('Binärpuzzle · ${widget.difficulty.label}'),
      ),
      body: Center(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _CollectionProgressCard(
                      completed: completed,
                      total: puzzles.length,
                      label: '${widget.difficulty.label} · Rätselsammlung',
                    ),
                    const SizedBox(height: 16),
                    for (final chapter in chapters) ...[
                      _BinaryChapterCard(
                        chapter: chapter,
                        results: _results,
                        initiallyExpanded: chapter.index == 1,
                        onOpenPuzzle: (definition) async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  BinaryPuzzleScreen(definition: definition),
                            ),
                          );
                          await _loadResults();
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionProgressCard extends StatelessWidget {
  const _CollectionProgressCard({
    required this.completed,
    required this.total,
    required this.label,
  });

  final int completed;
  final int total;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text('$completed von $total Rätseln gelöst'),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: total == 0 ? 0 : completed / total,
            ),
          ),
        ],
      ),
    );
  }
}

class _BinaryChapterCard extends StatelessWidget {
  const _BinaryChapterCard({
    required this.chapter,
    required this.results,
    required this.initiallyExpanded,
    required this.onOpenPuzzle,
  });

  final BinaryPuzzleChapter chapter;
  final Map<String, PuzzleResult> results;
  final bool initiallyExpanded;
  final ValueChanged<BinaryPuzzleDefinition> onOpenPuzzle;

  @override
  Widget build(BuildContext context) {
    final completed = chapter.puzzles
        .where((puzzle) => results.containsKey(puzzle.id))
        .length;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: CircleAvatar(child: Text('${chapter.index}')),
        title: Text(
          chapter.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${chapter.description}\n$completed von ${chapter.puzzles.length} gelöst',
        ),
        children: [
          const Divider(height: 1),
          for (final definition in chapter.puzzles)
            _BinaryPuzzleListTile(
              definition: definition,
              result: results[definition.id],
              onTap: () => onOpenPuzzle(definition),
            ),
        ],
      ),
    );
  }
}

class _BinaryPuzzleListTile extends StatelessWidget {
  const _BinaryPuzzleListTile({
    required this.definition,
    required this.result,
    required this.onTap,
  });

  final BinaryPuzzleDefinition definition;
  final PuzzleResult? result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
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
              ? '${definition.size} × ${definition.size} · ${definition.clueCount} Vorgaben'
              : 'Bestzeit ${_formatHomeTime(result!.bestSeconds)} · ${definition.size} × ${definition.size}',
        ),
        trailing: Icon(
          result == null ? Icons.play_arrow_rounded : Icons.replay_rounded,
        ),
        onTap: onTap,
      );
}

class GeneratedPuzzleSetupScreen extends StatefulWidget {
  const GeneratedPuzzleSetupScreen({super.key});

  @override
  State<GeneratedPuzzleSetupScreen> createState() =>
      _GeneratedPuzzleSetupScreenState();
}

class _GeneratedPuzzleSetupScreenState
    extends State<GeneratedPuzzleSetupScreen> {
  BinaryPuzzleSize _size = BinaryPuzzleSize.small;
  PuzzleDifficulty _difficulty = PuzzleDifficulty.easy;
  bool _isGenerating = false;
  String? _errorMessage;

  Future<void> _generatePuzzle() async {
    if (_isGenerating) return;

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    // Give Flutter one frame to display the progress indicator before the
    // synchronous generator starts its work.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    try {
      final generated = const BinaryPuzzleGenerator().generate(
        size: _size.value,
        difficulty: _difficulty,
        seed: DateTime.now().microsecondsSinceEpoch,
      );

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BinaryPuzzleScreen(
            definition: generated.definition,
            storeDefinition: true,
            source: PuzzleSource.generated,
            titleOverride:
                '${_difficulty.label} · Zufallsrätsel ${_size.label}',
          ),
        ),
      );
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Das Rätsel konnte nicht erzeugt werden: $error';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Zufallsrätsel')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Stell dein Rätsel zusammen',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Wähle Größe und Schwierigkeit. Das Rätsel wird direkt auf deinem Gerät erstellt und auf eine eindeutige Lösung geprüft.',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                Text('Rastergröße',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        )),
                const SizedBox(height: 10),
                SegmentedButton<BinaryPuzzleSize>(
                  segments: [
                    for (final size in BinaryPuzzleSize.values)
                      ButtonSegment<BinaryPuzzleSize>(
                        value: size,
                        label: Text(size.label),
                      ),
                  ],
                  selected: {_size},
                  onSelectionChanged: _isGenerating
                      ? null
                      : (selection) => setState(() => _size = selection.first),
                ),
                const SizedBox(height: 24),
                Text('Schwierigkeit',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        )),
                const SizedBox(height: 10),
                SegmentedButton<PuzzleDifficulty>(
                  segments: [
                    for (final difficulty in PuzzleDifficulty.values)
                      ButtonSegment<PuzzleDifficulty>(
                        value: difficulty,
                        label: Text(difficulty.label),
                        tooltip: difficulty.description,
                      ),
                  ],
                  selected: {_difficulty},
                  onSelectionChanged: _isGenerating
                      ? null
                      : (selection) =>
                          setState(() => _difficulty = selection.first),
                ),
                const SizedBox(height: 8),
                Text(
                  _difficulty.description,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Material(
                    color: colors.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: colors.onErrorContainer),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isGenerating ? null : _generatePuzzle,
                  icon: _isGenerating
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome_rounded),
                  label: Text(
                    _isGenerating ? 'Rätsel wird erzeugt …' : 'Rätsel starten',
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Generierte Rätsel werden automatisch gespeichert und können im Binärpuzzle-Hub über „Spiel fortsetzen“ wieder geöffnet werden.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
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
    this.saveProgress = true,
    this.storeDefinition = false,
    this.source = PuzzleSource.catalog,
    this.titleOverride,
    super.key,
  });

  final BinaryPuzzleDefinition definition;
  final SavedGame? savedGame;
  final bool saveProgress;
  final bool storeDefinition;
  final PuzzleSource source;
  final String? titleOverride;

  @override
  State<BinaryPuzzleScreen> createState() => _BinaryPuzzleScreenState();
}

class _BinaryPuzzleScreenState extends State<BinaryPuzzleScreen>
    with WidgetsBindingObserver {
  final GameStorage _storage = GameStorage();
  late BinaryPuzzle puzzle;
  bool showIssues = true;
  late final Timer _timer;
  int elapsedSeconds = 0;
  int? _elapsedBeforeReset;
  bool _completionRecorded = false;
  CellPosition? _selectedCell;
  CellPosition? _hintCell;
  Set<CellPosition> _hintRelatedCells = const {};
  HintBudget _hintBudget = const HintBudget();
  int _hintsUsed = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    puzzle = widget.definition.createPuzzle();
    showIssues = true;
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    showIssues = PreferencesScope.of(context).showRuleIssues;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _saveGame();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final issues = puzzle.validate();
    final issueCells = {
      for (final issue in issues) ...issue.cells,
    };
    final premium = PreferencesScope.of(context).premiumSimulationEnabled;
    final hintLabel = premium
        ? 'Logischer Hinweis · Premium'
        : 'Logischer Hinweis · ${_hintBudget.remainingHints} übrig';

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
        bottomNavigationBar: puzzle.isSolved
            ? SafeArea(
                minimum: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (widget.source == PuzzleSource.generated)
                          FilledButton.icon(
                            onPressed: _startNextGeneratedPuzzle,
                            icon: const Icon(Icons.auto_awesome_rounded),
                            label: const Text('Noch eins'),
                          )
                        else if (widget.source == PuzzleSource.catalog &&
                            _hasNextPuzzle)
                          FilledButton.icon(
                            onPressed: () =>
                                Navigator.of(context).pushReplacement(
                              MaterialPageRoute<void>(
                                builder: (_) => BinaryPuzzleScreen(
                                  definition: _nextPuzzle!,
                                ),
                              ),
                            ),
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: const Text('Nächstes Rätsel'),
                          ),
                        OutlinedButton.icon(
                          onPressed: _reset,
                          icon: const Icon(Icons.replay_rounded),
                          label: const Text('Noch einmal'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : null,
        appBar: AppBar(
          title: Text(
            widget.titleOverride ??
                '${widget.definition.difficulty.label} · ${widget.definition.displayName}',
          ),
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
              tooltip: hintLabel,
              onPressed: puzzle.isSolved ? null : _showHint,
              icon: const Icon(Icons.lightbulb_outline_rounded),
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
                        selectedCell: _selectedCell,
                        hintCell: _hintCell,
                        hintRelatedCells: _hintRelatedCells,
                        animationsEnabled:
                            PreferencesScope.of(context).animationsEnabled,
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
                    OutlinedButton.icon(
                      onPressed: puzzle.isSolved ? null : _showHint,
                      icon: const Icon(Icons.lightbulb_outline_rounded),
                      label: Text(hintLabel),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Regelfehler markieren'),
                      subtitle: const Text(
                        'Markiert direkte Widersprüche, ohne die Lösung zu verraten.',
                      ),
                      value: showIssues,
                      onChanged: (value) {
                        setState(() => showIssues = value);
                        PreferencesScope.of(context).setShowRuleIssues(value);
                      },
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
      _selectedCell = CellPosition(row, column);
      _hintCell = null;
      _hintRelatedCells = const {};
      puzzle.cycleCell(row, column);
    });

    if (PreferencesScope.of(context).hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
    _saveGame();

    if (puzzle.isSolved) {
      _showSolvedDialog();
    }
  }

  Future<void> _showHint() async {
    final hint = findBinaryHint(puzzle);
    if (hint == null) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.psychology_alt_outlined),
          title: const Text('Hier hilft nur dein nächster Schritt'),
          content: const Text(
            'Aus dem aktuellen Spielstand lässt sich kein garantiert richtiger Wert ableiten. Prüfe mögliche Fehler oder löse zunächst einen anderen Bereich.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Okay'),
            ),
          ],
        ),
      );
      return;
    }

    final preferences = PreferencesScope.of(context);
    if (!preferences.premiumSimulationEnabled && !_hintBudget.canUseHint) {
      await _showHintRewardDialog();
      return;
    }

    if (!preferences.premiumSimulationEnabled) {
      setState(() => _hintBudget = _hintBudget.useHint());
    }
    _hintsUsed++;

    setState(() {
      _selectedCell = hint.position;
      _hintCell = hint.position;
      _hintRelatedCells = hint.relatedPositions.toSet();
    });

    final apply = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.lightbulb_outline_rounded),
        title: Text(hint.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hint.badge,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(hint.reason),
            const SizedBox(height: 16),
            Text(
              hint.coordinate,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(hint.action),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Nur markieren'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hinweis anwenden'),
          ),
        ],
      ),
    );

    if (apply == true && mounted) {
      setState(() {
        puzzle.setCell(
          hint.position.row,
          hint.position.column,
          hint.value,
        );
        _selectedCell = hint.position;
        _hintCell = null;
        _hintRelatedCells = const {};
      });
      if (PreferencesScope.of(context).hapticsEnabled) {
        HapticFeedback.lightImpact();
      }
      await _saveGame();
      if (puzzle.isSolved) _showSolvedDialog();
    }
  }

  Future<void> _showHintRewardDialog() async {
    final simulateAd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.ondemand_video_outlined),
        title: const Text('Keine Hinweise mehr'),
        content: const Text(
          'In der kostenlosen Version kannst du eine kurze Werbung ansehen und dafür einen weiteren Hinweis erhalten.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Später'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Werbung simulieren'),
          ),
        ],
      ),
    );
    if (simulateAd != true || !mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.smart_display_outlined),
        title: const Text('Simulierte Werbung'),
        content: const Text(
          'Hier wird später ein freiwilliges Rewarded-Ad eingeblendet. Für den Prototyp wird die Belohnung sofort vergeben.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Werbung abschließen'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _hintBudget = _hintBudget.earnRewardedHint());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Ein zusätzlicher Hinweis wurde freigeschaltet.')),
    );
  }

  void _runDeveloperAction(_DeveloperAction action) {
    setState(() {
      _hintCell = null;
      _hintRelatedCells = const {};
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

  Future<void> _showSolvedDialog() async {
    int? previousBestSeconds;
    String? collectionProgress;
    if (!_completionRecorded) {
      _completionRecorded = true;
      if (widget.saveProgress) {
        if (widget.source == PuzzleSource.catalog) {
          previousBestSeconds =
              (await _storage.loadResults())[widget.definition.id]?.bestSeconds;
        } else {
          previousBestSeconds = GameStatistics.fromAttempts(
            await _storage.loadAttempts(),
            gameType: GameType.binairo,
          )
              .filtered(
                mode: widget.source,
                difficulty: widget.definition.difficulty,
                boardSize: widget.definition.size,
              )
              .bestSeconds;
        }
        await _storage.recordCompletion(
          puzzleId: widget.definition.id,
          elapsedSeconds: elapsedSeconds,
          source: widget.source,
          difficulty: widget.definition.difficulty,
          boardSize: widget.definition.size,
          hintsUsed: _hintsUsed,
          rewardedHints: _hintBudget.rewardedHints,
        );
        await _storage.clearActiveGame();
        if (widget.source == PuzzleSource.catalog) {
          final results = await _storage.loadResults();
          final chapter = chaptersFor(widget.definition.difficulty).firstWhere(
            (chapter) => chapter.puzzles
                .any((puzzle) => puzzle.id == widget.definition.id),
          );
          final chapterSolved = chapter.puzzles
              .where((puzzle) => results.containsKey(puzzle.id))
              .length;
          final group = puzzlesFor(widget.definition.difficulty);
          final groupSolved =
              group.where((puzzle) => results.containsKey(puzzle.id)).length;
          collectionProgress =
              '${chapter.title}: $chapterSolved/${chapter.puzzles.length} · '
              'Sammlung: $groupSolved/${group.length}';
        }
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final isNewRecord =
          previousBestSeconds == null || elapsedSeconds < previousBestSeconds;
      showDialog<void>(
        context: context,
        builder: (context) {
          final animations =
              PreferencesScope.of(this.context).animationsEnabled;
          return AlertDialog(
            icon: TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: animations ? 550 : 0),
              tween: Tween(begin: 0.6, end: 1),
              curve: Curves.elasticOut,
              builder: (context, value, child) =>
                  Transform.scale(scale: value, child: child),
              child: const Icon(Icons.emoji_events_outlined, size: 42),
            ),
            title: Text(widget.source == PuzzleSource.daily
                ? 'Tagesrätsel geschafft!'
                : 'Gelöst!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.source == PuzzleSource.daily
                    ? 'Die Spielserie ist für heute gesichert.'
                    : 'Alle Regeln sind erfüllt.'),
                const SizedBox(height: 16),
                if (isNewRecord)
                  const Chip(
                    avatar: Icon(Icons.workspace_premium_outlined),
                    label: Text('Neue Bestzeit'),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CompactStatistic(
                      value: _formatTime(elapsedSeconds),
                      label: 'Zeit',
                    ),
                    _CompactStatistic(
                      value: '$_hintsUsed',
                      label: 'Hinweise',
                    ),
                    _CompactStatistic(
                      value: previousBestSeconds == null
                          ? '–'
                          : _formatTime(previousBestSeconds),
                      label: 'Bisher',
                    ),
                  ],
                ),
                if (collectionProgress != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    collectionProgress,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Brett ansehen'),
              ),
              if (widget.source == PuzzleSource.generated)
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _startNextGeneratedPuzzle();
                  },
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Noch eins'),
                )
              else if (widget.source == PuzzleSource.catalog)
                if (_hasNextPuzzle)
                  FilledButton.tonal(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(this.context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) => BinaryPuzzleScreen(
                            definition: _nextPuzzle!,
                          ),
                        ),
                      );
                    },
                    child: const Text('Nächstes Rätsel'),
                  )
                else
                  FilledButton.tonal(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(this.context).pop();
                    },
                    child: const Text('Zur Sammlung'),
                  ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _reset();
                },
                child: const Text('Noch einmal spielen'),
              ),
            ],
          );
        },
      );
    });
  }

  Future<void> _startNextGeneratedPuzzle() async {
    if (widget.source != PuzzleSource.generated) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(width: 18),
            Expanded(child: Text('Dein Rätsel wird vorbereitet …')),
          ],
        ),
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 50));

    try {
      final difficulty = widget.definition.difficulty;
      final size = widget.definition.size;
      final generated = const BinaryPuzzleGenerator().generate(
        size: size,
        difficulty: difficulty,
        seed: DateTime.now().microsecondsSinceEpoch,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => BinaryPuzzleScreen(
            definition: generated.definition,
            storeDefinition: true,
            source: PuzzleSource.generated,
            titleOverride: '${difficulty.label} · Zufallsrätsel $size × $size',
          ),
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Das Rätsel konnte gerade nicht erstellt werden: $error'),
        ),
      );
    }
  }

  void _undo() {
    final restoresReset = puzzle.nextUndoIsReset;
    setState(() {
      puzzle.undo();
      if (restoresReset && _elapsedBeforeReset != null) {
        elapsedSeconds = _elapsedBeforeReset!;
      }
      _hintCell = null;
      _hintRelatedCells = const {};
    });
    _saveGame();
  }

  void _redo() {
    final reappliesReset = puzzle.nextRedoIsReset;
    setState(() {
      puzzle.redo();
      if (reappliesReset) elapsedSeconds = 0;
      _hintCell = null;
      _hintRelatedCells = const {};
    });
    _saveGame();
  }

  bool get _hasNextPuzzle => _nextPuzzle != null;

  BinaryPuzzleDefinition? get _nextPuzzle {
    return nextPuzzleInDifficulty(widget.definition);
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;
    return '$minutes:${rest.toString().padLeft(2, '0')}';
  }

  Future<void> _reset() async {
    if (!await confirmPuzzleRestart(context) || !mounted) return;
    setState(() {
      _elapsedBeforeReset = elapsedSeconds;
      puzzle.reset();
      elapsedSeconds = 0;
      _completionRecorded = false;
      _selectedCell = null;
      _hintCell = null;
      _hintRelatedCells = const {};
    });
    _saveGame();
  }

  Future<void> _saveGame() {
    if (!widget.saveProgress) return Future<void>.value();
    return _storage.saveActiveGame(
      SavedGame(
        puzzleId: widget.definition.id,
        elapsedSeconds: elapsedSeconds,
        values: puzzle.exportEditableValues(),
        savedAt: DateTime.now(),
        definition: widget.storeDefinition ? widget.definition : null,
        titleOverride: widget.titleOverride,
        source: widget.source,
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

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final preferences = PreferencesScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: Center(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: AnimatedBuilder(
                animation: preferences,
                builder: (context, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Darstellung',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: DropdownButtonFormField<AppThemePreference>(
                          initialValue: preferences.themePreference,
                          decoration: const InputDecoration(
                            labelText: 'Farbschema',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            for (final value in AppThemePreference.values)
                              DropdownMenuItem(
                                value: value,
                                child: Text(value.label),
                              ),
                          ],
                          onChanged: (value) {
                            if (value != null) preferences.setTheme(value);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('Animationen'),
                            subtitle: const Text(
                              'Zahlenwechsel und Erfolgsanimationen anzeigen',
                            ),
                            value: preferences.animationsEnabled,
                            onChanged: preferences.setAnimationsEnabled,
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            title: const Text('Haptisches Feedback'),
                            subtitle: const Text(
                              'Kurze Rückmeldung auf unterstützten Geräten',
                            ),
                            value: preferences.hapticsEnabled,
                            onChanged: preferences.setHapticsEnabled,
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            title: const Text('Regelfehler markieren'),
                            subtitle: const Text(
                              'Standardwert für neu geöffnete Rätsel',
                            ),
                            value: preferences.showRuleIssues,
                            onChanged: preferences.setShowRuleIssues,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Monetarisierung testen',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: SwitchListTile(
                        secondary: const Icon(Icons.workspace_premium_outlined),
                        title: const Text('Premium simulieren'),
                        subtitle: Text(
                          preferences.premiumSimulationEnabled
                              ? 'Werbefrei und Hinweise ohne Begrenzung'
                              : 'Kostenlose Version mit drei Hinweisen pro Rätsel',
                        ),
                        value: preferences.premiumSimulationEnabled,
                        onChanged: preferences.setPremiumSimulationEnabled,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Sicherung & Wiederherstellung',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: Column(
                        children: [
                          const ListTile(
                            leading: Icon(Icons.cloud_done_outlined),
                            title: Text('Android-Gerätesicherung aktiv'),
                            subtitle: Text(
                              'Android kann deine lokalen App-Daten geschützt mit deinem Google-Konto sichern.',
                            ),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.copy_all_outlined),
                            title: const Text('Sicherung kopieren'),
                            subtitle: const Text(
                              'Erstellt eine vollständige, versionierte Sicherung in der Zwischenablage',
                            ),
                            onTap: () => _copyBackup(context),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.settings_backup_restore),
                            title: const Text('Sicherung wiederherstellen'),
                            subtitle: const Text(
                              'Prüft die Sicherung vollständig vor dem Import',
                            ),
                            onTap: () => _restoreBackup(context),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.undo_rounded),
                            title: const Text('Import rückgängig machen'),
                            subtitle: const Text(
                              'Stellt den lokalen Stand vor dem letzten Import wieder her',
                            ),
                            onTap: () => _restoreRecoveryBackup(context),
                          ),
                          const Divider(height: 1),
                          const ListTile(
                            leading: Icon(Icons.cloud_sync_outlined),
                            title: Text('Google-Cloud-Synchronisierung'),
                            subtitle: Text(
                              'Vorbereitet · folgt mit der endgültigen App-ID und Google-Anmeldung',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Importierte Daten ersetzen den aktuellen Stand. Vorher wird automatisch eine lokale Sicherheitskopie erstellt.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Lokale Daten',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        title: const Text('Gespeicherte Daten löschen'),
                        subtitle: const Text(
                          'Entfernt aktives Spiel, Bestzeiten und Statistik',
                        ),
                        onTap: () => _confirmReset(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Alle Einstellungen und Spielstände werden nur lokal auf diesem Gerät beziehungsweise in diesem Browser gespeichert.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: const Text('Wirklich alles löschen?'),
        content: const Text(
          'Aktives Spiel, Bestzeiten und die gesamte Statistik werden dauerhaft gelöscht. Die Einstellungen bleiben erhalten.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await GameStorage().clearAllProgress();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Deine gespeicherten Daten wurden gelöscht.')),
    );
  }

  Future<void> _copyBackup(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final backup = await const DataBackupService().createBackup();
      await Clipboard.setData(ClipboardData(text: backup));
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Vollständige Sicherung wurde kopiert.'),
        ),
      );
    } on Object {
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Sicherung konnte nicht erstellt werden.')),
      );
    }
  }

  Future<void> _restoreBackup(BuildContext context) async {
    final controller = TextEditingController();
    final backup = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.settings_backup_restore),
        title: const Text('Sicherung einfügen'),
        content: TextField(
          controller: controller,
          minLines: 5,
          maxLines: 10,
          decoration: const InputDecoration(
            hintText: 'Project-Logic-Sicherung hier einfügen',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Prüfen'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (backup == null || backup.trim().isEmpty || !context.mounted) return;

    const service = DataBackupService();
    try {
      final summary = service.inspect(backup.trim());
      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.verified_outlined),
          title: const Text('Gültige Sicherung gefunden'),
          content: Text(
            '${summary.entryCount} Datenbereiche vom ${_backupDate(summary.createdAt)} wiederherstellen? Der aktuelle Stand wird vorher lokal gesichert.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Wiederherstellen'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await service.restoreBackup(backup.trim());
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sicherung wiederhergestellt. App bitte neu öffnen.'),
        ),
      );
    } on BackupValidationException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _restoreRecoveryBackup(BuildContext context) async {
    const service = DataBackupService();
    if (!await service.hasRecoveryBackup()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keine Sicherheitskopie vorhanden.')),
      );
      return;
    }
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.undo_rounded),
        title: const Text('Import rückgängig machen?'),
        content: const Text(
          'Der lokale Stand vor dem letzten Import wird wiederhergestellt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Wiederherstellen'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await service.restoreRecoveryBackup();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Vorheriger Stand wiederhergestellt. App bitte neu öffnen.'),
      ),
    );
  }

  static String _backupDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year} um ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

int _dailyStreak(List<PuzzleResult> results, {DateTime? now}) {
  if (results.isEmpty) return 0;
  final days = results
      .map((result) => DateTime(
            result.completedAt.year,
            result.completedAt.month,
            result.completedAt.day,
          ))
      .toSet()
      .toList()
    ..sort();
  final todayValue = now ?? DateTime.now();
  final today = DateTime(todayValue.year, todayValue.month, todayValue.day);
  if (today.difference(days.last).inDays > 1) return 0;
  var streak = 1;
  for (var index = days.length - 1; index > 0; index--) {
    if (days[index].difference(days[index - 1]).inDays == 1) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
}

class PlayerProfileScreen extends StatelessWidget {
  const PlayerProfileScreen({
    required this.results,
    required this.progress,
    super.key,
  });

  final Map<String, PuzzleResult> results;
  final PlayerProgress progress;

  @override
  Widget build(BuildContext context) {
    final snapshot = ProgressSnapshot(
      results: results,
      progress: progress,
      catalogPuzzleIds: {
        ...binaryPuzzleCatalog.map((puzzle) => puzzle.id),
        ...hashiPuzzleCatalog.map((puzzle) => 'hashi:${puzzle.id}'),
      },
    );
    const service = PlayerProgressService();
    final rank = service.rank(snapshot);
    final dailyMissions = service.dailyMissions(snapshot);
    final longTermMissions = service.longTermMissions(snapshot);
    final achievements = service.achievements(snapshot);
    final unlockedCount = achievements.where((goal) => goal.isCompleted).length;
    final upcomingAchievements = achievements
        .where((goal) => !goal.isCompleted)
        .toList()
      ..sort((a, b) => b.progress.compareTo(a.progress));
    final completedAchievements =
        achievements.where((goal) => goal.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Dein Fortschritt')),
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
                          CircleAvatar(
                            radius: 38,
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            child: Icon(
                              Icons.psychology_alt_rounded,
                              size: 42,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Level ${rank.level}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(rank.title),
                          const SizedBox(height: 16),
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 650),
                            tween: Tween(begin: 0, end: rank.progress),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) =>
                                LinearProgressIndicator(value: value),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${rank.currentXp} von ${rank.nextLevelXp} XP bis zum nächsten Level',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Heute',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Drei klare Ziele, die jeden Tag neu beginnen.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final mission in dailyMissions)
                    _ProgressGoalCard(goal: mission),
                  const SizedBox(height: 20),
                  Text(
                    'Langzeitziele',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fortschritt, der über den heutigen Tag hinaus zählt.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final mission in longTermMissions)
                    _ProgressGoalCard(goal: mission),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Erfolge',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Text('$unlockedCount von ${achievements.length}'),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final achievement in upcomingAchievements.take(5))
                    _ProgressGoalCard(goal: achievement),
                  if (upcomingAchievements.length > 5 ||
                      completedAchievements.isNotEmpty)
                    Card(
                      child: ExpansionTile(
                        leading: const Icon(Icons.inventory_2_outlined),
                        title: const Text('Alle Erfolge'),
                        subtitle: Text(
                          '${completedAchievements.length} freigeschaltet · ${achievements.length} insgesamt',
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                        children: [
                          for (final achievement
                              in upcomingAchievements.skip(5))
                            _ProgressGoalCard(goal: achievement),
                          for (final achievement in completedAchievements)
                            _ProgressGoalCard(goal: achievement),
                        ],
                      ),
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

class _ProgressGoalCard extends StatelessWidget {
  const _ProgressGoalCard({required this.goal});

  final ProgressGoal goal;

  @override
  Widget build(BuildContext context) {
    final completed = goal.isCompleted;
    final colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: completed
                    ? colors.primaryContainer
                    : colors.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                completed ? Icons.check_rounded : _goalIcon(goal.iconName),
                color: completed
                    ? colors.onPrimaryContainer
                    : colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          goal.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (completed)
                        const Text(
                          'Geschafft',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        )
                      else
                        Text(
                          '${goal.current.clamp(0, goal.target)} / ${goal.target}',
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(goal.description),
                  const SizedBox(height: 10),
                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 550),
                    tween: Tween(begin: 0, end: goal.progress),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) =>
                        LinearProgressIndicator(value: value),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _goalIcon(String name) => switch (name) {
        'flag' => Icons.flag_outlined,
        'psychology' => Icons.psychology_alt_outlined,
        'workspace_premium' => Icons.workspace_premium_outlined,
        'local_fire_department' => Icons.local_fire_department_outlined,
        'calendar_month' => Icons.calendar_month_outlined,
        'today' => Icons.today_outlined,
        'auto_awesome' => Icons.auto_awesome_outlined,
        'collections_bookmark' => Icons.collections_bookmark_outlined,
        'diamond' => Icons.diamond_outlined,
        'grid_on' => Icons.grid_on_outlined,
        'hub' => Icons.hub_outlined,
        'menu_book' => Icons.menu_book_outlined,
        _ => Icons.emoji_events_outlined,
      };
}

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({
    required this.results,
    required this.progress,
    this.gameType,
    super.key,
  });

  final Map<String, PuzzleResult> results;
  final PlayerProgress progress;
  final GameType? gameType;

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<PuzzleAttempt> _attempts = const [];

  @override
  void initState() {
    super.initState();
    _loadAttempts();
  }

  Future<void> _loadAttempts() async {
    final attempts = await GameStorage().loadAttempts();
    if (mounted) setState(() => _attempts = attempts);
  }

  @override
  Widget build(BuildContext context) {
    final results = widget.results;
    final progress = widget.progress;
    final catalogIds = binaryPuzzleCatalog.map((puzzle) => puzzle.id).toSet();
    final catalogResults = <String, PuzzleResult>{
      for (final entry in results.entries)
        if (catalogIds.contains(entry.key)) entry.key: entry.value,
    };
    final generatedResults = results.values
        .where((result) =>
            result.gameType == GameType.binairo &&
            result.effectiveSource == GameMode.generated)
        .toList(growable: false);
    final dailyResults = results.values
        .where((result) =>
            result.gameType == GameType.binairo &&
            result.effectiveSource == GameMode.daily)
        .toList(growable: false);
    final catalogCompleted = catalogResults.length;
    final catalogTotal = binaryPuzzleCatalog.length;
    final generatedCompleted = generatedResults.fold<int>(
      0,
      (sum, result) => sum + result.completionCount,
    );
    final dailyCompleted = dailyResults.length;
    final todayDailyId = const DailyChallengeService().today().puzzleId;
    final dailyCompletedToday = results.containsKey(todayDailyId);
    final dailyStreak = _dailyStreak(dailyResults);
    final resultCompletionCount = results.values.fold<int>(
      0,
      (sum, result) => sum + result.completionCount,
    );
    final totalCompleted = progress.totalCompleted > resultCompletionCount
        ? progress.totalCompleted
        : resultCompletionCount;
    final averageSeconds =
        totalCompleted == 0 ? 0 : progress.totalPlaySeconds ~/ totalCompleted;
    final binairoStatistics = GameStatistics.fromAttempts(
      _attempts,
      gameType: GameType.binairo,
    );
    final hashiStatistics = GameStatistics.fromAttempts(
      _attempts,
      gameType: GameType.hashi,
    );
    final binairoResults = results.values
        .where((result) => result.gameType == GameType.binairo)
        .toList(growable: false);
    final binairoCompleted = binairoResults.fold<int>(
      0,
      (sum, result) => sum + result.completionCount,
    );
    final binairoPlaySeconds = binairoResults.fold<int>(
      0,
      (sum, result) => sum + result.totalElapsedSeconds,
    );
    final binairoAverageSeconds =
        binairoCompleted == 0 ? 0 : binairoPlaySeconds ~/ binairoCompleted;
    final hashiCompleted = results.values
        .where((result) => result.gameType == GameType.hashi)
        .fold<int>(0, (sum, result) => sum + result.completionCount);
    final hashiCollectionCompleted = results.values
        .where((result) =>
            result.gameType == GameType.hashi &&
            result.effectiveSource == GameMode.catalog)
        .map((result) => result.puzzleId)
        .toSet()
        .length;
    final isBinairoDetail = widget.gameType == GameType.binairo;
    final isHashiDetail = widget.gameType == GameType.hashi;
    final isGameDetail = widget.gameType != null;
    final selectedStatistics = isBinairoDetail
        ? binairoStatistics
        : isHashiDetail
            ? hashiStatistics
            : GameStatistics.fromAttempts(_attempts);
    final selectedCompleted = isBinairoDetail
        ? binairoCompleted
        : isHashiDetail
            ? hashiCompleted
            : totalCompleted;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            isGameDetail ? '${widget.gameType!.label}-Statistik' : 'Statistik'),
      ),
      body: Center(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StatisticsHero(
                    value: selectedCompleted,
                    label: isGameDetail
                        ? '${widget.gameType!.label}-Rätsel gelöst'
                        : 'Rätsel insgesamt gelöst',
                  ),
                  if (isBinairoDetail) ...[
                    const SizedBox(height: 12),
                    _StatisticListCard(
                      icon: Icons.collections_bookmark_outlined,
                      title: 'Rätselsammlung',
                      subtitle: '$catalogCompleted von $catalogTotal gelöst',
                      trailing:
                          '${((catalogCompleted / catalogTotal) * 100).round()} %',
                    ),
                    const SizedBox(height: 12),
                    _StatisticListCard(
                      icon: Icons.all_inclusive_rounded,
                      title: 'Zufallsrätsel',
                      subtitle: '$generatedCompleted abgeschlossen',
                    ),
                    const SizedBox(height: 12),
                    _StatisticListCard(
                      icon: Icons.calendar_today_outlined,
                      title: 'Tagesrätsel',
                      subtitle: dailyCompletedToday
                          ? 'Heute gelöst · $dailyCompleted insgesamt'
                          : 'Heute noch offen · $dailyCompleted insgesamt',
                      trailing: '$dailyStreak Tage',
                    ),
                    const SizedBox(height: 12),
                    _StatisticListCard(
                      icon: Icons.timer_outlined,
                      title: 'Spielzeit',
                      subtitle: _formatLongTime(binairoPlaySeconds),
                      trailing: binairoCompleted == 0
                          ? null
                          : 'Ø ${_formatLongTime(binairoAverageSeconds)}',
                    ),
                    const SizedBox(height: 24),
                    _PerformanceStatisticsSection(
                      statistics: selectedStatistics,
                      legacyBestSeconds: _bestResultSeconds(binairoResults),
                    ),
                    const SizedBox(height: 24),
                    _ModePerformanceSection(
                      statistics: selectedStatistics,
                      modes: const [
                        GameMode.catalog,
                        GameMode.generated,
                        GameMode.daily,
                      ],
                    ),
                    const SizedBox(height: 24),
                    _DifficultyPerformanceSection(
                      statistics: selectedStatistics,
                      legacyResults: binairoResults,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Rätselsammlung',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    for (final difficulty in PuzzleDifficulty.values)
                      _DifficultyStatistic(
                        difficulty: difficulty,
                        results: catalogResults,
                      ),
                    const SizedBox(height: 24),
                    Text(
                      'Zufallsrätsel nach Größe',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    for (final size in BinaryPuzzleSize.values)
                      _GeneratedSizeStatistic(
                        size: size,
                        results: generatedResults,
                        statistics: binairoStatistics.filtered(
                          mode: GameMode.generated,
                          boardSize: size.value,
                        ),
                      ),
                  ] else if (isHashiDetail) ...[
                    const SizedBox(height: 12),
                    _StatisticListCard(
                      icon: Icons.collections_bookmark_outlined,
                      title: 'Rätselsammlung',
                      subtitle:
                          '$hashiCollectionCompleted von ${hashiPuzzleCatalog.length} gelöst',
                      trailing:
                          '${((hashiCollectionCompleted / hashiPuzzleCatalog.length) * 100).round()} %',
                    ),
                    const SizedBox(height: 12),
                    _StatisticListCard(
                      icon: Icons.timer_outlined,
                      title: 'Spielzeit',
                      subtitle:
                          _formatLongTime(hashiStatistics.totalPlaySeconds),
                      trailing: hashiStatistics.averageSeconds == null
                          ? null
                          : 'Ø ${_formatLongTime(hashiStatistics.averageSeconds!)}',
                    ),
                    const SizedBox(height: 24),
                    _PerformanceStatisticsSection(
                      statistics: hashiStatistics,
                      legacyBestSeconds: _bestResultSeconds(
                        results.values.where(
                          (result) => result.gameType == GameType.hashi,
                        ),
                      ),
                      showMoves: true,
                    ),
                    const SizedBox(height: 24),
                    _ModePerformanceSection(
                      statistics: hashiStatistics,
                      modes: const [GameMode.catalog, GameMode.generated],
                      showMoves: true,
                    ),
                    const SizedBox(height: 24),
                    _DifficultyPerformanceSection(
                      statistics: hashiStatistics,
                      legacyResults: results.values
                          .where(
                            (result) => result.gameType == GameType.hashi,
                          )
                          .toList(growable: false),
                      showMoves: true,
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    _StatisticListCard(
                      icon: Icons.local_fire_department_outlined,
                      title: '${progress.currentStreak} Tage Spielserie',
                      subtitle: progress.completedToday
                          ? 'Heute gesichert · Beste Serie: ${progress.bestStreak} Tage'
                          : 'Heute noch ein Rätsel lösen · Beste Serie: ${progress.bestStreak} Tage',
                    ),
                    const SizedBox(height: 12),
                    _StatisticListCard(
                      icon: Icons.timer_outlined,
                      title: 'Gesamte Spielzeit',
                      subtitle: _formatLongTime(progress.totalPlaySeconds),
                      trailing: totalCompleted == 0
                          ? null
                          : 'Ø ${_formatLongTime(averageSeconds)}',
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Deine Spiele',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kompakte Übersicht – ausführliche Werte findest du direkt im jeweiligen Spielbereich.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 10),
                    _GameStatisticsOverviewCard(
                      gameType: GameType.binairo,
                      icon: Icons.grid_view_rounded,
                      completed: binairoCompleted,
                      catalogCompleted: catalogCompleted,
                      catalogTotal: catalogTotal,
                      endlessCompleted: generatedCompleted,
                      solvedWithoutHints: binairoStatistics.solvedWithoutHints,
                      onOpenDetails: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => StatisticsScreen(
                            results: results,
                            progress: progress,
                            gameType: GameType.binairo,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _GameStatisticsOverviewCard(
                      gameType: GameType.hashi,
                      icon: Icons.hub_outlined,
                      completed: hashiCompleted,
                      catalogCompleted: hashiCollectionCompleted,
                      catalogTotal: hashiPuzzleCatalog.length,
                      endlessCompleted: hashiStatistics.completedForMode(
                        GameMode.generated,
                      ),
                      solvedWithoutHints: hashiStatistics.solvedWithoutHints,
                      onOpenDetails: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => StatisticsScreen(
                            results: results,
                            progress: progress,
                            gameType: GameType.hashi,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _RecentActivitySection(attempts: _attempts),
                  ],
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

  static int? _bestResultSeconds(Iterable<PuzzleResult> results) {
    final values = results.map((result) => result.bestSeconds);
    if (values.isEmpty) return null;
    return values.reduce((best, value) => value < best ? value : best);
  }
}

class _StatisticsHero extends StatelessWidget {
  const _StatisticsHero({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                '$value',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(label),
            ],
          ),
        ),
      );
}

class _StatisticListCard extends StatelessWidget {
  const _StatisticListCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: trailing == null ? null : Text(trailing!),
        ),
      );
}

class _PerformanceStatisticsSection extends StatelessWidget {
  const _PerformanceStatisticsSection({
    required this.statistics,
    this.legacyBestSeconds,
    this.showMoves = false,
  });

  final GameStatistics statistics;
  final int? legacyBestSeconds;
  final bool showMoves;

  @override
  Widget build(BuildContext context) {
    String time(int? seconds) =>
        seconds == null ? '–' : _StatisticsScreenState._formatLongTime(seconds);
    final recordedBest = statistics.bestSeconds;
    final bestSeconds = recordedBest == null
        ? legacyBestSeconds
        : legacyBestSeconds == null
            ? recordedBest
            : recordedBest < legacyBestSeconds!
                ? recordedBest
                : legacyBestSeconds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Leistung', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _CompactStatistic(
                        value: time(bestSeconds),
                        label: 'Bestzeit',
                      ),
                    ),
                    Expanded(
                      child: _CompactStatistic(
                        value: time(statistics.averageSeconds),
                        label: 'Durchschnitt',
                      ),
                    ),
                    Expanded(
                      child: _CompactStatistic(
                        value: time(statistics.bestWithoutHintsSeconds),
                        label: 'Bestzeit ohne Hilfe',
                      ),
                    ),
                  ],
                ),
                const Divider(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: _CompactStatistic(
                        value: '${statistics.solvedWithoutHints}',
                        label: 'Ohne Hinweise',
                      ),
                    ),
                    Expanded(
                      child: _CompactStatistic(
                        value: '${statistics.hintsUsed}',
                        label: 'Hinweise genutzt',
                      ),
                    ),
                    Expanded(
                      child: _CompactStatistic(
                        value: showMoves
                            ? (statistics.fewestMoves?.toString() ?? '–')
                            : '${statistics.rewardedHints}',
                        label: showMoves ? 'Wenigste Züge' : 'Bonus-Hinweise',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (statistics.completedCount == 0 && legacyBestSeconds == null) ...[
          const SizedBox(height: 6),
          Text(
            'Deine Rekorde erscheinen nach dem nächsten abgeschlossenen Rätsel.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }
}

class _DifficultyPerformanceSection extends StatelessWidget {
  const _DifficultyPerformanceSection({
    required this.statistics,
    this.legacyResults = const [],
    this.showMoves = false,
  });

  final GameStatistics statistics;
  final List<PuzzleResult> legacyResults;
  final bool showMoves;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Nach Schwierigkeit',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        for (final difficulty in PuzzleDifficulty.values)
          _DifficultyPerformanceCard(
            difficulty: difficulty,
            statistics: statistics.filtered(difficulty: difficulty),
            legacyBestSeconds: _bestForDifficulty(difficulty),
            completedCount: _completedForDifficulty(difficulty),
            showMoves: showMoves,
          ),
      ],
    );
  }

  int? _bestForDifficulty(PuzzleDifficulty difficulty) {
    final values = legacyResults
        .where((result) => result.effectiveDifficulty == difficulty)
        .map((result) => result.bestSeconds);
    if (values.isEmpty) return null;
    return values.reduce((best, value) => value < best ? value : best);
  }

  int _completedForDifficulty(PuzzleDifficulty difficulty) {
    final recorded = statistics.completedForDifficulty(difficulty);
    final legacy = legacyResults
        .where((result) => result.effectiveDifficulty == difficulty)
        .fold<int>(0, (sum, result) => sum + result.completionCount);
    return recorded > legacy ? recorded : legacy;
  }
}

class _DifficultyPerformanceCard extends StatelessWidget {
  const _DifficultyPerformanceCard({
    required this.difficulty,
    required this.statistics,
    required this.legacyBestSeconds,
    required this.completedCount,
    required this.showMoves,
  });

  final PuzzleDifficulty difficulty;
  final GameStatistics statistics;
  final int? legacyBestSeconds;
  final int completedCount;
  final bool showMoves;

  @override
  Widget build(BuildContext context) {
    String time(int? seconds) =>
        seconds == null ? '–' : _StatisticsScreenState._formatLongTime(seconds);
    final recordedBest = statistics.bestSeconds;
    final bestSeconds = recordedBest == null
        ? legacyBestSeconds
        : legacyBestSeconds == null
            ? recordedBest
            : recordedBest < legacyBestSeconds!
                ? recordedBest
                : legacyBestSeconds;
    return Card(
      child: ExpansionTile(
        leading: Icon(switch (difficulty) {
          PuzzleDifficulty.easy => Icons.eco_outlined,
          PuzzleDifficulty.medium => Icons.psychology_alt_outlined,
          PuzzleDifficulty.hard => Icons.local_fire_department_outlined,
        }),
        title: Text(difficulty.label),
        subtitle: Text('$completedCount abgeschlossen'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Row(
            children: [
              Expanded(
                child: _CompactStatistic(
                  value: time(bestSeconds),
                  label: 'Bestzeit',
                ),
              ),
              Expanded(
                child: _CompactStatistic(
                  value: time(statistics.averageSeconds),
                  label: 'Durchschnitt',
                ),
              ),
              Expanded(
                child: _CompactStatistic(
                  value: showMoves
                      ? (statistics.fewestMoves?.toString() ?? '–')
                      : '${statistics.solvedWithoutHints}',
                  label: showMoves ? 'Wenigste Züge' : 'Ohne Hinweise',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModePerformanceSection extends StatelessWidget {
  const _ModePerformanceSection({
    required this.statistics,
    required this.modes,
    this.showMoves = false,
  });

  final GameStatistics statistics;
  final List<GameMode> modes;
  final bool showMoves;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Nach Spielart', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Aufgeschlüsselt nach Sammlung, Zufalls- und Tagesrätseln.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 10),
          for (final mode in modes)
            _ModePerformanceCard(
              mode: mode,
              statistics: statistics.filtered(mode: mode),
              showMoves: showMoves,
            ),
        ],
      );
}

class _ModePerformanceCard extends StatelessWidget {
  const _ModePerformanceCard({
    required this.mode,
    required this.statistics,
    required this.showMoves,
  });

  final GameMode mode;
  final GameStatistics statistics;
  final bool showMoves;

  @override
  Widget build(BuildContext context) {
    String time(int? seconds) =>
        seconds == null ? '–' : _StatisticsScreenState._formatLongTime(seconds);
    final title = switch (mode) {
      GameMode.catalog => 'Sammlungsmodus',
      GameMode.generated => 'Zufallsrätsel',
      GameMode.daily => 'Tagesmodus',
      GameMode.event => 'Ereignisrätsel',
      GameMode.tutorial => 'Einführung',
    };
    final icon = switch (mode) {
      GameMode.catalog => Icons.collections_bookmark_outlined,
      GameMode.generated => Icons.auto_awesome_outlined,
      GameMode.daily => Icons.calendar_today_outlined,
      GameMode.event => Icons.celebration_outlined,
      GameMode.tutorial => Icons.school_outlined,
    };

    return Card(
      child: ExpansionTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text('${statistics.completedCount} abgeschlossen'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Row(
            children: [
              Expanded(
                child: _CompactStatistic(
                  value: time(statistics.bestSeconds),
                  label: 'Bestzeit',
                ),
              ),
              Expanded(
                child: _CompactStatistic(
                  value: time(statistics.averageSeconds),
                  label: 'Durchschnitt',
                ),
              ),
              Expanded(
                child: _CompactStatistic(
                  value: _StatisticsScreenState._formatLongTime(
                    statistics.totalPlaySeconds,
                  ),
                  label: 'Spielzeit',
                ),
              ),
            ],
          ),
          const Divider(height: 28),
          Row(
            children: [
              Expanded(
                child: _CompactStatistic(
                  value: '${statistics.solvedWithoutHints}',
                  label: 'Ohne Hinweise',
                ),
              ),
              Expanded(
                child: _CompactStatistic(
                  value: '${statistics.hintsUsed}',
                  label: 'Hinweise',
                ),
              ),
              Expanded(
                child: _CompactStatistic(
                  value: showMoves
                      ? (statistics.averageMoves?.toString() ?? '–')
                      : '${statistics.rewardedHints}',
                  label: showMoves ? 'Ø Züge' : 'Bonus-Hinweise',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection({required this.attempts});

  final List<PuzzleAttempt> attempts;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day)
        .subtract(const Duration(days: 6));
    final recent = attempts
        .where((attempt) => !attempt.completedAt.isBefore(start))
        .toList(growable: false);
    final activeDays = recent
        .map((attempt) =>
            '${attempt.completedAt.year}-${attempt.completedAt.month}-${attempt.completedAt.day}')
        .toSet()
        .length;
    final playSeconds =
        recent.fold<int>(0, (sum, attempt) => sum + attempt.elapsedSeconds);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Letzte 7 Tage', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
            child: Row(
              children: [
                Expanded(
                  child: _CompactStatistic(
                    value: '${recent.length}',
                    label: 'Rätsel',
                  ),
                ),
                Expanded(
                  child: _CompactStatistic(
                    value: '$activeDays/7',
                    label: 'Aktive Tage',
                  ),
                ),
                Expanded(
                  child: _CompactStatistic(
                    value: _StatisticsScreenState._formatLongTime(playSeconds),
                    label: 'Spielzeit',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GameStatisticsOverviewCard extends StatelessWidget {
  const _GameStatisticsOverviewCard({
    required this.gameType,
    required this.icon,
    required this.completed,
    required this.catalogCompleted,
    required this.catalogTotal,
    required this.endlessCompleted,
    required this.solvedWithoutHints,
    required this.onOpenDetails,
  });

  final GameType gameType;
  final IconData icon;
  final int completed;
  final int catalogCompleted;
  final int catalogTotal;
  final int endlessCompleted;
  final int solvedWithoutHints;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final progress = catalogTotal == 0 ? 0.0 : catalogCompleted / catalogTotal;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.onPrimaryContainer,
          child: Icon(icon),
        ),
        title: Text(
          gameType.label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('$completed Rätsel abgeschlossen'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          LinearProgressIndicator(value: progress.clamp(0, 1)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CompactStatistic(
                  value: '$catalogCompleted/$catalogTotal',
                  label: 'Sammlung',
                ),
              ),
              Expanded(
                child: _CompactStatistic(
                  value: '$endlessCompleted',
                  label: 'Zufallsrätsel',
                ),
              ),
              Expanded(
                child: _CompactStatistic(
                  value: '$solvedWithoutHints',
                  label: 'Ohne Hinweise*',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onOpenDetails,
              icon: const Icon(Icons.insights_outlined),
              label: const Text('Alle Statistiken'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactStatistic extends StatelessWidget {
  const _CompactStatistic({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      );
}

class _GeneratedSizeStatistic extends StatelessWidget {
  const _GeneratedSizeStatistic({
    required this.size,
    required this.results,
    required this.statistics,
  });

  final BinaryPuzzleSize size;
  final List<PuzzleResult> results;
  final GameStatistics statistics;

  @override
  Widget build(BuildContext context) {
    int completedFor(PuzzleDifficulty difficulty) => results
        .where((result) =>
            result.effectiveBoardSize == size.value &&
            result.effectiveDifficulty == difficulty)
        .fold<int>(0, (sum, result) => sum + result.completionCount);

    final counts = {
      for (final difficulty in PuzzleDifficulty.values)
        difficulty: completedFor(difficulty),
    };
    final total = counts.values.fold<int>(0, (sum, count) => sum + count);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.grid_4x4_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    size.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Text('$total gesamt'),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Schwierigkeit',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: Text(
                    'Gelöst',
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                SizedBox(
                  width: 82,
                  child: Text(
                    'Bestzeit',
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ),
            for (final difficulty in PuzzleDifficulty.values)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(child: Text(difficulty.label)),
                    SizedBox(
                      width: 72,
                      child: Text(
                        '${counts[difficulty]}',
                        textAlign: TextAlign.end,
                      ),
                    ),
                    SizedBox(
                      width: 82,
                      child: Text(
                        _formatBestTime(
                          _bestSecondsFor(difficulty),
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _formatBestTime(int? seconds) =>
      seconds == null ? '–' : _StatisticsScreenState._formatLongTime(seconds);

  int? _bestSecondsFor(PuzzleDifficulty difficulty) {
    final recorded = statistics.filtered(difficulty: difficulty).bestSeconds;
    final legacy = results
        .where((result) =>
            result.effectiveBoardSize == size.value &&
            result.effectiveDifficulty == difficulty)
        .map((result) => result.bestSeconds);
    if (legacy.isEmpty) return recorded;
    final legacyBest =
        legacy.reduce((best, value) => value < best ? value : best);
    if (recorded == null) return legacyBest;
    return recorded < legacyBest ? recorded : legacyBest;
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
    required this.selectedCell,
    required this.hintCell,
    required this.hintRelatedCells,
    required this.animationsEnabled,
    required this.onCellPressed,
  });

  final BinaryPuzzle puzzle;
  final Set<CellPosition> issueCells;
  final CellPosition? selectedCell;
  final CellPosition? hintCell;
  final Set<CellPosition> hintRelatedCells;
  final bool animationsEnabled;
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

            final isSelected = selectedCell == CellPosition(row, column);
            final isRelated = selectedCell != null &&
                (selectedCell!.row == row || selectedCell!.column == column);
            final position = CellPosition(row, column);
            final isHint = hintCell == position;
            final isHintRelated =
                hintRelatedCells.contains(position) && !isHint;

            return _PuzzleCell(
              value: value,
              clue: clue,
              hasIssue: hasIssue,
              isSelected: isSelected,
              isRelated: isRelated,
              isHint: isHint,
              isHintRelated: isHintRelated,
              animationsEnabled: animationsEnabled,
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
    required this.isSelected,
    required this.isRelated,
    required this.isHint,
    required this.isHintRelated,
    required this.animationsEnabled,
    required this.onPressed,
  });

  final CellValue? value;
  final bool clue;
  final bool hasIssue;
  final bool isSelected;
  final bool isRelated;
  final bool isHint;
  final bool isHintRelated;
  final bool animationsEnabled;
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
      child: AnimatedContainer(
        duration: Duration(milliseconds: animationsEnabled ? 160 : 0),
        decoration: BoxDecoration(
          color: isHint
              ? colors.primaryContainer
              : isHintRelated && !hasIssue
                  ? colors.secondaryContainer.withValues(alpha: 0.55)
                  : isRelated && value == null && !hasIssue
                      ? colors.surfaceContainerHigh
                      : background,
          border: Border.all(
            color: isSelected || isHint
                ? colors.primary
                : isHintRelated
                    ? colors.secondary
                    : colors.outlineVariant,
            width: isSelected || isHint
                ? 2.2
                : isHintRelated
                    ? 1.4
                    : 0.6,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            child: Center(
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: animationsEnabled ? 140 : 0),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Text(
                  value?.label ?? '',
                  key: ValueKey(value),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: foreground,
                        fontWeight: clue ? FontWeight.w800 : FontWeight.w700,
                      ),
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
      title: const Text('So funktioniert es'),
      childrenPadding: const EdgeInsets.only(bottom: 12),
      children: [
        const _RuleLine(
            'In jeder Reihe und Spalte stehen gleich viele 0 und 1.'),
        const _RuleLine(
            'Drei gleiche Zahlen dürfen nie direkt aufeinanderfolgen.'),
        const _RuleLine(
            'Keine zwei fertigen Reihen oder Spalten dürfen identisch sein.'),
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
