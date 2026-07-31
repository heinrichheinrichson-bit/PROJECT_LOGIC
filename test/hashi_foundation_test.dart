import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/hashi_foundation.dart';

void main() {
  test('tutorial puzzle starts empty', () {
    final game = HashiGameState(puzzle: hashiTutorialPuzzle);

    expect(game.bridges, isEmpty);
    expect(game.isSolved, isFalse);
  });

  test('connection cycles from none to one, two and none', () {
    var game = HashiGameState(puzzle: hashiTutorialPuzzle);

    game = game.cycleConnection(0, 1);
    expect(game.bridgeCountBetween(0, 1), 1);

    game = game.cycleConnection(0, 1);
    expect(game.bridgeCountBetween(0, 1), 2);

    game = game.cycleConnection(0, 1);
    expect(game.bridgeCountBetween(0, 1), 0);
  });

  test('an existing bridge can be removed directly', () {
    var game = HashiGameState(puzzle: hashiTutorialPuzzle);
    game = game.cycleConnection(0, 1);
    game = game.cycleConnection(0, 1);

    final updated = game.removeConnection(0, 1);

    expect(game.bridgeCountBetween(0, 1), 2);
    expect(updated.bridgeCountBetween(0, 1), 0);
  });

  test('removing a missing bridge leaves state unchanged', () {
    final game = HashiGameState(puzzle: hashiTutorialPuzzle);

    expect(identical(game.removeConnection(0, 1), game), isTrue);
  });

  test('islands cannot connect through another island', () {
    final game = HashiGameState(puzzle: hashiTutorialPuzzle);

    expect(game.canConnect(2, 4), isFalse);
    expect(game.canConnect(2, 3), isTrue);
  });

  test('crossing bridges are rejected', () {
    const puzzle = HashiPuzzle(
      title: 'Kreuzung',
      size: 5,
      islands: [
        HashiIsland(row: 2, column: 0, bridges: 1),
        HashiIsland(row: 2, column: 4, bridges: 1),
        HashiIsland(row: 0, column: 2, bridges: 1),
        HashiIsland(row: 4, column: 2, bridges: 1),
      ],
    );
    var game = HashiGameState(puzzle: puzzle);
    game = game.cycleConnection(0, 1);

    expect(game.canConnect(2, 3), isFalse);
  });

  test('tutorial solution satisfies numbers and connectivity', () {
    final game = HashiGameState(
      puzzle: hashiTutorialPuzzle,
      bridges: hashiPreviewBridges,
    );

    expect(game.numbersAreSatisfied, isTrue);
    expect(game.allIslandsConnected, isTrue);
    expect(game.isSolved, isTrue);
  });

  test('all catalog solutions satisfy numbers and connectivity', () {
    expect(hashiPuzzleCatalog, hasLength(6));
    for (final puzzle in hashiPuzzleCatalog) {
      final game = HashiGameState(puzzle: puzzle, bridges: puzzle.solution);
      expect(game.isSolved, isTrue, reason: puzzle.title);
    }
  });
}

