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

  test('shared puzzle hubs and rules have English presentations', () {
    const strings = AppLocalizations(Locale('en'));
    expect(strings.known('Baue ein gemeinsames Brückennetz'),
        'Build one connected bridge network');
    expect(
        strings.known('12 von 50 Rätseln gelöst'), '12 of 50 puzzles solved');
    expect(
      strings.known(
          'Die Linie darf sich nicht verzweigen oder kreuzen und muss eine einzige Schleife bilden.'),
      'The line may not branch or cross and must form one single loop.',
    );
    expect(strings.known('30 feste Expeditionen entdecken'),
        'Explore 30 fixed expeditions');
  });

  test('all puzzle families expose English gameplay terminology', () {
    const strings = AppLocalizations(Locale('en'));
    expect(strings.known('Zelte & Bäume'), 'Tents & Trees');
    expect(
        strings.known('Doppelte Zahlen entfernen'), 'Remove duplicate numbers');
    expect(strings.known('Alle freien Seiten werden gebraucht'),
        'All free sides are needed');
    expect(strings.known('Ein gemeinsames Netz'), 'One connected network');
    expect(strings.known('Binärpuzzle'), 'Binairo');
    expect(strings.known('7 von 20 Rätseln gelöst'), '7 of 20 puzzles solved');
  });

  test('daily calendars, result badges and stored catalog data are English',
      () {
    const strings = AppLocalizations(Locale('en'));

    expect(strings.known('Heute bereits gelöst'), 'Already solved today');
    expect(strings.known('Tagesrätsel starten'), 'Start daily puzzle');
    expect(strings.known('Testabschluss · keine Statistik'),
        'Test completion · no statistics');
    expect(strings.known('Testabschluss · im Kalender gewertet'),
        'Test completion · counted in calendar');
    expect(strings.known('Rätsel 12'), 'Puzzle 12');
    expect(strings.known('Brückenweg 13'), 'Bridge path 13');
    expect(strings.known('Inselnetz 28'), 'Island network 28');
    expect(strings.known('Sanfte Kurven'), 'Gentle curves');
    expect(strings.known('Erster Überblick'), 'First overview');
    expect(strings.known('Mittel · 30 Grundwert + 10 ohne Hinweis'),
        'Medium · 30 base value + 10 without hints');
  });
}
