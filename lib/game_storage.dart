import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'core/domain/game_identity.dart';
import 'core/statistics/puzzle_attempt.dart';
import 'core/progress/experience_event.dart';
import 'core/progress/experience_points_policy.dart';
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

  /// Binairo keeps its historic unprefixed keys for UI and save compatibility.
  /// Other games use a namespaced key to avoid collisions between catalogs.
  String get storageKey =>
      gameType == GameType.binairo ? puzzleId : '${gameType.name}:$puzzleId';

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

/// Immutable, versioned copy of a completed daily puzzle.
///
/// Daily generators may evolve over the lifetime of the app. Keeping the
/// concrete puzzle data here means a solved calendar entry never silently
/// turns into a different board after an update.
class DailyPuzzleSnapshot {
  static const int currentSchemaVersion = 1;

  const DailyPuzzleSnapshot({
    required this.puzzleId,
    required this.gameType,
    required this.difficulty,
    required this.boardSize,
    required this.completedAt,
    required this.elapsedSeconds,
    required this.puzzleData,
  });

  final String puzzleId;
  final GameType gameType;
  final PuzzleDifficulty difficulty;
  final int boardSize;
  final DateTime completedAt;
  final int elapsedSeconds;
  final Map<String, Object?> puzzleData;

  String get storageKey => '${gameType.name}:$puzzleId';

  Map<String, Object?> toJson() => {
        'schemaVersion': currentSchemaVersion,
        'puzzleId': puzzleId,
        'gameType': gameType.name,
        'difficulty': difficulty.name,
        'boardSize': boardSize,
        'completedAt': completedAt.toIso8601String(),
        'elapsedSeconds': elapsedSeconds,
        'puzzleData': puzzleData,
      };

  factory DailyPuzzleSnapshot.fromJson(Map<String, Object?> json) {
    final version = (json['schemaVersion'] as num?)?.toInt() ?? 1;
    final puzzleData = json['puzzleData'];
    if (version < 1 || version > currentSchemaVersion || puzzleData is! Map) {
      throw const FormatException('Unsupported daily snapshot.');
    }
    return DailyPuzzleSnapshot(
      puzzleId: _requiredSnapshotString(json, 'puzzleId'),
      gameType: GameType.values.firstWhere(
        (value) => value.name == json['gameType'],
        orElse: () => GameType.binairo,
      ),
      difficulty: PuzzleDifficulty.values.firstWhere(
        (value) => value.name == json['difficulty'],
        orElse: () => PuzzleDifficulty.easy,
      ),
      boardSize: (json['boardSize'] as num?)?.toInt() ?? 0,
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      elapsedSeconds: (json['elapsedSeconds'] as num?)?.toInt() ?? 0,
      puzzleData: Map<String, Object?>.from(puzzleData),
    );
  }

  static String _requiredSnapshotString(
    Map<String, Object?> json,
    String key,
  ) {
    final value = json[key];
    if (value is String && value.isNotEmpty) return value;
    throw FormatException('Missing $key in daily snapshot.');
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
  static const _attemptsKey = 'puzzle_attempts_v1';
  static const _dailySnapshotsKey = 'daily_puzzle_snapshots_v1';
  static const _experienceEventsKey = 'experience_events_v1';
  static const _experienceEventsRecoveryKey = 'experience_events_recovery_v1';
  static const _celebratedLevelKey = 'celebrated_player_level_v1';

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
      return {for (final result in results) result.storageKey: result};
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

  Future<int> recordCompletion({
    required String puzzleId,
    required int elapsedSeconds,
    required PuzzleSource source,
    required PuzzleDifficulty difficulty,
    required int boardSize,
    GameType gameType = GameType.binairo,
    int? moves,
    int hintsUsed = 0,
    int rewardedHints = 0,
    DateTime? completedAt,
    Map<String, Object?>? dailyPuzzleData,
  }) async {
    final results = await loadResults();
    final progress = await loadPlayerProgress();
    final resultKey =
        gameType == GameType.binairo ? puzzleId : '${gameType.name}:$puzzleId';
    final existing = results[resultKey];
    final completionTime = completedAt ?? DateTime.now();

    results[resultKey] = existing == null
        ? PuzzleResult(
            puzzleId: puzzleId,
            bestSeconds: elapsedSeconds,
            completedAt: completionTime,
            gameType: gameType,
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

    final attempts = await loadAttempts();
    final attemptId =
        '${completionTime.microsecondsSinceEpoch}-${gameType.name}-$puzzleId';
    attempts.add(PuzzleAttempt(
      id: attemptId,
      gameType: gameType,
      puzzleId: puzzleId,
      mode: source,
      difficulty: difficulty,
      boardSize: boardSize,
      startedAt: completionTime.subtract(Duration(seconds: elapsedSeconds)),
      completedAt: completionTime,
      elapsedSeconds: elapsedSeconds,
      moves: moves,
      hintsUsed: hintsUsed,
      rewardedHints: rewardedHints,
    ));
    await preferences.setString(
      _attemptsKey,
      jsonEncode(attempts.map((attempt) => attempt.toJson()).toList()),
    );

    final experienceEvents = await loadExperienceEvents();
    final completionXp = ExperiencePointsPolicy.puzzleCompletion(
      source: source,
      difficulty: difficulty,
      hintsUsed: hintsUsed,
      repeated: existing != null,
    );
    experienceEvents.putIfAbsent(
      'completion:$attemptId',
      () => ExperienceEvent(
        id: 'completion:$attemptId',
        kind: ExperienceEventKind.puzzleCompleted,
        points: completionXp,
        occurredAt: completionTime,
        referenceId: attemptId,
      ),
    );
    await saveExperienceEvents(experienceEvents.values);

    if (source == PuzzleSource.daily && dailyPuzzleData != null) {
      final snapshots = await loadDailySnapshots();
      final snapshot = DailyPuzzleSnapshot(
        puzzleId: puzzleId,
        gameType: gameType,
        difficulty: difficulty,
        boardSize: boardSize,
        completedAt: completionTime,
        elapsedSeconds: elapsedSeconds,
        puzzleData: dailyPuzzleData,
      );
      snapshots[snapshot.storageKey] = snapshot;
      await preferences.setString(
        _dailySnapshotsKey,
        jsonEncode(snapshots.values.map((value) => value.toJson()).toList()),
      );
    }
    return completionXp;
  }

  Future<Map<String, DailyPuzzleSnapshot>> loadDailySnapshots() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_dailySnapshotsKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      final snapshots = decoded.map(
        (item) => DailyPuzzleSnapshot.fromJson(
          Map<String, Object?>.from(item as Map),
        ),
      );
      return {for (final snapshot in snapshots) snapshot.storageKey: snapshot};
    } on Object {
      // Do not delete the raw value. A future app version may be able to
      // recover an entry this version does not understand.
      return {};
    }
  }

