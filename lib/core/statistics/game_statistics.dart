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
  int get hintsUsed =>
      attempts.fold(0, (total, attempt) => total + attempt.hintsUsed);
  int? get bestSeconds => attempts.isEmpty
      ? null
      : attempts
          .map((attempt) => attempt.elapsedSeconds)
          .reduce((best, value) => value < best ? value : best);
  int? get averageSeconds =>
      attempts.isEmpty ? null : (totalPlaySeconds / attempts.length).round();
  int? get bestWithoutHintsSeconds {
    final values = attempts
        .where((attempt) => attempt.solvedWithoutHints)
        .map((attempt) => attempt.elapsedSeconds);
    if (values.isEmpty) return null;
    return values.reduce((best, value) => value < best ? value : best);
  }

  int? get fewestMoves {
    final values = attempts.map((attempt) => attempt.moves).whereType<int>();
    if (values.isEmpty) return null;
    return values.reduce((best, value) => value < best ? value : best);
  }

  int? get averageMoves {
    final values = attempts.map((attempt) => attempt.moves).whereType<int>();
    if (values.isEmpty) return null;
    final list = values.toList(growable: false);
    return (list.fold<int>(0, (sum, value) => sum + value) / list.length)
        .round();
  }

  int completedForMode(GameMode mode) =>
      attempts.where((attempt) => attempt.mode == mode).length;

  int completedForDifficulty(PuzzleDifficulty difficulty) =>
      attempts.where((attempt) => attempt.difficulty == difficulty).length;

  GameStatistics filtered({
    GameMode? mode,
    PuzzleDifficulty? difficulty,
    int? boardSize,
  }) {
    return GameStatistics._(
      attempts: List.unmodifiable(attempts.where(
        (attempt) =>
            (mode == null || attempt.mode == mode) &&
            (difficulty == null || attempt.difficulty == difficulty) &&
            (boardSize == null || attempt.boardSize == boardSize),
      )),
    );
  }

  int uniqueCatalogPuzzles(GameType gameType) => attempts
      .where((attempt) =>
          attempt.gameType == gameType && attempt.mode == GameMode.catalog)
      .map((attempt) => attempt.puzzleId)
      .toSet()
      .length;
}
