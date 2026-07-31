import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'core/domain/game_identity.dart';
import 'game_logic.dart';

export 'core/domain/game_identity.dart' show GameMode, GameType, PuzzleSource;

class SavedGame {
  static const int currentSchemaVersion = 3;

  const SavedGame({
    required this.puzzleId,
    required this.elapsedSeconds,
    required this.values,
    required this.savedAt,
    this.definition,
    this.titleOverride,
    this.source = PuzzleSource.catalog,
  });

  final String puzzleId;
  final int elapsedSeconds;
  final List<int?> values;
  final DateTime savedAt;

  /// Present for generated puzzles so they can be restored without relying on
  /// the static catalog.
  final BinaryPuzzleDefinition? definition;
  final String? titleOverride;
  final PuzzleSource source;

  bool get isGenerated => definition != null;

  Map<String, Object?> toJson() => {
        'schemaVersion': currentSchemaVersion,
        'puzzleId': puzzleId,
        'elapsedSeconds': elapsedSeconds,
        'values': values,
        'savedAt': savedAt.toIso8601String(),
        if (definition != null) 'definition': _definitionToJson(definition!),
        if (titleOverride != null) 'titleOverride': titleOverride,
        'source': source.name,
      };

  factory SavedGame.fromJson(Map<String, Object?> json) {
    final schemaVersion = _readInt(json, 'schemaVersion', fallback: 1);
    if (schemaVersion < 1 || schemaVersion > currentSchemaVersion) {
      throw const FormatException('Unsupported saved-game schema version.');
    }

    final puzzleId = _readRequiredString(json, 'puzzleId');
    final elapsedSeconds = _readInt(json, 'elapsedSeconds', fallback: 0);
    if (elapsedSeconds < 0) {
      throw const FormatException('Elapsed time cannot be negative.');
    }

    final rawValues = json['values'];
    if (rawValues is! List) {
      throw const FormatException('Saved values must be a list.');
    }
    final values = rawValues.map<int?>((value) {
      if (value == null) return null;
      if (value is num && (value.toInt() == 0 || value.toInt() == 1)) {
        return value.toInt();
      }
      throw const FormatException('Saved cell values must be 0, 1 or null.');
    }).toList(growable: false);

    final rawDefinition = json['definition'];
    final definition = rawDefinition is Map
        ? _definitionFromJson(Map<String, Object?>.from(rawDefinition))
        : null;
    if (definition != null) {
      final editableCellCount =
          definition.size * definition.size - definition.clues.length;
      if (values.length != editableCellCount) {
        throw const FormatException(
          'Saved values do not match the generated puzzle definition.',
        );
      }
      if (definition.id != puzzleId) {
        throw const FormatException(
          'Saved puzzle id does not match its generated definition.',
        );
      }
    }

    final rawTitle = json['titleOverride'];
    if (rawTitle != null && rawTitle is! String) {
      throw const FormatException('Saved title must be text.');
    }

    return SavedGame(
      puzzleId: puzzleId,
      elapsedSeconds: elapsedSeconds,
      values: values,
      savedAt:
          DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.now(),
      definition: definition,
      titleOverride: rawTitle as String?,
      source: PuzzleSource.values.firstWhere(
        (value) => value.name == json['source'],
        orElse: () =>
            definition != null ? PuzzleSource.generated : PuzzleSource.catalog,
      ),
    );
  }

