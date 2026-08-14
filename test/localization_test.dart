import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/app_localizations.dart';
import 'package:project_logic_prototype/app_preferences.dart';
import 'package:project_logic_prototype/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('language selection updates the app immediately', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await AppPreferences.load();

    await tester.pumpWidget(ProjectLogicApp(preferences: preferences));
    await tester.pumpAndSettle();
    expect(find.text('Deine Spiele'), findsOneWidget);

    await preferences.setLanguage(AppLanguagePreference.english);
    await tester.pumpAndSettle();

    expect(find.text('Your games'), findsOneWidget);
    expect(find.text('Your space'), findsOneWidget);
    expect(find.byTooltip('Settings'), findsOneWidget);

    await tester.tap(find.textContaining('Level 1 ·'));
    await tester.pumpAndSettle();
    expect(find.text('Your progress'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Your records'), findsWidgets);
    expect(find.text('Played'), findsOneWidget);
    expect(find.text('Frozen'), findsOneWidget);
  });

  test('system language falls back to German for unsupported locales', () {
    expect(
      AppLocalizations.resolve(
        const Locale('fr'),
        AppLocalizations.supportedLocales,
      ),
      const Locale('de'),
    );
  });

  test('goals and dynamic progress text have English presentations', () {
    const strings = AppLocalizations(Locale('en'));
    expect(strings.known('Brückenbauer'), 'Bridge builder');
    expect(strings.known('Löse 250 Rätsel.'), 'Solve 250 puzzles.');
    expect(strings.known('Sammlung erkunden · Stufe 4'),
        'Explore the collection · Level 4');
  });
}
