import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/core/domain/game_identity.dart';
import 'package:project_logic_prototype/features/hitori/domain/hitori_generator.dart';
import 'package:project_logic_prototype/features/hitori/domain/hitori_catalog.dart';
import 'package:project_logic_prototype/features/hitori/domain/hitori_puzzle.dart';
import 'package:project_logic_prototype/features/hitori/domain/hitori_solver.dart';
import 'package:project_logic_prototype/hitori_foundation.dart';
import 'package:project_logic_prototype/game_storage.dart';
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
    expect(open.protectedDuplicateConflicts, isEmpty);

    final wronglyProtected = HitoriState(
      puzzle: puzzle,
      marks: const {
        (0, 0): HitoriCellMark.protected,
        (0, 1): HitoriCellMark.protected,
      },
    );
    expect(
      wronglyProtected.protectedDuplicateConflicts,
      containsAll(const [(0, 0), (0, 1)]),
    );

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

  test('collection contains 28 unique and uniquely solvable puzzles', () {
    const solver = HitoriSolver();
    expect(hitoriChapters, hasLength(3));
    expect(
        hitoriChapters.map((chapter) => chapter.puzzles.length), [10, 10, 8]);
    expect(hitoriPuzzleCatalog, hasLength(28));
    expect(
      hitoriPuzzleCatalog.map((puzzle) => puzzle.id).toSet(),
      hasLength(28),
    );
    for (final puzzle in hitoriPuzzleCatalog) {
      expect(solver.hasUniqueSolution(puzzle), isTrue, reason: puzzle.id);
      expect(solver.solve(puzzle), puzzle.solution, reason: puzzle.id);
    }
  });

  test('generator stays unique across a representative seed sample', () {
    const generator = HitoriGenerator();
    const solver = HitoriSolver();
    for (final difficulty in PuzzleDifficulty.values) {
      for (var sample = 0; sample < 6; sample++) {
        final puzzle = generator.generate(
          seed: 18000 + difficulty.index * 100 + sample,
          difficulty: difficulty,
        );
        expect(solver.hasUniqueSolution(puzzle), isTrue, reason: puzzle.id);
      }
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
    expect(find.textContaining('Tippen: offen'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.bug_report_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sofort lösen'));
    await tester.pumpAndSettle();
    expect(find.text('Hitori gelöst!'), findsOneWidget);
    expect(find.text('Testabschluss · keine Statistik'), findsOneWidget);
    expect(find.text('Noch eins'), findsOneWidget);
  });

  testWidgets('completed Hitori can be viewed, restarted, and played again',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'hitori_rules_guide_seen_v1': true,
    });
    final puzzle = const HitoriGenerator().generate(
      seed: 9113,
      difficulty: PuzzleDifficulty.easy,
    );
    await tester.pumpWidget(
      MaterialApp(home: HitoriGameScreen(puzzle: puzzle)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.bug_report_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sofort lösen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Brett ansehen'));
    await tester.pumpAndSettle();
    expect(find.text('Noch ein Hitori'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.restart_alt_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Neu starten'));
    await tester.pumpAndSettle();
    expect(find.text('0 Züge'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('hitori-cell-0-0')));
    await tester.pump();
    expect(find.text('1 Züge'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Feld geschwärzt')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('hitori-cell-0-0')));
    await tester.pump();
    expect(
      find.bySemanticsLabel(RegExp('Feld als sicher markiert')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('collection completion offers the next puzzle', (tester) async {
    SharedPreferences.setMockInitialValues({
      'hitori_rules_guide_seen_v1': true,
    });
    final puzzle = hitoriPuzzleCatalog.first;
    await tester.pumpWidget(MaterialApp(
      home: HitoriGameScreen(
        puzzle: puzzle,
        mode: GameMode.catalog,
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.bug_report_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sofort lösen'));
    await tester.pumpAndSettle();
    expect(find.text('Nächstes Rätsel'), findsWidgets);

    await tester.tap(find.text('Brett ansehen'));
    await tester.pumpAndSettle();
    expect(find.text('Nächstes Rätsel'), findsOneWidget);
  });

  testWidgets('show hint highlights its cell without applying the answer',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'hitori_rules_guide_seen_v1': true,
    });
    final puzzle = const HitoriGenerator().generate(
      seed: 9114,
      difficulty: PuzzleDifficulty.easy,
    );
    final target = [
      for (var row = 0; row < puzzle.size; row++)
        for (var column = 0; column < puzzle.size; column++)
          if (puzzle.solution.contains((row, column))) (row, column),
    ].first;
    await tester.pumpWidget(
      MaterialApp(home: HitoriGameScreen(puzzle: puzzle)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Hinweis'));
    await tester.pumpAndSettle();
    expect(find.text('Auf dem Brett zeigen'), findsOneWidget);
    await tester.tap(find.text('Auf dem Brett zeigen'));
    await tester.pump();

    expect(find.text('2 Tipps'), findsOneWidget);
    expect(
      find.byKey(ValueKey(
        'hitori-hint-highlight-${target.$1}-${target.$2}',
      )),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('Feld offen, Hinweisziel')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(ValueKey(
      'hitori-cell-${target.$1}-${target.$2}',
    )));
    await tester.pump();
    expect(find.bySemanticsLabel(RegExp('Hinweisziel')), findsNothing);
    expect(find.text('1 Züge'), findsOneWidget);
  });

  testWidgets('applied hint is a reversible move', (tester) async {
    SharedPreferences.setMockInitialValues({
      'hitori_rules_guide_seen_v1': true,
    });
    final puzzle = const HitoriGenerator().generate(
      seed: 9115,
      difficulty: PuzzleDifficulty.easy,
    );
    final target = [
      for (var row = 0; row < puzzle.size; row++)
        for (var column = 0; column < puzzle.size; column++)
          if (puzzle.solution.contains((row, column))) (row, column),
    ].first;
    await tester.pumpWidget(
      MaterialApp(home: HitoriGameScreen(puzzle: puzzle)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Hinweis'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hinweis anwenden'));
    await tester.pump();
    expect(find.text('2 Tipps'), findsOneWidget);
    expect(find.text('1 Züge'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Feld geschwärzt')),
      findsOneWidget,
    );

    await tester.ensureVisible(find.byIcon(Icons.undo_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.undo_rounded));
    await tester.pump();
    expect(
      find.byKey(ValueKey(
        'hitori-cell-state-${target.$1}-${target.$2}-open',
      )),
      findsOneWidget,
    );
    expect(find.text('0 Züge'), findsOneWidget);
  });

  testWidgets('empty Hitori hint budget offers a simulated rewarded tip',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'hitori_rules_guide_seen_v1': true,
    });
    final puzzle = const HitoriGenerator().generate(
      seed: 9116,
      difficulty: PuzzleDifficulty.easy,
    );
    await tester.pumpWidget(MaterialApp(
      home: HitoriGameScreen(
        puzzle: puzzle,
        savedGame: SavedHitoriGame(
          puzzle: puzzle,
          marks: const {},
          elapsedSeconds: 0,
          moves: 0,
          hintsRemaining: 0,
          hintsUsed: 3,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Hinweis'));
    await tester.pumpAndSettle();
    expect(find.text('Keine Tipps mehr'), findsOneWidget);
    await tester.tap(find.text('Werbung simulieren'));
    await tester.pumpAndSettle();
    expect(find.text('Simulierte Werbung'), findsOneWidget);
    await tester.tap(find.text('Werbung abschließen'));
    await tester.pumpAndSettle();
    expect(find.text('1 Tipps'), findsOneWidget);
  });

  testWidgets('test solve counts for a daily Hitori puzzle', (tester) async {
    SharedPreferences.setMockInitialValues({
      'hitori_rules_guide_seen_v1': true,
    });
    final puzzle = const HitoriGenerator().generate(
      seed: 20260801,
      difficulty: PuzzleDifficulty.easy,
      id: 'daily-hitori-2026-08-01',
      title: 'Tagesrätsel',
    );
    await tester.pumpWidget(MaterialApp(
      home: HitoriGameScreen(
        puzzle: puzzle,
        mode: GameMode.daily,
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.bug_report_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sofort lösen'));
    await tester.pumpAndSettle();

    expect(
      find.text('Testabschluss · im Kalender gewertet'),
      findsOneWidget,
    );
    expect(find.text('Zum Kalender'), findsWidgets);
    expect(
      (await GameStorage().loadResults()).containsKey('hitori:${puzzle.id}'),
      isTrue,
    );
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
      hintsUsed: 2,
      rewardedHints: 1,
      mode: GameMode.daily,
    ));
    final restored = await store.load();
    expect(restored, isNotNull);
    expect(restored!.marks[cell], HitoriCellMark.shaded);
    expect(restored.elapsedSeconds, 64);
    expect(restored.moves, 3);
    expect(restored.hintsRemaining, 2);
    expect(restored.hintsUsed, 2);
    expect(restored.rewardedHints, 1);
    expect(restored.mode, GameMode.daily);
  });
}
