import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_localizations.dart';
import 'app_preferences.dart';
import 'app_data_migration.dart';
import 'app_theme.dart';
import 'core/monetization/hint_economy.dart';
import 'core/progress/experience_event.dart';
import 'core/progress/experience_points_policy.dart';
import 'core/presentation/confirm_restart_dialog.dart';
import 'core/presentation/mission_event_presentation.dart';
import 'core/presentation/personal_records_section.dart';
import 'core/presentation/puzzle_hub_components.dart';
import 'core/presentation/puzzle_interaction_feedback.dart';
import 'core/presentation/reminder_notifications.dart';
import 'core/presentation/rewarded_hint_dialog.dart';
import 'core/presentation/streak_calendar.dart';
import 'core/presentation/xp_award_badge.dart';
import 'core/statistics/game_statistics.dart';
import 'core/statistics/personal_records.dart';
import 'core/statistics/puzzle_attempt.dart';
import 'daily_challenge.dart';
import 'daily_snapshot_viewer.dart';
import 'data_backup.dart';
import 'game_logic.dart';
import 'game_storage.dart';
import 'hint_engine.dart';
import 'hashi_foundation.dart';
import 'hitori_foundation.dart';
import 'futoshiki_foundation.dart';
import 'player_progress_system.dart';
import 'slitherlink_foundation.dart';
import 'tents_game.dart';
import 'features/binary_puzzle/domain/binary_puzzle_generator.dart';
import 'features/hashi/domain/hashi_generator.dart';
import 'features/futoshiki/domain/futoshiki_generator.dart';
import 'features/futoshiki/domain/futoshiki_puzzle.dart';
import 'features/hitori/domain/hitori_generator.dart';
import 'features/hitori/domain/hitori_catalog.dart';
import 'features/tents/domain/tents_generator.dart';
import 'features/tents/domain/tents_puzzle.dart';
import 'features/tents/domain/tents_catalog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await const AppDataMigrationService().migrate();
  final preferences = await AppPreferences.load();
  runApp(ProjectLogicApp(preferences: preferences));
  unawaited(ReminderNotifications.configure(
    dailyEnabled: preferences.dailyReminderEnabled,
    dailyMinutes: preferences.dailyReminderMinutes,
    streakEnabled: preferences.streakWarningEnabled,
    streakMinutes: preferences.streakWarningMinutes,
  ));
  if (preferences.soundsEnabled) PuzzleInteractionFeedback.warmUpSounds();
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
          locale: preferences.languagePreference.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localeResolutionCallback: (locale, supportedLocales) =>
              AppLocalizations.resolve(locale, supportedLocales),
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          themeMode: preferences.themePreference.themeMode,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          builder: (context, child) => SafeArea(
            top: false,
            left: false,
            right: false,
            child: child ?? const SizedBox.shrink(),
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
  PlayerRank? _rank;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final results = await _storage.loadResults();
    final progress = await _storage.loadPlayerProgress();
    final attempts = await _storage.loadAttempts();
    final existingEvents = await _storage.loadExperienceEvents();
    final savedHashiGame = await HashiGameStore().load();
    final savedSlitherlinkGame = await SlitherlinkGameStore().load();
    const progressService = PlayerProgressService();
    final snapshot = ProgressSnapshot(
      results: results,
      progress: progress,
      catalogPuzzleIds: {
        ...binaryPuzzleCatalog.map((puzzle) => puzzle.id),
        ...hashiPuzzleCatalog.map((puzzle) => 'hashi:${puzzle.id}'),
        ...slitherlinkPuzzleCatalog.map((puzzle) => 'slitherlink:${puzzle.id}'),
        ...futoshikiPuzzleCatalog.map((puzzle) => puzzle.id),
        ...hitoriPuzzleCatalog.map((puzzle) => puzzle.id),
        ...tentsPuzzleCatalog.map((puzzle) => puzzle.id),
      },
      attempts: attempts,
    );
    final withAchievements = progressService.synchronizeAchievementXp(
      snapshot,
      existingEvents.values,
    );
    final synchronized = progressService.synchronizeMissionXp(
      snapshot,
      withAchievements,
    );
    await _storage.saveExperienceEvents(synchronized);
    final rank = progressService.rank(
      snapshot,
      experienceEvents: synchronized,
    );
    if (!mounted) return;
    setState(() {
      _results = results;
      _progress = progress;
      _savedHashiGame = savedHashiGame;
      _savedSlitherlinkGame = savedSlitherlinkGame;
      _rank = rank;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
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
                  const SizedBox(height: 16),
                  _HomeHeader(
                    completedToday: _progress.completedToday,
                    onSettings: () async {
                      await Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => const SettingsScreen(),
                      ));
                      await _refresh();
                    },
                  ),
                  const SizedBox(height: 18),
                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    if (_rank case final rank?) ...[
                      _HomeLevelCard(
                        rank: rank,
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
                      const SizedBox(height: 14),
                    ],
                    if (_savedHashiGame case final saved?) ...[
                      _HomeAction(
                        icon: Icons.play_circle_outline_rounded,
                        title:
                            strings.text('Hashi fortsetzen', 'Continue Hashi'),
                        subtitle:
                            '${saved.puzzle.sharedDifficulty.label} · ${saved.moves} ${strings.text('Züge', 'moves')} · ${_shortTime(saved.elapsedSeconds)}',
                        enabled: true,
                        emphasized: true,
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
                        title: strings.text(
                            'Slitherlink fortsetzen', 'Continue Slitherlink'),
                        subtitle:
                            '${saved.puzzle.rows} × ${saved.puzzle.columns} · ${saved.moves} ${strings.text('Züge', 'moves')} · ${_shortTime(saved.elapsedSeconds)}',
                        enabled: true,
                        emphasized: true,
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
                    const SizedBox(height: 28),
                    _HomeSectionHeader(
                      title: strings.text('Deine Spiele', 'Your games'),
                      subtitle: strings.text(
                        'Sechs Arten zu denken. Womit beginnst du?',
                        'Six ways to think. Where will you begin?',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _HomeAction(
                      icon: Icons.grid_4x4_rounded,
                      title: strings.text('Binärpuzzle', 'Binary puzzle'),
                      subtitle:
                          '${_catalogCompletedCount(_results)} ${strings.text('von', 'of')} ${binaryPuzzleCatalog.length} ${strings.text('Rätseln gelöst', 'puzzles solved')}',
                      enabled: true,
                      accent: AppTheme.gameColors['binairo'],
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
                      subtitle: strings.text(
                        'Entdecke Inseln, Brücken und das neue Spielgefühl',
                        'Discover islands, bridges, and a new way to play',
                      ),
                      enabled: true,
                      accent: AppTheme.gameColors['hashi'],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => HashiHubScreen(
                            onOpenDaily: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const DailyArchiveScreen(
                                  gameType: GameType.hashi,
                                ),
                              ),
                            ),
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
                      subtitle: strings.text(
                        'Zeichne eine einzige geschlossene Schleife',
                        'Draw one single closed loop',
                      ),
                      enabled: true,
                      accent: AppTheme.gameColors['slitherlink'],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => SlitherlinkHubScreen(
                            onOpenDaily: (slitherContext) =>
                                Navigator.of(slitherContext).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const DailyArchiveScreen(
                                  gameType: GameType.slitherlink,
                                ),
                              ),
                            ),
                            onOpenStatistics: (slitherContext) async {
                              final storage = GameStorage();
                              final results = await storage.loadResults();
                              final progress =
                                  await storage.loadPlayerProgress();
                              if (!slitherContext.mounted) return;
                              await Navigator.of(slitherContext).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => StatisticsScreen(
                                    results: results,
                                    progress: progress,
                                    gameType: GameType.slitherlink,
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
                      icon: Icons.compare_arrows_rounded,
                      title: 'Futoshiki',
                      subtitle: strings.text(
                        'Zahlen logisch in Beziehung setzen',
                        'Connect numbers through logical relations',
                      ),
                      enabled: true,
                      accent: AppTheme.gameColors['futoshiki'],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => FutoshikiHubScreen(
                            onOpenDaily: (futoshikiContext) =>
                                Navigator.of(futoshikiContext).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const DailyArchiveScreen(
                                  gameType: GameType.futoshiki,
                                ),
                              ),
                            ),
                            onOpenStatistics: (futoshikiContext) async {
                              final storage = GameStorage();
                              final results = await storage.loadResults();
                              final progress =
                                  await storage.loadPlayerProgress();
                              if (!futoshikiContext.mounted) return;
                              await Navigator.of(futoshikiContext).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => StatisticsScreen(
                                    results: results,
                                    progress: progress,
                                    gameType: GameType.futoshiki,
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
                      icon: Icons.filter_b_and_w_rounded,
                      title: 'Hitori',
                      subtitle: strings.text(
                        'Doppelte Zahlen geschickt schwärzen',
                        'Carefully shade duplicate numbers',
                      ),
                      enabled: true,
                      accent: AppTheme.gameColors['hitori'],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => HitoriHubScreen(
                            onOpenDaily: (hitoriContext) =>
                                Navigator.of(hitoriContext).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const DailyArchiveScreen(
                                  gameType: GameType.hitori,
                                ),
                              ),
                            ),
                            onOpenStatistics: (hitoriContext) async {
                              final storage = GameStorage();
                              final results = await storage.loadResults();
                              final progress =
                                  await storage.loadPlayerProgress();
                              if (!hitoriContext.mounted) return;
                              await Navigator.of(hitoriContext).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => StatisticsScreen(
                                    results: results,
                                    progress: progress,
                                    gameType: GameType.hitori,
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
                      icon: Icons.park_rounded,
                      title: strings.text('Zelte & Bäume', 'Tents & Trees'),
                      subtitle: strings.text(
                        'Finde für jeden Baum das passende Zelt',
                        'Find the matching tent for every tree',
                      ),
                      enabled: true,
                      accent: AppTheme.gameColors['tents'],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => TentsHubScreen(
                            onOpenDaily: (tentsContext) =>
                                Navigator.of(tentsContext).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const DailyArchiveScreen(
                                  gameType: GameType.tents,
                                ),
                              ),
                            ),
                            onOpenStatistics: (tentsContext) async {
                              final storage = GameStorage();
                              final results = await storage.loadResults();
                              final progress =
                                  await storage.loadPlayerProgress();
                              if (!tentsContext.mounted) return;
                              await Navigator.of(tentsContext).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => StatisticsScreen(
                                    results: results,
                                    progress: progress,
                                    gameType: GameType.tents,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _HomeSectionHeader(
                      title: strings.text('Dein Bereich', 'Your space'),
                      subtitle: strings.text(
                        'Fortschritt, Statistiken und Einstellungen',
                        'Progress, statistics, and settings',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _HomeAction(
                      icon: Icons.person_outline_rounded,
                      title: strings.text('Dein Fortschritt', 'Your progress'),
                      subtitle: strings.text(
                        'Level, Ziele und Erfolge auf einen Blick',
                        'Levels, goals, and achievements at a glance',
                      ),
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
                      title: strings.text('Statistik', 'Statistics'),
                      subtitle: strings.text(
                        'Deine bisherigen Partien und Bestleistungen',
                        'Your games and personal bests',
                      ),
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
                  ],
                  const SizedBox(height: 28),
                  Text(
                    'Project Logic · Designstudie 1',
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
    var savedGame = await _storage.loadActiveGame();
    if (savedGame != null) {
      final definition = savedGame.definition ??
          binaryPuzzleCatalog
              .where((candidate) => candidate.id == savedGame!.puzzleId)
              .firstOrNull;
      if (definition != null) {
        final savedPuzzle = definition.createPuzzle()
          ..restoreEditableValues(savedGame.values);
        if (savedPuzzle.isSolved) {
          await _storage.clearActiveGame();
          savedGame = null;
        }
      }
    }
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
      appBar:
          AppBar(title: Text(context.strings.text('Binärpuzzle', 'Binairo'))),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PuzzleHubHeader(
                  icon: Icons.grid_4x4_rounded,
                  title: 'Zwei Zahlen, klare Regeln',
                  description: 'Setze 0 und 1 so, dass jede Reihe und Spalte '
                      'aufgeht – ohne Dreiergruppen oder gleiche Reihen.',
                  accent: AppTheme.gameColors['binairo']!,
                  progress: _catalogCompletedCount(_results) /
                      binaryPuzzleCatalog.length,
                  progressLabel:
                      '${_catalogCompletedCount(_results)} von ${binaryPuzzleCatalog.length} Rätseln gelöst',
                ),
                const SizedBox(height: 24),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  if (_savedGame != null && savedDefinition != null) ...[
                    _HomeAction(
                      icon: Icons.play_circle_outline_rounded,
                      title: 'Rätsel fortsetzen',
                      subtitle:
                          '${_savedGame!.titleOverride ?? '${savedDefinition.difficulty.label} · ${savedDefinition.displayName}'} · ${_formatHomeTime(_savedGame!.elapsedSeconds)}',
                      enabled: true,
                      accent: AppTheme.gameColors['binairo'],
                      emphasized: true,
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
                    icon: Icons.calendar_today_outlined,
                    title: 'Tagesrätsel & Kalender',
                    subtitle: _results.containsKey(_dailyChallenge!.puzzleId)
                        ? 'Heute gelöst · ${_dailyChallenge!.difficulty.label} · ${_dailyChallenge!.size} × ${_dailyChallenge!.size}'
                        : 'Heute offen · ${_dailyChallenge!.difficulty.label} · ${_dailyChallenge!.size} × ${_dailyChallenge!.size}',
                    enabled: true,
                    accent: AppTheme.gameColors['binairo'],
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
                    icon: Icons.play_arrow_rounded,
                    title: 'Rätselsammlung',
                    subtitle: 'Wähle ein handverlesenes Rätsel',
                    enabled: true,
                    accent: AppTheme.gameColors['binairo'],
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
                    accent: AppTheme.gameColors['binairo'],
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
                    icon: Icons.bar_chart_rounded,
                    title: 'Binärpuzzle-Statistik',
                    subtitle:
                        '${_catalogCompletedCount(_results)} von ${binaryPuzzleCatalog.length} Rätseln gelöst',
                    enabled: true,
                    accent: AppTheme.gameColors['binairo'],
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
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () =>
                        Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) => const PuzzleRulesScreen(
                        title: 'Binärpuzzle',
                        introduction:
                            'Fülle das Raster ausschließlich mit 0 und 1.',
                        rules: [
                          'In jeder Zeile und Spalte stehen gleich viele Nullen und Einsen.',
                          'Nie dürfen drei gleiche Zahlen direkt nebeneinander oder untereinander stehen.',
                          'Keine zwei vollständigen Zeilen oder Spalten dürfen identisch sein.',
                        ],
                        interaction:
                            'Tippen wechselt ein freies Feld von leer zu 0, zu 1 und wieder zu leer.',
                      ),
                    )),
                    icon: const Icon(Icons.menu_book_rounded),
                    label: Text(
                        context.strings.text('Regeln ansehen', 'View rules')),
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
  const DailyArchiveScreen({this.gameType = GameType.binairo, super.key});

  final GameType gameType;

  @override
  State<DailyArchiveScreen> createState() => _DailyArchiveScreenState();
}

class _DailyArchiveScreenState extends State<DailyArchiveScreen> {
  static const _archiveDays = 30;
  final GameStorage _storage = GameStorage();
  final DailyChallengeService _service = const DailyChallengeService();
  Map<String, PuzzleResult> _results = const {};
  Map<String, DailyPuzzleSnapshot> _snapshots = const {};
  bool _loading = true;
  bool _openingChallenge = false;

  Future<void> _refresh() async {
    final values = await Future.wait([
      _storage.loadResults(),
      _storage.loadDailySnapshots(),
    ]);
    if (!mounted) return;
    setState(() {
      _results = values[0] as Map<String, PuzzleResult>;
      _snapshots = values[1] as Map<String, DailyPuzzleSnapshot>;
      _loading = false;
    });
  }

  Future<void> _openCalendarEntry(DailyChallengeSummary summary) async {
    final result = _results[_resultKey(summary)];
    if (result == null) {
      await _openChallenge(summary);
      return;
    }
    var snapshot = _snapshots['${widget.gameType.name}:${summary.puzzleId}'];
    snapshot ??= _snapshotForLegacyResult(summary, result);
    if (snapshot == null) {
      await _openChallenge(summary);
      return;
    }
    if (!_snapshots.containsKey(snapshot.storageKey)) {
      await _storage.saveDailySnapshot(snapshot);
      _snapshots = {..._snapshots, snapshot.storageKey: snapshot};
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (viewerContext) => DailySnapshotViewerScreen(
          snapshot: snapshot!,
          onReplay: () {
            Navigator.of(viewerContext).pop();
            _openChallenge(summary);
          },
        ),
      ),
    );
  }

  DailyPuzzleSnapshot? _snapshotForLegacyResult(
    DailyChallengeSummary summary,
    PuzzleResult result,
  ) {
    Map<String, Object?> data;
    switch (widget.gameType) {
      case GameType.binairo:
        final puzzle = _service.challengeFor(summary.day).definition;
        data = {
          'kind': 'binairo',
          'solution': [
            for (final row in puzzle.solution)
              [for (final value in row) value == CellValue.zero ? 0 : 1],
          ],
          'clues': [
            for (final clue in puzzle.clues) [clue.row, clue.column],
          ],
        };
      case GameType.hashi:
        final puzzle = const HashiGenerator()
            .generate(
              seed: summary.seed,
              number: 1,
              difficulty: summary.difficulty.index + 1,
            )
            .puzzle;
        data = {
          'kind': 'hashi',
          'islands': [
            for (final island in puzzle.islands)
              [island.row, island.column, island.bridges],
          ],
          'bridges': [
            for (final bridge in puzzle.solution)
              [bridge.from, bridge.to, bridge.count],
          ],
        };
      case GameType.slitherlink:
        final puzzle = const SlitherlinkGenerator().generate(
          seed: summary.seed,
          difficulty: summary.difficulty,
        );
        data = {
          'kind': 'slitherlink',
          'rows': puzzle.rows,
          'columns': puzzle.columns,
          'clues': puzzle.clues,
          'lines': puzzle.solution.toList()..sort(),
        };
      case GameType.futoshiki:
        final puzzle = const FutoshikiGenerator().generate(
          seed: summary.seed,
          difficulty: summary.difficulty,
        );
        data = {
          'kind': 'futoshiki',
          'givens': puzzle.givens,
          'solution': puzzle.solution,
          'inequalities': [
            for (final inequality in puzzle.inequalities)
              [
                inequality.firstRow,
                inequality.firstColumn,
                inequality.secondRow,
                inequality.secondColumn,
                inequality.firstIsLess,
              ],
          ],
        };
      case GameType.hitori:
        final puzzle = const HitoriGenerator().generate(
          seed: summary.seed,
          difficulty: summary.difficulty,
          id: summary.puzzleId,
          title: 'Tagesrätsel',
        );
        data = {
          'kind': 'hitori',
          'grid': puzzle.grid,
          'shaded': [
            for (final cell in puzzle.solution) [cell.$1, cell.$2],
          ],
        };
      case GameType.tents:
        final puzzle = const TentsGenerator().generate(
          seed: summary.seed,
          difficulty: summary.difficulty,
          size: summary.size,
          id: summary.puzzleId,
          title: 'Tagesrätsel',
        );
        data = {
          'kind': 'tents',
          'trees': [
            for (final cell in puzzle.trees) [cell.$1, cell.$2]
          ],
          'rowCounts': puzzle.rowCounts,
          'columnCounts': puzzle.columnCounts,
          'tents': [
            for (final cell in puzzle.solution) [cell.$1, cell.$2]
          ],
        };
      case GameType.kakuro:
      case GameType.nurikabe:
        return null;
    }
    return DailyPuzzleSnapshot(
      puzzleId: summary.puzzleId,
      gameType: widget.gameType,
      difficulty: summary.difficulty,
      boardSize: summary.size,
      completedAt: result.completedAt,
      elapsedSeconds: result.bestSeconds,
      puzzleData: data,
    );
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _openChallenge(DailyChallengeSummary summary) async {
    if (_openingChallenge) return;
    _openingChallenge = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        content: Row(
          children: [
            const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(width: 18),
            Expanded(
                child: Text(dialogContext.strings.text(
                    'Tagesrätsel wird vorbereitet …',
                    'Preparing daily puzzle…'))),
          ],
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 40));
    try {
      final route = switch (widget.gameType) {
        GameType.binairo => _binaryDailyRoute(summary),
        GameType.hashi => _hashiDailyRoute(summary),
        GameType.slitherlink => _slitherlinkDailyRoute(summary),
        GameType.futoshiki => _futoshikiDailyRoute(summary),
        GameType.hitori => _hitoriDailyRoute(summary),
        GameType.tents => _tentsDailyRoute(summary),
        _ => throw UnsupportedError('Tagesrätsel noch nicht verfügbar'),
      };
      if (!mounted) return;
      Navigator.of(context).pop();
      await Navigator.of(context).push(route);
      await _refresh();
    } on Object {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.strings.text(
              'Das Tagesrätsel konnte nicht vorbereitet werden.',
              'The daily puzzle could not be prepared.')),
        ),
      );
    } finally {
      _openingChallenge = false;
    }
  }

  MaterialPageRoute<void> _binaryDailyRoute(DailyChallengeSummary summary) {
    final challenge = _service.challengeFor(summary.day);
    return MaterialPageRoute<void>(
      builder: (_) => BinaryPuzzleScreen(
        definition: challenge.definition,
        storeDefinition: true,
        source: PuzzleSource.daily,
        titleOverride: challenge.title,
      ),
    );
  }

  MaterialPageRoute<void> _hashiDailyRoute(DailyChallengeSummary summary) {
    final generated = const HashiGenerator().generate(
      seed: summary.seed,
      number: 1,
      difficulty: summary.difficulty.index + 1,
    );
    final source = generated.puzzle;
    final puzzle = HashiPuzzle(
      id: summary.puzzleId,
      title: 'Tagesrätsel · ${DailyChallengeService.formatDate(summary.day)}',
      size: source.size,
      difficulty: source.difficulty,
      islands: source.islands,
      solution: source.solution,
    );
    return MaterialPageRoute<void>(
      builder: (_) => HashiGameScreen(puzzle: puzzle, mode: GameMode.daily),
    );
  }

  MaterialPageRoute<void> _slitherlinkDailyRoute(
    DailyChallengeSummary summary,
  ) {
    final generated = const SlitherlinkGenerator().generate(
      seed: summary.seed,
      difficulty: summary.difficulty,
    );
    final puzzle = SlitherlinkPuzzle(
      id: summary.puzzleId,
      title: 'Tagesrätsel · ${DailyChallengeService.formatDate(summary.day)}',
      rows: generated.rows,
      columns: generated.columns,
      clues: generated.clues,
      solution: generated.solution,
      difficulty: generated.difficulty,
    );
    return MaterialPageRoute<void>(
      builder: (_) => SlitherlinkGameScreen(puzzle: puzzle),
    );
  }

  MaterialPageRoute<void> _futoshikiDailyRoute(
    DailyChallengeSummary summary,
  ) {
    final generated = const FutoshikiGenerator().generate(
      seed: summary.seed,
      difficulty: summary.difficulty,
    );
    final puzzle = FutoshikiPuzzle(
      id: summary.puzzleId,
      title: 'Tagesrätsel · ${DailyChallengeService.formatDate(summary.day)}',
      size: generated.size,
      givens: generated.givens,
      inequalities: generated.inequalities,
      solution: generated.solution,
      difficulty: generated.difficulty,
    );
    return MaterialPageRoute<void>(
      builder: (_) => FutoshikiGameScreen(
        puzzle: puzzle,
        mode: GameMode.daily,
      ),
    );
  }

  MaterialPageRoute<void> _hitoriDailyRoute(DailyChallengeSummary summary) {
    final generated = const HitoriGenerator().generate(
      seed: summary.seed,
      difficulty: summary.difficulty,
      id: summary.puzzleId,
      title: 'Tagesrätsel · ${DailyChallengeService.formatDate(summary.day)}',
    );
    return MaterialPageRoute<void>(
      builder: (_) => HitoriGameScreen(
        puzzle: generated,
        mode: GameMode.daily,
      ),
    );
  }

  MaterialPageRoute<void> _tentsDailyRoute(DailyChallengeSummary summary) {
    final generated = const TentsGenerator().generate(
      seed: summary.seed,
      difficulty: summary.difficulty,
      size: summary.size,
      id: summary.puzzleId,
      title: 'Tagesr\u00e4tsel \u00b7 '
          '${DailyChallengeService.formatDate(summary.day)}',
    );
    final puzzle = TentsPuzzle(
      id: generated.id,
      title: generated.title,
      size: generated.size,
      trees: generated.trees,
      rowCounts: generated.rowCounts,
      columnCounts: generated.columnCounts,
      solution: generated.solution,
      difficulty: generated.difficulty,
    );
    return MaterialPageRoute<void>(
      builder: (_) => TentsGameScreen(
        puzzle: puzzle,
        mode: GameMode.daily,
      ),
    );
  }

  String _resultKey(DailyChallengeSummary summary) =>
      widget.gameType == GameType.binairo
          ? summary.puzzleId
          : '${widget.gameType.name}:${summary.puzzleId}';

  @override
  Widget build(BuildContext context) {
    final challenges = _service.archiveSummariesForGame(
      widget.gameType,
      days: _archiveDays,
    );
    final today = challenges.first;
    final todayCompleted = _results.containsKey(_resultKey(today));
    final gameName = widget.gameType.label;
    return Scaffold(
      appBar: AppBar(
          title: Text(context.strings.isEnglish
              ? '${context.strings.known(gameName)} daily puzzle'
              : '$gameName-Tagesrätsel')),
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
                                        context.strings.text(
                                          todayCompleted
                                              ? 'Heute bereits gelöst'
                                              : 'Dein heutiges Rätsel wartet',
                                          todayCompleted
                                              ? 'Already solved today'
                                              : 'Today’s puzzle is waiting',
                                        ),
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
                                  '${context.strings.known(today.difficulty.label)} · ${today.size} × ${today.size}',
                                ),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: () => todayCompleted
                                      ? _openCalendarEntry(today)
                                      : _openChallenge(today),
                                  icon: Icon(
                                    todayCompleted
                                        ? Icons.visibility_rounded
                                        : Icons.play_arrow_rounded,
                                  ),
                                  label: Text(
                                    context.strings.text(
                                      todayCompleted
                                          ? 'Gelöstes Brett ansehen'
                                          : 'Tagesrätsel starten',
                                      todayCompleted
                                          ? 'View solved board'
                                          : 'Start daily puzzle',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          context.strings.text(
                            'Kalender der letzten $_archiveDays Tage',
                            'Calendar of the last $_archiveDays days',
                          ),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.strings.text(
                            'Vergangene Rätsel können nachgeholt werden. Das füllt den Kalender, repariert aber keinen verlorenen Spiel-Streak.',
                            'Past puzzles can be completed later. This fills the calendar, but does not restore a lost play streak.',
                          ),
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 560
                                ? 7
                                : constraints.maxWidth >= 400
                                    ? 6
                                    : 5;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: challenges.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                mainAxisExtent: 100,
                              ),
                              itemBuilder: (context, index) {
                                final challenge = challenges[index];
                                final completed =
                                    _results.containsKey(_resultKey(challenge));
                                return _DailyCalendarTile(
                                  challenge: challenge,
                                  completed: completed,
                                  isToday: index == 0,
                                  onTap: () => _openCalendarEntry(challenge),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          children: [
                            _CalendarLegend(
                              icon: Icons.check_circle_rounded,
                              label: context.strings.known('Gelöst'),
                            ),
                            _CalendarLegend(
                              icon: Icons.radio_button_unchecked_rounded,
                              label: context.strings.known('Offen'),
                            ),
                            _CalendarLegend(
                              icon: Icons.today_rounded,
                              label: context.strings.known('Heute'),
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
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                completed
                    ? Icons.check_circle_rounded
                    : isToday
                        ? Icons.today_rounded
                        : Icons.radio_button_unchecked_rounded,
                size: 20,
              ),
              const SizedBox(height: 2),
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

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.completedToday,
    required this.onSettings,
  });

  final bool completedToday;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final strings = context.strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.grid_view_rounded,
                  color: colors.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('PROJECT LOGIC',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4)),
                  const SizedBox(height: 2),
                  Text(strings.text(
                    'Deine ruhige Rätselecke',
                    'Your quiet puzzle corner',
                  )),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: strings.text('Einstellungen', 'Settings'),
              onPressed: onSettings,
              icon: const Icon(Icons.tune_rounded),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          completedToday
              ? strings.text('Schön, dass du wieder da bist.',
                  'It’s good to see you again.')
              : strings.text('Zeit zum Knobeln?', 'Time for a puzzle?'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          completedToday
              ? strings.text(
                  'Dein Tagesziel ist geschafft. Entdecke noch ein Rätsel.',
                  'Your daily goal is complete. Discover another puzzle.',
                )
              : strings.text(
                  'Ein ruhiger Moment, ein klares Ziel – ganz ohne Zeitdruck.',
                  'A quiet moment, a clear goal — with no time pressure.',
                ),
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: colors.onSurfaceVariant, height: 1.35),
        ),
      ],
    );
  }
}

class _HomeSectionHeader extends StatelessWidget {
  const _HomeSectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.strings.known(title),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 3),
          Text(
            context.strings.known(subtitle),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      );
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.progress});

  final PlayerProgress progress;

  @override
  Widget build(BuildContext context) {
    final streak = progress.currentStreak;
    final secured = progress.completedToday;
    final colors = Theme.of(context).colorScheme;
    final strings = context.strings;
    return Card(
      color: secured ? colors.secondaryContainer : colors.surfaceContainerLow,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: secured ? colors.secondary : colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            secured
                ? Icons.local_fire_department_rounded
                : Icons.local_fire_department_outlined,
            color: secured ? colors.onSecondary : colors.onSurfaceVariant,
          ),
        ),
        title: Text(
          strings.plural(streak, '1 Tag Spielserie', '$streak Tage Spielserie',
              '1 day streak', '$streak day streak'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          secured
              ? strings.text('Deine Serie ist für heute gesichert.',
                  'Your streak is safe for today.')
              : streak == 0
                  ? strings.text(
                      'Löse heute ein Rätsel und starte deine Serie.',
                      'Solve a puzzle today to start your streak.',
                    )
                  : strings.text(
                      'Löse heute ein Rätsel, damit deine Serie weiterläuft.',
                      'Solve a puzzle today to keep your streak going.',
                    ),
        ),
        trailing:
            secured ? const Icon(Icons.check_circle_outline_rounded) : null,
      ),
    );
  }
}

