import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'game_logic.dart';

class SavedGame {
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
        'puzzleId': puzzleId,
        'elapsedSeconds': elapsedSeconds,
        'values': values,
        'savedAt': savedAt.toIso8601String(),
        if (definition != null) 'definition': _definitionToJson(definition!),
        if (titleOverride != null) 'titleOverride': titleOverride,
      };

  factory SavedGame.fromJson(Map<String, Object?> json) {
    final rawDefinition = json['definition'];
    return SavedGame(
      puzzleId: json['puzzleId'] as String,
      elapsedSeconds: json['elapsedSeconds'] as int? ?? 0,
      values: (json['values'] as List<dynamic>)
          .map((value) => value as int?)
          .toList(),
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ??
          DateTime.now(),
      definition: rawDefinition is Map
          ? _definitionFromJson(Map<String, Object?>.from(rawDefinition))
          : null,
      titleOverride: json['titleOverride'] as String?,
    );
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
    final difficultyName = json['difficulty'] as String? ?? 'easy';
    final difficulty = PuzzleDifficulty.values.firstWhere(
      (value) => value.name == difficultyName,
      orElse: () => PuzzleDifficulty.easy,
    );
    final solution = (json['solution'] as List<dynamic>)
        .map(
          (row) => (row as List<dynamic>)
              .map((value) => value == 0 ? CellValue.zero : CellValue.one)
              .toList(),
        )
        .toList();
    final clues = (json['clues'] as List<dynamic>)
        .map((item) => Map<String, Object?>.from(item as Map))
        .map(
          (item) => CellPosition(
            item['row'] as int,
            item['column'] as int,
          ),
        )
        .toSet();

    return BinaryPuzzleDefinition(
      id: json['id'] as String,
      number: json['number'] as int? ?? 1,
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
  });

  final String puzzleId;
  final int bestSeconds;
  final DateTime completedAt;

  Map<String, Object?> toJson() => {
        'puzzleId': puzzleId,
        'bestSeconds': bestSeconds,
        'completedAt': completedAt.toIso8601String(),
      };

  factory PuzzleResult.fromJson(Map<String, Object?> json) {
    return PuzzleResult(
      puzzleId: json['puzzleId'] as String,
      bestSeconds: json['bestSeconds'] as int,
      completedAt:
          DateTime.tryParse(json['completedAt'] as String? ?? '') ??
              DateTime.now(),
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
  }) async {
    final results = await loadResults();
    final existing = results[puzzleId];

    if (existing == null || elapsedSeconds < existing.bestSeconds) {
      results[puzzleId] = PuzzleResult(
        puzzleId: puzzleId,
        bestSeconds: elapsedSeconds,
        completedAt: DateTime.now(),
      );
    }

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
