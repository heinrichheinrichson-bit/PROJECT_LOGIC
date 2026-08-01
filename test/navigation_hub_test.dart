import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:project_logic_prototype/app_preferences.dart';
import 'package:project_logic_prototype/game_storage.dart';
import 'package:project_logic_prototype/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('home opens the dedicated binary puzzle hub', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await AppPreferences.load();

    await tester.pumpWidget(ProjectLogicApp(preferences: preferences));
    await tester.pumpAndSettle();

    expect(find.text('Binärpuzzle'), findsOneWidget);
    expect(find.text('Rätsel generieren'), findsNothing);
    expect(find.text('Spiel fortsetzen'), findsNothing);

    await tester.tap(find.text('Binärpuzzle'));
    await tester.pumpAndSettle();

    expect(find.text('Rätselsammlung'), findsOneWidget);
    expect(find.text('Zufallsrätsel'), findsOneWidget);
    expect(find.text('Tagesrätsel'), findsOneWidget);
    expect(find.text('Deine Binärpuzzle-Statistik'), findsOneWidget);
  });

  testWidgets('home opens the Hashi foundation', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await AppPreferences.load();

    await tester.pumpWidget(ProjectLogicApp(preferences: preferences));
    await tester.pumpAndSettle();

    expect(find.text('Hashi'), findsOneWidget);
    await tester.tap(find.text('Hashi'));
    await tester.pumpAndSettle();

    expect(find.text('Baue ein gemeinsames Brückennetz'), findsOneWidget);
    expect(find.text('Regeln ansehen'), findsOneWidget);
    expect(find.text('Rätselsammlung'), findsOneWidget);
    expect(find.text('Erste Herausforderung'), findsOneWidget);
    expect(find.text('Hashi-Statistik'), findsOneWidget);
    expect(find.text('Zufallsrätsel'), findsOneWidget);
    expect(find.text('Tagesrätsel & Kalender'), findsOneWidget);

    await tester.ensureVisible(find.text('Zufallsrätsel'));
    await tester.tap(find.text('Zufallsrätsel'));
    await tester.pumpAndSettle();
    expect(find.text('Hashi-Zufallsrätsel'), findsOneWidget);
    expect(find.text('Rätsel erstellen'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Hashi-Statistik'));
    await tester.tap(find.text('Hashi-Statistik'));
    await tester.pumpAndSettle();
    expect(find.text('Hashi-Statistik'), findsOneWidget);
    expect(find.text('Leistung'), findsOneWidget);
  });

  testWidgets('global and Binairo statistics stay separated', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const MaterialApp(
        home: StatisticsScreen(
          results: <String, PuzzleResult>{},
          progress: PlayerProgress.empty(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Deine Spiele'), findsOneWidget);
    expect(find.text('Tagesrätsel'), findsNothing);
    expect(find.text('Rätselsammlung'), findsNothing);

    await tester.pumpWidget(
      const MaterialApp(
        home: StatisticsScreen(
          results: <String, PuzzleResult>{},
          progress: PlayerProgress.empty(),
          gameType: GameType.binairo,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Binairo-Statistik'), findsOneWidget);
    expect(find.text('Deine Spiele'), findsNothing);
    expect(find.text('Tagesrätsel'), findsOneWidget);
    expect(find.text('Rätselsammlung'), findsNWidgets(2));
  });

  testWidgets('Hashi has a dedicated detailed statistics screen',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const MaterialApp(
        home: StatisticsScreen(
          results: <String, PuzzleResult>{},
          progress: PlayerProgress.empty(),
          gameType: GameType.hashi,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hashi-Statistik'), findsOneWidget);
    expect(find.text('Leistung'), findsOneWidget);
    expect(find.text('Nach Schwierigkeit'), findsOneWidget);
    expect(find.text('Wenigste Züge'), findsOneWidget);
    expect(find.text('Tagesrätsel'), findsOneWidget);
  });

  testWidgets('Futoshiki has detailed mode and board-size statistics',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const MaterialApp(
        home: StatisticsScreen(
          results: <String, PuzzleResult>{},
          progress: PlayerProgress.empty(),
          gameType: GameType.futoshiki,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Futoshiki-Statistik'), findsOneWidget);
    expect(find.text('Tagesrätsel'), findsOneWidget);
    expect(find.text('Nach Rastergröße'), findsOneWidget);
    expect(find.text('7 × 7'), findsOneWidget);
  });

  testWidgets('Hitori hub exposes calendar and detailed statistics',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await AppPreferences.load();
    await tester.pumpWidget(ProjectLogicApp(preferences: preferences));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Hitori'));
    await tester.tap(find.text('Hitori'));
    await tester.pumpAndSettle();
    expect(find.text('Tagesrätsel & Kalender'), findsOneWidget);
    expect(find.text('Hitori-Statistik'), findsOneWidget);

    await tester.ensureVisible(find.text('Hitori-Statistik'));
    await tester.tap(find.text('Hitori-Statistik'));
    await tester.pumpAndSettle();
    expect(find.text('Hitori-Statistik'), findsOneWidget);
    expect(find.text('Tagesrätsel'), findsOneWidget);
    expect(find.text('Leistung'), findsOneWidget);
    expect(find.text('Nach Schwierigkeit'), findsOneWidget);
  });

  testWidgets('daily calendar tiles fit a narrow phone without overflow',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: DailyArchiveScreen(gameType: GameType.slitherlink),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Slitherlink-Tagesrätsel'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