class _HomeLevelCard extends StatelessWidget {
  const _HomeLevelCard({required this.rank, required this.onTap});

  final PlayerRank rank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final remaining = rank.nextLevelXp - rank.currentXp;
    return Semantics(
      button: true,
      label: 'Level ${rank.level}, ${context.strings.known(rank.title)}',
      hint: context.strings
          .text('Deinen Fortschritt öffnen', 'Open your progress'),
      child: Card(
        color: colors.primaryContainer.withValues(alpha: .55),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    '${rank.level}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Level ${rank.level} · ${context.strings.known(rank.title)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${rank.currentXp} / ${rank.nextLevelXp} XP',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          minHeight: 6,
                          value: rank.progress,
                          backgroundColor:
                              colors.surface.withValues(alpha: .65),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        context.strings.text(
                          'Noch $remaining XP bis Level ${rank.level + 1}',
                          '$remaining XP to level ${rank.level + 1}',
                        ),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(Icons.chevron_right_rounded, size: 20),
              ],
            ),
          ),
        ),
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
      this.accent,
      this.emphasized = false,
      this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final Color? accent;
  final bool emphasized;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final actionColor = accent ?? colors.primary;
    final cardColor = emphasized
        ? colors.primaryContainer
        : accent == null
            ? colors.surfaceContainerLow
            : Color.alphaBlend(
                actionColor.withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? .14
                        : .09),
                colors.surfaceContainerLow,
              );
    return Card(
      color: cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: actionColor.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 25, color: actionColor),
            ),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(context.strings.known(title),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(context.strings.known(subtitle),
                      style: Theme.of(context).textTheme.bodySmall),
                ])),
            if (enabled)
              const Icon(Icons.arrow_forward_ios_rounded, size: 17)
            else
              Text(context.strings.text('BALD', 'SOON'),
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold)),
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
      appBar: AppBar(
          title:
              Text(context.strings.text('Spiel auswählen', 'Choose a game'))),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(context.strings.text('Welches Spiel?', 'Which game?'),
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
      appBar:
          AppBar(title: Text(context.strings.text('Binärpuzzle', 'Binairo'))),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PuzzleHubHeader(
                  icon: Icons.tune_rounded,
                  title: context.strings.known('Deine Rätselsammlung'),
                  description: context.strings.known(
                      'Wähle die Schwierigkeit, die heute zu dir passt.'),
                  accent: AppTheme.gameColors['binairo']!,
                ),
                const SizedBox(height: 24),
                for (final difficulty in PuzzleDifficulty.values) ...[
                  PuzzleHubAction(
                    icon: switch (difficulty) {
                      PuzzleDifficulty.easy => Icons.eco_outlined,
                      PuzzleDifficulty.medium => Icons.psychology_alt_outlined,
                      PuzzleDifficulty.hard =>
                        Icons.local_fire_department_outlined,
                    },
                    title: context.strings.known(difficulty.label),
                    subtitle:
                        '${context.strings.known(difficulty.description)} · ${puzzlesFor(difficulty).length} ${context.strings.text('Rätsel', 'puzzles')}',
                    accent: AppTheme.gameColors['binairo']!,
                    onTap: () =>
                        Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (_) =>
                          PuzzleSelectionScreen(difficulty: difficulty),
                    )),
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
        title: Text(
            '${context.strings.text('Binärpuzzle', 'Binairo')} · ${context.strings.known(widget.difficulty.label)}'),
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
                      label:
                          '${context.strings.known(widget.difficulty.label)} · ${context.strings.known('Rätselsammlung')}',
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
          Text(context.strings.known('$completed von $total Rätseln gelöst')),
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
          context.strings.known(chapter.title),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${context.strings.known(chapter.description)}\n${context.strings.isEnglish ? '$completed of ${chapter.puzzles.length} solved' : '$completed von ${chapter.puzzles.length} gelöst'}',
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
          context.strings.known(definition.displayName),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          result == null
              ? context.strings.text(
                  '${definition.size} × ${definition.size} · ${definition.clueCount} Vorgaben',
                  '${definition.size} × ${definition.size} · ${definition.clueCount} clues',
                )
              : context.strings.text(
                  'Bestzeit ${_formatHomeTime(result!.bestSeconds)} · ${definition.size} × ${definition.size}',
                  'Best time ${_formatHomeTime(result!.bestSeconds)} · ${definition.size} × ${definition.size}',
                ),
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
      appBar: AppBar(
          title: Text(context.strings.text('Zufallsrätsel', 'Random puzzle'))),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.strings
                      .text('Stell dein Rätsel zusammen', 'Build your puzzle'),
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  context.strings.text(
                      'Wähle Größe und Schwierigkeit. Das Rätsel wird direkt auf deinem Gerät erstellt und auf eine eindeutige Lösung geprüft.',
                      'Choose a size and difficulty. The puzzle is created directly on your device and checked for a unique solution.'),
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                Text(context.strings.text('Rastergröße', 'Grid size'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        )),
                const SizedBox(height: 10),
                SegmentedButton<BinaryPuzzleSize>(
                  segments: [
                    for (final size in BinaryPuzzleSize.values)
                      ButtonSegment<BinaryPuzzleSize>(
                        value: size,
                        label: Text(context.strings.known(size.label)),
                      ),
                  ],
                  selected: {_size},
                  onSelectionChanged: _isGenerating
                      ? null
                      : (selection) => setState(() => _size = selection.first),
                ),
                const SizedBox(height: 24),
                Text(context.strings.text('Schwierigkeit', 'Difficulty'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        )),
                const SizedBox(height: 10),
                SegmentedButton<PuzzleDifficulty>(
                  segments: [
                    for (final difficulty in PuzzleDifficulty.values)
                      ButtonSegment<PuzzleDifficulty>(
                        value: difficulty,
                        label: Text(context.strings.known(difficulty.label)),
                        tooltip: context.strings.known(difficulty.description),
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
                  context.strings.known(_difficulty.description),
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
                    _isGenerating
                        ? context.strings
                            .text('Rätsel wird erzeugt …', 'Generating puzzle…')
                        : context.strings
                            .text('Rätsel starten', 'Start puzzle'),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  context.strings.text(
                      'Generierte Rätsel werden automatisch gespeichert und können im Binärpuzzle-Hub über „Spiel fortsetzen“ wieder geöffnet werden.',
                      'Generated puzzles are saved automatically and can be reopened from the Binairo hub via “Continue puzzle”.'),
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
  bool _developerCompletion = false;
  CellPosition? _selectedCell;
  CellPosition? _hintCell;
  Set<CellPosition> _hintRelatedCells = const {};
  HintBudget _hintBudget = const HintBudget();
  int _hintsUsed = 0;
  bool _checkingExistingGame = false;

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
      _checkingExistingGame = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_protectExistingGame());
      });
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !puzzle.isSolved && !_checkingExistingGame) {
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
    if (!_checkingExistingGame && !puzzle.isSolved) unawaited(_saveGame());
    super.dispose();
  }

  Future<void> _protectExistingGame() async {
    final existing = await _storage.loadActiveGame();
    if (!mounted) return;
    if (existing == null) {
      _checkingExistingGame = false;
      await _saveGame();
      return;
    }
    final definition = existing.definition ??
        binaryPuzzleCatalog
            .where((candidate) => candidate.id == existing.puzzleId)
            .firstOrNull;
    if (definition == null) {
      await _storage.clearActiveGame();
      _checkingExistingGame = false;
      await _saveGame();
      return;
    }
    final savedPuzzle = definition.createPuzzle()
      ..restoreEditableValues(existing.values);
    if (savedPuzzle.isSolved) {
      await _storage.clearActiveGame();
      _checkingExistingGame = false;
      await _saveGame();
      return;
    }
    final resume = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.save_outlined),
        title: Text(dialogContext.strings
            .text('Offenes Binairo-Rätsel', 'Open Binairo puzzle')),
        content: Text(dialogContext.strings.text(
          'Du hast bereits ein begonnenes Binairo-Rätsel. Möchtest du es fortsetzen oder mit dem neuen Rätsel beginnen?',
          'You already have a Binairo puzzle in progress. Would you like to continue it or start the new puzzle?',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child:
                Text(dialogContext.strings.text('Neu beginnen', 'Start new')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(dialogContext.strings.text('Fortsetzen', 'Continue')),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (resume == true) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => BinaryPuzzleScreen(
            definition: definition,
            savedGame: existing,
            titleOverride: existing.titleOverride,
            storeDefinition: existing.isGenerated,
            source: existing.source,
          ),
        ),
      );
      return;
    }
    _checkingExistingGame = false;
    await _storage.clearActiveGame();
    await _saveGame();
  }

  @override
  Widget build(BuildContext context) {
    final issues = puzzle.validate();
    final issueCells = {
      for (final issue in issues) ...issue.cells,
    };
    final premium = PreferencesScope.of(context).premiumSimulationEnabled;

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
                            label: Text(context.strings
                                .text('Noch eins', 'Another one')),
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
                            label: Text(context.strings
                                .text('Nächstes Rätsel', 'Next puzzle')),
                          ),
                        if (widget.source == PuzzleSource.daily)
                          FilledButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.calendar_month_outlined),
                            label: Text(context.strings
                                .text('Zum Kalender', 'To calendar')),
                          ),
                        OutlinedButton.icon(
                          onPressed: _reset,
                          icon: const Icon(Icons.replay_rounded),
                          label: Text(context.strings
                              .text('Noch einmal', 'Play again')),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : null,
        appBar: AppBar(
          title: Text(
            context.strings.known(widget.titleOverride ??
                '${widget.definition.difficulty.label} · ${widget.definition.displayName}'),
          ),
          actions: [
            if (kDebugMode)
              PopupMenuButton<_DeveloperAction>(
                tooltip: context.strings.text('Testwerkzeuge', 'Test tools'),
                icon: const Icon(Icons.bug_report_outlined),
                onSelected: _runDeveloperAction,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _DeveloperAction.almostSolved,
                    child: Text(context.strings.text(
                        'Bis auf 1 Feld lösen', 'Solve except for 1 cell')),
                  ),
                  PopupMenuItem(
                    value: _DeveloperAction.solve,
                    child: Text(context.strings
                        .text('Sofort lösen', 'Solve instantly')),
                  ),
                  PopupMenuItem(
                    value: _DeveloperAction.error,
                    child: Text(context.strings
                        .text('Regelfehler erzeugen', 'Create rule error')),
                  ),
                  PopupMenuItem(
                    value: _DeveloperAction.reset,
                    child: Text(context.strings
                        .text('Testzustand löschen', 'Clear test state')),
                  ),
                ],
              ),
            IconButton(
              tooltip: context.strings.text('Rückgängig', 'Undo'),
              onPressed: puzzle.canUndo ? _undo : null,
              icon: const Icon(Icons.undo_rounded),
            ),
            IconButton(
              tooltip: context.strings.text('Wiederholen', 'Redo'),
              onPressed: puzzle.canRedo ? _redo : null,
              icon: const Icon(Icons.redo_rounded),
            ),
            IconButton(
              tooltip: context.strings.text('Zurücksetzen', 'Reset'),
              onPressed: _reset,
              icon: const Icon(Icons.restart_alt),
            ),
            IconButton(
              tooltip: context.strings.text('Spielhilfen', 'Game assists'),
              onPressed: () => showPuzzleGameOptions(
                context,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(context.strings.text(
                        'Regelfehler markieren', 'Highlight rule errors')),
                    subtitle: Text(
                      context.strings.text(
                          'Markiert direkte Widersprüche, ohne die Lösung zu verraten.',
                          'Highlights direct contradictions without revealing the solution.'),
                    ),
                    value: showIssues,
                    onChanged: (value) {
                      setState(() => showIssues = value);
                      PreferencesScope.of(context).setShowRuleIssues(value);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              icon: const Icon(Icons.tune_rounded),
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
                      hintLabel: premium
                          ? 'Premium'
                          : context.strings.isEnglish
                              ? '${_hintBudget.remainingHints} hints'
                              : '${_hintBudget.remainingHints} Tipps',
                      onHint: puzzle.isSolved ? null : _showHint,
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
                    const SizedBox(height: 12),
                    PuzzleGameRulesButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PuzzleRulesScreen(
                            title: 'Binärpuzzle',
                            introduction:
                                'Setze 0 und 1 nach drei klaren Regeln.',
                            rules: [
                              'In jeder Zeile und Spalte stehen gleich viele Nullen und Einsen.',
                              'Nie dürfen drei gleiche Zahlen direkt nebeneinander stehen.',
                              'Keine zwei Zeilen oder Spalten dürfen identisch sein.',
                            ],
                            interaction: 'Tippe ein freies Feld: leer → 0 → 1.',
                          ),
                        ),
                      ),
                    ),
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

    PuzzleInteractionFeedback.selection(context);
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
          title: Text(context.strings.text(
              'Hier hilft nur dein nächster Schritt',
              'Your next step is needed here')),
          content: Text(context.strings.text(
            'Aus dem aktuellen Spielstand lässt sich kein garantiert richtiger Wert ableiten. Prüfe mögliche Fehler oder löse zunächst einen anderen Bereich.',
            'No guaranteed correct value can be deduced from the current state. Check for possible errors or solve another area first.',
          )),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.strings.text('Okay', 'OK')),
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
        title: Text(context.strings.known(hint.title)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.strings.known(hint.badge),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(context.strings.known(hint.reason)),
            const SizedBox(height: 16),
            Text(
              hint.coordinate,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(context.strings.known(hint.action)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child:
                Text(context.strings.text('Nur markieren', 'Highlight only')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.strings.text('Hinweis anwenden', 'Apply hint')),
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
      PuzzleInteractionFeedback.hint(context);
      await _saveGame();
      if (puzzle.isSolved) _showSolvedDialog();
    }
  }

  Future<void> _showHintRewardDialog() async {
    if (!await showRewardedHintSimulation(context) || !mounted) return;
    setState(() => _hintBudget = _hintBudget.earnRewardedHint());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(context.strings.text(
              'Ein zusätzlicher Hinweis wurde freigeschaltet.',
              'An additional hint has been unlocked.'))),
    );
  }

  void _runDeveloperAction(_DeveloperAction action) {
    setState(() {
      _hintCell = null;
      _hintRelatedCells = const {};
      switch (action) {
        case _DeveloperAction.almostSolved:
          _developerCompletion = true;
          puzzle.fillWithSolution(leaveOneEmpty: true);
          break;
        case _DeveloperAction.solve:
          _developerCompletion = true;
          puzzle.fillWithSolution();
          break;
        case _DeveloperAction.error:
          _developerCompletion = true;
          puzzle.createTestError();
          break;
        case _DeveloperAction.reset:
          _developerCompletion = false;
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
    int? earnedXp;
    String? collectionProgress;
    final firstCompletion = !_completionRecorded;
    if (!_completionRecorded) {
      _completionRecorded = true;
      final countsForTesting =
          _developerCompletion && widget.source == PuzzleSource.daily;
      if (widget.saveProgress && (!_developerCompletion || countsForTesting)) {
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
        earnedXp = await _storage.recordCompletion(
          puzzleId: widget.definition.id,
          elapsedSeconds: elapsedSeconds,
          source: widget.source,
          difficulty: widget.definition.difficulty,
          boardSize: widget.definition.size,
          hintsUsed: _hintsUsed,
          rewardedHints: _hintBudget.rewardedHints,
          dailyPuzzleData: widget.source == PuzzleSource.daily
              ? {
                  'kind': 'binairo',
                  'solution': [
                    for (final row in widget.definition.solution)
                      [
                        for (final value in row) value == CellValue.zero ? 0 : 1
                      ],
                  ],
                  'clues': [
                    for (final clue in widget.definition.clues)
                      [clue.row, clue.column],
                  ],
                }
              : null,
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
      if (firstCompletion) PuzzleInteractionFeedback.success(context);
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
                ? context.strings
                    .text('Tagesrätsel geschafft!', 'Daily puzzle complete!')
                : context.strings.text('Gelöst!', 'Solved!')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.source == PuzzleSource.daily
                    ? context.strings.text(
                        'Die Spielserie ist für heute gesichert.',
                        'Your streak is safe for today.')
                    : context.strings.text('Alle Regeln sind erfüllt.',
                        'All rules are satisfied.')),
                const SizedBox(height: 16),
                if (isNewRecord && !_developerCompletion)
                  Chip(
                    avatar: const Icon(Icons.workspace_premium_outlined),
                    label: Text(
                        context.strings.text('Neue Bestzeit', 'New best time')),
                  ),
                if (_developerCompletion)
                  Chip(
                    avatar: const Icon(Icons.science_outlined),
                    label: Text(
                      context.strings.known(
                        widget.source == PuzzleSource.daily
                            ? 'Testabschluss · im Kalender gewertet'
                            : 'Testabschluss · keine Statistik',
                      ),
                    ),
                  ),
                if (earnedXp != null) ...[
                  const SizedBox(height: 10),
                  XpAwardBadge(points: earnedXp),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CompactStatistic(
                      value: _formatTime(elapsedSeconds),
                      label: context.strings.text('Zeit', 'Time'),
                    ),
                    _CompactStatistic(
                      value: '$_hintsUsed',
                      label: context.strings.text('Hinweise', 'Hints'),
                    ),
                    _CompactStatistic(
                      value: previousBestSeconds == null
                          ? '–'
                          : _formatTime(previousBestSeconds),
                      label: context.strings.text('Bisher', 'Previous'),
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
                child:
                    Text(context.strings.text('Brett ansehen', 'View board')),
              ),
              if (widget.source == PuzzleSource.generated)
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _startNextGeneratedPuzzle();
                  },
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: Text(context.strings.text('Noch eins', 'Another one')),
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
                    child: Text(
                        context.strings.text('Nächstes Rätsel', 'Next puzzle')),
                  )
                else
                  FilledButton.tonal(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(this.context).pop();
                    },
                    child: Text(context.strings
                        .text('Zur Sammlung', 'Back to collection')),
                  ),
              if (widget.source == PuzzleSource.daily)
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(this.context).pop();
                  },
                  icon: const Icon(Icons.calendar_month_outlined),
                  label:
                      Text(context.strings.text('Zum Kalender', 'To calendar')),
                ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _reset();
                },
                child: Text(
                    context.strings.text('Noch einmal spielen', 'Play again')),
              ),
            ],
          );
        },
      );
    });
  }

  Future<void> _startNextGeneratedPuzzle() async {
    if (widget.source != PuzzleSource.generated) return;
    await _storage.clearActiveGame();
    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        content: Row(
          children: [
            const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(width: 18),
            Expanded(
                child: Text(dialogContext.strings.text(
                    'Dein Rätsel wird vorbereitet …',
                    'Preparing your puzzle…'))),
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
          content: Text(context.strings.isEnglish
              ? 'The puzzle could not be created: $error'
              : 'Das Rätsel konnte gerade nicht erstellt werden: $error'),
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
      _developerCompletion = false;
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
    required this.hintLabel,
    required this.onHint,
  });

  final int elapsedSeconds;
  final int filled;
  final int total;
  final double progress;
  final String hintLabel;
  final VoidCallback? onHint;

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
                Text(context.strings
                    .text('$filled/$total Felder', '$filled/$total cells')),
                const SizedBox(width: 10),
                PuzzleGameStatusChip(
                  icon: Icons.lightbulb_outline_rounded,
                  label: hintLabel,
                  onTap: onHint,
                ),
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
    final strings = context.strings;

    return Scaffold(
      appBar: AppBar(title: Text(strings.text('Einstellungen', 'Settings'))),
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
                      strings.text(
                          'Sprache & Darstellung', 'Language & appearance'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.language_rounded),
                        title: Text(strings.text('Sprache', 'Language')),
                        subtitle: Text(switch (preferences.languagePreference) {
                          AppLanguagePreference.system =>
                            strings.text('Systemsprache', 'System language'),
                          AppLanguagePreference.german => 'Deutsch',
                          AppLanguagePreference.english => 'English',
                        }),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _chooseLanguage(context, preferences),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(strings.text('Farbschema', 'Color scheme'),
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 12),
                            SegmentedButton<AppThemePreference>(
                              showSelectedIcon: false,
                              segments: [
                                ButtonSegment(
                                  value: AppThemePreference.system,
                                  icon: const Icon(
                                      Icons.brightness_auto_outlined),
                                  label: Text(strings.text('Auto', 'Auto')),
                                ),
                                ButtonSegment(
                                  value: AppThemePreference.light,
                                  icon: const Icon(Icons.light_mode_outlined),
                                  label: Text(strings.text('Hell', 'Light')),
                                ),
                                ButtonSegment(
                                  value: AppThemePreference.dark,
                                  icon: const Icon(Icons.dark_mode_outlined),
                                  label: Text(strings.text('Dunkel', 'Dark')),
                                ),
                              ],
                              selected: {preferences.themePreference},
                              onSelectionChanged: (selection) =>
                                  preferences.setTheme(selection.single),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: Column(
                        children: [
                          SwitchListTile(
                            title:
                                Text(strings.text('Animationen', 'Animations')),
                            subtitle: Text(strings.text(
                              'Zahlenwechsel und Erfolgsanimationen anzeigen',
                              'Show number transitions and success animations',
                            )),
                            value: preferences.animationsEnabled,
                            onChanged: preferences.setAnimationsEnabled,
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            title: Text(strings.text('Töne', 'Sounds')),
                            subtitle: Text(strings.text(
                              'Leise Spielklänge und melodische Erfolge',
                              'Quiet game sounds and melodic celebrations',
                            )),
                            value: preferences.soundsEnabled,
                            onChanged: preferences.setSoundsEnabled,
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            title: Text(strings.text(
                                'Haptisches Feedback', 'Haptic feedback')),
                            subtitle: Text(strings.text(
                              'Kurze Rückmeldung auf unterstützten Geräten',
                              'Brief feedback on supported devices',
                            )),
                            value: preferences.hapticsEnabled,
                            onChanged: preferences.setHapticsEnabled,
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            title: Text(strings.text('Regelfehler markieren',
                                'Highlight rule issues')),
                            subtitle: Text(strings.text(
                              'Standardwert für neu geöffnete Rätsel',
                              'Default for newly opened puzzles',
                            )),
                            value: preferences.showRuleIssues,
                            onChanged: preferences.setShowRuleIssues,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      strings.text('Erinnerungen', 'Reminders'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    _ReminderSettingsCard(preferences: preferences),
                    const SizedBox(height: 24),
                    Text(
                      strings.text(
                          'Monetarisierung testen', 'Test monetization'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: SwitchListTile(
                        secondary: const Icon(Icons.workspace_premium_outlined),
                        title: Text(strings.text(
                            'Premium simulieren', 'Simulate Premium')),
                        subtitle: Text(
                          preferences.premiumSimulationEnabled
                              ? strings.text(
                                  'Werbefrei und Hinweise ohne Begrenzung',
                                  'Ad-free with unlimited hints')
                              : strings.text(
                                  'Kostenlose Version mit drei Hinweisen pro Rätsel',
                                  'Free version with three hints per puzzle'),
                        ),
                        value: preferences.premiumSimulationEnabled,
                        onChanged: preferences.setPremiumSimulationEnabled,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      strings.text(
                          'Sicherung & Wiederherstellung', 'Backup & restore'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.cloud_done_outlined),
                            title: Text(strings.text(
                              'Android-Gerätesicherung aktiv',
                              'Android device backup active',
                            )),
                            subtitle: Text(strings.text(
                              'Android kann deine lokalen App-Daten geschützt mit deinem Google-Konto sichern.',
                              'Android can securely back up your local app data with your Google account.',
                            )),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.copy_all_outlined),
                            title: Text(strings.text(
                                'Sicherung kopieren', 'Copy backup')),
                            subtitle: Text(strings.text(
                              'Erstellt eine vollständige, versionierte Sicherung in der Zwischenablage',
                              'Creates a complete, versioned backup on the clipboard',
                            )),
                            onTap: () => _copyBackup(context),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.settings_backup_restore),
                            title: Text(strings.text(
                                'Sicherung wiederherstellen',
                                'Restore backup')),
                            subtitle: Text(strings.text(
                              'Prüft die Sicherung vollständig vor dem Import',
                              'Fully validates the backup before importing it',
                            )),
                            onTap: () => _restoreBackup(context),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.undo_rounded),
                            title: Text(strings.text(
                                'Import rückgängig machen', 'Undo import')),
                            subtitle: Text(strings.text(
                              'Stellt den lokalen Stand vor dem letzten Import wieder her',
                              'Restores the local state from before the last import',
                            )),
                            onTap: () => _restoreRecoveryBackup(context),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.cloud_sync_outlined),
                            title: Text(strings.text(
                              'Google-Cloud-Synchronisierung',
                              'Google Cloud synchronization',
                            )),
                            subtitle: Text(strings.text(
                              'Konfliktsichere Synchronisierung vorbereitet · Google-Anmeldung folgt mit der endgültigen App-ID',
                              'Conflict-safe synchronization prepared · Google sign-in will follow with the final app ID',
                            )),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.text(
                        'Importierte Daten ersetzen den aktuellen Stand. Vorher wird automatisch eine lokale Sicherheitskopie erstellt.',
                        'Imported data replaces the current state. A local safety copy is created automatically first.',
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      strings.text('Lokale Daten', 'Local data'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        title: Text(strings.text(
                            'Gespeicherte Daten löschen', 'Delete saved data')),
                        subtitle: Text(strings.text(
                          'Entfernt aktives Spiel, Bestzeiten und Statistik',
                          'Removes the active game, best times, and statistics',
                        )),
                        onTap: () => _confirmReset(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      strings.text(
                        'Alle Einstellungen und Spielstände werden nur lokal auf diesem Gerät beziehungsweise in diesem Browser gespeichert.',
                        'All settings and game progress are stored locally on this device or in this browser.',
                      ),
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

  Future<void> _chooseLanguage(
    BuildContext context,
    AppPreferences preferences,
  ) async {
    final strings = context.strings;
    final selected = await showModalBottomSheet<AppLanguagePreference>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 10),
                child: Text(
                  strings.text('Sprache auswählen', 'Choose language'),
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
              ),
              RadioGroup<AppLanguagePreference>(
                groupValue: preferences.languagePreference,
                onChanged: (value) => Navigator.pop(sheetContext, value),
                child: Column(
                  children: [
                    RadioListTile<AppLanguagePreference>(
                      value: AppLanguagePreference.system,
                      title: Text(
                          strings.text('Systemsprache', 'System language')),
                      subtitle: Text(strings.text(
                        'Folgt der Sprache deines Geräts',
                        'Follows your device language',
                      )),
                    ),
                    const RadioListTile<AppLanguagePreference>(
                      value: AppLanguagePreference.german,
                      title: Text('Deutsch'),
                    ),
                    const RadioListTile<AppLanguagePreference>(
                      value: AppLanguagePreference.english,
                      title: Text('English'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null) await preferences.setLanguage(selected);
  }

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: Text(context.strings
            .text('Wirklich alles löschen?', 'Really delete everything?')),
        content: Text(context.strings.text(
          'Aktives Spiel, Bestzeiten und die gesamte Statistik werden dauerhaft gelöscht. Die Einstellungen bleiben erhalten.',
          'The active game, best times and all statistics will be permanently deleted. Settings will be preserved.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.strings.text('Abbrechen', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.strings.text('Löschen', 'Delete')),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await GameStorage().clearAllProgress();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(context.strings.text(
              'Deine gespeicherten Daten wurden gelöscht.',
              'Your saved data has been deleted.'))),
    );
  }

  Future<void> _copyBackup(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final backup = await const DataBackupService().createBackup();
      await Clipboard.setData(ClipboardData(text: backup));
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(context.strings.text(
              'Vollständige Sicherung wurde kopiert.',
              'Complete backup copied.')),
        ),
      );
    } on Object {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
            content: Text(context.strings.text(
                'Sicherung konnte nicht erstellt werden.',
                'Backup could not be created.'))),
      );
    }
  }

  Future<void> _restoreBackup(BuildContext context) async {
    final controller = TextEditingController();
    final backup = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.settings_backup_restore),
        title: Text(
            dialogContext.strings.text('Sicherung einfügen', 'Paste backup')),
        content: TextField(
          controller: controller,
          minLines: 5,
          maxLines: 10,
          decoration: InputDecoration(
            hintText: dialogContext.strings.text(
                'Project-Logic-Sicherung hier einfügen',
                'Paste Project Logic backup here'),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(dialogContext.strings.text('Abbrechen', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(dialogContext.strings.text('Prüfen', 'Check')),
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
          title: Text(dialogContext.strings
              .text('Gültige Sicherung gefunden', 'Valid backup found')),
          content: Text(
            '${summary.entryCount} Datenbereiche vom ${_backupDate(summary.createdAt)} wiederherstellen? Der aktuelle Stand wird vorher lokal gesichert.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(dialogContext.strings.text('Abbrechen', 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(
                  dialogContext.strings.text('Wiederherstellen', 'Restore')),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await service.restoreBackup(backup.trim());
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.strings.text(
              'Sicherung wiederhergestellt. App bitte neu öffnen.',
              'Backup restored. Please reopen the app.')),
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
        title: Text(dialogContext.strings
            .text('Import rückgängig machen?', 'Undo import?')),
        content: Text(dialogContext.strings.text(
          'Der lokale Stand vor dem letzten Import wird wiederhergestellt.',
          'The local state from before the last import will be restored.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.strings.text('Abbrechen', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child:
                Text(dialogContext.strings.text('Wiederherstellen', 'Restore')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await service.restoreRecoveryBackup();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.strings.text(
            'Vorheriger Stand wiederhergestellt. App bitte neu öffnen.',
            'Previous state restored. Please reopen the app.')),
      ),
    );
  }

  static String _backupDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year} um ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _ReminderSettingsCard extends StatelessWidget {
  const _ReminderSettingsCard({required this.preferences});
  final AppPreferences preferences;

  Future<void> _configure({required bool requestPermission}) async {
    await ReminderNotifications.configure(
      dailyEnabled: preferences.dailyReminderEnabled,
      dailyMinutes: preferences.dailyReminderMinutes,
      streakEnabled: preferences.streakWarningEnabled,
      streakMinutes: preferences.streakWarningMinutes,
      requestPermission: requestPermission,
    );
  }

  Future<void> _toggleDaily(BuildContext context, bool enabled) async {
    await preferences.setDailyReminderEnabled(enabled);
    final granted = await ReminderNotifications.configure(
      dailyEnabled: enabled,
      dailyMinutes: preferences.dailyReminderMinutes,
      streakEnabled: preferences.streakWarningEnabled,
      streakMinutes: preferences.streakWarningMinutes,
      requestPermission: enabled,
    );
    if (enabled && !granted) {
      await preferences.setDailyReminderEnabled(false);
      await _configure(requestPermission: false);
      if (context.mounted) _showPermissionMessage(context);
    }
  }

  Future<void> _toggleStreak(BuildContext context, bool enabled) async {
    await preferences.setStreakWarningEnabled(enabled);
    final granted = await ReminderNotifications.configure(
      dailyEnabled: preferences.dailyReminderEnabled,
      dailyMinutes: preferences.dailyReminderMinutes,
      streakEnabled: enabled,
      streakMinutes: preferences.streakWarningMinutes,
      requestPermission: enabled,
    );
    if (enabled && !granted) {
      await preferences.setStreakWarningEnabled(false);
      await _configure(requestPermission: false);
      if (context.mounted) _showPermissionMessage(context);
    }
  }

  Future<void> _pickTime(
    BuildContext context, {
    required bool streak,
  }) async {
    final strings = context.strings;
    final minutes = streak
        ? preferences.streakWarningMinutes
        : preferences.dailyReminderMinutes;
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      helpText: streak
          ? strings.text('Zeit der Streak-Warnung', 'Streak warning time')
          : strings.text('Zeit der Spielerinnerung', 'Play reminder time'),
    );
    if (selected == null) return;
    final value = selected.hour * 60 + selected.minute;
    if (streak) {
      await preferences.setStreakWarningMinutes(value);
    } else {
      await preferences.setDailyReminderMinutes(value);
    }
    await _configure(requestPermission: false);
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: Text(strings.text(
                'Tägliche Spielerinnerung', 'Daily play reminder')),
            subtitle: Text(
              strings.text(
                'Um ${_formatReminderTime(preferences.dailyReminderMinutes, context)} · nur wenn heute noch nicht gespielt wurde',
                'At ${_formatReminderTime(preferences.dailyReminderMinutes, context)} · only if you have not played today',
              ),
            ),
            value: preferences.dailyReminderEnabled,
            onChanged: (value) => _toggleDaily(context, value),
          ),
          if (preferences.dailyReminderEnabled)
            ListTile(
              leading: const SizedBox(width: 24),
              title: Text(strings.text('Uhrzeit ändern', 'Change time')),
              trailing: Text(_formatReminderTime(
                  preferences.dailyReminderMinutes, context)),
              onTap: () => _pickTime(context, streak: false),
            ),
          const Divider(height: 1),
          SwitchListTile(
            secondary: const Icon(Icons.local_fire_department_outlined),
            title: Text(strings.text('Streak-Warnung', 'Streak warning')),
            subtitle: Text(
              strings.text(
                'Um ${_formatReminderTime(preferences.streakWarningMinutes, context)} · nur bei laufender, noch offener Serie',
                'At ${_formatReminderTime(preferences.streakWarningMinutes, context)} · only when an active streak is still at risk',
              ),
            ),
            value: preferences.streakWarningEnabled,
            onChanged: (value) => _toggleStreak(context, value),
          ),
          if (preferences.streakWarningEnabled)
            ListTile(
              leading: const SizedBox(width: 24),
              title: Text(strings.text('Uhrzeit ändern', 'Change time')),
              trailing: Text(_formatReminderTime(
                  preferences.streakWarningMinutes, context)),
              onTap: () => _pickTime(context, streak: true),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              strings.text(
                'Liegen beide Zeiten höchstens 60 Minuten auseinander, erscheint bei einer laufenden Serie nur die Streak-Warnung.',
                'If both times are no more than 60 minutes apart, only the streak warning appears while a streak is active.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _showPermissionMessage(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
    content: Text(
      'Benachrichtigungen sind im System nicht erlaubt. Du kannst sie in den Android-App-Einstellungen freigeben.',
    ),
  ));
}

String _formatReminderTime(int minutes, BuildContext context) {
  final time = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  return MaterialLocalizations.of(context).formatTimeOfDay(time);
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

class PlayerProfileScreen extends StatefulWidget {
  const PlayerProfileScreen({
    required this.results,
    required this.progress,
    super.key,
  });

  final Map<String, PuzzleResult> results;
  final PlayerProgress progress;

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen> {
  PlayerRank? _persistedRank;
  List<ExperienceEvent> _experienceEvents = const [];
  List<PuzzleAttempt> _attempts = const [];
  late Map<String, PuzzleResult> _results;
  late PlayerProgress _progress;

  ProgressSnapshot get _snapshot => ProgressSnapshot(
        results: _results,
        progress: _progress,
        catalogPuzzleIds: {
          ...binaryPuzzleCatalog.map((puzzle) => puzzle.id),
          ...hashiPuzzleCatalog.map((puzzle) => 'hashi:${puzzle.id}'),
          ...slitherlinkPuzzleCatalog
              .map((puzzle) => 'slitherlink:${puzzle.id}'),
          ...futoshikiPuzzleCatalog.map((puzzle) => puzzle.id),
          ...hitoriPuzzleCatalog.map((puzzle) => puzzle.id),
          ...tentsPuzzleCatalog.map((puzzle) => puzzle.id),
        },
        attempts: _attempts,
      );

  @override
  void initState() {
    super.initState();
    _results = widget.results;
    _progress = widget.progress;
    _loadPersistedRank();
  }

  Future<void> _loadPersistedRank() async {
    const service = PlayerProgressService();
    final storage = GameStorage();
    final results = await storage.loadResults();
    final progress = await storage.loadPlayerProgress();
    final attempts = await storage.loadAttempts();
    final freshSnapshot = ProgressSnapshot(
      results: results,
      progress: progress,
      catalogPuzzleIds: _snapshot.catalogPuzzleIds,
      attempts: attempts,
    );
    final existing = await storage.loadExperienceEvents();
    final withAchievements =
        service.synchronizeAchievementXp(freshSnapshot, existing.values);
    final synchronized =
        service.synchronizeMissionXp(freshSnapshot, withAchievements);
    await storage.saveExperienceEvents(synchronized);
    final freshRank = service.rank(
      freshSnapshot,
      experienceEvents: synchronized,
    );
    final celebratedLevel = await storage.loadCelebratedLevel();
    final reachedNewLevel = freshRank.level > celebratedLevel;
    if (freshRank.level != celebratedLevel) {
      await storage.saveCelebratedLevel(freshRank.level);
    }
    if (!mounted) return;
    setState(() {
      _results = results;
      _progress = progress;
      _persistedRank = freshRank;
      _experienceEvents = synchronized;
      _attempts = attempts;
    });
    if (reachedNewLevel) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          PuzzleInteractionFeedback.levelUp(context);
          _showLevelUpDialog(freshRank);
        }
      });
    }
  }

  Future<void> _showLevelUpDialog(PlayerRank rank) => showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.workspace_premium_rounded, size: 52),
          title: Text(context.strings.text(
              'Level ${rank.level} erreicht!', 'Level ${rank.level} reached!')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.strings.known(rank.title),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                context.strings.text(
                  'Deine gelösten Rätsel, Ziele und Erfolge haben dich auf das nächste Level gebracht.',
                  'Your solved puzzles, goals, and achievements have taken you to the next level.',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child:
                  Text(context.strings.text('Weiterknobeln', 'Keep puzzling')),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final snapshot = _snapshot;
    const service = PlayerProgressService();
    final rank = _persistedRank ?? service.rank(snapshot);
    final dailyMissions = service.dailyMissions(snapshot);
    final weeklyMissions = service.weeklyMissions(snapshot);
    final longTermMissions = service.longTermMissions(snapshot);
    final achievements = service.achievements(snapshot);
    final unlockedCount = achievements.where((goal) => goal.isCompleted).length;
    final upcomingAchievements = achievements
        .where((goal) => !goal.isCompleted)
        .toList()
      ..sort((a, b) => b.progress.compareTo(a.progress));
    final completedAchievements =
        achievements.where((goal) => goal.isCompleted).toList();
    final achievementTitles = {
      for (final goal in achievements) goal.id: goal.title,
    };
    final attemptsById = {for (final attempt in _attempts) attempt.id: attempt};
    final recentXp = _experienceEvents
        .where((event) => event.points > 0)
        .toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    final totalXp =
        _experienceEvents.fold<int>(0, (sum, event) => sum + event.points);
    final records = PersonalRecordsCalculator.calculate(
      attempts: _attempts,
      experienceEvents: _experienceEvents,
      completedDays: snapshot.progress.completedDays,
      frozenDays: snapshot.progress.frozenDays,
    );

    return Scaffold(
      appBar: AppBar(
          title: Text(strings.text('Dein Fortschritt', 'Your progress'))),
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
                          Text(strings.known(rank.title)),
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
                            strings.text(
                              '${rank.currentXp} von ${rank.nextLevelXp} XP in diesem Level',
                              '${rank.currentXp} of ${rank.nextLevelXp} XP in this level',
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            strings.text(
                              'Insgesamt $totalXp XP · noch ${rank.nextLevelXp - rank.currentXp} XP bis Level ${rank.level + 1}',
                              '$totalXp XP total · ${rank.nextLevelXp - rank.currentXp} XP to level ${rank.level + 1}',
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (recentXp.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Card(
                      child: ExpansionTile(
                        leading: const Icon(Icons.auto_awesome_rounded),
                        title: Text(
                            strings.text('Deine letzten XP', 'Your latest XP')),
                        subtitle: Text(strings.text(
                            'Jede Gutschrift nachvollziehen',
                            'See every XP award')),
                        children: [
                          for (final event in recentXp.take(6))
                            ListTile(
                              dense: true,
                              leading: Icon(_xpEventIcon(event)),
                              title: Text(strings.known(_xpEventTitle(
                                event,
                                attemptsById,
                                achievementTitles,
                              ))),
                              subtitle: Text(strings.known(_xpEventDetail(
                                event,
                                attemptsById,
                              ))),
                              trailing: Text(
                                '+${event.points} XP',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          if (recentXp.length > 6)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                              child: SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => _XpHistoryScreen(
                                        events: recentXp,
                                        attempts: attemptsById,
                                        achievementTitles: achievementTitles,
                                      ),
                                    ),
                                  ),
                                  icon: const Icon(Icons.history_rounded),
                                  label: Text(strings.text(
                                    'Gesamten XP-Verlauf anzeigen',
                                    'View full XP history',
                                  )),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  StreakCalendarCard(progress: snapshot.progress),
                  const SizedBox(height: 20),
                  PersonalRecordsSection(records: records),
                  const SizedBox(height: 20),
                  Text(
                    strings.text('Heute', 'Today'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.text(
                      'Drei klare Ziele, die jeden Tag neu beginnen.',
                      'Three clear goals that begin again every day.',
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final mission in dailyMissions)
                    _ProgressGoalCard(goal: mission),
                  if (dailyMissions.every((mission) => mission.isCompleted))
                    _MissionSetBonusCard(
                      title: strings.text('Alle Tagesziele geschafft',
                          'All daily goals complete'),
                      points: 15,
                    ),
                  const SizedBox(height: 20),
                  Text(
                    strings.text('Diese Woche', 'This week'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.text(
                      'Zwei ruhige Wochenziele – ohne täglichen Druck.',
                      'Two calm weekly goals — without daily pressure.',
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final mission in weeklyMissions)
                    _ProgressGoalCard(goal: mission),
                  if (weeklyMissions.every((mission) => mission.isCompleted))
                    _MissionSetBonusCard(
                      title: strings.text('Alle Wochenziele geschafft',
                          'All weekly goals complete'),
                      points: 30,
                    ),
                  const SizedBox(height: 20),
                  Text(
                    strings.text('Langzeitziele', 'Long-term goals'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    strings.text(
                      'Fortschritt, der über den heutigen Tag hinaus zählt.',
                      'Progress that matters beyond today.',
                    ),
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
                          strings.text('Erfolge', 'Achievements'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Text(strings.text(
                        '$unlockedCount von ${achievements.length}',
                        '$unlockedCount of ${achievements.length}',
                      )),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final achievement in upcomingAchievements.take(3))
                    _ProgressGoalCard(goal: achievement),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.emoji_events_outlined),
                      title: Text(strings.text(
                          'Alle Erfolge ansehen', 'View all achievements')),
                      subtitle: Text(
                        strings.text(
                          '${completedAchievements.length} freigeschaltet · ${achievements.length} insgesamt',
                          '${completedAchievements.length} unlocked · ${achievements.length} total',
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => _AchievementsScreen(
                            achievements: achievements,
                          ),
                        ),
                      ),
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

String _xpEventTitle(
  ExperienceEvent event,
  Map<String, PuzzleAttempt> attempts,
  Map<String, String> achievementTitles,
) {
  if (event.kind == ExperienceEventKind.achievementUnlocked) {
    return achievementTitles[event.referenceId] ?? 'Erfolg freigeschaltet';
  }
  if (event.kind == ExperienceEventKind.missionCompleted) {
    return missionEventTitle(event.referenceId ?? '');
  }
  final attempt = attempts[event.referenceId];
  if (attempt == null) return 'Rätsel abgeschlossen';
  final mode = switch (attempt.mode) {
    GameMode.catalog => 'Rätselsammlung',
    GameMode.generated => 'Zufallsrätsel',
    GameMode.daily => 'Tagesrätsel',
    GameMode.event => 'Ereignisrätsel',
    GameMode.tutorial => 'Einführung',
  };
  return '${attempt.gameType.label} · $mode';
}

String _xpEventDetail(
  ExperienceEvent event,
  Map<String, PuzzleAttempt> attempts,
) {
  if (event.kind == ExperienceEventKind.achievementUnlocked) {
    return 'Einmaliger Erfolgsbonus';
  }
  if (event.kind == ExperienceEventKind.missionCompleted) {
    return missionEventDetail(event.referenceId ?? '');
  }
  final attempt = attempts[event.referenceId];
  if (attempt == null) return 'Abschlussbonus';
  if (event.points == 0) return 'Bereits gewertetes Tagesrätsel';
  if (event.points == 5) return 'Wiederholungsbonus';
  final noHintBonus = attempt.hintsUsed == 0 ? 10 : 0;
  final base = event.points - noHintBonus;
  return noHintBonus == 0
      ? '${attempt.difficulty.label} · $base XP Grundwert'
      : '${attempt.difficulty.label} · $base Grundwert + 10 ohne Hinweis';
}

class _XpHistoryScreen extends StatelessWidget {
  const _XpHistoryScreen({
    required this.events,
    required this.attempts,
    required this.achievementTitles,
  });

  final List<ExperienceEvent> events;
  final Map<String, PuzzleAttempt> attempts;
  final Map<String, String> achievementTitles;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Scaffold(
      appBar: AppBar(title: Text(strings.text('XP-Verlauf', 'XP history'))),
      body: Center(
        child: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: events.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final event = events[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              leading: CircleAvatar(
                child: Icon(_xpEventIcon(event)),
              ),
              title: Text(strings.known(_xpEventTitle(
                event,
                attempts,
                achievementTitles,
              ))),
              subtitle: Text(
                '${strings.known(_xpEventDetail(event, attempts))}\n${_xpDate(context, event.occurredAt)}',
              ),
              isThreeLine: true,
              trailing: Text(
                '+${event.points} XP',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            );
          },
        ),
      ),
    );
  }
}

String _xpDate(BuildContext context, DateTime value) {
  final local = value.toLocal();
  final material = MaterialLocalizations.of(context);
  final date = material.formatCompactDate(local);
  final time = material.formatTimeOfDay(
    TimeOfDay.fromDateTime(local),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
  return '$date · $time';
}

IconData _xpEventIcon(ExperienceEvent event) => switch (event.kind) {
      ExperienceEventKind.achievementUnlocked => Icons.emoji_events_outlined,
      ExperienceEventKind.missionCompleted => Icons.task_alt_rounded,
      ExperienceEventKind.puzzleCompleted => Icons.extension_outlined,
    };

enum _AchievementFilter { all, open, unlocked }

class _AchievementsScreen extends StatefulWidget {
  const _AchievementsScreen({required this.achievements});

  final List<ProgressGoal> achievements;

  @override
  State<_AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<_AchievementsScreen> {
  _AchievementFilter _filter = _AchievementFilter.all;

  @override
  Widget build(BuildContext context) {
    final unlocked =
        widget.achievements.where((goal) => goal.isCompleted).length;
    final visible = widget.achievements.where((goal) {
      return switch (_filter) {
        _AchievementFilter.all => true,
        _AchievementFilter.open => !goal.isCompleted,
        _AchievementFilter.unlocked => goal.isCompleted,
      };
    }).toList()
      ..sort((a, b) {
        if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
        return b.progress.compareTo(a.progress);
      });
    final colors = Theme.of(context).colorScheme;
    final strings = context.strings;

    return Scaffold(
      appBar: AppBar(title: Text(strings.text('Erfolge', 'Achievements'))),
      body: Center(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    color: colors.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.emoji_events_rounded,
                            size: 48,
                            color: colors.onPrimaryContainer,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            strings.text(
                              '$unlocked von ${widget.achievements.length} freigeschaltet',
                              '$unlocked of ${widget.achievements.length} unlocked',
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(
                            value: widget.achievements.isEmpty
                                ? 0
                                : unlocked / widget.achievements.length,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<_AchievementFilter>(
                    segments: [
                      ButtonSegment(
                        value: _AchievementFilter.all,
                        label: Text(strings.text('Alle', 'All')),
                      ),
                      ButtonSegment(
                        value: _AchievementFilter.open,
                        label: Text(strings.text('Offen', 'Open')),
                      ),
                      ButtonSegment(
                        value: _AchievementFilter.unlocked,
                        label: Text(strings.text('Erreicht', 'Unlocked')),
                      ),
                    ],
                    selected: {_filter},
                    onSelectionChanged: (selection) => setState(
                      () => _filter = selection.single,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (visible.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          strings.text(
                            'In diesem Bereich gibt es derzeit keine Erfolge.',
                            'There are currently no achievements in this section.',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    for (final achievement in visible)
                      _ProgressGoalCard(goal: achievement),
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
    final strings = context.strings;
    final reward = goal.kind == ProgressGoalKind.mission
        ? ExperiencePointsPolicy.mission(goal.id)
        : ExperiencePointsPolicy.achievement(goal.id);
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
                          strings.known(goal.title),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (completed)
                        Text(
                          strings.text('Geschafft', 'Complete'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        )
                      else
                        Text(
                          '${goal.current.clamp(0, goal.target)} / ${goal.target}',
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(strings.known(goal.description)),
                  if (reward > 0) ...[
                    const SizedBox(height: 5),
                    Text(
                      '+$reward XP',
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
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
        'gesture' => Icons.gesture_outlined,
        'menu_book' => Icons.menu_book_outlined,
        'park' => Icons.park_outlined,
        _ => Icons.emoji_events_outlined,
      };
}

class _MissionSetBonusCard extends StatelessWidget {
  const _MissionSetBonusCard({required this.title, required this.points});

  final String title;
  final int points;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.primaryContainer,
      child: ListTile(
        leading: Icon(Icons.workspace_premium_rounded,
            color: colors.onPrimaryContainer),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(context.strings
            .text('Komplettbonus gutgeschrieben', 'Completion bonus awarded')),
        trailing: Text(
          '+$points XP',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
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
    final strings = context.strings;
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
    final slitherlinkStatistics = GameStatistics.fromAttempts(
      _attempts,
      gameType: GameType.slitherlink,
    );
    final futoshikiStatistics = GameStatistics.fromAttempts(
      _attempts,
      gameType: GameType.futoshiki,
    );
    final hitoriStatistics = GameStatistics.fromAttempts(
      _attempts,
      gameType: GameType.hitori,
    );
    final tentsStatistics = GameStatistics.fromAttempts(
      _attempts,
      gameType: GameType.tents,
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
    final slitherlinkResults = results.values
        .where((result) => result.gameType == GameType.slitherlink)
        .toList(growable: false);
    final slitherlinkCompleted = slitherlinkResults.fold<int>(
      0,
      (sum, result) => sum + result.completionCount,
    );
    final slitherlinkCollectionCompleted = slitherlinkResults
        .where((result) => result.effectiveSource == GameMode.catalog)
        .map((result) => result.puzzleId)
        .toSet()
        .length;
    final futoshikiResults = results.values
        .where((result) => result.gameType == GameType.futoshiki)
        .toList(growable: false);
    final futoshikiCompleted = futoshikiResults.fold<int>(
      0,
      (sum, result) => sum + result.completionCount,
    );
    final futoshikiCollectionCompleted = futoshikiResults
        .where((result) => result.effectiveSource == GameMode.catalog)
        .map((result) => result.puzzleId)
        .toSet()
        .length;
    final hitoriResults = results.values
        .where((result) => result.gameType == GameType.hitori)
        .toList(growable: false);
    final hitoriCompleted = hitoriResults.fold<int>(
      0,
      (sum, result) => sum + result.completionCount,
    );
    final hitoriCollectionCompleted = hitoriResults
        .where((result) => result.effectiveSource == GameMode.catalog)
        .map((result) => result.puzzleId)
        .toSet()
        .length;
    final tentsResults = results.values
        .where((result) => result.gameType == GameType.tents)
        .toList(growable: false);
    final tentsCompleted = tentsResults.fold<int>(
      0,
      (sum, result) => sum + result.completionCount,
    );
    final tentsCollectionCompleted = tentsResults
        .where((result) => result.effectiveSource == GameMode.catalog)
        .map((result) => result.puzzleId)
        .toSet()
        .length;
    final isBinairoDetail = widget.gameType == GameType.binairo;
    final isHashiDetail = widget.gameType == GameType.hashi;
    final isSlitherlinkDetail = widget.gameType == GameType.slitherlink;
    final isFutoshikiDetail = widget.gameType == GameType.futoshiki;
    final isHitoriDetail = widget.gameType == GameType.hitori;
    final isTentsDetail = widget.gameType == GameType.tents;
    final isGameDetail = widget.gameType != null;
    final selectedStatistics = isBinairoDetail
        ? binairoStatistics
        : isHashiDetail
            ? hashiStatistics
            : isSlitherlinkDetail
                ? slitherlinkStatistics
                : isFutoshikiDetail
                    ? futoshikiStatistics
                    : isHitoriDetail
                        ? hitoriStatistics
                        : isTentsDetail
                            ? tentsStatistics
                            : GameStatistics.fromAttempts(_attempts);
    final selectedCompleted = isBinairoDetail
        ? binairoCompleted
        : isHashiDetail
            ? hashiCompleted
            : isSlitherlinkDetail
                ? slitherlinkCompleted
                : isFutoshikiDetail
                    ? futoshikiCompleted
                    : isHitoriDetail
                        ? hitoriCompleted
                        : isTentsDetail
                            ? tentsCompleted
                            : totalCompleted;

    return Scaffold(
      appBar: AppBar(
        title: Text(isGameDetail
            ? strings.text(
                '${widget.gameType!.label}-Statistik',
                '${strings.known(widget.gameType!.label)} statistics',
              )
            : strings.text('Statistik', 'Statistics')),
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
                        ? strings.text(
                            '${widget.gameType!.label}-Rätsel gelöst',
                            '${strings.known(widget.gameType!.label)} puzzles solved',
                          )
                        : strings.text(
                            'Rätsel insgesamt gelöst', 'Total puzzles solved'),
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
                      strings.text('Rätselsammlung', 'Puzzle collection'),
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
                      strings.text(
                          'Zufallsrätsel nach Größe', 'Random puzzles by size'),
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
                      icon: Icons.auto_awesome_outlined,
                      title: 'Zufallsrätsel',
                      subtitle:
                          '${hashiStatistics.completedForMode(GameMode.generated)} abgeschlossen',
                    ),
                    const SizedBox(height: 12),
                    _StatisticListCard(
                      icon: Icons.calendar_today_outlined,
                      title: 'Tagesrätsel',
                      subtitle:
                          '${hashiStatistics.completedForMode(GameMode.daily)} abgeschlossen',
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
                      modes: const [
                        GameMode.catalog,
                        GameMode.generated,
                        GameMode.daily,
                      ],
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
                  ] else if (isSlitherlinkDetail) ...[
                    const SizedBox(height: 12),
                    _StatisticListCard(
                      icon: Icons.collections_bookmark_outlined,
                      title: 'Rätselsammlung',
                      subtitle:
                          '$slitherlinkCollectionCompleted von ${slitherlinkPuzzleCatalog.length} gelöst',
                      trailing:
                          '${((slitherlinkCollectionCompleted / slitherlinkPuzzleCatalog.length) * 100).round()} %',
                    ),
                    const SizedBox(height: 12),
                    _StatisticListCard(
                      icon: Icons.auto_awesome_outlined,
                      title: 'Zufallsrätsel',
                      subtitle:
                          '${slitherlinkStatistics.completedForMode(GameMode.generated)} abgeschlossen',
                    ),
                    const SizedBox(height: 12),
                    _StatisticListCard(
                      icon: Icons.calendar_today_outlined,
                      title: 'Tagesrätsel',
                      subtitle:
                          '${slitherlinkStatistics.completedForMode(GameMode.daily)} abgeschlossen',
                    ),
                    const SizedBox(height: 12),
                    _StatisticListCard(
                      icon: Icons.timer_outlined,
                      title: 'Spielzeit',
                      subtitle: _formatLongTime(
                        slitherlinkStatistics.totalPlaySeconds,
                      ),
                      trailing: slitherlinkStatistics.averageSeconds == null
                          ? null
                          : 'Ø ${_formatLongTime(slitherlinkStatistics.averageSeconds!)}',
                    ),
                    const SizedBox(height: 24),
                    _PerformanceStatisticsSection(
                      statistics: slitherlinkStatistics,
                      legacyBestSeconds: _bestResultSeconds(slitherlinkResults),
                      showMoves: true,
                    ),
                    const SizedBox(height: 24),
                    _ModePerformanceSection(
                      statistics: slitherlinkStatistics,
                      modes: const [
                        GameMode.catalog,
                        GameMode.generated,
                        GameMode.daily,
                      ],
                      showMoves: true,
                    ),
                    const SizedBox(height: 24),
                    _DifficultyPerformanceSection(
                      statistics: slitherlinkStatistics,
                      legacyResults: slitherlinkResults,
                      showMoves: true,
                    ),
                  ] else if (isFutoshikiDetail) ...[
                    const SizedBox(height: 12),
                    _StatisticListCard(
                      icon: Icons.collections_bookmark_outlined,
                      title: 'Rätselsammlung',
                      subtitle:
                          '$futoshikiCollectionCompleted von ${futoshikiPuzzleCatalog.length} gelöst',
                      trailing:
                          '${((futoshikiCollectionCompleted / futoshikiPuzzleCatalog.length) * 100).round()} %',
                    ),
                    const SizedBox(height: 12),
                    _StatisticListCard(
                      icon: Icons.auto_awesome_outlined,
                      title: 'Zufallsrätsel',
                      subtitle:
                          '${futoshikiStatistics.completedForMode(GameMode.generated)} abgeschlossen',
                    ),
                    const SizedBox(height: 12),
                    _StatisticListCard(
                      icon: Icons.calendar_today_outlined,
                      title: 'Tagesrätsel',
                      subtitle:
                          '${futoshikiStatistics.completedForMode(GameMode.daily)} abgeschlossen',
                    ),
                    const SizedBox(height: 12),
                    _StatisticListCard(
                      icon: Icons.timer_outlined,
                      title: 'Spielzeit',
                      subtitle: _formatLongTime(
                        futoshikiStatistics.totalPlaySeconds,
                      ),
                      trailing: futoshikiStatistics.averageSeconds == null
                          ? null
                          : 'Ø ${_formatLongTime(futoshikiStatistics.averageSeconds!)}',
                    ),
                    const SizedBox(height: 24),
                    _PerformanceStatisticsSection(
                      statistics: futoshikiStatistics,
                      legacyBestSeconds: _bestResultSeconds(futoshikiResults),
                      showMoves: true,
                    ),
                    const SizedBox(height: 24),
                    _ModePerformanceSection(
                      statistics: futoshikiStatistics,
                      modes: const [
                        GameMode.catalog,
                        GameMode.generated,
                        GameMode.daily,
                      ],
                      showMoves: true,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      strings.text('Nach Rastergröße', 'By grid size'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    for (final size in const [4, 5, 6, 7]) ...[
                      Builder(builder: (context) {
                        final sizeResults = futoshikiResults
                            .where(
                                (result) => result.effectiveBoardSize == size)
                            .toList(growable: false);
                        final completed = sizeResults.fold<int>(
                          0,
                          (sum, result) => sum + result.completionCount,
                        );
                        final best = _bestResultSeconds(sizeResults);
                        return _StatisticListCard(
                          icon: Icons.grid_on_rounded,
                          title: '$size × $size',
                          subtitle: '$completed Rätsel abgeschlossen',
                          trailing: best == null
                              ? null
                              : 'Bestzeit ${_formatLongTime(best)}',
                        );
                      }),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 14),
                    _DifficultyPerformanceSection(
                      statistics: futoshikiStatistics,
                      legacyResults: futoshikiResults,
                      showMoves: true,
                    ),
                  ] else if (isHitoriDetail) ...[
                    const SizedBox(height: 12),
                    _StatisticListCard(
                      icon: Icons.collections_bookmark_outlined,
                      title: 'Rätselsammlung',
                      subtitle:
                          '$hitoriCollectionCompleted von ${hitoriPuzzleCatalog.length} gelöst',
                      trailing:
                          '${((hitoriCollectionCompleted / hitoriPuzzleCatalog.length) * 100).round()} %',
                    ),
                    const SizedBox(height: 12),
                    _StatisticListCard(
                      icon: Icons.auto_awesome_outlined,
                      title: 'Zufallsrätsel',
                      subtitle:
                          '${hitoriStatistics.completedForMode(GameMode.generated)} abgeschlossen',
                    ),
                    const SizedBox(height: 12),
                    _StatisticListCard(
                      icon: Icons.calendar_today_outlined,
                      title: 'Tagesrätsel',
                      subtitle:
                          '${hitoriStatistics.completedForMode(GameMode.daily)} abgeschlossen',
                    ),
                    const SizedBox(height: 12),
                    _StatisticListCard(
                      icon: Icons.timer_outlined,
                      title: 'Spielzeit',
                      subtitle:
                          _formatLongTime(hitoriStatistics.totalPlaySeconds),
                      trailing: hitoriStatistics.averageSeconds == null
                          ? null
                          : 'Ø ${_formatLongTime(hitoriStatistics.averageSeconds!)}',
                    ),
                    const SizedBox(height: 24),
                    _PerformanceStatisticsSection(
                      statistics: hitoriStatistics,
                      legacyBestSeconds: _bestResultSeconds(hitoriResults),
                      showMoves: true,
                    ),
                    const SizedBox(height: 24),
                    _ModePerformanceSection(
                      statistics: hitoriStatistics,
                      modes: const [
                        GameMode.catalog,
                        GameMode.generated,
                        GameMode.daily,
                      ],
                      showMoves: true,
                    ),
                    const SizedBox(height: 24),
                    _DifficultyPerformanceSection(
                      statistics: hitoriStatistics,
                      legacyResults: hitoriResults,
                      showMoves: true,
                    ),
                  ] else if (isTentsDetail) ...[
                    const SizedBox(height: 12),
                    _StatisticListCard(
                      icon: Icons.collections_bookmark_outlined,
                      title: 'R\u00e4tselsammlung',
                      subtitle:
                          '$tentsCollectionCompleted von ${tentsPuzzleCatalog.length} gel\u00f6st',
                      trailing:
                          '${((tentsCollectionCompleted / tentsPuzzleCatalog.length) * 100).round()} %',
                    ),
                    const SizedBox(height: 12),
                    _StatisticListCard(
                      icon: Icons.auto_awesome_outlined,
                      title: 'Zufallsr\u00e4tsel',
                      subtitle:
                          '${tentsStatistics.completedForMode(GameMode.generated)} abgeschlossen',
                    ),
                    const SizedBox(height: 12),
                    _StatisticListCard(
                      icon: Icons.calendar_today_outlined,
                      title: 'Tagesr\u00e4tsel',
                      subtitle:
                          '${tentsStatistics.completedForMode(GameMode.daily)} abgeschlossen',
                    ),
                    const SizedBox(height: 12),
                    _StatisticListCard(
                      icon: Icons.timer_outlined,
                      title: 'Spielzeit',
                      subtitle:
                          _formatLongTime(tentsStatistics.totalPlaySeconds),
                      trailing: tentsStatistics.averageSeconds == null
                          ? null
                          : '\u00d8 ${_formatLongTime(tentsStatistics.averageSeconds!)}',
                    ),
                    const SizedBox(height: 24),
                    _PerformanceStatisticsSection(
                      statistics: tentsStatistics,
                      legacyBestSeconds: _bestResultSeconds(tentsResults),
                      showMoves: true,
                    ),
                    const SizedBox(height: 24),
                    _ModePerformanceSection(
                      statistics: tentsStatistics,
                      modes: const [
                        GameMode.catalog,
                        GameMode.generated,
                        GameMode.daily,
                      ],
                      showMoves: true,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      strings.text('Nach Rastergröße', 'By grid size'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 10),
                    for (final size in const [6, 8, 10]) ...[
                      Builder(builder: (context) {
                        final sizeResults = tentsResults
                            .where(
                                (result) => result.effectiveBoardSize == size)
                            .toList(growable: false);
                        final completed = sizeResults.fold<int>(
                          0,
                          (sum, result) => sum + result.completionCount,
                        );
                        final best = _bestResultSeconds(sizeResults);
                        return _StatisticListCard(
                          icon: Icons.grid_on_rounded,
                          title: '$size \u00d7 $size',
                          subtitle: '$completed R\u00e4tsel abgeschlossen',
                          trailing: best == null
                              ? null
                              : 'Bestzeit ${_formatLongTime(best)}',
                        );
                      }),
                      const SizedBox(height: 10),
                    ],
                    const SizedBox(height: 14),
                    _DifficultyPerformanceSection(
                      statistics: tentsStatistics,
                      legacyResults: tentsResults,
                      showMoves: true,
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    _StatisticListCard(
                      icon: Icons.local_fire_department_outlined,
                      title: '${progress.currentStreak} Tage Spielserie',
                      subtitle: progress.completedToday
                          ? strings.text(
                              'Heute gesichert · Beste Serie: ${progress.bestStreak} Tage',
                              'Safe today · Best streak: ${progress.bestStreak} days')
                          : strings.text(
                              'Heute noch ein Rätsel lösen · Beste Serie: ${progress.bestStreak} Tage',
                              'Solve one puzzle today · Best streak: ${progress.bestStreak} days'),
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
                      strings.text('Deine Spiele', 'Your games'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.text(
                        'Kompakte Übersicht – ausführliche Werte findest du direkt im jeweiligen Spielbereich.',
                        'Compact overview — detailed values are available in each game section.',
                      ),
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
                    const SizedBox(height: 10),
                    _GameStatisticsOverviewCard(
                      gameType: GameType.slitherlink,
                      icon: Icons.gesture_outlined,
                      completed: slitherlinkCompleted,
                      catalogCompleted: slitherlinkCollectionCompleted,
                      catalogTotal: slitherlinkPuzzleCatalog.length,
                      endlessCompleted: slitherlinkStatistics.completedForMode(
                        GameMode.generated,
                      ),
                      solvedWithoutHints:
                          slitherlinkStatistics.solvedWithoutHints,
                      onOpenDetails: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => StatisticsScreen(
                            results: results,
                            progress: progress,
                            gameType: GameType.slitherlink,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _GameStatisticsOverviewCard(
                      gameType: GameType.futoshiki,
                      icon: Icons.compare_arrows_rounded,
                      completed: futoshikiCompleted,
                      catalogCompleted: futoshikiCollectionCompleted,
                      catalogTotal: futoshikiPuzzleCatalog.length,
                      endlessCompleted: futoshikiStatistics.completedForMode(
                        GameMode.generated,
                      ),
                      solvedWithoutHints:
                          futoshikiStatistics.solvedWithoutHints,
                      onOpenDetails: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => StatisticsScreen(
                            results: results,
                            progress: progress,
                            gameType: GameType.futoshiki,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _GameStatisticsOverviewCard(
                      gameType: GameType.hitori,
                      icon: Icons.filter_b_and_w_outlined,
                      completed: hitoriCompleted,
                      catalogCompleted: hitoriCollectionCompleted,
                      catalogTotal: hitoriPuzzleCatalog.length,
                      endlessCompleted: hitoriStatistics.completedForMode(
                        GameMode.generated,
                      ),
                      solvedWithoutHints: hitoriStatistics.solvedWithoutHints,
                      onOpenDetails: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => StatisticsScreen(
                            results: results,
                            progress: progress,
                            gameType: GameType.hitori,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _GameStatisticsOverviewCard(
                      gameType: GameType.tents,
                      icon: Icons.park_outlined,
                      completed: tentsCompleted,
                      catalogCompleted: tentsCollectionCompleted,
                      catalogTotal: tentsPuzzleCatalog.length,
                      endlessCompleted: tentsStatistics.completedForMode(
                        GameMode.generated,
                      ),
                      solvedWithoutHints: tentsStatistics.solvedWithoutHints,
                      onOpenDetails: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => StatisticsScreen(
                            results: results,
                            progress: progress,
                            gameType: GameType.tents,
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
              Text(context.strings.known(label)),
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
          title: Text(context.strings.known(title)),
          subtitle: Text(context.strings.known(subtitle)),
          trailing:
              trailing == null ? null : Text(context.strings.known(trailing!)),
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
        Text(context.strings.text('Leistung', 'Performance'),
            style: Theme.of(context).textTheme.titleLarge),
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
            context.strings.text(
              'Deine Rekorde erscheinen nach dem nächsten abgeschlossenen Rätsel.',
              'Your records will appear after your next completed puzzle.',
            ),
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
          context.strings.text('Nach Schwierigkeit', 'By difficulty'),
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
        title: Text(context.strings.known(difficulty.label)),
        subtitle: Text(context.strings.text(
            '$completedCount abgeschlossen', '$completedCount completed')),
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
          Text(context.strings.text('Nach Spielart', 'By mode'),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            context.strings.text(
              'Aufgeschlüsselt nach Sammlung, Zufalls- und Tagesrätseln.',
              'Broken down by collection, random, and daily puzzles.',
            ),
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
        title: Text(context.strings.known(title)),
        subtitle: Text(context.strings.text(
          '${statistics.completedCount} abgeschlossen',
          '${statistics.completedCount} completed',
        )),
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
        Text(context.strings.text('Letzte 7 Tage', 'Last 7 days'),
            style: Theme.of(context).textTheme.titleLarge),
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
          context.strings.known(gameType.label),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(context.strings.text(
            '$completed Rätsel abgeschlossen', '$completed puzzles completed')),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          if (catalogTotal > 0) ...[
            LinearProgressIndicator(value: progress.clamp(0, 1)),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: _CompactStatistic(
                  value: catalogTotal > 0
                      ? '$catalogCompleted/$catalogTotal'
                      : '0',
                  label: catalogTotal > 0 ? 'Sammlung' : 'Tagesrätsel',
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
              label: Text(
                  context.strings.text('Alle Statistiken', 'All statistics')),
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
            context.strings.known(label),
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
                Text(context.strings.text('$total gesamt', '$total total')),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.strings.text('Schwierigkeit', 'Difficulty'),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: Text(
                    context.strings.text('Gelöst', 'Solved'),
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
                SizedBox(
                  width: 82,
                  child: Text(
                    context.strings.text('Bestzeit', 'Best time'),
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
                    Expanded(
                        child: Text(context.strings.known(difficulty.label))),
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
        title: Text(context.strings.known(difficulty.label)),
        subtitle: Text(
            context.strings.known('$completed von ${puzzles.length} gelöst')),
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
    final palette = AppTheme.boardPalette(
      'binairo',
      Theme.of(context).brightness,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.board,
        border: Border.all(color: palette.muted, width: 2),
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
    final palette = AppTheme.boardPalette(
      'binairo',
      Theme.of(context).brightness,
    );

    final background = switch ((value, clue, hasIssue)) {
      (_, _, true) => colors.errorContainer,
      (null, _, false) => palette.board,
      (_, true, false) => palette.cellStrong,
      (CellValue.zero, false, false) =>
        Color.alphaBlend(palette.accent.withValues(alpha: .44), palette.board),
      (CellValue.one, false, false) => Color.alphaBlend(
          palette.accentAlt.withValues(alpha: .48), palette.board),
    };

    final foreground = hasIssue
        ? colors.onErrorContainer
        : clue
            ? palette.foreground
            : value == CellValue.one
                ? palette.foreground
                : palette.foreground;

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
              ? palette.cellStrong
              : isHintRelated && !hasIssue
                  ? colors.secondaryContainer.withValues(alpha: 0.55)
                  : isRelated && value == null && !hasIssue
                      ? palette.cell
                      : background,
          border: Border.all(
            color: isSelected || isHint
                ? palette.accent
                : isHintRelated
                    ? palette.accentAlt
                    : palette.muted.withValues(alpha: .55),
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
    final strings = context.strings;
    final (icon, title, text) = switch ((isSolved, isComplete, issueCount)) {
      (true, _, _) => (
          Icons.check_circle_outline,
          strings.text('Rätsel gelöst', 'Puzzle solved'),
          strings.text('Alle Regeln sind erfüllt.', 'All rules are satisfied.'),
        ),
      (false, true, 0) => (
          Icons.hourglass_bottom,
          strings.text('Fast geschafft', 'Almost there'),
          strings.text('Das Raster ist vollständig und wird geprüft.',
              'The grid is complete and is being checked.'),
        ),
      (false, _, > 0) => (
          Icons.info_outline,
          strings.text('$issueCount Regelhinweis${issueCount == 1 ? '' : 'e'}',
              '$issueCount rule ${issueCount == 1 ? 'issue' : 'issues'}'),
          strings.text(
              'Korrigiere die markierten Felder.', 'Correct the marked cells.'),
        ),
      _ => (
          Icons.touch_app_outlined,
          strings.text('Tippen: leer → 0 → 1', 'Tap: empty → 0 → 1'),
          strings.text('Vorgaben sind stärker hervorgehoben.',
              'Given cells are highlighted more strongly.'),
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
