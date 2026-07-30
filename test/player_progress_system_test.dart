import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/game_logic.dart';
import 'package:project_logic_prototype/game_storage.dart';
import 'package:project_logic_prototype/player_progress_system.dart';

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

}

// Daily missions deliberately use an injected date so tests do not depend on
// the machine clock.
