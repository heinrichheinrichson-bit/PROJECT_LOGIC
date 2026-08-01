import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/core/domain/game_identity.dart';
import 'package:project_logic_prototype/features/futoshiki/domain/futoshiki_generator.dart';
import 'package:project_logic_prototype/features/futoshiki/domain/futoshiki_puzzle.dart';
import 'package:project_logic_prototype/features/futoshiki/domain/futoshiki_solver.dart';
import 'package:project_logic_prototype/futoshiki_foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('generator creates a deterministic unique puzzle for every difficulty',
      () {
    const generator = FutoshikiGenerator();
    const solver = FutoshikiSolver();
    for (final difficulty in PuzzleDifficulty.values) {
      final first = generator.generate(
          seed: 4400 + difficulty.index, difficulty: difficulty);
      final second = generator.generate(
          seed: 4400 + difficulty.index, difficulty: difficulty);
      expect(first.givens, second.givens);
      expect(first.inequalities.length, second.inequalities.length);
      expect(solver.hasUniqueSolution(first), isTrue, reason: difficulty.name);
      expect(solver.solve(first), first.solution, reason: difficulty.name);
    }
  });

  test('state detects duplicate numbers and broken inequalities', () {
    final puzzle = const FutoshikiGenerator().generate(
      seed: 90210,
      difficulty: PuzzleDifficulty.easy,
    );
    final editable = <(int, int)>[];
    for (var row = 0; row < puzzle.size; row++) {
      for (var column = 0; column < puzzle.size; column++) {
        if (puzzle.givens[row][column] == null) editable.add((row, column));
      }
    }
    var state = FutoshikiState(puzzle: puzzle);
    state = state.setValue(editable[0].$1, editable[0].$2, 1);
    state = state.setValue(editable[1].$1, editable[1].$2, 1);
    expect(state.conflictingCells, isNotEmpty);
    expect(state.isSolved, isFalse);
  });

  testWidgets('game fits a narrow phone and supports a test completion',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final puzzle = const FutoshikiGenerator().generate(
      seed: 90210,
      difficulty: PuzzleDifficulty.easy,
    );

    await tester.pumpWidget(
      MaterialApp(home: FutoshikiGameScreen(puzzle: puzzle)),
    );
    await tester.pumpAndSettle();
    expect(find.text('So liest du die Zeichen'), findsOneWidget);
    expect(find.textContaining('offene Seite'), findsOneWidget);
    await tester.tap(find.text('Verstanden'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Jede Zahl genau einmal pro Zeile und Spalte.'),
        findsOneWidget);

    await tester.tap(find.byIcon(Icons.bug_report_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sofort lösen'));
    await tester.pumpAndSettle();

    expect(find.text('Ungleichungen gelöst!'), findsOneWidget);
    expect(find.text('Testabschluss · keine Statistik'), findsOneWidget);
  });

  test('saved game preserves board progress and play time', () async {
    final puzzle = const FutoshikiGenerator().generate(
      seed: 117,
      difficulty: PuzzleDifficulty.medium,
    );
    final state = FutoshikiState(puzzle: puzzle);
    final editable = <(int, int)>[
      for (var row = 0; row < puzzle.size; row++)
        for (var column = 0; column < puzzle.size; column++)
          if (puzzle.givens[row][column] == null) (row, column),
    ];
    final changed = state.setValue(
      editable.first.$1,
      editable.first.$2,
      puzzle.solution[editable.first.$1][editable.first.$2],
    );
    final store = FutoshikiGameStore();
    await store.save(SavedFutoshikiGame(
      puzzle: puzzle,
      values: changed.values,
      elapsedSeconds: 83,
      moves: 7,
      hintsRemaining: 2,
    ));

    final restored = await store.load();
    expect(restored, isNotNull);
    expect(restored!.puzzle.id, puzzle.id);
    expect(restored.values, changed.values);
    expect(restored.elapsedSeconds, 83);
    expect(restored.moves, 7);
    expect(restored.hintsRemaining, 2);
  });
}
