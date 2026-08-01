import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/core/domain/game_identity.dart';
import 'package:project_logic_prototype/features/hitori/domain/hitori_generator.dart';
import 'package:project_logic_prototype/features/hitori/domain/hitori_puzzle.dart';
import 'package:project_logic_prototype/features/hitori/domain/hitori_solver.dart';
import 'package:project_logic_prototype/hitori_foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('state enforces all three Hitori rules', () {
    const puzzle = HitoriPuzzle(
      id: 'rules',
      title: 'Rules',
      grid: [
        [1, 1, 2],
        [2, 3, 1],
        [3, 2, 3],
      ],
      solution: {(0, 0), (2, 2)},
      difficulty: PuzzleDifficulty.easy,
    );
    final open = HitoriState(puzzle: puzzle);
    expect(open.duplicateConflicts, isNotEmpty);

    final solved = HitoriState(
      puzzle: puzzle,
      marks: const {
        (0, 0): HitoriCellMark.shaded,
        (2, 2): HitoriCellMark.shaded,
      },
    );
    expect(solved.adjacentShadeConflicts, isEmpty);
    expect(solved.openCellsConnected, isTrue);
    expect(solved.isSolved, isTrue);
  });

  test('generator creates a deterministic unique puzzle for each difficulty',
      () {
    const generator = HitoriGenerator();
    const solver = HitoriSolver();
    for (final difficulty in PuzzleDifficulty.values) {
      final first = generator.generate(
        seed: 9100 + difficulty.index,
        difficulty: difficulty,
      );
      final second = generator.generate(
        seed: 9100 + difficulty.index,
        difficulty: difficulty,
      );
      expect(first.grid, second.grid);
      expect(first.solution, second.solution);
      expect(solver.hasUniqueSolution(first), isTrue);
      expect(solver.solve(first), first.solution);
    }
  });

  testWidgets('Hitori fits a narrow phone and supports test completion',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final puzzle = const HitoriGenerator().generate(
      seed: 9112,
      difficulty: PuzzleDifficulty.hard,
    );
    await tester.pumpWidget(
      MaterialApp(home: HitoriGameScreen(puzzle: puzzle)),
    );
    await tester.pumpAndSettle();
    expect(find.text('So funktioniert Hitori'), findsOneWidget);
    expect(find.text('Doppelte Zahlen entfernen'), findsOneWidget);
    await tester.tap(find.text('Verstanden'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Tippen: unverändert'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.bug_report_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sofort lösen'));
    await tester.pumpAndSettle();
    expect(find.text('Hitori gelöst!'), findsOneWidget);
    expect(find.text('Testabschluss · keine Statistik'), findsOneWidget);
  });

  test('saved Hitori game preserves marks and time', () async {
    final puzzle = const HitoriGenerator().generate(
      seed: 9110,
      difficulty: PuzzleDifficulty.easy,
    );
    final cell = puzzle.solution.first;
    final store = HitoriGameStore();
    await store.save(SavedHitoriGame(
      puzzle: puzzle,
      marks: {cell: HitoriCellMark.shaded},
      elapsedSeconds: 64,
      moves: 3,
      hintsRemaining: 2,
    ));
    final restored = await store.load();
    expect(restored, isNotNull);
    expect(restored!.marks[cell], HitoriCellMark.shaded);
    expect(restored.elapsedSeconds, 64);
    expect(restored.moves, 3);
  });
}
