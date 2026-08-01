import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/app_preferences.dart';
import 'package:project_logic_prototype/game_logic.dart';
import 'package:project_logic_prototype/game_storage.dart';
import 'package:project_logic_prototype/hashi_foundation.dart';
import 'package:project_logic_prototype/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<AppPreferences> freshPreferences() async {
    SharedPreferences.setMockInitialValues({});
    return AppPreferences.load();
  }

  testWidgets('Binairo developer solve never records player progress',
      (tester) async {
    final preferences = await freshPreferences();
    await tester.pumpWidget(
      PreferencesScope(
        preferences: preferences,
        child: MaterialApp(
          home: BinaryPuzzleScreen(definition: binaryPuzzleCatalog.first),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.bug_report_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sofort lösen'));
    await tester.pumpAndSettle();

    expect(find.text('Testabschluss · keine Statistik'), findsOneWidget);
    expect(await GameStorage().loadResults(), isEmpty);
    expect((await GameStorage().loadPlayerProgress()).totalCompleted, 0);
  });

  testWidgets('Hashi developer solve never records player progress',
      (tester) async {
    final preferences = await freshPreferences();
    await tester.pumpWidget(
      PreferencesScope(
        preferences: preferences,
        child: const MaterialApp(
          home: HashiGameScreen(puzzle: hashiTutorialPuzzle),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.bug_report_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sofort lösen'));
    await tester.pumpAndSettle();

    expect(find.text('Testabschluss · keine Statistik'), findsOneWidget);
    expect(await GameStorage().loadResults(), isEmpty);
    expect((await GameStorage().loadPlayerProgress()).totalCompleted, 0);
  });
}
