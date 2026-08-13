import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/core/domain/game_identity.dart';
import 'package:project_logic_prototype/core/progress/experience_event.dart';
import 'package:project_logic_prototype/core/statistics/personal_records.dart';
import 'package:project_logic_prototype/core/statistics/puzzle_attempt.dart';

void main() {
  test('calculates daily records and uses the newest date for ties', () {
    final attempts = [
      _attempt('a', GameType.binairo, DateTime(2026, 8, 10, 8), 120),
      _attempt('b', GameType.hashi, DateTime(2026, 8, 10, 9), 180),
      _attempt('c', GameType.hashi, DateTime(2026, 8, 12, 9), 90),
      _attempt('d', GameType.slitherlink, DateTime(2026, 8, 12, 10), 60),
    ];
    final xp = [
      _xp('one', 40, DateTime(2026, 8, 10)),
      _xp('two', 10, DateTime(2026, 8, 10)),
      _xp('three', 50, DateTime(2026, 8, 12)),
    ];

    final records = PersonalRecordsCalculator.calculate(
      attempts: attempts,
      experienceEvents: xp,
      completedDays: const ['2026-08-10', '2026-08-12'],
      frozenDays: const ['2026-08-11'],
    );

    expect(records.longestStreak?.value, 3);
    expect(records.longestStreak?.start, DateTime(2026, 8, 10));
    expect(records.longestStreak?.end, DateTime(2026, 8, 12));
    expect(records.mostXp?.value, 50);
    expect(records.mostXp?.start, DateTime(2026, 8, 12));
    expect(records.mostPuzzles?.value, 2);
    expect(records.mostPuzzles?.start, DateTime(2026, 8, 12));
    expect(records.longestPlaytime?.value, 300);
    expect(records.mostGameTypes?.value, 2);
    expect(records.strongestMonth?.value, 4);
    expect(records.usedFreezes, 1);
  });

  test('keeps one fastest record for every played game type', () {
    final records = PersonalRecordsCalculator.calculate(
      attempts: [
        _attempt('slow', GameType.tents, DateTime(2026, 8, 1), 100),
        _attempt('fast', GameType.tents, DateTime(2026, 8, 2), 50),
        _attempt('hashi', GameType.hashi, DateTime(2026, 8, 3), 70),
      ],
      experienceEvents: const [],
      completedDays: const [],
      frozenDays: const [],
    );

    expect(records.fastestByGame, hasLength(2));
    expect(
      records.fastestByGame
          .firstWhere((record) => record.gameType == GameType.tents)
          .seconds,
      50,
    );
  });

  test('empty history still reports zero used freezes', () {
    final records = PersonalRecordsCalculator.calculate(
      attempts: const [],
      experienceEvents: const [],
      completedDays: const [],
      frozenDays: const [],
    );
    expect(records.longestStreak, isNull);
    expect(records.mostXp, isNull);
    expect(records.fastestByGame, isEmpty);
    expect(records.usedFreezes, 0);
  });
}

PuzzleAttempt _attempt(
  String id,
  GameType gameType,
  DateTime completedAt,
  int seconds,
) =>
    PuzzleAttempt(
      id: id,
      gameType: gameType,
      puzzleId: id,
      mode: GameMode.catalog,
      difficulty: PuzzleDifficulty.easy,
      boardSize: 6,
      startedAt: completedAt.subtract(Duration(seconds: seconds)),
      completedAt: completedAt,
      elapsedSeconds: seconds,
    );

ExperienceEvent _xp(String id, int points, DateTime date) => ExperienceEvent(
      id: id,
      kind: ExperienceEventKind.puzzleCompleted,
      points: points,
      occurredAt: date,
    );
