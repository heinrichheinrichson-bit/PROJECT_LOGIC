import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/game_logic.dart';
import 'package:project_logic_prototype/game_storage.dart';
import 'package:project_logic_prototype/player_progress_system.dart';
import 'package:project_logic_prototype/core/progress/experience_event.dart';

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
    expect(service.rank(snapshot, experienceEvents: second).currentXp, 50);
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

    expect(firstDay[1].isCompleted, isTrue);
    expect(nextDay[1].isCompleted, isFalse);
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
}

// Daily missions deliberately use an injected date so tests do not depend on
// the machine clock.
