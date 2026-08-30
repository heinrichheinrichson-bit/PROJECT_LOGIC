import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/slitherlink_foundation.dart';
import 'package:project_logic_prototype/app_preferences.dart';
import 'package:project_logic_prototype/core/domain/game_identity.dart';
import 'package:project_logic_prototype/game_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('tutorial solution satisfies clues and forms one loop', () {
    final state = SlitherlinkState(
      puzzle: slitherlinkTutorialPuzzle,
      marks: {
        for (final id in slitherlinkTutorialPuzzle.solution)
          id: SlitherEdgeMark.line,
      },
    );

    expect(state.isSolved, isTrue);
  });

  test('every collection puzzle contains a valid advertised solution', () {
    expect(slitherlinkPuzzleCatalog, hasLength(60));
    expect(
      slitherlinkPuzzleCatalog.map((puzzle) => puzzle.id).toSet(),
      hasLength(60),
    );
    expect(
      slitherlinkPuzzleCatalog
          .where((puzzle) => puzzle.title.contains(RegExp(r'[ÃÂÆ]'))),
      isEmpty,
    );
    expect(
      slitherlinkPuzzleCatalog.map((puzzle) => puzzle.title),
      containsAll(
        const [
          'Letzte Übung',
          'Viele Möglichkeiten',
          'Falsche Fährten',
          'Große Prüfung',
          'Ruhige Runde',
          'Kombinierte Runde',
          'Letzte Meisterrunde',
          'Leichte Schleife',
          'Geschlossene Fährte',
          'Finale Schleife',
        ],
      ),
    );
    for (final difficulty in PuzzleDifficulty.values) {
      expect(
        slitherlinkPuzzleCatalog
            .where((puzzle) => puzzle.difficulty == difficulty),
        hasLength(20),
      );
    }
    for (final puzzle in slitherlinkPuzzleCatalog) {
      final state = SlitherlinkState(
        puzzle: puzzle,
        marks: {
          for (final id in puzzle.solution) id: SlitherEdgeMark.line,
        },
      );
      expect(state.isSolved, isTrue, reason: puzzle.id);
      expect(
        const SlitherlinkSolver().hasUniqueSolution(puzzle),
        isTrue,
        reason: '${puzzle.id} must be unique',
      );
    }
  });

  testWidgets('collection exposes the fourth chapter and new puzzles',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SlitherlinkHubScreen()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rätselsammlung'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leicht'));
    await tester.pumpAndSettle();

    expect(find.text('Neue Runden'), findsOneWidget);
    expect(find.text('Ruhige Runde'), findsOneWidget);
    expect(find.text('Sichere Kurve'), findsOneWidget);
  });

  test('solver confirms the tutorial has exactly one solution', () {
    expect(
      const SlitherlinkSolver().countSolutions(slitherlinkTutorialPuzzle),
      1,
    );
  });

  test('generator creates a valid unique puzzle reproducibly', () {
    const generator = SlitherlinkGenerator();
    final first = generator.generate(
      seed: 20260801,
      difficulty: PuzzleDifficulty.easy,
    );
    final repeated = generator.generate(
      seed: 20260801,
      difficulty: PuzzleDifficulty.easy,
    );
    final solved = SlitherlinkState(
      puzzle: first,
      marks: {
        for (final id in first.solution) id: SlitherEdgeMark.line,
      },
    );

    expect(solved.isSolved, isTrue);
    expect(const SlitherlinkSolver().hasUniqueSolution(first), isTrue);
    expect(repeated.solution, first.solution);
    expect(repeated.clues, first.clues);
  });

  test('generator creates a unique puzzle for every difficulty', () {
    const generator = SlitherlinkGenerator();
    const solver = SlitherlinkSolver();
    for (final difficulty in PuzzleDifficulty.values) {
      final puzzle = generator.generate(
        seed: 8100 + difficulty.index,
        difficulty: difficulty,
      );
      expect(solver.hasUniqueSolution(puzzle), isTrue, reason: difficulty.name);
      expect(
        puzzle.clues.expand((row) => row).whereType<int>().length,
        lessThan(puzzle.rows * puzzle.columns),
        reason: difficulty.name,
      );
    }
  });

  test('exact clues without a closed loop are not solved', () {
    final state = SlitherlinkState(
      puzzle: slitherlinkTutorialPuzzle,
      marks: {
        for (final id in slitherlinkTutorialPuzzle.solution.take(7))
          id: SlitherEdgeMark.line,
      },
    );

    expect(state.isSolved, isFalse);
  });

  test('two separate closed loops are not a solution', () {
    const puzzle = SlitherlinkPuzzle(
      id: 'two-loops-regression',
      title: 'Two loops regression',
      rows: 1,
      columns: 3,
      clues: [
        <int?>[null, null, null]
      ],
      solution: <String>{},
      difficulty: PuzzleDifficulty.easy,
    );
    const leftLoop = <String>{'h:0:0', 'h:1:0', 'v:0:0', 'v:0:1'};
    const rightLoop = <String>{'h:0:2', 'h:1:2', 'v:0:2', 'v:0:3'};
    final state = SlitherlinkState(
      puzzle: puzzle,
      marks: {
        for (final id in {...leftLoop, ...rightLoop}) id: SlitherEdgeMark.line,
      },
    );

    expect(state.isSolved, isFalse);
  });

  test('one closed loop remains a valid solution', () {
    const puzzle = SlitherlinkPuzzle(
      id: 'one-loop-regression',
      title: 'One loop regression',
      rows: 1,
      columns: 1,
      clues: [
        <int?>[4]
      ],
      solution: <String>{},
      difficulty: PuzzleDifficulty.easy,
    );
    const state = SlitherlinkState(
      puzzle: puzzle,
      marks: {
        'h:0:0': SlitherEdgeMark.line,
        'h:1:0': SlitherEdgeMark.line,
        'v:0:0': SlitherEdgeMark.line,
        'v:0:1': SlitherEdgeMark.line,
      },
    );

    expect(state.isSolved, isTrue);
  });

  test('edge input cycles through line, blocked and empty', () {
    const edge = SlitherEdge.horizontal(0, 0);
    const empty = SlitherlinkState(puzzle: slitherlinkTutorialPuzzle);
    final line = empty.cycle(edge);
    final blocked = line.cycle(edge);
    final emptyAgain = blocked.cycle(edge);

    expect(line.markAt(edge), SlitherEdgeMark.line);
    expect(blocked.markAt(edge), SlitherEdgeMark.blocked);
    expect(emptyAgain.markAt(edge), SlitherEdgeMark.empty);
  });

  test('hint prefers a useful exclusion that unlocks the next deduction', () {
    const puzzle = SlitherlinkPuzzle(
      id: 'useful-exclusion',
      title: 'Useful exclusion',
      rows: 1,
      columns: 1,
      clues: [
        <int?>[3]
      ],
      solution: {'h:0:0', 'h:1:0', 'v:0:0'},
    );

    final hint = findSlitherlinkExclusionHint(
      const SlitherlinkState(puzzle: puzzle),
    );

    expect(hint, isNotNull);
    expect(hint!.edge.id, 'v:0:1');
    expect(hint.unlocksImmediateStep, isTrue);
    expect(puzzle.solution.contains(hint.edge.id), isFalse);
  });

  test('hint skips exclusions already obvious from zero or satisfied clues',
      () {
    const zeroPuzzle = SlitherlinkPuzzle(
      id: 'zero',
      title: 'Zero',
      rows: 1,
      columns: 1,
      clues: [
        <int?>[0]
      ],
      solution: {},
    );
    const satisfiedPuzzle = SlitherlinkPuzzle(
      id: 'satisfied',
      title: 'Satisfied',
      rows: 1,
      columns: 1,
      clues: [
        <int?>[1]
      ],
      solution: {'h:0:0'},
    );

    expect(
      findSlitherlinkExclusionHint(
        const SlitherlinkState(puzzle: zeroPuzzle),
      ),
      isNull,
    );
    expect(
      findSlitherlinkExclusionHint(
        const SlitherlinkState(
          puzzle: satisfiedPuzzle,
          marks: {'h:0:0': SlitherEdgeMark.line},
        ),
      ),
      isNull,
    );
  });

  test('rule issues detect clue conflicts and branching lines', () {
    const puzzle = SlitherlinkPuzzle(
      id: 'rule-issue-regression',
      title: 'Rule issue regression',
      rows: 1,
      columns: 1,
      clues: [
        <int?>[0]
      ],
      solution: <String>{},
    );
    const clueConflict = SlitherlinkState(
      puzzle: puzzle,
      marks: {'h:0:0': SlitherEdgeMark.line},
    );
    const branching = SlitherlinkState(
      puzzle: puzzle,
      marks: {
        'h:0:0': SlitherEdgeMark.line,
        'h:0:1': SlitherEdgeMark.line,
        'v:0:1': SlitherEdgeMark.line,
      },
    );

    expect(clueConflict.clueHasRuleIssue(0, 0), isTrue);
    expect(branching.branchingLineIds, hasLength(3));
  });

  testWidgets('Slitherlink rule issue switch is interactive and persisted',
      (tester) async {
    final preferences = await AppPreferences.load();
    await tester.pumpWidget(
      PreferencesScope(
        preferences: preferences,
        child: const MaterialApp(
          home: SlitherlinkGameScreen(puzzle: slitherlinkTutorialPuzzle),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Spielhilfen'));
    await tester.pumpAndSettle();
    expect(find.text('Regelfehler markieren'), findsOneWidget);
    expect(find.text('Farben bei aktiver Hilfe'), findsOneWidget);
    expect(find.textContaining('Lila = Zahl momentan genau erfüllt'),
        findsOneWidget);
    expect(
      find.textContaining(
          'Offene Enden und getrennte Schleifen werden nicht sofort'),
      findsOneWidget,
    );
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(preferences.showRuleIssues, isFalse);
    final reloaded = await AppPreferences.load();
    expect(reloaded.showRuleIssues, isFalse);
    expect(find.text('Spielhilfen'), findsNothing);
  });

  testWidgets('Slitherlink rules explain that colors require active help',
      (tester) async {
    final preferences = await AppPreferences.load();
    await tester.pumpWidget(
      PreferencesScope(
        preferences: preferences,
        child: const MaterialApp(
          home: SlitherlinkGameScreen(puzzle: slitherlinkTutorialPuzzle),
        ),
      ),
    );

    await tester.tap(find.text('Spielregeln & Bedienung'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining(
          'Nur wenn die Spielhilfe „Regelfehler markieren“ eingeschaltet ist'),
      findsOneWidget,
    );
    expect(find.textContaining('Lila bedeutet'), findsOneWidget);
    expect(find.textContaining('Rot zeigt einen sicheren Regelkonflikt'),
        findsOneWidget);
  });

  testWidgets('debug solve is clearly marked as a test completion',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await AppPreferences.load();
    await tester.pumpWidget(
      PreferencesScope(
        preferences: preferences,
        child: const MaterialApp(
          home: SlitherlinkGameScreen(puzzle: slitherlinkTutorialPuzzle),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.bug_report_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Fast lösen'), findsOneWidget);
    expect(find.text('Fehler erzeugen'), findsOneWidget);

    await tester.tap(find.text('Sofort lösen'));
    await tester.pumpAndSettle();

    expect(find.text('Schleife vollendet!'), findsOneWidget);
    expect(find.text('Testabschluss · keine Statistik'), findsOneWidget);
    expect(await GameStorage().loadResults(), isEmpty);

    await tester.tap(find.text('Brett ansehen'));
    await tester.pumpAndSettle();
    expect(find.text('Noch einmal'), findsOneWidget);
  });

  testWidgets('debug solve marks a daily Slitherlink puzzle as completed',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await AppPreferences.load();
    final dailyPuzzle = SlitherlinkPuzzle(
      id: 'daily-slitherlink-2026-08-01',
      title: 'Tagesrätsel',
      rows: 4,
      columns: 4,
      clues: slitherlinkTutorialPuzzle.clues,
      solution: slitherlinkTutorialPuzzle.solution,
      difficulty: PuzzleDifficulty.easy,
    );
    await tester.pumpWidget(
      PreferencesScope(
        preferences: preferences,
        child: MaterialApp(
          home: SlitherlinkGameScreen(puzzle: dailyPuzzle),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.bug_report_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Sofort'));
    await tester.pumpAndSettle();

    expect(
      find.text('Testabschluss · im Kalender gewertet'),
      findsOneWidget,
    );
    expect(find.text('Zum Kalender'), findsWidgets);
    expect(
      (await GameStorage().loadResults())
          .containsKey('slitherlink:${dailyPuzzle.id}'),
      isTrue,
    );
  });

  testWidgets('hint explains a logical step before applying it',
      (tester) async {
    final preferences = await AppPreferences.load();
    await tester.pumpWidget(
      PreferencesScope(
        preferences: preferences,
        child: const MaterialApp(
          home: SlitherlinkGameScreen(puzzle: slitherlinkTutorialPuzzle),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Hinweis'));
    await tester.pumpAndSettle();

    expect(find.text('Hinweis anwenden'), findsOneWidget);
    expect(find.text('Abbrechen'), findsOneWidget);

    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();
    expect(find.text('Hinweis anwenden'), findsNothing);
  });

  testWidgets('empty Slitherlink hint budget offers a simulated rewarded tip',
      (tester) async {
    final preferences = await AppPreferences.load();
    const saved = SavedSlitherlinkGame(
      puzzle: slitherlinkTutorialPuzzle,
      marks: {},
      elapsedSeconds: 0,
      moves: 0,
      hintsUsed: 3,
      rewardedHints: 0,
    );
    await tester.pumpWidget(
      PreferencesScope(
        preferences: preferences,
        child: const MaterialApp(
          home: SlitherlinkGameScreen(
            puzzle: slitherlinkTutorialPuzzle,
            savedGame: saved,
          ),
        ),
      ),
    );

    await tester.tap(find.byTooltip('Hinweis'));
    await tester.pumpAndSettle();
    expect(find.text('Keine Tipps mehr'), findsOneWidget);
    await tester.tap(find.text('Werbung simulieren'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Werbung abschließen'));
    await tester.pumpAndSettle();
    expect(find.text('1 Tipps'), findsOneWidget);
  });

  test('saved Slitherlink game preserves puzzle and progress', () async {
    final store = SlitherlinkGameStore();
    const edge = SlitherEdge.horizontal(1, 1);
    final saved = SavedSlitherlinkGame(
      puzzle: slitherlinkTutorialPuzzle,
      marks: {edge.id: SlitherEdgeMark.line},
      elapsedSeconds: 91,
      moves: 4,
      hintsUsed: 1,
      rewardedHints: 2,
    );

    await store.save(saved);
    final restored = await store.load();

    expect(restored, isNotNull);
    expect(restored!.puzzle.id, slitherlinkTutorialPuzzle.id);
    expect(restored.marks[edge.id], SlitherEdgeMark.line);
    expect(restored.elapsedSeconds, 91);
    expect(restored.moves, 4);
    expect(restored.hintsUsed, 1);
    expect(restored.rewardedHints, 2);
  });

  testWidgets('Slitherlink hub offers a saved puzzle to continue',
      (tester) async {
    await SlitherlinkGameStore().save(
      const SavedSlitherlinkGame(
        puzzle: slitherlinkTutorialPuzzle,
        marks: {'h:1:1': SlitherEdgeMark.line},
        elapsedSeconds: 73,
        moves: 1,
        hintsUsed: 0,
        rewardedHints: 0,
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(home: SlitherlinkHubScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rätsel fortsetzen'), findsOneWidget);
    expect(find.textContaining('1:13'), findsOneWidget);
  });

  test('completed Slitherlink save is not offered as an open game', () async {
    final store = SlitherlinkGameStore();
    await store.save(SavedSlitherlinkGame(
      puzzle: slitherlinkTutorialPuzzle,
      marks: {
        for (final edge in slitherlinkTutorialPuzzle.solution)
          edge: SlitherEdgeMark.line,
      },
      elapsedSeconds: 38,
      moves: 10,
      hintsUsed: 0,
      rewardedHints: 0,
    ));

    expect(await store.load(), isNull);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.containsKey('active_slitherlink_game_v1'), isFalse);
  });
}
