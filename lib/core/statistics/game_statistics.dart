import '../domain/game_identity.dart';
import 'puzzle_attempt.dart';

class GameStatistics {
  const GameStatistics._({required this.attempts});

  factory GameStatistics.fromAttempts(
    Iterable<PuzzleAttempt> attempts, {
    GameType? gameType,
  }) {
    final filtered = gameType == null
        ? attempts
        : attempts.where((attempt) => attempt.gameType == gameType);
    return GameStatistics._(attempts: List.unmodifiable(filtered));
  }

  final List<PuzzleAttempt> attempts;

  int get completedCount => attempts.length;
  int get totalPlaySeconds =>
      attempts.fold(0, (total, attempt) => total + attempt.elapsedSeconds);
  int get solvedWithoutHints =>
      attempts.where((attempt) => attempt.solvedWithoutHints).length;
  int get rewardedHints =>
      attempts.fold(0, (total, attempt) => total + attempt.rewardedHints);

  int completedForMode(GameMode mode) =>
      attempts.where((attempt) => attempt.mode == mode).length;

  int completedForDifficulty(PuzzleDifficulty difficulty) =>
      attempts.where((attempt) => attempt.difficulty == difficulty).length;

  int uniqueCatalogPuzzles(GameType gameType) => attempts
      .where((attempt) =>
          attempt.gameType == gameType && attempt.mode == GameMode.catalog)
      .map((attempt) => attempt.puzzleId)
      .toSet()
      .length;
}
