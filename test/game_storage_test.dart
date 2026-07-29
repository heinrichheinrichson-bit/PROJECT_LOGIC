import 'package:flutter_test/flutter_test.dart';
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
