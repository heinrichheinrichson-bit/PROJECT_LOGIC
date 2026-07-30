import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'game_logic.dart';

class SavedGame {
  static const int currentSchemaVersion = 2;

  const SavedGame({
    required this.puzzleId,
    required this.elapsedSeconds,
    required this.values,
    required this.savedAt,
    this.definition,
    this.titleOverride,
  });

  final String puzzleId;
  final int elapsedSeconds;
  final List<int?> values;
  final DateTime savedAt;

  /// Present for generated puzzles so they can be restored without relying on
  /// the static catalog.
  final BinaryPuzzleDefinition? definition;
  final String? titleOverride;

  bool get isGenerated => definition != null;

  Map<String, Object?> toJson() => {
        'schemaVersion': currentSchemaVersion,
        'puzzleId': puzzleId,
        'elapsedSeconds': elapsedSeconds,
        'values': values,
        'savedAt': savedAt.toIso8601String(),
        if (definition != null) 'definition': _definitionToJson(definition!),
        if (titleOverride != null) 'titleOverride': titleOverride,
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
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ??
          DateTime.now(),
      definition: definition,
      titleOverride: rawTitle as String?,
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

enum PuzzleSource {
  catalog,
  generated,
  daily,
  event,
  tutorial,
}

class PuzzleResult {
  const PuzzleResult({
    required this.puzzleId,
    required this.bestSeconds,
    required this.completedAt,
    this.source = PuzzleSource.catalog,
    this.difficulty,
    this.boardSize,
    this.completionCount = 1,
  });

  final String puzzleId;
  final int bestSeconds;
  final DateTime completedAt;
  final PuzzleSource source;
  final PuzzleDifficulty? difficulty;
  final int? boardSize;
  final int completionCount;

  PuzzleSource get effectiveSource =>
      puzzleId.startsWith('binary-') ? PuzzleSource.generated : source;

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
        'source': source.name,
        if (difficulty != null) 'difficulty': difficulty!.name,
        if (boardSize != null) 'boardSize': boardSize,
        'completionCount': completionCount,
      };

  factory PuzzleResult.fromJson(Map<String, Object?> json) {
    final sourceName = json['source'] as String?;
    final difficultyName = json['difficulty'] as String?;
    final rawBoardSize = json['boardSize'];
    final rawCompletionCount = json['completionCount'];

    return PuzzleResult(
      puzzleId: json['puzzleId'] as String,
      bestSeconds: json['bestSeconds'] as int,
      completedAt:
          DateTime.tryParse(json['completedAt'] as String? ?? '') ??
              DateTime.now(),
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
      bestSeconds:
          elapsedSeconds < bestSeconds ? elapsedSeconds : bestSeconds,
      completedAt: completedAt,
      source: source,
      difficulty: difficulty,
      boardSize: boardSize,
      completionCount: completionCount + 1,
    );
  }
}

class GameStorage {
  static const _activeGameKey = 'active_binary_game_v1';
  static const _resultsKey = 'binary_results_v1';

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

  Future<void> recordCompletion({
    required String puzzleId,
    required int elapsedSeconds,
    required PuzzleSource source,
    required PuzzleDifficulty difficulty,
    required int boardSize,
  }) async {
    final results = await loadResults();
    final existing = results[puzzleId];
    final completedAt = DateTime.now();

    results[puzzleId] = existing == null
        ? PuzzleResult(
            puzzleId: puzzleId,
            bestSeconds: elapsedSeconds,
            completedAt: completedAt,
            source: source,
            difficulty: difficulty,
            boardSize: boardSize,
          )
        : existing.recordAnotherCompletion(
            elapsedSeconds: elapsedSeconds,
            completedAt: completedAt,
            source: source,
            difficulty: difficulty,
            boardSize: boardSize,
          );

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _resultsKey,
      jsonEncode(results.values.map((result) => result.toJson()).toList()),
    );
  }

  Future<void> clearAllProgress() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_activeGameKey);
    await preferences.remove(_resultsKey);
  }
}
