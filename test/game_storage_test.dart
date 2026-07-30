import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/game_logic.dart';
import 'package:project_logic_prototype/game_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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
        day.subtract(const Duration(days: 6)).toIso8601String().substring(0, 10),
        day.subtract(const Duration(days: 5)).toIso8601String().substring(0, 10),
        day.subtract(const Duration(days: 2)).toIso8601String().substring(0, 10),
        day.subtract(const Duration(days: 1)).toIso8601String().substring(0, 10),
        day.toIso8601String().substring(0, 10),
      ],
    );

    expect(progress.currentStreak, 3);
    expect(progress.bestStreak, 3);
  });

  test('recordCompletion updates results, playtime and streak only once', () async {
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

}
