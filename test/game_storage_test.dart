import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/game_logic.dart';
import 'package:project_logic_prototype/game_storage.dart';

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
}
