import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/core/domain/game_identity.dart';
import 'package:project_logic_prototype/core/statistics/game_statistics.dart';
import 'package:project_logic_prototype/core/statistics/puzzle_attempt.dart';

void main() {
  final completedAt = DateTime(2026, 7, 31, 20);
  final attempt = PuzzleAttempt(
    id: 'attempt-1',
    gameType: GameType.hashi,
    puzzleId: 'hashi_01',
    mode: GameMode.catalog,
    difficulty: PuzzleDifficulty.easy,
    boardSize: 7,
    startedAt: completedAt.subtract(const Duration(seconds: 90)),
    completedAt: completedAt,
    elapsedSeconds: 90,
    moves: 8,
    hintsUsed: 1,
    rewardedHints: 1,
  );

  test('PuzzleAttempt survives JSON conversion', () {
    final restored = PuzzleAttempt.fromJson(attempt.toJson());

    expect(restored.id, attempt.id);
    expect(restored.gameType, GameType.hashi);
    expect(restored.moves, 8);
    expect(restored.hintsUsed, 1);
    expect(restored.rewardedHints, 1);
  });

  test('GameStatistics filters games and aggregates useful values', () {
    final withoutHint = PuzzleAttempt(
      id: 'attempt-2',
      gameType: GameType.binairo,
      puzzleId: 'easy-01',
      mode: GameMode.generated,
      difficulty: PuzzleDifficulty.medium,
      boardSize: 6,
      startedAt: completedAt.subtract(const Duration(seconds: 30)),
      completedAt: completedAt,
      elapsedSeconds: 30,
    );

    final global = GameStatistics.fromAttempts([attempt, withoutHint]);
    final binairo = GameStatistics.fromAttempts(
      [attempt, withoutHint],
      gameType: GameType.binairo,
    );

    expect(global.completedCount, 2);
    expect(global.totalPlaySeconds, 120);
    expect(global.solvedWithoutHints, 1);
    expect(global.rewardedHints, 1);
    expect(binairo.completedCount, 1);
    expect(binairo.completedForMode(GameMode.generated), 1);
    expect(binairo.completedForDifficulty(PuzzleDifficulty.medium), 1);
  });
}
