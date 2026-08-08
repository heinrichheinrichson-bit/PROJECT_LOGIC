import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/game_logic.dart';
import 'package:project_logic_prototype/game_storage.dart';
import 'package:project_logic_prototype/player_progress_system.dart';
import 'package:project_logic_prototype/core/progress/experience_event.dart';
import 'package:project_logic_prototype/core/statistics/puzzle_attempt.dart';
import 'package:project_logic_prototype/daily_challenge.dart';

void main() {
  const service = PlayerProgressService();

  test('first achievement unlocks after first completed puzzle', () {
    final progress = const PlayerProgress.empty().recordCompletion(
      elapsedSeconds: 30,
      completedAt: DateTime(2026, 7, 30),
    );
    final snapshot = ProgressSnapshot(
      results: const {},
      progress: progress,
      catalogPuzzleIds: const {'easy-01'},
    );

    final first = service
        .achievements(snapshot)
        .firstWhere((goal) => goal.id == 'first-solve');

    expect(first.isCompleted, isTrue);
    expect(first.progress, 1);
  });

  test('generated completion mission counts repeated completions', () {
    final result = PuzzleResult(
      puzzleId: 'binary-6-easy-42',
      bestSeconds: 40,
      completedAt: DateTime(2026, 7, 30),
      source: PuzzleSource.generated,
      difficulty: PuzzleDifficulty.easy,
      boardSize: 6,
      completionCount: 3,
    );
    final snapshot = ProgressSnapshot(
      results: {result.puzzleId: result},
      progress: const PlayerProgress(
        totalCompleted: 3,
        totalPlaySeconds: 120,
        completedDays: ['2026-07-30'],
      ),
      catalogPuzzleIds: const {},
    );

    final mission = service
        .missions(snapshot)
        .firstWhere((goal) => goal.id == 'generator-three');

    expect(mission.current, 3);
    expect(mission.isCompleted, isTrue);
  });

  test('rank gains xp from completions and unlocked achievements', () {
    const snapshot = ProgressSnapshot(
      results: {},
      progress: PlayerProgress(
        totalCompleted: 10,
        totalPlaySeconds: 500,
        completedDays: ['2026-07-28', '2026-07-29', '2026-07-30'],
      ),
      catalogPuzzleIds: {'one', 'two'},
    );

    final rank = service.rank(snapshot);

    expect(rank.level, greaterThanOrEqualTo(2));
    expect(rank.nextLevelXp, 200);
  });

  test('achievement XP is awarded once and keeps its stored value', () {
    const snapshot = ProgressSnapshot(
      results: {},
      progress: PlayerProgress(
        totalCompleted: 1,
        totalPlaySeconds: 30,
        completedDays: ['2026-08-02'],
      ),
      catalogPuzzleIds: {},
    );
    final first = service.synchronizeAchievementXp(snapshot, const [],
        now: DateTime(2026, 8, 2));
    final second = service.synchronizeAchievementXp(snapshot, first,
        now: DateTime(2026, 8, 3));
    expect(
        first.where(
            (event) => event.kind == ExperienceEventKind.achievementUnlocked),
        hasLength(1));
    expect(second, hasLength(first.length));
    expect(service.rank(snapshot, experienceEvents: second).currentXp, 25);
  });
  test('daily missions reset through date-specific ids', () {
    final result = PuzzleResult(
      puzzleId: 'binary-6-easy-99',
      bestSeconds: 50,
      completedAt: DateTime(2026, 7, 30),
      source: PuzzleSource.generated,
      difficulty: PuzzleDifficulty.easy,
      boardSize: 6,
    );
    final snapshot = ProgressSnapshot(
      results: {result.puzzleId: result},
      progress: const PlayerProgress.empty(),
      catalogPuzzleIds: const {},
    );

    final firstDay = service.dailyMissions(
      snapshot,
      date: DateTime(2026, 7, 30),
    );
    final nextDay = service.dailyMissions(
      snapshot,
      date: DateTime(2026, 7, 31),
    );

    expect(firstDay, hasLength(3));
    expect(nextDay, hasLength(3));
    expect(
        firstDay.map((goal) => goal.id), isNot(nextDay.map((goal) => goal.id)));
    expect(firstDay.first.id, isNot(nextDay.first.id));
  });

  test('game-specific achievements count Binairo and Hashi separately', () {
    final hashi = PuzzleResult(
      puzzleId: 'easy-01',
      bestSeconds: 60,
      completedAt: DateTime(2026, 7, 31),
      gameType: GameType.hashi,
      source: PuzzleSource.catalog,
      difficulty: PuzzleDifficulty.easy,
      boardSize: 7,
    );
    final snapshot = ProgressSnapshot(
      results: {'hashi:easy-01': hashi},
      progress: const PlayerProgress(
        totalCompleted: 1,
        totalPlaySeconds: 60,
        completedDays: ['2026-07-31'],
      ),
      catalogPuzzleIds: const {'hashi:easy-01'},
    );

    final achievements = service.achievements(snapshot);

    expect(
      achievements.firstWhere((goal) => goal.id == 'hashi-first').isCompleted,
      isTrue,
    );
    expect(
      achievements.firstWhere((goal) => goal.id == 'binairo-first').isCompleted,
      isFalse,
    );
    expect(snapshot.catalogCompleted, 1);
  });

  test('weekly active-day mission counts unique days in the current week', () {
    const snapshot = ProgressSnapshot(
      results: {},
      progress: PlayerProgress(
        totalCompleted: 3,
        totalPlaySeconds: 90,
        completedDays: ['2026-08-03', '2026-08-05', '2026-08-07'],
      ),
      catalogPuzzleIds: {},
    );
    final weekly = service.weeklyMissions(
      snapshot,
      date: DateTime(2026, 8, 7),
    );
    expect(weekly.first.current, 3);
    expect(weekly.first.isCompleted, isTrue);
    expect(weekly.first.id, contains('2026-08-03'));
  });

  test('mission XP is complete, idempotent, and date-specific', () {
    final day = DateTime(2026, 8, 8, 12);
    const dailyService = DailyChallengeService();
    final attempts = <PuzzleAttempt>[
      _attempt(
        id: 'daily',
        puzzleId: dailyService.summaryForGame(day, GameType.binairo).puzzleId,
        gameType: GameType.binairo,
        mode: GameMode.daily,
        date: day,
        difficulty: PuzzleDifficulty.hard,
      ),
      _attempt(
        id: 'generated',
        puzzleId: 'generated-1',
        gameType: GameType.hashi,
        mode: GameMode.generated,
        date: day,
        difficulty: PuzzleDifficulty.hard,
      ),
      _attempt(
        id: 'catalog',
        puzzleId: 'catalog-1',
        gameType: GameType.slitherlink,
        mode: GameMode.catalog,
        date: day,
      ),
      _attempt(
        id: 'extra-1',
        puzzleId: 'generated-2',
        gameType: GameType.futoshiki,
        mode: GameMode.generated,
        date: day.subtract(const Duration(days: 1)),
      ),
      _attempt(
        id: 'extra-2',
        puzzleId: 'catalog-2',
        gameType: GameType.hitori,
        mode: GameMode.catalog,
        date: day.subtract(const Duration(days: 2)),
      ),
    ];
    final snapshot = ProgressSnapshot(
      results: const {},
      progress: const PlayerProgress.empty(),
      catalogPuzzleIds: const {},
      attempts: attempts,
    );

    final first = service.synchronizeMissionXp(snapshot, const [], now: day);
    final second = service.synchronizeMissionXp(snapshot, first,
        now: day.add(const Duration(hours: 1)));

    expect(first, isNotEmpty);
    expect(first.map((event) => event.id).toSet(), hasLength(first.length));
    expect(second, hasLength(first.length));
    expect(first.every((event) => event.points > 0), isTrue);
    expect(
      first.any(
          (event) => event.referenceId?.endsWith('daily-complete') ?? false),
      isTrue,
    );
  });
}

PuzzleAttempt _attempt({
  required String id,
  required String puzzleId,
  required GameType gameType,
  required GameMode mode,
  required DateTime date,
  PuzzleDifficulty difficulty = PuzzleDifficulty.easy,
}) =>
    PuzzleAttempt(
      id: id,
      gameType: gameType,
      puzzleId: puzzleId,
      mode: mode,
      difficulty: difficulty,
      boardSize: 6,
      startedAt: date.subtract(const Duration(minutes: 1)),
      completedAt: date,
      elapsedSeconds: 60,
    );

// Daily missions deliberately use an injected date so tests do not depend on
// the machine clock.
