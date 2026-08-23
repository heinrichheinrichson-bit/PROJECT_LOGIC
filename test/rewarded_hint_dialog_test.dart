import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/core/presentation/rewarded_hint_dialog.dart';

void main() {
  testWidgets('release flow never offers or grants a simulated ad reward',
      (tester) async {
    bool? rewarded;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                rewarded = await requestRewardedHint(
                  context,
                  allowSimulation: false,
                );
              },
              child: const Text('Request hint'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Request hint'));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Simulate ad'), findsNothing);

    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(FilledButton),
    ));
    await tester.pumpAndSettle();

    expect(rewarded, isFalse);
  });
}
