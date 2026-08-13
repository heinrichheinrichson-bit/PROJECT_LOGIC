import 'package:flutter/material.dart';
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

  test('hint applies the next missing solution bridge', () {
    final game = HashiGameState(puzzle: hashiTutorialPuzzle);

    final hinted = game.applyHint();

    expect(hinted.bridges, hasLength(1));
    expect(hinted.bridges.first.from, hashiPreviewBridges.first.from);
    expect(hinted.bridges.first.to, hashiPreviewBridges.first.to);
  });

  test('a hint adds only one line when a double bridge is required', () {
    const puzzle = HashiPuzzle(
      id: 'double-hint',
      title: 'Double hint',
      size: 3,
      difficulty: 1,
      islands: [
        HashiIsland(row: 1, column: 0, bridges: 2),
        HashiIsland(row: 1, column: 2, bridges: 2),
      ],
      solution: [HashiBridge(from: 0, to: 1, count: 2)],
    );

    final firstHint = HashiGameState(puzzle: puzzle).applyHint();
    final secondHint = firstHint.applyHint();

    expect(firstHint.bridgeCountBetween(0, 1), 1);
    expect(secondHint.bridgeCountBetween(0, 1), 2);
  });

  test('incorrect bridges are detected against the stored solution', () {
    final game = HashiGameState(
      puzzle: hashiTutorialPuzzle,
      bridges: const [HashiBridge(from: 0, to: 1, count: 2)],
    );

    expect(game.incorrectBridges, hasLength(1));
  });

  test('islands touching an incorrect bridge are identified', () {
    final game = HashiGameState(
      puzzle: hashiTutorialPuzzle,
      bridges: const [HashiBridge(from: 0, to: 1, count: 2)],
    );

    expect(game.incorrectIslandIndices, containsAll(<int>{0, 1}));
  });

  test('correct bridges do not mark islands as incorrect', () {
    final firstSolutionBridge = hashiPreviewBridges.first;
    final game = HashiGameState(
      puzzle: hashiTutorialPuzzle,
      bridges: <HashiBridge>[firstSolutionBridge],
    );

    expect(game.incorrectIslandIndices, isEmpty);
  });

  test('catalog puzzle ids are unique', () {
    final ids = hashiPuzzleCatalog.map((puzzle) => puzzle.id).toSet();

    expect(ids, hasLength(hashiPuzzleCatalog.length));
  });

  test('all catalog solutions satisfy numbers and connectivity', () {
    expect(hashiPuzzleCatalog, hasLength(60));
    for (final puzzle in hashiPuzzleCatalog) {
      final game = HashiGameState(puzzle: puzzle, bridges: puzzle.solution);
      expect(game.isSolved, isTrue, reason: puzzle.title);
    }
  });

  testWidgets('dragging from one island to another requests a bridge',
      (tester) async {
    (int, int)? draggedConnection;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox.square(
              dimension: 300,
              child: HashiBoard(
                puzzle: hashiTutorialPuzzle,
                bridges: const [],
                onIslandTap: (_) {},
                onIslandDrag: (first, second) {
                  draggedConnection = (first, second);
                },
              ),
            ),
          ),
        ),
      ),
    );

    final board = tester.getRect(find.byType(HashiBoard));
    final cell = board.width / hashiTutorialPuzzle.size;
    Offset islandCenter(int index) {
      final island = hashiTutorialPuzzle.islands[index];
      return Offset(
        board.left + (island.column + 0.5) * cell,
        board.top + (island.row + 0.5) * cell,
      );
    }

    await tester.dragFrom(
      islandCenter(0),
      islandCenter(1) - islandCenter(0),
    );
    await tester.pump();

    expect(draggedConnection, (0, 1));
  });

  test('Hashi chapters preserve every puzzle and difficulty filter', () {
    final all = hashiChaptersFor();
    final medium = hashiChaptersFor(difficulty: 2);

    expect(
      all
          .expand((chapter) => chapter.puzzles)
          .map((puzzle) => puzzle.id)
          .toSet(),
      hashiPuzzleCatalog.map((puzzle) => puzzle.id).toSet(),
    );
    expect(
      medium.expand((chapter) => chapter.puzzles),
      hashiPuzzleCatalog.where((puzzle) => puzzle.difficulty == 2),
    );
    expect(all.map((chapter) => chapter.title), contains('Brücken bauen'));
    expect(all.map((chapter) => chapter.title), contains('Netze planen'));
    expect(all.map((chapter) => chapter.title), contains('Inselmeister'));
  });
}
