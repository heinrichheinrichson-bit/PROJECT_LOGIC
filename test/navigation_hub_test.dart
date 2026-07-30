import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/app_preferences.dart';
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

    expect(find.text('Katalog öffnen'), findsOneWidget);
    expect(find.text('Freies Rätsel'), findsOneWidget);
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
    expect(find.text('Erste Herausforderung'), findsOneWidget);
  });

}
