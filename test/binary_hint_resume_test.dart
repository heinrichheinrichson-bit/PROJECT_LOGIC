import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/app_preferences.dart';
import 'package:project_logic_prototype/core/presentation/rewarded_hint_dialog.dart';
import 'package:project_logic_prototype/game_logic.dart';
import 'package:project_logic_prototype/game_storage.dart';
import 'package:project_logic_prototype/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/confirmed_hint_ad_provider.dart';

void main() {
  testWidgets('Binairo saves consumed hints and rewards across resume',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await AppPreferences.load();
    final definition = binaryPuzzleCatalog.first;
    Future<void> open({SavedGame? saved}) async {
      await tester.pumpWidget(PreferencesScope(
        preferences: preferences,
        child: HintAdScope(
          provider: const ConfirmedHintAdProvider(),
          child: MaterialApp(
              home: BinaryPuzzleScreen(
            definition: definition,
            savedGame: saved,
          )),
        ),
      ));
      await tester.pumpAndSettle();
    }

    await open();
    for (var remaining = 3; remaining > 0; remaining--) {
      await tester.tap(find.text('$remaining ${remaining == 1 ? 'Tipp' : 'Tipps'}'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nur markieren'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Tipp mit Werbung'), findsOneWidget);
    final exhausted = (await GameStorage().loadActiveGame())!;
    expect(exhausted.budgetHintsUsed, 3);
    expect(exhausted.hintsUsed, 3);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await open(saved: exhausted);
    expect(find.text('Tipp mit Werbung'), findsOneWidget);
    expect(find.text('3 Tipps'), findsNothing);
    await tester.tap(find.text('Tipp mit Werbung'));
    await tester.pumpAndSettle();
    expect(find.text('Werbung ansehen'), findsOneWidget);
    await tester.tap(find.text('Später'));
    await tester.pumpAndSettle();
    expect(find.text('Tipp mit Werbung'), findsOneWidget);
    expect((await GameStorage().loadActiveGame())!.rewardedHints, 0);
    await tester.tap(find.text('Tipp mit Werbung'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Werbung ansehen'));
    await tester.pumpAndSettle();
    expect(find.text('1 Tipp'), findsOneWidget);
    final rewarded = (await GameStorage().loadActiveGame())!;
    expect(rewarded.rewardedHints, 1);
    expect(rewarded.budgetHintsUsed, 3);

    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await open(saved: rewarded);
    expect(find.text('1 Tipp'), findsOneWidget);
    await tester.tap(find.text('1 Tipp'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nur markieren'));
    await tester.pumpAndSettle();
    expect(find.text('Tipp mit Werbung'), findsOneWidget);
    expect((await GameStorage().loadActiveGame())!.budgetHintsUsed, 4);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
}
