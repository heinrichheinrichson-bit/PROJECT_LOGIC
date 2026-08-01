import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/core/domain/game_identity.dart';
import 'package:project_logic_prototype/features/tents/domain/tents_difficulty_rater.dart';
import 'package:project_logic_prototype/features/tents/domain/tents_catalog.dart';
import 'package:project_logic_prototype/features/tents/domain/tents_generator.dart';
import 'package:project_logic_prototype/features/tents/domain/tents_puzzle.dart';
import 'package:project_logic_prototype/features/tents/domain/tents_solver.dart';
import 'package:project_logic_prototype/tents_game.dart';
import 'package:project_logic_prototype/game_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('generator is deterministic and uniquely solvable for all difficulties',
      () {
    const generator = TentsGenerator();
    const solver = TentsSolver();
    for (final difficulty in PuzzleDifficulty.values) {
      final first = generator.generate(
        seed: 7300 + difficulty.index,
        difficulty: difficulty,
      );
      final second = generator.generate(
        seed: 7300 + difficulty.index,
        difficulty: difficulty,
      );
      expect(first.trees, second.trees, reason: difficulty.name);
      expect(first.rowCounts, second.rowCounts, reason: difficulty.name);
      expect(first.columnCounts, second.columnCounts, reason: difficulty.name);
      expect(first.isStructurallyValid, isTrue, reason: difficulty.name);
      expect(solver.hasUniqueSolution(first), isTrue, reason: difficulty.name);
      expect(solver.solve(first)!.solution, first.solution,
          reason: difficulty.name);
      final pairings = solver.pairTrees(first, first.solution);
      expect(pairings.length, first.trees.length, reason: difficulty.name);
      expect(pairings.values.toSet().length, first.solution.length,
          reason: difficulty.name);
      for (final entry in pairings.entries) {
        expect(
          (entry.key.$1 - entry.value.$1).abs() +
              (entry.key.$2 - entry.value.$2).abs(),
          1,
          reason: difficulty.name,
        );
      }
    }
  });

  test('generated solutions obey every tents rule across representative seeds',
      () {
    const generator = TentsGenerator();
    for (final difficulty in PuzzleDifficulty.values) {
      for (var index = 0; index < 4; index++) {
        final puzzle = generator.generate(
          seed: 9100 + difficulty.index * 100 + index,
          difficulty: difficulty,
        );
        final state = TentsState(
          puzzle: puzzle,
          marks: {
            for (final tent in puzzle.solution) tent: TentsCellMark.tent,
          },
        );
        expect(state.isSolved, isTrue,
            reason: '${difficulty.name} seed $index');
        expect(state.touchingTentConflicts, isEmpty);
        expect(state.orphanTentConflicts, isEmpty);
      }
    }
  });

  test('state rejects touching tents and overflowing line counts', () {
    const puzzle = TentsPuzzle(
      id: 'invalid-state-test',
      title: 'Test',
      size: 5,
      trees: {(0, 0), (1, 2)},
      rowCounts: [1, 0, 1, 0, 0],
      columnCounts: [0, 1, 0, 1, 0],
      solution: {(0, 1), (2, 3)},
      difficulty: PuzzleDifficulty.easy,
    );
    final state = TentsState(
      puzzle: puzzle,
      marks: const {
        (0, 1): TentsCellMark.tent,
        (1, 1): TentsCellMark.tent,
      },
    );
    expect(state.touchingTentConflicts, {(0, 1), (1, 1)});
    expect(state.countConflicts, isNotEmpty);
    expect(state.isSolved, isFalse);
  });

  test('custom sizes stay uniquely solvable', () {
    const generator = TentsGenerator();
    const solver = TentsSolver();
    for (final configuration in const [
      (size: 6, difficulty: PuzzleDifficulty.easy),
      (size: 8, difficulty: PuzzleDifficulty.medium),
      (size: 10, difficulty: PuzzleDifficulty.hard),
    ]) {
      final puzzle = generator.generate(
        seed: 12000 + configuration.size,
        size: configuration.size,
        difficulty: configuration.difficulty,
      );
      expect(puzzle.size, configuration.size);
      expect(solver.countSolutions(puzzle), 1);
    }
  });

  test('default board sizes form clearly separated difficulty bands', () {
    const generator = TentsGenerator();
    const rater = TentsDifficultyRater();
    final ratings = [
      for (final difficulty in PuzzleDifficulty.values)
        rater.rate(generator.generate(
            seed: 15000 + difficulty.index, difficulty: difficulty)),
    ];
    expect(ratings.map((rating) => rating.band), PuzzleDifficulty.values);
    expect(ratings[0].score, lessThan(ratings[1].score));
    expect(ratings[1].score, lessThan(ratings[2].score));
  });

  test('collection contains 60 distinct and uniquely solvable puzzles', () {
    const solver = TentsSolver();
    expect(tentsPuzzleCatalog, hasLength(60));
    expect(
        tentsPuzzleCatalog.map((puzzle) => puzzle.id).toSet(), hasLength(60));
    for (final difficulty in PuzzleDifficulty.values) {
      expect(
        tentsPuzzleCatalog.where((puzzle) => puzzle.difficulty == difficulty),
        hasLength(20),
      );
    }
    for (final puzzle in tentsPuzzleCatalog) {
      expect(solver.hasUniqueSolution(puzzle), isTrue, reason: puzzle.id);
    }
  });

  test('saved game preserves puzzle, marks, time, and moves', () async {
    final puzzle = const TentsGenerator().generate(
      seed: 19191,
      difficulty: PuzzleDifficulty.easy,
    );
    final editable = [
      for (var row = 0; row < puzzle.size; row++)
        for (var column = 0; column < puzzle.size; column++)
          if (!puzzle.trees.contains((row, column))) (row, column),
    ].first;
    await TentsGameStore().save(SavedTentsGame(
      puzzle: puzzle,
      marks: {editable: TentsCellMark.grass},
      elapsedSeconds: 83,
      moves: 7,
      hintsRemaining: 1,
      hintsUsed: 2,
      rewardedHints: 1,
      autoGrass: false,
    ));
    final restored = await TentsGameStore().load();
    expect(restored, isNotNull);
    expect(restored!.puzzle.trees, puzzle.trees);
    expect(restored.marks[editable], TentsCellMark.grass);
    expect(restored.elapsedSeconds, 83);
    expect(restored.moves, 7);
    expect(restored.hintsRemaining, 1);
    expect(restored.hintsUsed, 2);
    expect(restored.rewardedHints, 1);
    expect(restored.autoGrass, isFalse);
  });

  testWidgets('game fits a narrow phone and supports test completion',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final puzzle = const TentsGenerator().generate(
      seed: 20260801,
      difficulty: PuzzleDifficulty.easy,
    );
    await tester.pumpWidget(MaterialApp(home: TentsGameScreen(puzzle: puzzle)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Tippen: leer'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.bug_report_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sofort lösen'));
    await tester.pumpAndSettle();
    expect(find.text('Lager vollständig!'), findsOneWidget);
    expect(find.textContaining('Testabschluss'), findsOneWidget);
  });

  testWidgets('empty hint budget offers a simulated rewarded hint',
      (tester) async {
    final puzzle = const TentsGenerator().generate(
      seed: 20260802,
      difficulty: PuzzleDifficulty.easy,
    );
    await tester.pumpWidget(MaterialApp(
      home: TentsGameScreen(
        puzzle: puzzle,
        savedGame: SavedTentsGame(
          puzzle: puzzle,
          marks: const {},
          elapsedSeconds: 0,
          moves: 0,
          hintsRemaining: 0,
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

  testWidgets('test solve counts for a daily Tents puzzle', (tester) async {
    final puzzle = const TentsGenerator().generate(
      seed: 20260803,
      difficulty: PuzzleDifficulty.easy,
      id: 'daily-tents-2026-08-03',
      title: 'Tagesr\u00e4tsel',
    );
    await tester.pumpWidget(MaterialApp(
      home: TentsGameScreen(puzzle: puzzle, mode: GameMode.daily),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.bug_report_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sofort l\u00f6sen'));
    await tester.pumpAndSettle();
    expect(find.textContaining('im Kalender gewertet'), findsOneWidget);
    expect(
      (await GameStorage().loadResults()).containsKey('tents:${puzzle.id}'),
      isTrue,
    );
  });
}
