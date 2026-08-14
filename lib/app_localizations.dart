import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  bool get isEnglish => locale.languageCode == 'en';

  static const supportedLocales = [Locale('de'), Locale('en')];

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ??
      const AppLocalizations(Locale('de'));

  static Locale resolve(Locale? locale, Iterable<Locale> supported) =>
      locale?.languageCode == 'en' ? const Locale('en') : const Locale('de');

  String text(String german, String english) => isEnglish ? english : german;

  String known(String value) {
    if (!isEnglish) return value;
    const values = <String, String>{
      'Der Anfang ist gemacht': 'A good start',
      'Gut im Denken': 'Thinking clearly',
      'Nicht aufzuhalten': 'Unstoppable',
      'Hundertmal geknobelt': 'One hundred puzzles',
      'Ausdauernder Denker': 'Persistent thinker',
      'Logik gehört zum Alltag': 'Logic is a way of life',
      'Tausend Rätsel': 'One thousand puzzles',
      'Binairo entdeckt': 'Discovered Binairo',
      'Brückenbauer': 'Bridge builder',
      'Schleifenkünstler': 'Loop artist',
      'Ungleichungen gemeistert': 'Mastered inequalities',
      'Einzelgänger': 'Lone thinker',
      'Lager aufgeschlagen': 'Camp established',
      'Dranbleiben': 'Keep it going',
      'Eine ganze Woche': 'A full week',
      'Fester Bestandteil': 'A lasting habit',
      'Jeden Tag ein Rätsel': 'A puzzle every day',
      'Kalenderfreund': 'Calendar companion',
      'Freie Wahl': 'Freedom of choice',
      'Immer etwas Neues': 'Always something new',
      'Vielseitiger Denker': 'Versatile thinker',
      'Eine Stunde Logik': 'One hour of logic',
      'Zeit für klare Gedanken': 'Time for clear thoughts',
      'Alles gesehen': 'Seen it all',
      'Harte Nüsse': 'Tough nuts',
      'Großes Raster': 'Large grid',
      'Neue Herausforderung': 'New challenge',
      'Aus der Sammlung': 'From the collection',
      'Ganz ohne Hilfe': 'Without any help',
      'Doppelte Abwechslung': 'Double variety',
      'Heute dran': 'Today’s puzzle',
      'Dreimal Zeit zum Denken': 'Three moments to think',
      'Abwechslungsreiche Woche': 'A varied week',
      'Fünf klare Momente': 'Five clear moments',
      'Aus eigener Kraft': 'On your own',
      'Schwere Kost': 'A tough challenge',
      'Sammlung erkunden': 'Explore the collection',
      'Eigene Auswahl': 'Your own choice',
      'Regelmäßig dabei': 'A regular habit',
      'Erfolg freigeschaltet': 'Achievement unlocked',
      'Rätsel abgeschlossen': 'Puzzle completed',
      'Rätselsammlung': 'Puzzle collection',
      'Zufallsrätsel': 'Random puzzle',
      'Tagesrätsel': 'Daily puzzle',
      'Tagesrätsel & Kalender': 'Daily puzzle & calendar',
      'Rätsel fortsetzen': 'Continue puzzle',
      'Regeln ansehen': 'View rules',
      'Erste Herausforderung': 'First challenge',
      'Noch einmal spielen': 'Play again',
      'Nächstes ungelöstes Rätsel': 'Next unsolved puzzle',
      'Heute spielen oder vergangene Tage nachholen':
          'Play today or catch up on previous days',
      'Heute lösen oder verpasste Tage nachholen':
          'Solve today or catch up on missed days',
      'Größe und Schwierigkeit auswählen': 'Choose size and difficulty',
      'Schwierigkeit auswählen und neu erzeugen':
          'Choose a difficulty and generate a new puzzle',
      'Direkt mit deiner Sammlung weitermachen':
          'Continue straight from your collection',
      'Bestzeiten, Spielzeit und Fortschritt':
          'Best times, playtime and progress',
      'Bestzeiten, Spielzeit und Lösungswege':
          'Best times, playtime and solving paths',
      'Bestzeiten, Spielzeit und Expeditionen':
          'Best times, playtime and expeditions',
      'Bestzeiten, Spielarten und Schwierigkeiten':
          'Best times, game modes and difficulties',
      'Baue ein gemeinsames Brückennetz': 'Build one connected bridge network',
      'Verbinde alle Inseln zu einem einzigen Netz – ohne Kreuzungen.':
          'Connect all islands into one network — without crossings.',
      'Ein neues Brückennetz erzeugen lassen': 'Generate a new bridge network',
      'Eine einzige Schleife': 'One single loop',
      'Verbinde die Punkte zu einer geschlossenen Schleife. Die Zahlen zeigen, wie viele Feldseiten zur Linie gehören.':
          'Connect the dots into one closed loop. Each number shows how many sides of its cell belong to the line.',
      'Heute spielen oder vergangene Schleifen nachholen':
          'Play today or catch up on previous loops',
      'Finde die einzelnen Zahlen': 'Find the unique numbers',
      'Schwärze doppelte Zahlen. Schwarze Felder dürfen sich nicht berühren und alle hellen Felder bleiben verbunden.':
          'Shade duplicate numbers. Shaded cells may not touch, and all light cells must stay connected.',
      'Ungleich, aber logisch': 'Unequal, but logical',
      'Fülle jede Zeile und Spalte mit allen Zahlen. Jedes Ungleichheitszeichen muss stimmen.':
          'Fill every row and column with all numbers. Every inequality sign must be correct.',
      'Plane ein ruhiges Waldlager': 'Plan a peaceful forest camp',
      'Ordne jedem Baum genau ein Zelt zu. Jeder Start erzeugt ein neues, eindeutig lösbares Brett.':
          'Assign exactly one tent to every tree. Each start creates a new puzzle with a unique solution.',
      'Zwei Zahlen, klare Regeln': 'Two numbers, clear rules',
      'Setze 0 und 1 so, dass jede Reihe und Spalte aufgeht – ohne Dreiergruppen oder gleiche Reihen.':
          'Place 0 and 1 so every row and column works — without triples or identical rows.',
      'Deine Rätselsammlung': 'Your puzzle collection',
      'Wähle die Schwierigkeit, die heute zu dir passt.':
          'Choose the difficulty that suits you today.',
      'Zeichne genau eine geschlossene Schleife.':
          'Draw exactly one closed loop.',
      'Die Linie verläuft nur waagerecht oder senkrecht zwischen den Punkten.':
          'The line runs only horizontally or vertically between the dots.',
      'Eine Zahl zeigt, wie viele ihrer vier Feldseiten Teil der Schleife sind.':
          'A number shows how many of its four cell sides are part of the loop.',
      'Die Linie darf sich nicht verzweigen oder kreuzen und muss eine einzige Schleife bilden.':
          'The line may not branch or cross and must form one single loop.',
      'Tippen wechselt eine Kante von leer zu Linie, zu ausgeschlossen und wieder zu leer.':
          'Tap an edge to cycle from empty to line, excluded, and back to empty.',
      'Fülle das Raster mit logisch passenden Zahlen.':
          'Fill the grid with logically fitting numbers.',
      'Jede Zahl von 1 bis zur Rastergröße kommt in jeder Zeile genau einmal vor.':
          'Every number from 1 to the grid size appears exactly once in each row.',
      'Auch in jeder Spalte darf jede Zahl nur einmal vorkommen.':
          'Each number may also appear only once in every column.',
      'Alle Ungleichheitszeichen zwischen benachbarten Feldern müssen stimmen.':
          'All inequality signs between adjacent cells must be satisfied.',
      'Tippe ein Feld und wähle eine Zahl. Notizen helfen beim Ausschließen.':
          'Tap a cell and choose a number. Notes help with elimination.',
      'Bilde eindeutige Paare aus jeweils einem Baum und einem Zelt.':
          'Form unique pairs of one tree and one tent.',
      'Jeder Baum erhält genau ein Zelt auf einem direkt waagerecht oder senkrecht benachbarten Feld.':
          'Every tree gets exactly one tent in a directly adjacent horizontal or vertical cell.',
      'Jedes Zelt gehört genau zu einem Baum. Zelte dürfen sich auch diagonal nicht berühren.':
          'Every tent belongs to exactly one tree. Tents may not touch, even diagonally.',
      'Die Zahlen am Rand geben die genaue Zahl der Zelte in jeder Zeile und Spalte an.':
          'The edge numbers give the exact number of tents in each row and column.',
      'Tippen wechselt ein freies Feld von leer zu Zelt, zu Gras und wieder zu leer.':
          'Tap a free cell to cycle from empty to tent, grass, and back to empty.',
      'Ereignisrätsel': 'Event puzzle',
      'Einführung': 'Introduction',
      'Einmaliger Erfolgsbonus': 'One-time achievement bonus',
      'Abschlussbonus': 'Completion bonus',
      'Bereits gewertetes Tagesrätsel': 'Daily puzzle already counted',
      'Wiederholungsbonus': 'Replay bonus',
      'Zelte & Bäume': 'Tents & Trees',
      'Leicht': 'Easy',
      'Mittel': 'Medium',
      'Schwer': 'Hard',
      'Statistik': 'Statistics',
      'Rätsel': 'Puzzles',
      'Sammlung': 'Collection',
      'Sammlungsmodus': 'Collection mode',
      'Tagesmodus': 'Daily mode',
      'Spielzeit': 'Playtime',
      'Gesamte Spielzeit': 'Total playtime',
      'Bestzeit': 'Best time',
      'Durchschnitt': 'Average',
      'Bestzeit ohne Hilfe': 'Best time without help',
      'Ohne Hinweise': 'Without hints',
      'Ohne Hinweise*': 'Without hints*',
      'Hinweise': 'Hints',
      'Hinweise genutzt': 'Hints used',
      'Bonus-Hinweise': 'Bonus hints',
      'Wenigste Züge': 'Fewest moves',
      'Aktive Tage': 'Active days',
      'Alle Statistiken': 'All statistics',
      'Logiklegende': 'Logic legend',
      'Meisterdenker': 'Master thinker',
      'Rätselstratege': 'Puzzle strategist',
      'Logiktalent': 'Logic talent',
      'Musterfinder': 'Pattern finder',
      'Logikfreund': 'Logic friend',
      'Neugieriger Denker': 'Curious thinker',
      'Harte Kost': 'Tough challenge',
      'Schwere Denkarbeit': 'Serious thinking',
      'Meister der Schwierigkeit': 'Master of difficulty',
      'Unerschrockener Denker': 'Fearless thinker',
      'Keine Nuss zu hart': 'No puzzle too hard',
      'Ohne Stützräder': 'Without training wheels',
      'Sicherer Blick': 'A confident eye',
      'Ganz aus eigener Kraft': 'Entirely on your own',
      'Unabhängiger Kopf': 'Independent thinker',
      'Sicher aus Erfahrung': 'Confidence through experience',
      'Hundert Tage Logik': 'One hundred days of logic',
      'Halbes Kalenderjahr': 'Half a calendar year',
      'Ein Jahr Tagesrätsel': 'One year of daily puzzles',
      'Zwei Jahre Tagesrätsel': 'Two years of daily puzzles',
      'Tausend Tage Logik': 'One thousand days of logic',
      'Fünfzig Stunden Logik': 'Fifty hours of logic',
      'Hundert Stunden Fokus': 'One hundred hours of focus',
      'Logik als Leidenschaft': 'A passion for logic',
      'Fünfhundert Stunden Fokus': 'Five hundred hours of focus',
      'Tausend Stunden Logik': 'One thousand hours of logic',
      'Löse dein erstes Rätsel.': 'Solve your first puzzle.',
      'Löse dein erstes Binairo-Rätsel.': 'Solve your first Binairo puzzle.',
      'Vollende dein erstes Hashi-Rätsel.': 'Complete your first Hashi puzzle.',
      'Vollende dein erstes Slitherlink-Rätsel.':
          'Complete your first Slitherlink puzzle.',
      'Vollende dein erstes Futoshiki-Rätsel.':
          'Complete your first Futoshiki puzzle.',
      'Vollende dein erstes Hitori-Rätsel.':
          'Complete your first Hitori puzzle.',
      'Vollende dein erstes Zelte-&-Bäume-Rätsel.':
          'Complete your first Tents & Trees puzzle.',
      'Spiele an 3 Tagen in Folge.': 'Play on 3 consecutive days.',
      'Spiele an 7 Tagen in Folge.': 'Play on 7 consecutive days.',
      'Spiele an 30 Tagen in Folge.': 'Play on 30 consecutive days.',
      'Löse mindestens ein Rätsel in jeder Spielart.':
          'Solve at least one puzzle in every game type.',
      'Verbringe insgesamt eine Stunde beim Rätseln.':
          'Spend a total of one hour solving puzzles.',
      'Verbringe insgesamt zehn Stunden beim Rätseln.':
          'Spend a total of ten hours solving puzzles.',
      'Löse jedes Rätsel der Sammlung.':
          'Solve every puzzle in the collection.',
      'Löse heute ein frei erzeugtes Rätsel.':
          'Solve a generated puzzle today.',
      'Löse heute ein Rätsel aus der Sammlung.':
          'Solve a collection puzzle today.',
      'Löse heute ein Rätsel ohne Hinweis.':
          'Solve a puzzle without a hint today.',
      'Löse heute zwei verschiedene Spielarten.':
          'Solve two different game types today.',
      'Löse das heutige Tagesrätsel.': 'Solve today’s daily puzzle.',
      'Löse diese Woche drei verschiedene Spielarten.':
          'Solve three different game types this week.',
      'Löse diese Woche fünf Rätsel.': 'Solve five puzzles this week.',
      'Löse diese Woche drei Rätsel ohne Hinweis.':
          'Solve three puzzles without a hint this week.',
      'Löse diese Woche zwei schwere Rätsel.':
          'Solve two hard puzzles this week.',
    };
    final direct = values[value];
    if (direct != null) return direct;
    return value
        .replaceAll('Zelte & Bäume', 'Tents & Trees')
        .replaceAll('Sammlung erkunden', 'Explore the collection')
        .replaceAll('Eigene Auswahl', 'Your own choice')
        .replaceAll('Regelmäßig dabei', 'A regular habit')
        .replaceAll(' · Vertraut', ' · Familiar')
        .replaceAll(' · Erfahren', ' · Experienced')
        .replaceAll(' · Meisterlich', ' · Masterful')
        .replaceAll(' · Spezialist', ' · Specialist')
        .replaceAll(' · Legende', ' · Legend')
        .replaceAll(' · Stufe ', ' · Level ')
        .replaceAllMapped(RegExp(r'^Löse (\d+) Rätsel\.$'),
            (match) => 'Solve ${match[1]} puzzles.')
        .replaceAllMapped(RegExp(r'^Löse (\d+) schwere Rätsel\.$'),
            (match) => 'Solve ${match[1]} hard puzzles.')
        .replaceAllMapped(RegExp(r'^Löse (\d+) Rätsel ohne Hinweis\.$'),
            (match) => 'Solve ${match[1]} puzzles without a hint.')
        .replaceAllMapped(RegExp(r'^Löse (\d+) Tagesrätsel\.$'),
            (match) => 'Solve ${match[1]} daily puzzles.')
        .replaceAllMapped(RegExp(r'^Löse (\d+) frei erzeugte Rätsel\.$'),
            (match) => 'Solve ${match[1]} generated puzzles.')
        .replaceAllMapped(
            RegExp(r'^Löse (\d+) verschiedene Rätsel aus der Sammlung\.$'),
            (match) =>
                'Solve ${match[1]} different puzzles from the collection.')
        .replaceAllMapped(
            RegExp(
                r'^Spiele an (\d+) verschiedenen Tagen – ohne Seriendruck\.$'),
            (match) =>
                'Play on ${match[1]} different days — without streak pressure.')
        .replaceAllMapped(
            RegExp(r'^Verbringe insgesamt (\d+) Stunden beim Rätseln\.$'),
            (match) => 'Spend a total of ${match[1]} hours solving puzzles.')
        .replaceAllMapped(RegExp(r'^Löse (\d+) (.+)-Rätsel\.$'),
            (match) => 'Solve ${match[1]} ${match[2]} puzzles.')
        .replaceAllMapped(RegExp(r'^(\d+) abgeschlossen$'),
            (match) => '${match[1]} completed')
        .replaceAllMapped(RegExp(r'^(\d+) Rätsel abgeschlossen$'),
            (match) => '${match[1]} puzzles completed')
        .replaceAllMapped(RegExp(r'^(\d+) von (\d+) gelöst$'),
            (match) => '${match[1]} of ${match[2]} solved')
        .replaceAllMapped(RegExp(r'^(\d+) von (\d+) Rätseln gelöst$'),
            (match) => '${match[1]} of ${match[2]} puzzles solved')
        .replaceAllMapped(RegExp(r'^(\d+) von (\d+) Expeditionen gelöst$'),
            (match) => '${match[1]} of ${match[2]} expeditions solved')
        .replaceAllMapped(
            RegExp(r'^(\d+) handverlesene Brückennetze entdecken$'),
            (match) => 'Explore ${match[1]} hand-picked bridge networks')
        .replaceAllMapped(RegExp(r'^(\d+) handverlesene Hitori-Rätsel$'),
            (match) => '${match[1]} hand-picked Hitori puzzles')
        .replaceAllMapped(RegExp(r'^(\d+) eindeutig lösbare Schleifen$'),
            (match) => '${match[1]} uniquely solvable loops')
        .replaceAllMapped(RegExp(r'^(\d+) feste Expeditionen entdecken$'),
            (match) => 'Explore ${match[1]} fixed expeditions')
        .replaceAllMapped(RegExp(r'^(\d+) ausgewählte Lern- und Logikrätsel$'),
            (match) => '${match[1]} selected learning and logic puzzles')
        .replaceAllMapped(RegExp(r'^(\d+) Tage Spielserie$'),
            (match) => '${match[1]} day streak')
        .replaceAllMapped(RegExp(r'^Heute gelöst · (\d+) insgesamt$'),
            (match) => 'Solved today · ${match[1]} total')
        .replaceAllMapped(RegExp(r'^Heute noch offen · (\d+) insgesamt$'),
            (match) => 'Still open today · ${match[1]} total')
        .replaceAllMapped(
            RegExp(r'^Bestzeit (.+)$'), (match) => 'Best time ${match[1]}')
        .replaceAll('Rätselsammlung', 'Puzzle collection')
        .replaceAll('Zufallsrätsel', 'Random puzzle')
        .replaceAll('Tagesrätsel', 'Daily puzzle');
  }

  String plural(int count, String germanOne, String germanMany,
          String englishOne, String englishMany) =>
      isEnglish
          ? (count == 1 ? englishOne : englishMany)
          : (count == 1 ? germanOne : germanMany);
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'de' || locale.languageCode == 'en';

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale));

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get strings => AppLocalizations.of(this);
}
