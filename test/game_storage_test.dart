import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/game_logic.dart';
import 'package:project_logic_prototype/game_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('celebrated level defaults to one and survives storage', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = GameStorage();

    expect(await storage.loadCelebratedLevel(), 1);

    await storage.saveCelebratedLevel(4);

    expect(await storage.loadCelebratedLevel(), 4);
  });

  test('clearing progress resets the celebrated level', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = GameStorage();
    await storage.saveCelebratedLevel(3);

    await storage.clearAllProgress();

    expect(await storage.loadCelebratedLevel(), 1);
  });

  test('SavedGame survives JSON conversion', () {
    final original = SavedGame(
      puzzleId: 'easy-01',
      elapsedSeconds: 42,
      values: const [0, 1, null],
      savedAt: DateTime(2026, 7, 29, 12, 0),
    );

    final restored = SavedGame.fromJson(original.toJson());

    expect(restored.puzzleId, original.puzzleId);
    expect(restored.elapsedSeconds, 42);
    expect(restored.values, const [0, 1, null]);
    expect(restored.savedAt, original.savedAt);
    expect(restored.definition, isNull);
    expect(restored.isGenerated, isFalse);
  });

  test('generated SavedGame preserves its complete puzzle definition', () {
    final definition = BinaryPuzzleDefinition(
      id: 'binary-4-medium-1234',
      number: 1,
      difficulty: PuzzleDifficulty.medium,
      solution: const [
        [CellValue.zero, CellValue.zero, CellValue.one, CellValue.one],
        [CellValue.zero, CellValue.one, CellValue.zero, CellValue.one],
        [CellValue.one, CellValue.zero, CellValue.one, CellValue.zero],
        [CellValue.one, CellValue.one, CellValue.zero, CellValue.zero],
      ],
      clues: {
        const CellPosition(0, 0),
        const CellPosition(1, 1),
        const CellPosition(2, 2),
        const CellPosition(3, 3),
      },
    );
    final original = SavedGame(
      puzzleId: definition.id,
      elapsedSeconds: 19,
      values: const [0, null, 1, null, 0, 1, null, null, 1, 0, null, 1],
      savedAt: DateTime(2026, 7, 30, 14, 30),
      definition: definition,
      titleOverride: 'Mittel · Generiert 4 × 4',
    );

    final restored = SavedGame.fromJson(original.toJson());

    expect(restored.isGenerated, isTrue);
    expect(restored.titleOverride, 'Mittel · Generiert 4 × 4');
    expect(restored.definition!.id, definition.id);
    expect(restored.definition!.difficulty, PuzzleDifficulty.medium);
    expect(restored.definition!.solution, definition.solution);
    expect(restored.definition!.clues, definition.clues);
    expect(restored.values, original.values);
  });

  test('PuzzleResult survives JSON conversion', () {
    final original = PuzzleResult(
      puzzleId: 'hard-03',
      bestSeconds: 125,
      completedAt: DateTime(2026, 7, 29, 12, 30),
    );

    final restored = PuzzleResult.fromJson(original.toJson());

    expect(restored.puzzleId, 'hard-03');
    expect(restored.bestSeconds, 125);
    expect(restored.completedAt, original.completedAt);
  });

  test('PuzzleResult preserves its game identity', () {
    final original = PuzzleResult(
      puzzleId: 'hashi-easy-01',
      bestSeconds: 42,
      completedAt: DateTime(2026, 7, 31),
      gameType: GameType.hashi,
      source: GameMode.catalog,
      difficulty: PuzzleDifficulty.easy,
      boardSize: 7,
    );

    final restored = PuzzleResult.fromJson(original.toJson());

    expect(restored.gameType, GameType.hashi);
    expect(restored.source, GameMode.catalog);
  });

  test('legacy PuzzleResult defaults to Binairo', () {
    final restored = PuzzleResult.fromJson({
      'puzzleId': 'easy-01',
      'bestSeconds': 42,
      'completedAt': '2026-07-31T00:00:00.000',
    });

    expect(restored.gameType, GameType.binairo);
  });

  test('SavedGame writes the current schema version', () {
    final game = SavedGame(
      puzzleId: 'easy-01',
      elapsedSeconds: 0,
      values: const [null],
      savedAt: DateTime(2026, 7, 30),
    );

    expect(game.toJson()['schemaVersion'], SavedGame.currentSchemaVersion);
  });

  test('legacy SavedGame without schema version remains readable', () {
    final restored = SavedGame.fromJson({
      'puzzleId': 'easy-01',
      'elapsedSeconds': 7,
      'values': [null, 0, 1],
      'savedAt': '2026-07-30T12:00:00.000',
    });

    expect(restored.puzzleId, 'easy-01');
    expect(restored.elapsedSeconds, 7);
    expect(restored.values, [null, 0, 1]);
  });

  test('SavedGame rejects unsupported future schemas', () {
    expect(
      () => SavedGame.fromJson({
        'schemaVersion': SavedGame.currentSchemaVersion + 1,
        'puzzleId': 'easy-01',
        'elapsedSeconds': 0,
        'values': <int?>[],
      }),
      throwsFormatException,
    );
  });

  test('SavedGame rejects invalid cell values', () {
    expect(
      () => SavedGame.fromJson({
        'puzzleId': 'easy-01',
        'elapsedSeconds': 0,
        'values': [0, 2, null],
      }),
      throwsFormatException,
    );
  });

  test('generated SavedGame rejects mismatching editable values', () {
    final definition = BinaryPuzzleDefinition(
      id: 'binary-4-easy-test',
      number: 1,
      difficulty: PuzzleDifficulty.easy,
      solution: const [
        [CellValue.zero, CellValue.zero, CellValue.one, CellValue.one],
        [CellValue.zero, CellValue.one, CellValue.zero, CellValue.one],
        [CellValue.one, CellValue.zero, CellValue.one, CellValue.zero],
        [CellValue.one, CellValue.one, CellValue.zero, CellValue.zero],
      ],
      clues: {
        const CellPosition(0, 0),
        const CellPosition(1, 1),
      },
    );
    final json = SavedGame(
      puzzleId: definition.id,
      elapsedSeconds: 0,
      values: List<int?>.filled(14, null),
      savedAt: DateTime(2026, 7, 30),
      definition: definition,
    ).toJson();
    json['values'] = [null];

    expect(() => SavedGame.fromJson(json), throwsFormatException);
  });

  // v0.6.7 player-progress metadata regression tests.
  test('PuzzleResult preserves progress metadata and completion count', () {
    final original = PuzzleResult(
      puzzleId: 'binary-8-hard-42',
      bestSeconds: 180,
      completedAt: DateTime(2026, 7, 30, 16, 0),
      source: PuzzleSource.generated,
      difficulty: PuzzleDifficulty.hard,
      boardSize: 8,
      completionCount: 3,
    );

    final restored = PuzzleResult.fromJson(original.toJson());

    expect(restored.source, PuzzleSource.generated);
    expect(restored.difficulty, PuzzleDifficulty.hard);
    expect(restored.boardSize, 8);
    expect(restored.completionCount, 3);
  });

  test('legacy generated result infers size and difficulty from puzzle id', () {
    final restored = PuzzleResult.fromJson({
      'puzzleId': 'binary-6-medium-12345',
      'bestSeconds': 90,
      'completedAt': '2026-07-30T16:00:00.000',
    });

    expect(restored.effectiveSource, PuzzleSource.generated);
    expect(restored.effectiveBoardSize, 6);
    expect(restored.effectiveDifficulty, PuzzleDifficulty.medium);
    expect(restored.completionCount, 1);
  });

  test('recordAnotherCompletion keeps best time and increments count', () {
    final original = PuzzleResult(
      puzzleId: 'easy-01',
      bestSeconds: 100,
      completedAt: DateTime(2026, 7, 30, 16, 0),
      difficulty: PuzzleDifficulty.easy,
      boardSize: 6,
    );

    final updated = original.recordAnotherCompletion(
      elapsedSeconds: 120,
      completedAt: DateTime(2026, 7, 30, 17, 0),
      source: PuzzleSource.catalog,
      difficulty: PuzzleDifficulty.easy,
      boardSize: 6,
    );

    expect(updated.bestSeconds, 100);
    expect(updated.completionCount, 2);
    expect(updated.completedAt, DateTime(2026, 7, 30, 17, 0));
  });

  test('PlayerProgress counts one streak day for multiple completions', () {
    final today = DateTime.now();
    final progress = const PlayerProgress.empty()
        .recordCompletion(elapsedSeconds: 40, completedAt: today)
        .recordCompletion(elapsedSeconds: 70, completedAt: today);

    expect(progress.totalCompleted, 2);
    expect(progress.totalPlaySeconds, 110);
    expect(progress.completedDays, hasLength(1));
    expect(progress.currentStreak, 1);
    expect(progress.bestStreak, 1);
    expect(progress.completedToday, isTrue);
  });

  test('PlayerProgress calculates current and best consecutive streaks', () {
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    final progress = PlayerProgress(
      totalCompleted: 5,
      totalPlaySeconds: 300,
      completedDays: [
        day
            .subtract(const Duration(days: 6))
            .toIso8601String()
            .substring(0, 10),
        day
            .subtract(const Duration(days: 5))
            .toIso8601String()
            .substring(0, 10),
        day
            .subtract(const Duration(days: 2))
            .toIso8601String()
            .substring(0, 10),
        day
            .subtract(const Duration(days: 1))
            .toIso8601String()
            .substring(0, 10),
        day.toIso8601String().substring(0, 10),
      ],
    );

    expect(progress.currentStreak, 3);
    expect(progress.bestStreak, 3);
  });

  test('recordCompletion updates results, playtime and streak only once',
      () async {
    SharedPreferences.setMockInitialValues({});
    final storage = GameStorage();
    final today = DateTime.now();

    await storage.recordCompletion(
      puzzleId: 'easy-01',
      elapsedSeconds: 45,
      source: PuzzleSource.catalog,
      difficulty: PuzzleDifficulty.easy,
      boardSize: 4,
      completedAt: today,
    );
    await storage.recordCompletion(
      puzzleId: 'easy-01',
      elapsedSeconds: 60,
      source: PuzzleSource.catalog,
      difficulty: PuzzleDifficulty.easy,
      boardSize: 4,
      completedAt: today,
    );

    final results = await storage.loadResults();
    final progress = await storage.loadPlayerProgress();
    expect(results['easy-01']!.completionCount, 2);
    expect(results['easy-01']!.bestSeconds, 45);
    expect(results['easy-01']!.totalElapsedSeconds, 105);
    expect(progress.totalCompleted, 2);
    expect(progress.totalPlaySeconds, 105);
    expect(progress.completedDays, hasLength(1));
  });

  test('results from different games cannot overwrite each other', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = GameStorage();

    await storage.recordCompletion(
      puzzleId: 'easy-01',
      elapsedSeconds: 60,
      source: GameMode.catalog,
      difficulty: PuzzleDifficulty.easy,
      boardSize: 6,
    );
    await storage.recordCompletion(
      puzzleId: 'easy-01',
      elapsedSeconds: 90,
      gameType: GameType.hashi,
      source: GameMode.catalog,
      difficulty: PuzzleDifficulty.easy,
      boardSize: 7,
    );

    final results = await storage.loadResults();

    expect(results, hasLength(2));
    expect(results['easy-01']?.gameType, GameType.binairo);
    expect(results['hashi:easy-01']?.gameType, GameType.hashi);
  });

  test('recordCompletion appends detailed attempt history', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = GameStorage();

    await storage.recordCompletion(
      puzzleId: 'hashi_01',
      elapsedSeconds: 90,
      gameType: GameType.hashi,
      source: GameMode.catalog,
      difficulty: PuzzleDifficulty.easy,
      boardSize: 7,
      moves: 8,
      hintsUsed: 1,
      rewardedHints: 1,
      completedAt: DateTime(2026, 7, 31, 20),
    );

    final attempts = await storage.loadAttempts();

    expect(attempts, hasLength(1));
    expect(attempts.single.gameType, GameType.hashi);
    expect(attempts.single.moves, 8);
    expect(attempts.single.hintsUsed, 1);
    expect(attempts.single.rewardedHints, 1);
  });

  // v0.6.9 daily challenge persistence regression tests.
  test('daily SavedGame preserves its puzzle source', () {
    final definition = BinaryPuzzleDefinition(
      id: 'daily-binary-2026-07-30',
      number: 1,
      difficulty: PuzzleDifficulty.medium,
      solution: const [
        [CellValue.zero, CellValue.zero, CellValue.one, CellValue.one],
        [CellValue.zero, CellValue.one, CellValue.zero, CellValue.one],
        [CellValue.one, CellValue.zero, CellValue.one, CellValue.zero],
        [CellValue.one, CellValue.one, CellValue.zero, CellValue.zero],
      ],
      clues: {
        const CellPosition(0, 0),
        const CellPosition(1, 1),
        const CellPosition(2, 2),
        const CellPosition(3, 3),
      },
    );
    final game = SavedGame(
      puzzleId: definition.id,
      elapsedSeconds: 12,
      values: List<int?>.filled(12, null),
      savedAt: DateTime(2026, 7, 30),
      definition: definition,
      source: PuzzleSource.daily,
    );

    final restored = SavedGame.fromJson(game.toJson());

    expect(restored.source, PuzzleSource.daily);
    expect(restored.definition?.id, definition.id);
  });

  test('explicit daily result is not classified as generated', () {
    final result = PuzzleResult(
      puzzleId: 'daily-binary-2026-07-30',
      bestSeconds: 90,
      completedAt: DateTime(2026, 7, 30),
      source: PuzzleSource.daily,
      difficulty: PuzzleDifficulty.medium,
      boardSize: 6,
    );

    expect(result.effectiveSource, PuzzleSource.daily);
  });

  test('daily completion keeps an immutable versioned board snapshot',
      () async {
    SharedPreferences.setMockInitialValues({});
    final storage = GameStorage();
    final completedAt = DateTime(2026, 8, 2, 12, 30);

    await storage.recordCompletion(
      puzzleId: 'daily-hitori-2026-08-02',
      elapsedSeconds: 95,
      gameType: GameType.hitori,
      source: PuzzleSource.daily,
      difficulty: PuzzleDifficulty.hard,
      boardSize: 7,
      completedAt: completedAt,
      dailyPuzzleData: const {
        'kind': 'hitori',
        'grid': [
          [1, 2],
          [2, 1],
        ],
        'shaded': [
          [0, 0],
        ],
      },
    );

    final snapshots = await storage.loadDailySnapshots();
    final snapshot = snapshots['hitori:daily-hitori-2026-08-02'];
    expect(snapshot, isNotNull);
    expect(snapshot!.completedAt, completedAt);
    expect(snapshot.elapsedSeconds, 95);
    expect(snapshot.puzzleData['kind'], 'hitori');
    expect(snapshot.puzzleData['grid'], isNotEmpty);
  });

  test('ordinary completions do not create daily snapshots', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = GameStorage();
    await storage.recordCompletion(
      puzzleId: 'catalog-1',
      elapsedSeconds: 30,
      source: PuzzleSource.catalog,
      difficulty: PuzzleDifficulty.easy,
      boardSize: 4,
      dailyPuzzleData: const {'should': 'be ignored'},
    );
    expect(await storage.loadDailySnapshots(), isEmpty);
  });

  test('completion XP is stored as an append-only event', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = GameStorage();
    await storage.recordCompletion(
      puzzleId: 'one',
      elapsedSeconds: 30,
      source: PuzzleSource.catalog,
      difficulty: PuzzleDifficulty.easy,
      boardSize: 4,
      completedAt: DateTime(2026, 8, 2),
    );
    final events = await storage.loadExperienceEvents();
    expect(events, hasLength(1));
    expect(events.values.single.points, 30);
  });

  test('completion XP distinguishes new puzzles, repeats and daily puzzles',
      () async {
    SharedPreferences.setMockInitialValues({});
    final storage = GameStorage();

    final firstCatalog = await storage.recordCompletion(
      puzzleId: 'catalog-easy',
      elapsedSeconds: 30,
      source: PuzzleSource.catalog,
      difficulty: PuzzleDifficulty.easy,
      boardSize: 4,
      hintsUsed: 0,
      completedAt: DateTime(2026, 8, 2, 10),
    );
    final repeatedCatalog = await storage.recordCompletion(
      puzzleId: 'catalog-easy',
      elapsedSeconds: 25,
      source: PuzzleSource.catalog,
      difficulty: PuzzleDifficulty.easy,
      boardSize: 4,
      hintsUsed: 0,
      completedAt: DateTime(2026, 8, 2, 10, 5),
    );
    final firstDaily = await storage.recordCompletion(
      puzzleId: 'daily-hard',
      elapsedSeconds: 90,
      source: PuzzleSource.daily,
      difficulty: PuzzleDifficulty.hard,
      boardSize: 6,
      hintsUsed: 0,
      completedAt: DateTime(2026, 8, 2, 11),
    );
    final repeatedDaily = await storage.recordCompletion(
      puzzleId: 'daily-hard',
      elapsedSeconds: 80,
      source: PuzzleSource.daily,
      difficulty: PuzzleDifficulty.hard,
      boardSize: 6,
      hintsUsed: 0,
      completedAt: DateTime(2026, 8, 2, 11, 5),
    );

    expect(firstCatalog, 30);
    expect(repeatedCatalog, 5);
    expect(firstDaily, 70);
    expect(repeatedDaily, 0);
    final events = (await storage.loadExperienceEvents()).values.toList()
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    expect(events.map((event) => event.points), [30, 5, 70, 0]);
  });

  test('XP ledger salvages valid entries and rebuilds damaged completions',
      () async {
    SharedPreferences.setMockInitialValues({});
    final storage = GameStorage();
    await storage.recordCompletion(
      puzzleId: 'first',
      elapsedSeconds: 30,
      source: PuzzleSource.catalog,
      difficulty: PuzzleDifficulty.easy,
      boardSize: 4,
      completedAt: DateTime(2026, 8, 8, 10),
    );
    await storage.recordCompletion(
      puzzleId: 'second',
      elapsedSeconds: 40,
      source: PuzzleSource.catalog,
      difficulty: PuzzleDifficulty.medium,
      boardSize: 6,
      completedAt: DateTime(2026, 8, 8, 10, 5),
    );
    final preferences = await SharedPreferences.getInstance();
    final original = jsonDecode(
      preferences.getString('experience_events_v1')!,
    ) as List<dynamic>;
    final damaged = jsonEncode([
      original.first,
      {'broken': true}
    ]);
    await preferences.setString('experience_events_v1', damaged);

    final recovered = await storage.loadExperienceEvents();

    expect(recovered, hasLength(2));
    expect(recovered.values.map((event) => event.points).toSet(), {30, 40});
    expect(
        recovered.values.every((event) => event.referenceId != null), isTrue);
    expect(
      preferences.getString('experience_events_recovery_v1'),
      damaged,
    );
  });

  test('malformed XP ledger is rebuilt with correct repeat rewards', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = GameStorage();
    await storage.recordCompletion(
      puzzleId: 'repeat-me',
      elapsedSeconds: 30,
      source: PuzzleSource.catalog,
      difficulty: PuzzleDifficulty.easy,
      boardSize: 4,
      completedAt: DateTime(2026, 8, 8, 11),
    );
    await storage.recordCompletion(
      puzzleId: 'repeat-me',
      elapsedSeconds: 25,
      source: PuzzleSource.catalog,
      difficulty: PuzzleDifficulty.easy,
      boardSize: 4,
      completedAt: DateTime(2026, 8, 8, 11, 5),
    );
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('experience_events_v1', '{not-json');

    final recovered = (await storage.loadExperienceEvents()).values.toList()
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));

    expect(recovered.map((event) => event.points), [30, 5]);
    expect(
      preferences.getString('experience_events_recovery_v1'),
      '{not-json',
    );
  });
}
