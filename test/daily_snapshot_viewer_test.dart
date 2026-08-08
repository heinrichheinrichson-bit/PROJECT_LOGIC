import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/daily_snapshot_viewer.dart';
import 'package:project_logic_prototype/game_logic.dart';
import 'package:project_logic_prototype/game_storage.dart';

void main() {
  Future<void> pumpSnapshot(
    WidgetTester tester, {
    required GameType gameType,
    required int size,
    required Map<String, Object?> data,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DailySnapshotViewerScreen(
          snapshot: DailyPuzzleSnapshot(
            puzzleId: 'daily-${gameType.name}',
            gameType: gameType,
            difficulty: PuzzleDifficulty.easy,
            boardSize: size,
            completedAt: DateTime(2026, 8, 8),
            elapsedSeconds: 42,
            puzzleData: data,
          ),
          onReplay: () {},
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('daily archive renders all six game formats', (tester) async {
    final cases = <(GameType, int, Map<String, Object?>)>[
      (
        GameType.binairo,
        2,
        {
          'kind': 'binairo',
          'solution': [
            [0, 1],
            [1, 0],
          ],
          'clues': [
            [0, 0],
          ],
        },
      ),
      (
        GameType.hashi,
        4,
        {
          'kind': 'hashi',
          'islands': [
            [0, 0, 1],
            [0, 3, 1],
          ],
          'bridges': [
            [0, 1, 1],
          ],
        },
      ),
      (
        GameType.slitherlink,
        2,
        {
          'kind': 'slitherlink',
          'rows': 2,
          'columns': 2,
          'clues': [1, 2, 2, 1],
          'lines': ['h:0:0', 'v:0:1'],
        },
      ),
      (
        GameType.futoshiki,
        2,
        {
          'kind': 'futoshiki',
          'solution': [
            [1, 2],
            [2, 1],
          ],
          'givens': [
            [1, null],
            [null, 1],
          ],
        },
      ),
      (
        GameType.hitori,
        2,
        {
          'kind': 'hitori',
          'grid': [
            [1, 1],
            [2, 1],
          ],
          'shaded': [
            [0, 0],
          ],
        },
      ),
      (
        GameType.tents,
        2,
        {
          'kind': 'tents',
          'trees': [
            [0, 0],
          ],
          'tents': [
            [0, 1],
          ],
        },
      ),
    ];

    for (final gameCase in cases) {
      await pumpSnapshot(
        tester,
        gameType: gameCase.$1,
        size: gameCase.$2,
        data: gameCase.$3,
      );
      expect(tester.takeException(), isNull, reason: gameCase.$1.name);
      expect(find.text('Archiv'), findsOneWidget);
    }
  });

  testWidgets('malformed legacy archive fails safely', (tester) async {
    await pumpSnapshot(
      tester,
      gameType: GameType.hitori,
      size: 7,
      data: {
        'kind': 'hitori',
        'grid': [
          [1, 2],
          [2, 1],
        ],
      },
    );

    expect(tester.takeException(), isNull);
    expect(
      find.textContaining('kann in dieser Version nicht dargestellt werden'),
      findsOneWidget,
    );
    expect(find.textContaining('Fortschritt bleiben erhalten'), findsOneWidget);
  });
}
