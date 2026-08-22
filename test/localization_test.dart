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
    expect(find.text('Monthly goals: 0 of 3'), findsOneWidget);
    expect(find.text('View progress'), findsOneWidget);
    expect(find.text('Progress & achievements'), findsOneWidget);
    expect(
      find.text('Arrange zeros and ones through clear logic'),
      findsOneWidget,
    );
    expect(find.textContaining('of 80 puzzles solved'), findsNothing);
    expect(find.byTooltip('Settings'), findsOneWidget);

    await tester.tap(find.textContaining('Level 1 ·'));
    await tester.pumpAndSettle();
    expect(find.text('Your progress'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Your records'), findsWidgets);
    expect(find.text('Played'), findsOneWidget);
    expect(find.text('Frozen'), findsOneWidget);
    expect(find.text('Monthly goals: 0 of 3'), findsOneWidget);
    expect(find.textContaining('That is 450 XP in total.'), findsOneWidget);
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
    expect(strings.known('Anspruchsvoller Monat'), 'A challenging month');
    expect(strings.known('Tagesrätsel im Blick'), 'Daily puzzles in focus');
    expect(
      strings.known('Löse diesen Monat acht Rätsel ohne Hinweis.'),
      'Solve eight puzzles without hints this month.',
    );
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

  test('remaining level, statistics and Hitori catalog terms are English', () {
    const strings = AppLocalizations(Locale('en'));

    expect(strings.known('Logiktalent'), 'Logic talent');
    expect(strings.known('Hashi-Statistik'), 'Hashi statistics');
    expect(strings.known('Schwarze Felder und helle Wege gemeinsam planen'),
        'Plan shaded cells and open paths together');
    expect(strings.known('Erste Schatten'), 'First shadows');
    expect(strings.known('Neue Verbindungen'), 'New connections');
    expect(strings.known('Heller Korridor'), 'Open corridor');
    expect(strings.known('Verbundene Wege'), 'Connected paths');
    expect(strings.known('Tausend Tage am Ball'),
        'One thousand days going strong');
    expect(strings.known('Spiele an 1000 Tagen in Folge.'),
        'Play on 1000 consecutive days.');
  });
}