  static String _readRequiredString(
    Map<String, Object?> json,
    String key,
  ) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) return value;
    throw FormatException('Missing or invalid $key.');
  }

  static int _readInt(
    Map<String, Object?> json,
    String key, {
    required int fallback,
  }) {
    final value = json[key];
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num && value == value.toInt()) return value.toInt();
    throw FormatException('Invalid integer value for $key.');
  }

  static Map<String, Object?> _definitionToJson(
    BinaryPuzzleDefinition definition,
  ) =>
      {
        'id': definition.id,
        'number': definition.number,
        'difficulty': definition.difficulty.name,
        'solution': [
          for (final row in definition.solution)
            [for (final value in row) value == CellValue.zero ? 0 : 1],
        ],
        'clues': [
          for (final clue in definition.clues)
            {'row': clue.row, 'column': clue.column},
        ],
      };

  static BinaryPuzzleDefinition _definitionFromJson(
    Map<String, Object?> json,
  ) {
    final id = _readRequiredString(json, 'id');
    final difficultyName = json['difficulty'] as String? ?? 'easy';
    final difficulty = PuzzleDifficulty.values.firstWhere(
      (value) => value.name == difficultyName,
      orElse: () => PuzzleDifficulty.easy,
    );
    final rawSolution = json['solution'];
    if (rawSolution is! List || rawSolution.isEmpty) {
      throw const FormatException('Puzzle solution must be a non-empty list.');
    }
    final solution = rawSolution.map<List<CellValue>>((rawRow) {
      if (rawRow is! List) {
        throw const FormatException('Every solution row must be a list.');
      }
      return rawRow.map<CellValue>((value) {
        if (value == 0) return CellValue.zero;
        if (value == 1) return CellValue.one;
        throw const FormatException('Solution values must be 0 or 1.');
      }).toList(growable: false);
    }).toList(growable: false);

    final size = solution.length;
    if (size.isOdd || solution.any((row) => row.length != size)) {
      throw const FormatException(
        'Puzzle solution must be an even-sized square.',
      );
    }

    final rawClues = json['clues'];
    if (rawClues is! List) {
      throw const FormatException('Puzzle clues must be a list.');
    }
    final clues = rawClues.map<CellPosition>((rawItem) {
      if (rawItem is! Map) {
        throw const FormatException('Every clue must be an object.');
      }
      final item = Map<String, Object?>.from(rawItem);
      final row = _readInt(item, 'row', fallback: -1);
      final column = _readInt(item, 'column', fallback: -1);
      if (row < 0 || row >= size || column < 0 || column >= size) {
        throw const FormatException('Puzzle clue is outside the board.');
      }
      return CellPosition(row, column);
    }).toSet();

    return BinaryPuzzleDefinition(
      id: id,
      number: _readInt(json, 'number', fallback: 1),
      difficulty: difficulty,
      solution: solution,
      clues: clues,
    );
  }
}

class PuzzleResult {
  const PuzzleResult({
    required this.puzzleId,
    required this.bestSeconds,
    required this.completedAt,
    this.gameType = GameType.binairo,
    this.source = PuzzleSource.catalog,
    this.difficulty,
    this.boardSize,
    this.completionCount = 1,
    int? totalElapsedSeconds,
  }) : totalElapsedSeconds =
            totalElapsedSeconds ?? bestSeconds * completionCount;

  final String puzzleId;
  final int bestSeconds;
  final DateTime completedAt;
  final GameType gameType;
  final PuzzleSource source;
  final PuzzleDifficulty? difficulty;
  final int? boardSize;
  final int completionCount;
  final int totalElapsedSeconds;

  PuzzleSource get effectiveSource {
    if (source != PuzzleSource.catalog) return source;
    return puzzleId.startsWith('binary-')
        ? PuzzleSource.generated
        : PuzzleSource.catalog;
  }

  int? get effectiveBoardSize {
    if (boardSize != null) return boardSize;
    final parts = puzzleId.split('-');
    if (parts.length >= 4 && parts.first == 'binary') {
      return int.tryParse(parts[1]);
    }
    return null;
  }

  PuzzleDifficulty? get effectiveDifficulty {
    if (difficulty != null) return difficulty;
    final parts = puzzleId.split('-');
    if (parts.length >= 4 && parts.first == 'binary') {
      return PuzzleDifficulty.values.firstWhere(
        (value) => value.name == parts[2],
        orElse: () => PuzzleDifficulty.easy,
      );
    }
    return null;
  }

  Map<String, Object?> toJson() => {
        'puzzleId': puzzleId,
        'bestSeconds': bestSeconds,
        'completedAt': completedAt.toIso8601String(),
        'gameType': gameType.name,
        'source': source.name,
        if (difficulty != null) 'difficulty': difficulty!.name,
        if (boardSize != null) 'boardSize': boardSize,
        'completionCount': completionCount,
        'totalElapsedSeconds': totalElapsedSeconds,
      };

