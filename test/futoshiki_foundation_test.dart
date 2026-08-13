import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/core/domain/game_identity.dart';
import 'package:project_logic_prototype/features/futoshiki/domain/futoshiki_generator.dart';
import 'package:project_logic_prototype/features/futoshiki/domain/futoshiki_puzzle.dart';
import 'package:project_logic_prototype/features/futoshiki/domain/futoshiki_solver.dart';
import 'package:project_logic_prototype/futoshiki_foundation.dart';
import 'package:project_logic_prototype/game_storage.dart';
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

  test('collection contains expanded distinct puzzle chapters', () {
    expect(futoshikiPuzzleCatalog, hasLength(96));
    expect(
      futoshikiPuzzleCatalog.map((puzzle) => puzzle.id).toSet(),
      hasLength(96),
    );
    for (final chapter in const [
      (difficulty: PuzzleDifficulty.easy, size: 4),
      (difficulty: PuzzleDifficulty.medium, size: 5),
      (difficulty: PuzzleDifficulty.hard, size: 6),
      (difficulty: PuzzleDifficulty.hard, size: 7),
    ]) {
      expect(
        futoshikiPuzzleCatalog.where((puzzle) =>
            puzzle.difficulty == chapter.difficulty &&
            puzzle.size == chapter.size),
        hasLength(24),
      );
    }
    const solver = FutoshikiSolver();
    for (final puzzle in futoshikiPuzzleCatalog) {
      expect(solver.hasUniqueSolution(puzzle), isTrue, reason: puzzle.id);
      expect(solver.solve(puzzle), puzzle.solution, reason: puzzle.id);
    }
  });

  test('generator creates a unique 7x7 expert puzzle', () {
    final puzzle = const FutoshikiGenerator().generate(
      seed: 77007,
      difficulty: PuzzleDifficulty.hard,
      size: 7,
    );
    expect(puzzle.size, 7);
    expect(const FutoshikiSolver().hasUniqueSolution(puzzle), isTrue);
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

  testWidgets('empty Futoshiki hint budget offers a simulated rewarded tip',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'futoshiki_inequality_guide_seen_v1': true,
    });
    final puzzle = const FutoshikiGenerator().generate(
      seed: 90211,
      difficulty: PuzzleDifficulty.easy,
    );
    await tester.pumpWidget(MaterialApp(
      home: FutoshikiGameScreen(
        puzzle: puzzle,
        savedGame: SavedFutoshikiGame(
          puzzle: puzzle,
          values: FutoshikiState(puzzle: puzzle).values,
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
    await tester.tap(find.text('Werbung abschließen'));
    await tester.pumpAndSettle();
    expect(find.text('1 Tipps'), findsOneWidget);
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
      candidates: {
        '1:2': {1, 3, 5}
      },
    ));

    final restored = await store.load();
    expect(restored, isNotNull);
    expect(restored!.puzzle.id, puzzle.id);
    expect(restored.values, changed.values);
    expect(restored.elapsedSeconds, 83);
    expect(restored.moves, 7);
    expect(restored.hintsRemaining, 2);
    expect(restored.candidates['1:2'], {1, 3, 5});
  });

  test('completed Futoshiki save is not offered as an open game', () async {
    final puzzle = const FutoshikiGenerator().generate(
      seed: 118,
      difficulty: PuzzleDifficulty.easy,
    );
    final store = FutoshikiGameStore();
    await store.save(SavedFutoshikiGame(
      puzzle: puzzle,
      values: [
        for (final row in puzzle.solution) [for (final value in row) value],
      ],
      elapsedSeconds: 40,
      moves: 8,
      hintsRemaining: 3,
    ));

    expect(await store.load(), isNull);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey('active_futoshiki_game_v1'), isFalse);
  });

  testWidgets('test solve counts for a daily Futoshiki puzzle', (tester) async {
    final generated = const FutoshikiGenerator().generate(
      seed: 20260801,
      difficulty: PuzzleDifficulty.easy,
      id: 'daily-futoshiki-2026-08-01',
      title: 'Tagesrätsel',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: FutoshikiGameScreen(
          puzzle: generated,
          mode: GameMode.daily,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verstanden'));
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
      (await GameStorage().loadResults())
          .containsKey('futoshiki:${generated.id}'),
      isTrue,
    );
  });

  testWidgets('7x7 fits a narrow phone and candidate notes are saved',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'futoshiki_inequality_guide_seen_v1': true,
    });
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final puzzle = const FutoshikiGenerator().generate(
      seed: 77123,
      difficulty: PuzzleDifficulty.hard,
      size: 7,
    );
    await tester.pumpWidget(
      MaterialApp(home: FutoshikiGameScreen(puzzle: puzzle)),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Notizen'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '1'));
    await tester.pump(const Duration(milliseconds: 100));

    final saved = await FutoshikiGameStore().load();
    expect(saved, isNotNull);
    expect(
        saved!.candidates.values.any((values) => values.contains(1)), isTrue);
  });

  testWidgets('another random puzzle keeps the exact 7x7 board size',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'futoshiki_inequality_guide_seen_v1': true,
    });
    final puzzle = const FutoshikiGenerator().generate(
      seed: 77881,
      difficulty: PuzzleDifficulty.hard,
      size: 7,
    );
    await tester.pumpWidget(
      MaterialApp(home: FutoshikiGameScreen(puzzle: puzzle)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.bug_report_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sofort lösen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Noch eins'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, '7'), findsOneWidget);
    expect(find.text('Ungleichungen gelöst!'), findsNothing);
  });
}