  Future<void> saveDailySnapshot(DailyPuzzleSnapshot snapshot) async {
    final snapshots = await loadDailySnapshots();
    snapshots[snapshot.storageKey] = snapshot;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _dailySnapshotsKey,
      jsonEncode(snapshots.values.map((value) => value.toJson()).toList()),
    );
  }

  Future<List<PuzzleAttempt>> loadAttempts() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_attemptsKey);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => PuzzleAttempt.fromJson(
                Map<String, Object?>.from(item as Map),
              ))
          .toList();
    } on Object {
      return [];
    }
  }

  Future<Map<String, ExperienceEvent>> loadExperienceEvents() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_experienceEventsKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! List) throw const FormatException('Invalid XP ledger.');
        final events = <String, ExperienceEvent>{};
        var damagedEntries = 0;
        for (final item in decoded) {
          try {
            final event = ExperienceEvent.fromJson(
              Map<String, Object?>.from(item as Map),
            );
            events[event.id] = event;
          } on Object {
            damagedEntries += 1;
          }
        }
        if (damagedEntries == 0) return events;

        await _preserveDamagedExperienceLedger(preferences, raw);
        events.addAll(await _experienceEventsFromAttempts(events));
        await saveExperienceEvents(events.values);
        return events;
      } on Object {
        await _preserveDamagedExperienceLedger(preferences, raw);
        final recovered = await _experienceEventsFromAttempts(const {});
        if (recovered.isNotEmpty) {
          await saveExperienceEvents(recovered.values);
        }
        return recovered;
      }
    }

    // One-time migration for installations that predate the XP ledger.
    final migrated = await _experienceEventsFromAttempts(const {});
    if (migrated.isNotEmpty) await saveExperienceEvents(migrated.values);
    return migrated;
  }

  Future<void> _preserveDamagedExperienceLedger(
    SharedPreferences preferences,
    String raw,
  ) async {
    if (!preferences.containsKey(_experienceEventsRecoveryKey)) {
      await preferences.setString(_experienceEventsRecoveryKey, raw);
    }
  }

  Future<Map<String, ExperienceEvent>> _experienceEventsFromAttempts(
    Map<String, ExperienceEvent> existing,
  ) async {
    final attempts = await loadAttempts()
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
    final seenPuzzles = <String>{};
    final recovered = <String, ExperienceEvent>{};
    for (final attempt in attempts) {
      final eventId = 'completion:${attempt.id}';
      final puzzleKey = '${attempt.gameType.name}:${attempt.mode.name}:'
          '${attempt.puzzleId}';
      final repeated = !seenPuzzles.add(puzzleKey);
      if (existing.containsKey(eventId)) continue;
      recovered[eventId] = ExperienceEvent(
        id: eventId,
        kind: ExperienceEventKind.puzzleCompleted,
        points: ExperiencePointsPolicy.puzzleCompletion(
          source: attempt.mode,
          difficulty: attempt.difficulty,
          hintsUsed: attempt.hintsUsed,
          repeated: repeated,
        ),
        occurredAt: attempt.completedAt,
        referenceId: attempt.id,
      );
    }
    return recovered;
  }

  Future<void> saveExperienceEvents(Iterable<ExperienceEvent> events) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _experienceEventsKey,
      jsonEncode(events.map((event) => event.toJson()).toList()),
    );
  }

  Future<int> loadCelebratedLevel() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getInt(_celebratedLevelKey) ?? 1;
  }

  Future<void> saveCelebratedLevel(int level) async {
    if (level < 1) throw ArgumentError.value(level, 'level');
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_celebratedLevelKey, level);
  }

  Future<void> clearAllProgress() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_activeGameKey);
    await preferences.remove(_resultsKey);
    await preferences.remove(_playerProgressKey);
    await preferences.remove(_attemptsKey);
    await preferences.remove(_dailySnapshotsKey);
    await preferences.remove(_experienceEventsKey);
    await preferences.remove(_experienceEventsRecoveryKey);
    await preferences.remove(_celebratedLevelKey);
  }
}