  factory PuzzleResult.fromJson(Map<String, Object?> json) {
    final sourceName = json['source'] as String?;
    final gameTypeName = json['gameType'] as String?;
    final difficultyName = json['difficulty'] as String?;
    final rawBoardSize = json['boardSize'];
    final rawCompletionCount = json['completionCount'];
    final rawTotalElapsedSeconds = json['totalElapsedSeconds'];

    return PuzzleResult(
      puzzleId: json['puzzleId'] as String,
      bestSeconds: json['bestSeconds'] as int,
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? '') ??
          DateTime.now(),
      gameType: GameType.values.firstWhere(
        (value) => value.name == gameTypeName,
        orElse: () => GameType.binairo,
      ),
      source: PuzzleSource.values.firstWhere(
        (value) => value.name == sourceName,
        orElse: () => PuzzleSource.catalog,
      ),
      difficulty: difficultyName == null
          ? null
          : PuzzleDifficulty.values.firstWhere(
              (value) => value.name == difficultyName,
              orElse: () => PuzzleDifficulty.easy,
            ),
      boardSize: rawBoardSize is num ? rawBoardSize.toInt() : null,
      completionCount:
          rawCompletionCount is num && rawCompletionCount.toInt() > 0
              ? rawCompletionCount.toInt()
              : 1,
      totalElapsedSeconds:
          rawTotalElapsedSeconds is num && rawTotalElapsedSeconds.toInt() >= 0
              ? rawTotalElapsedSeconds.toInt()
              : null,
    );
  }

  PuzzleResult recordAnotherCompletion({
    required int elapsedSeconds,
    required DateTime completedAt,
    required PuzzleSource source,
    required PuzzleDifficulty difficulty,
    required int boardSize,
  }) {
    return PuzzleResult(
      puzzleId: puzzleId,
      bestSeconds: elapsedSeconds < bestSeconds ? elapsedSeconds : bestSeconds,
      completedAt: completedAt,
      gameType: gameType,
      source: source,
      difficulty: difficulty,
      boardSize: boardSize,
      completionCount: completionCount + 1,
      totalElapsedSeconds: totalElapsedSeconds + elapsedSeconds,
    );
  }
}

class PlayerProgress {
  const PlayerProgress({
    required this.totalCompleted,
    required this.totalPlaySeconds,
    required this.completedDays,
  });

  const PlayerProgress.empty()
      : totalCompleted = 0,
        totalPlaySeconds = 0,
        completedDays = const <String>[];

  final int totalCompleted;
  final int totalPlaySeconds;
  final List<String> completedDays;

  bool get completedToday => completedDays.contains(_dayKey(DateTime.now()));

