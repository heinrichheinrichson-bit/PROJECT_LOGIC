import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/slitherlink_foundation.dart';
import 'package:project_logic_prototype/app_preferences.dart';
import 'package:project_logic_prototype/game_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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
  });
}
