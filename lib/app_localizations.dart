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
      'Noch eins': 'Another one',
      'Zur Sammlung': 'Back to collection',
      'Nächstes Rätsel': 'Next puzzle',
      'Nächstes Kapitel': 'Next chapter',
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
      'Doppelte Zahlen entfernen': 'Remove duplicate numbers',
      'In jeder Zeile und Spalte darf jede Zahl nur einmal hell bleiben.':
          'In each row and column, each number may remain light only once.',
      'Schwarze Felder trennen': 'Keep shaded cells apart',
      'Zwei schwarze Felder dürfen sich niemals oben, unten, links oder rechts berühren.':
          'Two shaded cells may never touch above, below, left or right.',
      'Helle Fläche verbinden': 'Connect the light area',
      'Alle hell gebliebenen Felder müssen einen einzigen zusammenhängenden Bereich bilden.':
          'All remaining light cells must form one connected area.',
      'Experte': 'Expert',
      'Große Raster für erfahrene Futoshiki-Fans':
          'Large grids for experienced Futoshiki fans',
      'Grundlagen': 'Fundamentals',
      'Sichere Vergleiche': 'Reliable comparisons',
      'Komplexe Beziehungen': 'Complex relationships',
      'Expertenraster': 'Expert grids',
      'Feld auswählen und unten eine Zahl setzen. Im Notizmodus kannst du Kandidaten vormerken.':
          'Select a cell and enter a number below. In notes mode, you can mark candidates.',
      'Jede Zahl kommt in jeder Zeile genau einmal vor.':
          'Every number appears exactly once in each row.',
      'Jede Zahl kommt in jeder Spalte genau einmal vor.':
          'Every number appears exactly once in each column.',
      'Das Ungleichheitszeichen zeigt stets zur kleineren Zahl.':
          'The inequality sign always points to the smaller number.',
      'Fülle das Raster mit Zahlen und beachte alle Ungleichheiten.':
          'Fill the grid with numbers and observe all inequalities.',
      'Wähle ein Feld und danach eine Zahl. Im Notizmodus kannst du mehrere Kandidaten eintragen.':
          'Select a cell and then a number. In notes mode, you can enter multiple candidates.',
      'Sicherer nächster Schritt': 'Safe next step',
      'Aus der aktuellen Stellung lässt sich hier ein sicherer Schritt ableiten.':
          'A safe step can be deduced here from the current position.',
      'Zahl bereits erfüllt': 'Number already satisfied',
      'Alle freien Seiten werden gebraucht': 'All free sides are needed',
      'Hashi verlassen': 'Leave Hashi',
      'Brücke entfernt': 'Bridge removed',
      'Doppelte Brücke': 'Double bridge',
      'Brücke gesetzt': 'Bridge placed',
      'Kein weiterer Tipp nötig': 'No further hint needed',
      'Eine passende Brücke wurde ergänzt': 'A suitable bridge was added',
      'Tippe eine Insel an oder ziehe direkt zur Zielinsel.':
          'Tap an island or drag directly to the target island.',
      'Wähle eine leuchtende Zielinsel.': 'Choose a highlighted target island.',
      'Brücken bauen': 'Building bridges',
      'Netze planen': 'Planning networks',
      'Inselmeister': 'Island master',
      'Klare Verbindungen und kleine Inselgruppen':
          'Clear connections and small island groups',
      'Mehrere Wege und größere zusammenhängende Netze':
          'Multiple paths and larger connected networks',
      'Komplexe Abhängigkeiten und anspruchsvolle Brückennetze':
          'Complex dependencies and challenging bridge networks',
      'Inseln verbinden': 'Connect islands',
      'Verbinde Inseln, die sich in derselben Zeile oder Spalte direkt sehen können.':
          'Connect islands that can see each other directly in the same row or column.',
      'Zahlen erfüllen': 'Satisfy the numbers',
      'Die Zahl einer Insel entspricht der Summe aller einfachen und doppelten Brücken an dieser Insel.':
          'An island’s number equals the total of all single and double bridges connected to it.',
      'Keine Kreuzungen': 'No crossings',
      'Brücken verlaufen waagerecht oder senkrecht. Sie dürfen weder Inseln durchqueren noch andere Brücken kreuzen.':
          'Bridges run horizontally or vertically. They may not pass through islands or cross other bridges.',
      'Brücken korrigieren': 'Correct bridges',
      'Wähle dieselben zwei Inseln erneut: eine, zwei, keine Brücke. Eine gesetzte Brücke kannst du außerdem direkt antippen, um sie zu entfernen.':
          'Choose the same two islands again: one, two, no bridge. You can also tap a placed bridge directly to remove it.',
      'Ein gemeinsames Netz': 'One connected network',
      'Alle Inseln müssen miteinander verbunden sein. Mehrere getrennte Gruppen sind keine gültige Lösung.':
          'All islands must be connected. Multiple separate groups are not a valid solution.',
      'Binärpuzzle': 'Binairo',
      'Wähle ein handverlesenes Rätsel': 'Choose a hand-picked puzzle',
      'Erstelle ein neues Rätsel nach deinen Wünschen':
          'Create a new puzzle to your preferences',
      'Fülle das Raster ausschließlich mit 0 und 1.':
          'Fill the grid using only 0 and 1.',
      'In jeder Zeile und Spalte stehen gleich viele Nullen und Einsen.':
          'Every row and column contains the same number of zeros and ones.',
      'Nie dürfen drei gleiche Zahlen direkt nebeneinander oder untereinander stehen.':
          'Three identical numbers may never appear directly beside or below one another.',
      'Keine zwei vollständigen Zeilen oder Spalten dürfen identisch sein.':
          'No two complete rows or columns may be identical.',
      'Tippen wechselt ein freies Feld von leer zu 0, zu 1 und wieder zu leer.':
          'Tap a free cell to cycle from empty to 0, 1, and back to empty.',
      'Setze 0 und 1 nach drei klaren Regeln.':
          'Place 0 and 1 according to three clear rules.',
      'Nie dürfen drei gleiche Zahlen direkt nebeneinander stehen.':
          'Three identical numbers may never appear directly next to one another.',
      'Keine zwei Zeilen oder Spalten dürfen identisch sein.':
          'No two rows or columns may be identical.',
      'Tippe ein freies Feld: leer → 0 → 1.': 'Tap a free cell: empty → 0 → 1.',
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
      'Ruhiger Einstieg': 'Gentle introduction',
      'Mehrere Schritte vorausdenken': 'Think several steps ahead',
      'Für erfahrene Rätselfans': 'For experienced puzzle fans',
      'Statistik': 'Statistics',
      'Rätsel': 'Puzzles',
      'Sammlung': 'Collection',
      'Sammlungsmodus': 'Collection mode',
      'Tagesmodus': 'Daily mode',
      'Spielzeit': 'Playtime',
      'Gesamte Spielzeit': 'Total playtime',
      'Bestzeit': 'Best time',
      'Schwierigkeit': 'Difficulty',
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
      'Heute bereits gelöst': 'Already solved today',
      'Dein heutiges Rätsel wartet': 'Today’s puzzle is waiting',
      'Gelöstes Brett ansehen': 'View solved board',
      'Tagesrätsel starten': 'Start daily puzzle',
      'Gelöst': 'Solved',
      'Offen': 'Open',
      'Heute': 'Today',
      'Testabschluss · keine Statistik': 'Test completion · no statistics',
      'Testabschluss · im Kalender gewertet':
          'Test completion · counted in calendar',
      'Zum Kalender': 'To calendar',
      'Fast lösen': 'Almost solve',
      'Sofort lösen': 'Solve instantly',
      'Vorgaben': 'Clues',
      'Gesamt': 'Total',
      'Insgesamt': 'Total',
      'Gesamt gelöst': 'Solved',
      'Grundlinien': 'Foundations',
      'Erste Ecken': 'First corners',
      'Kleine Runde': 'Small loop',
      'Sanfte Kurven': 'Gentle curves',
      'Am Rand entlang': 'Along the edge',
      'Kurven lesen': 'Reading curves',
      'Klare Spuren': 'Clear tracks',
      'Ruhige Runde': 'Calm loop',
      'Klare Kanten': 'Clear edges',
      'Sanfter Umweg': 'Gentle detour',
      'Sichere Kurve': 'Safe curve',
      'Verdeckte Wege': 'Hidden paths',
      'Verdeckter Weg': 'Hidden path',
      'Zwischen den Zahlen': 'Between the numbers',
      'Geteilte Spuren': 'Split tracks',
      'Die erste Schleife': 'The first loop',
      'Interaktive Einführung': 'Interactive introduction',
      'Erste Brücken': 'First bridges',
      'Zwei Ufer': 'Two shores',
      'Mittelpunkt': 'Center point',
      'Inselring': 'Island ring',
      'Neun Inseln': 'Nine islands',
      'Fundamentals': 'Fundamentals',
      'Erste Vergleiche': 'First comparisons',
      'Klare Reihen': 'Clear rows',
      'Kleine Ketten': 'Small chains',
      'Sicher eingeordnet': 'Safely ordered',
      'Zahlenspiel': 'Number game',
      'Enger Rahmen': 'Tight frame',
      'Logische Ordnung': 'Logical order',
      'Kombinationen': 'Combinations',
      'Fortgeschrittene Muster': 'Advanced patterns',
      'Direkte Regeln und kompakte Raster': 'Direct rules and compact grids',
      'Mehrere Schlüsse über Zeilen und Spalten':
          'Combine deductions across rows and columns',
      'Größere Raster und anspruchsvollere Muster':
          'Larger grids and more challenging patterns',
      'Grundwert': 'Base value',
      'ohne Hinweis': 'without hints',
      'Zeit': 'Time',
      'Vorherige': 'Previous',
      'Felder': 'cells',
      'Ecken, Ränder und sichere erste Schritte':
          'Corners, edges, and safe first steps',
      'Hinweise verbinden und Wege ausschließen':
          'Connect clues and rule out paths',
      'Sichere Schleifen': 'Safe loops',
      'Das Gelernte selbstständig anwenden':
          'Apply what you have learned independently',
      'Neue Runden': 'New loops',
      'Weitere ruhige Schleifen sicher schließen':
          'Safely complete more calm loops',
      'Mehrere Hinweise gemeinsam betrachten':
          'Consider multiple clues together',
      'Wendepunkte': 'Turning points',
      'Längere Schlussketten sicher verfolgen':
          'Follow longer chains of deductions safely',
      'Kombinierte Logik': 'Combined logic',
      'Verschiedene Muster geschickt verbinden':
          'Combine different patterns skillfully',
      'Neue Verläufe': 'New paths',
      'Zusätzliche Schleifen mit Ausdauer verfolgen':
          'Follow additional loops with persistence',
      'Wenige Spuren': 'Sparse tracks',
      'Mit sparsamen Vorgaben Orientierung finden':
          'Find your way with sparse clues',
      'Tiefe Schlüsse': 'Deep deductions',
      'Entscheidungen über mehrere Schritte absichern':
          'Confirm decisions across several steps',
      'Meisterschleifen': 'Master loops',
      'Die anspruchsvollsten Netze der Sammlung':
          'The collection’s most challenging networks',
      'Letzte Prüfungen': 'Final trials',
      'Neue sparsame Hinweise vollständig verbinden':
          'Fully connect new sparse clues',
      'Doppelte Kante': 'Double edge',
      'Brückenleiter': 'Bridge ladder',
      'Doppelkreuz': 'Double crossing',
      'Der Rahmen': 'The frame',
      'Dichter Nebel': 'Dense fog',
      'Doppelte Ecke': 'Double corner',
      'Enge Entscheidung': 'Tight decision',
      'Enge Kurven': 'Tight curves',
      'Falsche Fährten': 'False trails',
      'Finale Schleife': 'Final loop',
      'Freie Passage': 'Open passage',
      'Geschlossene Fährte': 'Closed trail',
      'Geteilte Wege': 'Split paths',
      'Große Prüfung': 'Great trial',
      'Helle Spur': 'Bright trail',
      'Im Gleichgewicht': 'In balance',
      'Knappe Entscheidung': 'Close decision',
      'Kombinierte Runde': 'Combined loop',
      'Kreuz und quer': 'Crisscross',
      'Kurzer Umweg': 'Short detour',
      'Langer Gedanke': 'Long thought',
      'Langer Umweg': 'Long detour',
      'Langer Wendepunkt': 'Long turning point',
      'Leichte Schleife': 'Easy loop',
      'Letzte Hinweise': 'Final clues',
      'Letzte Meisterrunde': 'Final master loop',
      'Letzte Übung': 'Final exercise',
      'Meisterhafte Kurven': 'Masterful curves',
      'Meisterhafte Windung': 'Masterful twist',
      'Meisterschleife': 'Master loop',
      'Offene Hinweise': 'Open clues',
      'Ohne Umweg': 'Without a detour',
      'Raffinierte Kurven': 'Clever curves',
      'Ruhiger Pfad': 'Calm path',
      'Runder Abschluss': 'A rounded finish',
      'Schmale Passage': 'Narrow passage',
      'Schmale Pfade': 'Narrow paths',
      'Schwierige Balance': 'Difficult balance',
      'Sicher herum': 'Safely around',
      'Sicher kombiniert': 'Safely combined',
      'Sparsame Hinweise': 'Sparse clues',
      'Täuschende Kreuzung': 'Deceptive crossing',
      'Tiefe Abzweigung': 'Deep branch',
      'Tiefe Schleife': 'Deep loop',
      'Unerwartete Wende': 'Unexpected turn',
      'Verborgene Schleife': 'Hidden loop',
      'Verborgener Verlauf': 'Hidden course',
      'Verdeckter Bogen': 'Hidden arc',
      'Versetzte Spuren': 'Offset tracks',
      'Verwobene Kanten': 'Interwoven edges',
      'Viele Möglichkeiten': 'Many possibilities',
      'Vier Tore': 'Four gates',
      'Weite Schleife': 'Wide loop',
      'Große Herausforderungen': 'Great challenges',
      'Längere logische Ketten sicher erkennen':
          'Recognize longer logical chains reliably',
      'Wenige Vorgaben und komplexe Abhängigkeiten':
          'Few clues and complex dependencies',
      'Die anspruchsvollsten Rätsel der Sammlung':
          'The collection’s most challenging puzzles',
      'Verknüpfte Zahlen': 'Linked numbers',
      'Große Vergleiche': 'Large comparisons',
      'Weite Schlüsse': 'Far-reaching deductions',
      'Meisterprüfung': 'Master trial',
      'Verdecktes Gefälle': 'Hidden inequality',
      'Großer Zusammenhang': 'The big picture',
      'Große Zahlenwege': 'Large number paths',
      'Enges Gefälle': 'Tight inequality',
      'Doppelte entdecken': 'Spot duplicates',
      'Eindeutige Zahlenpaare sicher auflösen':
          'Resolve unique number pairs reliably',
      'Erster Überblick': 'First overview',
      'Klare Fläche': 'Clear area',
      'Flächen sichern': 'Secure areas',
      'Stabile Fläche': 'Stable area',
      'Mittlere Prüfung': 'Intermediate trial',
      'Geordnete Fläche': 'Ordered area',
      'Versetzte Fläche': 'Offset area',
      'Mehrere Bedingungen über das ganze Raster kombinieren':
          'Combine multiple conditions across the entire grid',
      'Verborgene Brücke': 'Hidden bridge',
      'Verdeckte Fläche': 'Hidden area',
      'Viele Abhängigkeiten': 'Many dependencies',
      'Meister der Flächen': 'Master of areas',
      'Tiefe Flächenlogik': 'Deep area logic',
      'Meisterhafte Fläche': 'Masterful area',
      'Schwarze Felder und helle Wege gemeinsam planen':
          'Plan shaded cells and open paths together',
      'Erste Schatten': 'First shadows',
      'Klares Paar': 'Clear pair',
      'Ruhige Reihen': 'Calm rows',
      'Einzelne Spur': 'Single path',
      'Sicherer Abstand': 'Safe distance',
      'Helle Nachbarn': 'Open neighbors',
      'Doppelt gesehen': 'Seeing double',
      'Freie Mitte': 'Open center',
      'Saubere Trennung': 'Clean separation',
      'Neue Doppelspur': 'New double track',
      'Heller Rand': 'Open edge',
      'Ruhige Mitte': 'Calm center',
      'Getrennte Paare': 'Separated pairs',
      'Neue Lichtung': 'New clearing',
      'Ruhiger Winkel': 'Calm corner',
      'Freie Reihe': 'Open row',
      'Sanfte Trennung': 'Gentle separation',
      'Sicheres Muster': 'Safe pattern',
      'Offene Zahlenreihe': 'Open number row',
      'Sanfter Durchgang': 'Gentle passage',
      'Klarer Abschluss': 'Clear finish',
      'Neue Verbindungen': 'New connections',
      'Versetzte Paare': 'Offset pairs',
      'Heller Korridor': 'Open corridor',
      'Geteilte Zeile': 'Split row',
      'Sichere Inseln': 'Safe islands',
      'Verdeckte Ordnung': 'Hidden order',
      'Rund um die Mitte': 'Around the center',
      'Zwei Richtungen': 'Two directions',
      'Verborgener Korridor': 'Hidden corridor',
      'Drei sichere Wege': 'Three safe paths',
      'Schwarze Grenzen': 'Shaded boundaries',
      'Offene Verbindung': 'Open connection',
      'Versetzter Korridor': 'Offset corridor',
      'Doppelte Kreuzung': 'Double crossing',
      'Helle Umgehung': 'Open detour',
      'Sicher verbunden': 'Safely connected',
      'Heller Seitenweg': 'Open side path',
      'Geordnete Kreuzung': 'Ordered crossing',
      'Mittlerer Abschluss': 'Intermediate finish',
      'Verbundene Wege': 'Connected paths',
      'Dichte Spuren': 'Dense tracks',
      'Langer Zusammenhang': 'Long connection',
      'Knappe Wege': 'Tight paths',
      'Tiefe Entscheidung': 'Deep decision',
      'Mehrfach gedacht': 'Multiple deductions',
      'Letzte Sicherheit': 'Final certainty',
      'Dichtes Zahlenfeld': 'Dense number field',
      'Schmale Verbindung': 'Narrow connection',
      'Langer heller Weg': 'Long open path',
      'Schwarze Strategie': 'Shaded strategy',
      'Dichtes Wegenetz': 'Dense path network',
      'Verborgene Passage': 'Hidden passage',
      'Knapper Zusammenhang': 'Tight connection',
      'Letzte Verbindung': 'Final connection',
      'Verflochtene Schatten': 'Interwoven shadows',
      'Enger heller Pfad': 'Narrow open path',
      'Finaler Zusammenhang': 'Final connection',
      'Hashi-Statistik': 'Hashi statistics',
      'Zwei Monate am Ball': 'Two months going strong',
      'Hundert Tage Fokus': 'One hundred days of focus',
      'Ein Jahr Spielserie': 'A one-year streak',
      'Zwei Jahre Spielserie': 'A two-year streak',
      'Tausend Tage am Ball': 'One thousand days going strong',
      'Ordne jedem Baum genau ein Zelt zu.':
          'Assign exactly one tent to every tree.',
      'Ein Zelt steht direkt waagerecht oder senkrecht neben seinem Baum.':
          'A tent stands directly horizontally or vertically beside its tree.',
      'Alle Bäume und Zelte müssen sich zu eindeutigen 1:1-Paaren verbinden lassen.':
          'All trees and tents must form unique one-to-one pairs.',
      'Zelte dürfen sich weder seitlich noch diagonal berühren.':
          'Tents may not touch, either orthogonally or diagonally.',
      'Die Randzahlen nennen die Zelte pro Zeile und Spalte.':
          'The edge numbers show the tents in each row and column.',
      'Tippe ein Feld: leer → Zelt → Gras. Gras ist eine freiwillige Ausschlussnotiz.':
          'Tap a cell: empty → tent → grass. Grass is an optional exclusion mark.',
    };
    final direct = values[value];
    if (direct != null) return direct;
    return value
        .replaceAll('Zelte & Bäume', 'Tents & Trees')
        .replaceAll('Leicht ·', 'Easy ·')
        .replaceAll('Mittel ·', 'Medium ·')
        .replaceAll('Schwer ·', 'Hard ·')
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
        .replaceAllMapped(RegExp(r'^Spiele an (\d+) Tagen in Folge\.$'),
            (match) => 'Play on ${match[1]} consecutive days.')
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
        .replaceAllMapped(RegExp(r'^(\d+) von (\d+) geschafft$'),
            (match) => '${match[1]} of ${match[2]} completed')
        .replaceAllMapped(
            RegExp(r'^Rätsel (\d+)$'), (match) => 'Puzzle ${match[1]}')
        .replaceAllMapped(
            RegExp(r'^Brückenweg (\d+)$'), (match) => 'Bridge path ${match[1]}')
        .replaceAllMapped(RegExp(r'^Inselnetz (\d+)$'),
            (match) => 'Island network ${match[1]}')
        .replaceAllMapped(RegExp(r'^Meisterbrücken (\d+)$'),
            (match) => 'Master bridges ${match[1]}')
        .replaceAllMapped(RegExp(r'^(\d+)/(\d+) Inseln$'),
            (match) => '${match[1]}/${match[2]} islands')
        .replaceAllMapped(
            RegExp(r'^(\d+) Inseln$'), (match) => '${match[1]} islands')
        .replaceAllMapped(
            RegExp(r'^(\d+) gesamt$'), (match) => '${match[1]} total')
        .replaceAllMapped(
            RegExp(r'^(\d+) Vorgaben$'), (match) => '${match[1]} clues')
        .replaceAllMapped(RegExp(r'^(.+) · Rätselsammlung$'),
            (match) => '${known(match[1]!)} · Puzzle collection')
        .replaceAllMapped(RegExp(r'^(.+) · (\d+) Vorgaben$'),
            (match) => '${match[1]} · ${match[2]} clues')
        .replaceAllMapped(RegExp(r'^(.+) · (\d+) Inseln$'),
            (match) => '${match[1]} · ${match[2]} islands')
        .replaceAllMapped(RegExp(r'^(.+) · (\d+) islands$'),
            (match) => '${match[1]} · ${match[2]} islands')
        .replaceAllMapped(RegExp(r'^(.+) · (\d+) XP Grundwert$'),
            (match) => '${known(match[1]!)} · ${match[2]} XP base value')
        .replaceAllMapped(
            RegExp(r'^(.+) · (\d+) Grundwert \+ 10 ohne Hinweis$'),
            (match) =>
                '${known(match[1]!)} · ${match[2]} base value + 10 without hints')
        .replaceAllMapped(RegExp(r'^(.+) · Kapitel (\d+)$'),
            (match) => '${known(match[1]!)} · Chapter ${match[2]}')
        .replaceAllMapped(RegExp(r'^Sammlungsfortschritt: (\d+) von (\d+)$'),
            (match) => 'Collection progress: ${match[1]} of ${match[2]}')
        .replaceAllMapped(RegExp(r'^Tagesrätsel · (.+)$'),
            (match) => 'Daily puzzle · ${known(match[1]!)}')
        .replaceAllMapped(
            RegExp(
                r'^Das Feld in Zeile (\d+), Spalte (\d+) hat bereits (\d+) Linien\. Die übrigen Seiten können ausgeschlossen werden\.$'),
            (match) =>
                'The cell in row ${match[1]}, column ${match[2]} already has ${match[3]} lines. The remaining sides can be excluded.')
        .replaceAllMapped(
            RegExp(
                r'^Beim Feld in Zeile (\d+), Spalte (\d+) müssen alle noch freien Seiten zur Schleife gehören\.$'),
            (match) =>
                'For the cell in row ${match[1]}, column ${match[2]}, all remaining free sides must belong to the loop.')
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
        .replaceAllMapped(RegExp(r'^Heute gelöst · (.+)$'),
            (match) => 'Solved today · ${known(match[1]!)}')
        .replaceAllMapped(RegExp(r'^Heute offen · (.+)$'),
            (match) => 'Open today · ${known(match[1]!)}')
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
