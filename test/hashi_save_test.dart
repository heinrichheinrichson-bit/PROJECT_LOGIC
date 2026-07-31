import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/core/domain/game_identity.dart';
import 'package:project_logic_prototype/hashi_foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Hashi save round trip preserves generated puzzle and play state',
      () async {
    const saved = SavedHashiGame(
      puzzle: hashiTutorialPuzzle,
      mode: GameMode.generated,
      bridges: [HashiBridge(from: 0, to: 1, count: 2)],
      elapsedSeconds: 125,
      moves: 7,
      hintsUsed: 1,
      rewardedHints: 2,
    );
    final store = HashiGameStore();

    await store.save(saved);
    final restored = await store.load();

    expect(restored, isNotNull);
    expect(restored!.puzzle.id, hashiTutorialPuzzle.id);
    expect(restored.puzzle.islands.length, hashiTutorialPuzzle.islands.length);
    expect(
        restored.puzzle.solution.length, hashiTutorialPuzzle.solution.length);
    expect(restored.mode, GameMode.generated);
    expect(restored.bridges.single.count, 2);
    expect(restored.elapsedSeconds, 125);
    expect(restored.moves, 7);
    expect(restored.hintsUsed, 1);
    expect(restored.rewardedHints, 2);
  });

  test('corrupt Hashi save is removed safely', () async {
    SharedPreferences.setMockInitialValues({'active_hashi_game_v1': '{broken'});
    final store = HashiGameStore();

    expect(await store.load(), isNull);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey('active_hashi_game_v1'), isFalse);
  });
}
