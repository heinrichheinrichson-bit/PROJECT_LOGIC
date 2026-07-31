import '../domain/game_identity.dart';

/// A completed puzzle playthrough used as the source for detailed statistics.
///
/// Aggregated [PuzzleResult] values remain available for fast legacy screens.
/// New statistics should be derived from this append-only history instead.
class PuzzleAttempt {
  const PuzzleAttempt({
    required this.id,
    required this.gameType,
    required this.puzzleId,
    required this.mode,
    required this.difficulty,
    required this.boardSize,
    required this.startedAt,
    required this.completedAt,
    required this.elapsedSeconds,
    this.moves,
    this.hintsUsed = 0,
    this.rewardedHints = 0,
  });

  static const schemaVersion = 1;

  final String id;
  final GameType gameType;
  final String puzzleId;
  final GameMode mode;
  final PuzzleDifficulty difficulty;
  final int boardSize;
  final DateTime startedAt;
  final DateTime completedAt;
  final int elapsedSeconds;
  final int? moves;
  final int hintsUsed;
  final int rewardedHints;

  bool get solvedWithoutHints => hintsUsed == 0;

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'id': id,
        'gameType': gameType.name,
        'puzzleId': puzzleId,
        'mode': mode.name,
        'difficulty': difficulty.name,
        'boardSize': boardSize,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt.toIso8601String(),
        'elapsedSeconds': elapsedSeconds,
        if (moves != null) 'moves': moves,
        'hintsUsed': hintsUsed,
        'rewardedHints': rewardedHints,
      };

  factory PuzzleAttempt.fromJson(Map<String, Object?> json) {
    final version = _readInt(json, 'schemaVersion', fallback: 1);
    if (version != schemaVersion) {
      throw const FormatException('Unsupported attempt schema version.');
    }
    final elapsedSeconds = _readInt(json, 'elapsedSeconds');
    final hintsUsed = _readInt(json, 'hintsUsed', fallback: 0);
    final rewardedHints = _readInt(json, 'rewardedHints', fallback: 0);
    final boardSize = _readInt(json, 'boardSize');
    if (elapsedSeconds < 0 ||
        hintsUsed < 0 ||
        rewardedHints < 0 ||
        boardSize <= 0) {
      throw const FormatException('Attempt values cannot be negative.');
    }
    final startedAt = _readDate(json, 'startedAt');
    final completedAt = _readDate(json, 'completedAt');
    if (completedAt.isBefore(startedAt)) {
      throw const FormatException('Attempt cannot finish before it starts.');
    }
    final rawMoves = json['moves'];
    final moves = rawMoves == null ? null : _readInt(json, 'moves');
    if (moves != null && moves < 0) {
      throw const FormatException('Moves cannot be negative.');
    }

    return PuzzleAttempt(
      id: _readString(json, 'id'),
      gameType: GameType.values.firstWhere(
        (value) => value.name == json['gameType'],
        orElse: () => throw const FormatException('Unknown game type.'),
      ),
      puzzleId: _readString(json, 'puzzleId'),
      mode: GameMode.values.firstWhere(
        (value) => value.name == json['mode'],
        orElse: () => throw const FormatException('Unknown game mode.'),
      ),
      difficulty: PuzzleDifficulty.values.firstWhere(
        (value) => value.name == json['difficulty'],
        orElse: () => throw const FormatException('Unknown difficulty.'),
      ),
      boardSize: boardSize,
      startedAt: startedAt,
      completedAt: completedAt,
      elapsedSeconds: elapsedSeconds,
      moves: moves,
      hintsUsed: hintsUsed,
      rewardedHints: rewardedHints,
    );
  }

  static String _readString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) return value;
    throw FormatException('Missing or invalid $key.');
  }

  static int _readInt(
    Map<String, Object?> json,
    String key, {
    int? fallback,
  }) {
    final value = json[key];
    if (value == null && fallback != null) return fallback;
    if (value is num && value == value.toInt()) return value.toInt();
    throw FormatException('Missing or invalid $key.');
  }

  static DateTime _readDate(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
    throw FormatException('Missing or invalid $key.');
  }
}