  int get currentStreak {
    final days = _parsedDays;
    if (days.isEmpty) return 0;
    final today = _dateOnly(DateTime.now());
    final latest = days.last;
    if (today.difference(latest).inDays > 1) return 0;

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

  int get bestStreak {
    final days = _parsedDays;
    if (days.isEmpty) return 0;
    var best = 1;
    var current = 1;
    for (var index = 1; index < days.length; index++) {
      if (days[index].difference(days[index - 1]).inDays == 1) {
        current++;
        if (current > best) best = current;
      } else {
        current = 1;
      }
    }
    return best;
  }

  List<DateTime> get _parsedDays {
    final values = completedDays
        .map(DateTime.tryParse)
        .whereType<DateTime>()
        .map(_dateOnly)
        .toSet()
        .toList()
      ..sort();
    return values;
  }

  PlayerProgress recordCompletion({
    required int elapsedSeconds,
    required DateTime completedAt,
  }) {
    final days = {...completedDays, _dayKey(completedAt)}.toList()..sort();
    return PlayerProgress(
      totalCompleted: totalCompleted + 1,
      totalPlaySeconds: totalPlaySeconds + elapsedSeconds,
      completedDays: days,
    );
  }

  Map<String, Object?> toJson() => {
        'totalCompleted': totalCompleted,
        'totalPlaySeconds': totalPlaySeconds,
        'completedDays': completedDays,
      };

  factory PlayerProgress.fromJson(Map<String, Object?> json) {
    final rawDays = json['completedDays'];
    return PlayerProgress(
      totalCompleted: (json['totalCompleted'] as num?)?.toInt() ?? 0,
      totalPlaySeconds: (json['totalPlaySeconds'] as num?)?.toInt() ?? 0,
      completedDays: rawDays is List
          ? (rawDays.whereType<String>().toSet().toList()..sort())
          : const <String>[],
    );
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String _dayKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

class GameStorage {
  static const _activeGameKey = 'active_binary_game_v1';
  static const _resultsKey = 'binary_results_v1';
  static const _playerProgressKey = 'player_progress_v1';

  Future<SavedGame?> loadActiveGame() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_activeGameKey);
    if (raw == null) return null;

    try {
      return SavedGame.fromJson(
        Map<String, Object?>.from(jsonDecode(raw) as Map),
      );
    } on Object {
      await preferences.remove(_activeGameKey);
      return null;
    }
  }

  Future<void> saveActiveGame(SavedGame game) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_activeGameKey, jsonEncode(game.toJson()));
  }

  Future<void> clearActiveGame() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_activeGameKey);
  }

  Future<Map<String, PuzzleResult>> loadResults() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_resultsKey);
    if (raw == null) return {};

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final results = decoded
          .map((item) => PuzzleResult.fromJson(
                Map<String, Object?>.from(item as Map),
              ))
          .toList();
      return {for (final result in results) result.puzzleId: result};
    } on Object {
      return {};
    }
  }

  Future<PlayerProgress> loadPlayerProgress() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_playerProgressKey);
    if (raw != null) {
      try {
        return PlayerProgress.fromJson(
          Map<String, Object?>.from(jsonDecode(raw) as Map),
        );
      } on Object {
        // Fall through to a safe migration from the existing result data.
      }
    }

    final results = await loadResults();
    if (results.isEmpty) return const PlayerProgress.empty();
    final migrated = PlayerProgress(
      totalCompleted: results.values.fold<int>(
        0,
        (sum, result) => sum + result.completionCount,
      ),
      totalPlaySeconds: results.values.fold<int>(
        0,
        (sum, result) => sum + result.totalElapsedSeconds,
      ),
      completedDays: results.values
          .map((result) => PlayerProgress._dayKey(result.completedAt))
          .toSet()
          .toList()
        ..sort(),
    );
    await preferences.setString(
      _playerProgressKey,
      jsonEncode(migrated.toJson()),
    );
    return migrated;
  }

  Future<void> recordCompletion({
    required String puzzleId,
    required int elapsedSeconds,
    required PuzzleSource source,
    required PuzzleDifficulty difficulty,
    required int boardSize,
    DateTime? completedAt,
  }) async {
    final results = await loadResults();
    final progress = await loadPlayerProgress();
    final existing = results[puzzleId];
    final completionTime = completedAt ?? DateTime.now();

    results[puzzleId] = existing == null
        ? PuzzleResult(
            puzzleId: puzzleId,
            bestSeconds: elapsedSeconds,
            completedAt: completionTime,
            source: source,
            difficulty: difficulty,
            boardSize: boardSize,
          )
        : existing.recordAnotherCompletion(
            elapsedSeconds: elapsedSeconds,
            completedAt: completionTime,
            source: source,
            difficulty: difficulty,
            boardSize: boardSize,
          );

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _resultsKey,
      jsonEncode(results.values.map((result) => result.toJson()).toList()),
    );

    final updatedProgress = progress.recordCompletion(
      elapsedSeconds: elapsedSeconds,
      completedAt: completionTime,
    );
    await preferences.setString(
      _playerProgressKey,
      jsonEncode(updatedProgress.toJson()),
    );
  }

  Future<void> clearAllProgress() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_activeGameKey);
    await preferences.remove(_resultsKey);
    await preferences.remove(_playerProgressKey);
  }
}
