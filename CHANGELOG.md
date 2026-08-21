## v0.8.41 – Monatsziele und einheitliche Spielekarten

- Die Binary-Karte auf der Startseite zeigt nun wie alle anderen Spielarten eine kurze Spielbeschreibung statt eines Katalogzählers.
- Ein kompakter Monatsziel-Status auf der Startseite führt direkt zum Fortschrittsbereich.
- Monatsziele wechseln nun kalenderbasiert zwischen Abwechslung, aktiven Tagen, Spielen ohne Hinweis, schweren Rätseln und Tagesrätseln.
- Die Monatsauswahl bleibt für jeden Kalendermonat dauerhaft stabil, damit vergangener Fortschritt reproduzierbar bleibt.
- Regressionstests für Startseitentext und Monatsrotation ergänzt.
- Paketversion auf 0.8.41+70 erhöht.

## v0.8.39 – Offene Spiele und Katalogfortschritt korrigiert

- Angefangene Partien aller sechs Spielarten erscheinen nun auf der Startseite und lassen sich dort einzeln entfernen, ohne Erfolge oder Statistiken zu löschen.
- Katalogfortschritt zählt nur noch verschiedene echte Katalogrätsel; Tages-, Zufalls- und Wiederholungsabschlüsse können den Katalogumfang nicht mehr überschreiten.
- Statistikansichten unterscheiden bei Sammlungen zwischen verschiedenen Rätseln und der Gesamtzahl aller Abschlüsse.
- Zelte-&-Bäume-Hinweise bevorzugen konkrete, hilfreiche Zeltsetzungen statt belangloser Grasfelder fernab eines Baums.
- Regressionstests für Startseiten-Spielstände, Katalogabgrenzung und hilfreiche Zelte-Hinweise ergänzt.
- Paketversion auf 0.8.39+68 erhöht.

## v0.8.38 – Tagesrätsel und Spielzeit eindeutig benannt

- Auch die älteren Ein- und Zehn-Stunden-Erfolge auf lesbare Stunden- und Minutenwerte umgestellt.
- Langfristige Tagesrätsel-Erfolge als Mengen-Meilensteine statt fälschlich als verstrichene Jahre benannt.
- Lange Erfolgstitel und Fortschrittswerte untereinander angeordnet, damit sie auf schmalen Smartphones nicht kollidieren.
- Regressionstests für alte Spielzeit-IDs und mengenbasierte Tagesrätsel-Meilensteine ergänzt.
- Paketversion auf 0.8.38+67 erhöht.

## v0.8.37 – Erfolge lesbarer gegliedert

- Spielzeit-Erfolge zeigen Fortschritt und Ziel jetzt als Stunden und Minuten statt als interne Sekundenwerte.
- Beschreibungen der langfristigen Spielzeit-Erfolge nennen wieder die tatsächlichen Zielstunden.
- Die umfangreiche Erfolgsliste in Rätsel-Meilensteine, Spielserien, Tagesrätsel, Spielarten, besondere Herausforderungen und Spielzeit gegliedert.
- Regressionstests für deutsche und englische Zeitangaben sowie unveränderte Standardzähler ergänzt.
- Paketversion auf 0.8.37+66 erhöht.

## v0.8.36 – Streak-Freeze produktreif erweitert

- Automatischen Verbrauch eines Eiszapfens und Wiederauffüllung nach zehn unterschiedlichen aktiven Tagen verständlicher dargestellt.
- Verbleibende aktive Tage bis zum nächsten Eiszapfen direkt im Streak-Kalender sichtbar gemacht.
- Deutliche zweisprachige Rückmeldung ergänzt, wenn der gestrige Fehltag automatisch geschützt wurde.
- Streak-Berechnung gegen Sommerzeit, Winterzeit sowie Monats- und Jahreswechsel abgesichert.
- Langfristige Streak-Erfolge für 60, 100, 365, 730 und 1.000 aufeinanderfolgende Tage ergänzt.
- Regressionstests für Freeze-Verbrauch, Auffüllung, Rückmeldung und lange Streak-Ziele erweitert.
- Paketversion auf 0.8.36+65 erhöht.

## v0.8.35 – Weitere dynamische Sprachmischungen beseitigt

- Levelkarte, Streak-Statistik und dynamische Binairo-Spielinformationen vollständig lokalisiert.
- Hitori-Kapiteldaten und sämtliche Katalognamen beim englischen Anzeigen übersetzt.
- Hashi-Statistiktitel und Tents-&-Trees-Testwerkzeuge korrigiert.
- Regressionstests für zuvor übersehene dynamische und katalogbasierte Texte ergänzt.
- Paketversion auf 0.8.35+64 erhöht.

## v0.8.34 – Sprachmischungen in Kalendern und Katalogen beseitigt

- Gemeinsamen Tagesrätselkalender einschließlich Statuskarte, Erklärung, Aktionen und Legende vollständig lokalisiert.
- Deutsche Katalogdaten aller Spielarten beim Anzeigen ins Englische übertragen, darunter Kapitel, Rätselnamen, Schwierigkeitsstufen und Beschreibungen.
- Testabschluss-Badges, Kalenderaktionen, Statistiktabellen und persönliche Rekorde gegen gemischte Sprachausgabe abgesichert.
- Dynamische Binairo-Angaben wie Rätselnummer, Vorgaben, Bestzeit und Sammlungsfortschritt übersetzt.
- XP-Verlauf mit lokalisierten Schwierigkeits-, Grundwert- und Hinweisbonus-Angaben korrigiert.
- Regressionstest für Tageskalender, Testabschlüsse, Katalogdaten und dynamische XP-Texte ergänzt.
- Paketversion auf 0.8.34+63 erhöht.

## v0.8.33 – Vollständige deutsche und englische Spieloberfläche

- Alle sechs Spielarten durchgängig zweisprachig umgesetzt: Einstieg, Sammlung, Generator, Spielbrett, Regeln, Hilfen und Abschluss.
- Offene-Partie-, Neustart-, Rewarded-Hinweis- und Sicherungsdialoge vereinheitlicht und übersetzt.
- Dynamische Zug-, Hinweis-, Fortschritts-, Schwierigkeits- und Ergebnisangaben lokalisiert.
- Slitherlink-Regelerklärung betont in beiden Sprachen ausdrücklich die einzige zusammenhängende Schleife.
- Hashi-Regeln, Ziehbedienung, Brückenmeldungen und Netzbedingung vollständig übersetzt.
- Tagesrätsel-Archiv, Wiederholung und vorbereitende Lade- sowie Fehlermeldungen lokalisiert.
- Appweite Resttextprüfung für sichtbare Widgets, Dialoge, Tooltips und Debug-Werkzeuge durchgeführt.
- Regressionstests für Begriffe und dynamische Fortschrittstexte aller Spielfamilien ergänzt.
- Paketversion auf 0.8.33+62 erhöht.

## v0.8.32 – Spielbereiche und Regeln auf Englisch

- Gemeinsame Spielbereich-Bausteine für alle sechs Spielarten zweisprachig umgesetzt.
- Titel, Beschreibungen, Aktionen und Fortschrittsangaben der Spieleinstiege auf Englisch erweitert.
- Regelbildschirme einschließlich Slitherlink-Einzelschleifenregel und Bedienhinweisen lokalisiert.
- Spielhilfen-Menü, Hinweis-Tooltip und zentraler Regeln-und-Bedienung-Schalter übersetzt.
- Dynamische Sammlungs- und Fortschrittsangaben ohne Änderungen an Rätsel- oder Speicherlogik lokalisiert.
- Regressionstests für Spielbereich-, Fortschritts- und Regeltexte ergänzt.
- Paketversion auf 0.8.32+61 erhöht.

## v0.8.31 – Fortschritt und Statistiken auf Englisch

- Fortschrittsseite mit Level, XP-Verlauf, Tages-, Wochen- und Langzeitzielen zweisprachig umgesetzt.
- Alle bestehenden Ziel- und Erfolgsketten erhalten englische Titel und Beschreibungen, ohne gespeicherte IDs oder XP-Logik zu verändern.
- Streak-Kalender mit Monatsnamen, Wochentagen, Legende, Tagesdetails und Eiszapfenstatus lokalisiert.
- Persönliche Rekorde einschließlich lokaler Datums- und Monatsdarstellung übersetzt.
- Erfolgsübersicht, Filter und Statusanzeigen zweisprachig umgesetzt.
- Globale und spielspezifische Statistikansichten mit lokalisierten Überschriften und Leistungskennzahlen erweitert.
- Regressionstests für englische Fortschrittsansichten und dynamische Zieltexte ergänzt.
- Paketversion auf 0.8.31+60 erhöht.

## v0.8.30 – Deutsche und englische App-Basis

- Dauerhafte Sprachwahl für Deutsch, Englisch oder die Systemsprache ergänzt.
- Deutsch bleibt für bestehende Installationen und neue Nutzer zunächst der sichere Standard.
- Startseite einschließlich Begrüßung, Spieleübersicht, Streak und persönlichem Bereich vollständig zweisprachig umgesetzt.
- Zentrale Einstellungen, Erinnerungsoptionen, Darstellung, Monetarisierung und Datensicherung zweisprachig umgesetzt.
- Uhrzeiten und Material-Systemdialoge richten sich nach der gewählten Sprache.
- Android-Spielerinnerungen und Streak-Warnungen erscheinen passend auf Deutsch oder Englisch.
- Nicht unterstützte Systemsprachen fallen zuverlässig auf Deutsch zurück.
- Regressionstests für Speicherung, unmittelbaren Sprachwechsel und Sprachfallback ergänzt.
- Paketversion auf 0.8.30+59 erhöht.

## v0.8.24 – Zuverlässige Android-Vibrationen

- Systemabhängiges Flutter-Berührungsfeedback durch echte kurze Android-Vibrationsimpulse ersetzt.
- Erforderliche Android-Vibrationsberechtigung ergänzt.
- Unterschiedliche Stärken und Muster für Spielzug, Hashi-Brücke, Hinweis, Abschluss und Levelaufstieg eingeführt.
- Separater App-Schalter für haptisches Feedback bleibt erhalten.
- Paketversion auf 0.8.24+53 erhöht.

## v0.8.23 – Dezentes Hashi-Knistern

- Synthetischen Hashi-Verbindungston durch ein kurzes, dezentes elektrostatisches Knistern ersetzt.
- Pixabay-Ausgangsmaterial auf 0,30 Sekunden gekürzt, leiser abgestimmt, gefiltert und weich ausgeblendet.
- Herkunft und zulässige Verwendung intern bei den Klangassets dokumentiert; in der App ist keine Namensnennung erforderlich.
- Paketversion auf 0.8.23+52 erhöht.

## v0.8.22 – Kurze Klicks und echtes Hashi-Knistern

- Tonales Quietschen bei normalen Spielzügen durch einen sehr kurzen, neutralen Klick ersetzt.
- Hashi-Verbindung vollständig neu gestaltet: statisches Zischen, unregelmäßige Funken-Pops und eine kurze elektrische Entladung statt eines Tonbogens.
- Entfernen einer Hashi-Brücke erhält eine kürzere, abfallende Entladungsvariante.
- Lautstärken für häufige Spielzüge und Hashi separat neu abgestimmt.
- Paketversion auf 0.8.22+51 erhöht.

## v0.8.21 – Töne und haptisches Feedback getrennt steuerbar

- Eigenes, separat abschaltbares Tonsystem für Spielzüge, Hinweise und Erfolge ergänzt.
- Dezenter digitaler Zugton und eigener tieferer Rücknahmeton eingeführt.
- Hashi-Brücken erhalten ein kurzes elektrisches Neon-Knistern; das Entfernen klingt bewusst anders.
- Melodische Klänge für gelöste Rätsel und Levelaufstiege ergänzt.
- Alle Klangdateien reproduzierbar im Projekt erzeugt und ohne externe Lizenzabhängigkeit gespeichert.
- Paketversion auf 0.8.21+50 erhöht.

## v0.8.20 – Verständliche Slitherlink-Farbhilfen

- Farblegende direkt in den Slitherlink-Spielhilfen ergänzt.
- Spielregeln erklären nun ausdrücklich, dass Lila und Rot nur bei eingeschalteter Fehlerhilfe erscheinen.
- Bedeutung der Farben Türkis, Lila und Rot verständlich beschrieben.
- Hinweis ergänzt, dass offene Enden und getrennte Schleifen nicht sofort rot markiert werden.
- Bei ausgeschalteter Spielhilfe bleiben nun auch erfüllte Zahlen neutral statt lila.
- Regressionstests für beide Erklärungstexte ergänzt.
- Paketversion auf 0.8.20+49 erhöht.

## v0.8.19 – Slitherlink-Spielhilfen wieder schaltbar

- Fehlenden Ein-/Aus-Schalter „Regelfehler markieren“ in den Slitherlink-Spielhilfen wiederhergestellt.
- Einstellung wird dauerhaft in den appweiten Einstellungen gespeichert.
- Zahlenüberschreitungen und vollständig widersprüchliche Zahlen werden bei aktiver Hilfe rot markiert.
- Linien an ungültigen Abzweigungen werden bei aktiver Hilfe rot markiert.
- Bei ausgeschalteter Hilfe bleiben diese unmittelbaren Fehlermarkierungen verborgen; Lösungsprüfung und Hinweise bleiben unverändert.
- Regressionstests für Fehlererkennung, Schalterbedienung und Speicherung ergänzt.
- Paketversion auf 0.8.19+48 erhöht.

## v0.8.18 – Mehr Slitherlink-Schleifen

- Slitherlink-Katalog von 36 auf 48 Rätsel erweitert.
- Jede Schwierigkeitsstufe enthält nun 16 statt 12 Rätsel in vier Kapiteln.
- Zwölf neue Rätsel statisch gespeichert, damit beim App-Start keine zusätzliche Generierungsarbeit entsteht.
- Reproduzierbares Entwicklungswerkzeug zum Erzeugen und Validieren weiterer statischer Slitherlink-Rätsel ergänzt.
- Jedes neue Rätsel auf eindeutige Lösbarkeit und genau eine geschlossene, zusammenhängende Schleife geprüft.
- Sammlungsansicht um ein viertes Kapitel je Schwierigkeit erweitert, sodass alle neuen Rätsel erreichbar sind.
- Paketversion auf 0.8.18+47 erhöht.

## v0.8.17 – Level direkt auf der Startseite

- Kompakte Levelkarte direkt unter der Begrüßung auf der Startseite ergänzt.
- Karte zeigt Level, Rangtitel, aktuelle XP, Fortschrittsbalken und verbleibende XP bis zum nächsten Level.
- Antippen öffnet den bestehenden Bereich „Dein Fortschritt“.
- Die Startseite verwendet dieselbe synchronisierte XP-Berechnung wie der Fortschrittsbereich statt einer Schätzung.
- Layout- und Navigationstests für normale und schmale Smartphones ergänzt.
- Paketversion auf 0.8.17+46 erhöht.

## v0.8.16 – Größere Futoshiki- und Hitori-Sammlungen

- Futoshiki-Katalog von 44 auf 60 Rätsel erweitert.
- Jede Futoshiki-Gruppe enthält nun 15 Rätsel, einschließlich 15 großer 7×7-Expertenrätsel.
- Hitori-Katalog von 45 auf 60 Rätsel erweitert.
- Jede Hitori-Schwierigkeitsstufe enthält nun 20 Rätsel.
- Neue Katalogrätsel werden automatisiert auf eindeutige IDs, gültige Lösungen und eindeutige Lösbarkeit geprüft.
- Paketversion auf 0.8.16+45 erhöht.

## v0.8.15 – Ziele für viele Monate

- Hashi-Vorschaulinie beim Ziehen dezenter und transparenter gestaltet.
- Erfolgsketten pro Spielart auf 250 und 500 gelöste Rätsel erweitert.
- Weitere Stufen für schwere Rätsel, Lösungen ohne Hinweise, Tagesrätsel und Gesamtspielzeit ergänzt.
- Langzeitziele für Sammlung, Zufallsrätsel und aktive Tage bis hin zu mehrjährigem Fortschritt ausgebaut.
- XP-Belohnungen für die neuen hohen Zielstufen ergänzt.
- Regressionstests für tiefe Erfolgs- und Langzeitzielketten hinzugefügt.
- Paketversion auf 0.8.15+44 erhöht.

## v0.8.14 – Einheitliche Hashi-Touchsteuerung

- Hashi-Brettinteraktion grundlegend neu aufgebaut: Eine einzige zentrale Gestenfläche verarbeitet Tippen und Ziehen.
- Konkurrierende Insel-Schaltflächen und der zusätzliche rohe Pointer-Listener wurden entfernt.
- Kurzer Kontakt wählt eine Insel; eine klare Bewegung rastet horizontal oder vertikal auf die nächste sichtbare Insel ein.
- Eine Vorschau-Linie folgt dem Finger und verbindet sich sichtbar mit der erkannten Zielinsel.
- Direktes Antippen vorhandener Brücken zum Entfernen bleibt erhalten.
- Regressionstests für ungenaues Ziehen, ungültige Diagonalbewegungen, Insel-Tippen und Brücken-Tippen ergänzt.
- Paketversion auf 0.8.14+43 erhöht.

## v0.8.13 – Hashi-Ziehen per Richtung

- Hashi-Ziehen vollständig auf Richtungssteuerung umgestellt: Eine klare horizontale oder vertikale Bewegung wählt die nächste sichtbare Insel.
- Der Finger muss nicht mehr punktgenau auf der Zielinsel losgelassen werden.
- Start- und Zielinsel werden bereits während des Ziehens hervorgehoben.
- Kurze und diagonale Bewegungen bleiben ohne Wirkung; die bestehende Tippbedienung bleibt erhalten.
- Realistischere Gestentests für ungenaues Loslassen und ungültige Bewegungen ergänzt.
- Fortschrittsstufen, einmalige XP-Synchronisierung und erweiterte Katalognavigation erneut geprüft.
- Paketversion auf 0.8.13+42 erhöht.

## v0.8.12 – Langfristiger Fortschritt

- Drei Langzeitziele zu jeweils sechs aufeinanderfolgenden Stufen ausgebaut; nach einem Abschluss erscheint automatisch die nächste Stufe.
- Langzeitstufen vergeben rückwirkend und idempotent eigene XP, ohne bestehende Buchungen zu verändern.
- 30 zusätzliche dauerhafte Erfolge für spielartspezifische Abschlüsse, schwere und hintfreie Rätsel, Tagesrätsel sowie lange Spielzeiten ergänzt.
- „Vielseitiger Denker“ zählt nun korrekt die sechs tatsächlich spielbaren Spielarten statt zukünftiger, noch nicht verfügbarer Typen.
- Hashi-Ziehbedienung mit großzügigerer Inselerkennung und sichtbarem Bedienhinweis für Smartphones nachgebessert.
- Kataloge erweitert: Hashi 50 → 60, Futoshiki 32 → 44 und Hitori 28 → 45 feste Rätsel.
- Alle neuen Katalogrätsel besitzen stabile neue IDs; vorhandene Lösungen und Fortschritte bleiben erhalten.
- Paketversion auf 0.8.12+41 erhöht.

## v0.8.11 – Klare Ziele und stabile Wochen

- XP-Verlauf unterscheidet Tagesziele, Wochenziele und ihre jeweiligen Komplettboni eindeutig.
- Zielnamen im XP-Verlauf entsprechen nun exakt den sichtbaren Karten, darunter „Ganz ohne Hilfe“ und „Aus eigener Kraft“.
- Wochenanfang und Wochenfilter verwenden reine Kalenderdaten und bleiben auch beim Wechsel zwischen Sommer- und Winterzeit stabil.
- Jahresweite Regressionstests für Tages- und Wochenrotation ergänzt.
- Schutztests ergänzt, damit abgeschlossene Futoshiki-, Hitori- und Zelte-Spielstände nicht erneut als offene Spiele angeboten werden.
- Hashi-Brücken lassen sich zusätzlich durch Ziehen von einer Insel zur nächsten setzen und weiterschalten; die bisherige Tippbedienung bleibt erhalten.
- Bestehende XP, Ziele und Spielstände werden nicht verändert.
- Paketversion auf 0.8.11+40 erhöht.

## v0.8.10 – Korrekte Tagesziel-Boni

- Tages- und Wochenzielrotation verwendet reine Kalendertage und ist damit unabhängig von Uhrzeit und Sommerzeit.
- Der Komplettbonus wird erst vergeben, wenn exakt die drei sichtbaren Tagesziele erfüllt sind.
- Bestehende XP-Buchungen bleiben unangetastet; die Korrektur verhindert ausschließlich künftige Frühvergaben.
- Regressionstests für die auf dem Galaxy S22 beobachteten Fälle vom 12. und 13. August 2026 ergänzt.
- Paketversion auf 0.8.10+39 erhöht.

## v0.8.9 – Datensicherheit und mobile Stabilität

- App-weite sichere Systemabstände für Android, iOS und Tablets ergänzt.
- Slitherlink akzeptiert nur noch genau eine geschlossene, zusammenhängende Schleife.
- Tagesarchive, Sicherungsimport und Cloud-Snapshot-Grundlage weiter gehärtet.
- Zentrale, transaktionale Migration für bestehende App-Daten ergänzt.
- Lesbare ältere Binairo-Spielstände werden auf das aktuelle Format aktualisiert.
- Beschädigte Altdaten bleiben für bestehende Wiederherstellungswege erhalten und blockieren den App-Start nicht.
- Interne Migrationssicherungen werden nicht exportiert oder synchronisiert.
- Paketversion auf 0.8.9+38 erhöht.

## v0.8.8 – Hashi-Komfort

- Redo ergänzt
- optional zuschaltbare Fehleranzeige für gesetzte Brücken
- Tipp-Funktion ergänzt automatisch einen korrekten Lösungsschritt
- Undo/Redo und Debug-Zustände sauber synchronisiert
- zusätzliche Tests für Hinweise und Lösungsabweichungen
- Fehleranzeige korrigiert: Beim Ausschalten verschwinden rote Brücken und Inselmarkierungen vollständig
- Inseln an fehlerhaften Verbindungen werden bei aktiver Prüfung gezielt markiert
- klare Rückmeldung beim Ein- und Ausschalten der Fehleranzeige

## 0.8.7

- Hashi-Debugmenü im Debug-Build ergänzt.
- Rätsel können bis auf eine Brücke oder vollständig gelöst werden.
- Fehlerzustand und schneller Test-Reset ergänzt.
- Abschlussdialog lässt sich dadurch ohne manuelles Durchspielen prüfen.

# Changelog

## v0.8.6 – Hashi-Katalog erweitert

### Added
- Sechs neue handgebaute Hashi-Rätsel; der Katalog enthält jetzt zwölf Rätsel.
- Schwierigkeitsfilter für leichte, mittlere und schwere Rätsel.
- Fortschrittsbalken im Hashi-Hub und im Rätselkatalog.
- Direkter Einstieg in das nächste ungelöste Rätsel.
- Zusätzlicher Test für eindeutige Rätsel-IDs.

### Changed
- Der Hashi-Katalog zeigt den Gesamtfortschritt kompakter und deutlicher.
- Paketversion auf 0.8.6+34 erhöht.

## v0.8.5 – Hashi Premium Polish

### Changed
- Hashi-Spielfeld mit ruhiger Punktstruktur, klareren Brücken und räumlicher Tiefe überarbeitet.
- Inseln besitzen deutlichere Zustände für Auswahl, mögliche Ziele, Erfüllung und Überschreitung.
- Erfüllte Inseln erhalten eine kompakte visuelle Bestätigung.
- Statusbereich zeigt Zeit, Züge und erfüllte Inseln auf einen Blick.
- Aktionshinweise wechseln weich und bleiben während des Spiels besser lesbar.
- Bedienhinweis wurde zu einer kompakten, dauerhaft sichtbaren Kurzhilfe zusammengeführt.
- Versionsnummer auf 0.8.5+33 erhöht.

### Notes
- Rätsellogik, Lösungen und gespeicherter Hashi-Fortschritt bleiben unverändert.
- Der Schwerpunkt dieser Version liegt vollständig auf Spielgefühl und visueller Qualität.

# Changelog

## v0.8.4 – Repository Cleanup

### Changed
- Projektdokumentation aus dem Repository-Hauptordner in eine klare `docs/`-Struktur verschoben.
- Release Notes nach Versionsbereich geordnet und historische Hilfsdateien archiviert.
- README auf den aktuellen Stand mit Binärpuzzle und spielbarem Hashi gebracht.
- Dokumentationsregeln ergänzt, damit neue Releases den Hauptordner nicht erneut füllen.
- Paketversion auf 0.8.4+32 erhöht.

### Compatibility
- Keine Änderungen an Spiellogik, Spielständen oder Persistenzformaten.
- Bestehende Tests und Plattformdateien bleiben unverändert.

## v0.8.3

### Changed
- Hashi-Brücken lassen sich direkt durch Antippen entfernen.
- Sichtbare Rückmeldung für einfache, doppelte und entfernte Brücken.
- Spielhinweise und Regeln erklären die Korrektursteuerung deutlicher.

### Tests
- Logiktests für direktes Entfernen vorhandener Brücken ergänzt.

# v0.8.2 – Hashi-Rätselkatalog

### Added
- Sechs handgebaute Hashi-Rätsel in drei Schwierigkeitsstufen.
- Rätselkatalog mit dauerhaft gespeicherten Abschlussmarkierungen.
- Timer, Zugzähler und hervorgehobene mögliche Zielinseln.
- Abschlussdialog mit Zeit, Zügen und direkter Navigation zum nächsten Rätsel.
- Logiktests für sämtliche Kataloglösungen.

### Changed
- Hashi-Hub zeigt den aktuellen Katalogfortschritt.
- Paketversion auf 0.8.2+30 erhöht.

# v0.8.0 – Hashi-Fundament

### Added
- Hashi als zweites auswählbares Spiel auf der Startseite.
- Eigener Hashi-Hub mit gezeichneter Vorschau eines gelösten Inselnetzes.
- Eigene Regelseite und verständliche Einführung in die Spielidee.
- Erste Hashi-Modelle für Inseln, Brücken und Vorschau-Rätsel.
- Modell- und Navigationstests für das neue Fundament.

### Compatibility
- Binärpuzzle, bestehende Spielstände, Fortschritt und Statistiken bleiben unverändert.
- Noch keine Hashi-Spielstände oder Änderungen am Persistenzformat.
- Paketversion auf 0.8.0+28 erhöht.

# v0.7.3 – Sprache & Spielgefühl

### Changed
- Texte in Startseite, Binärpuzzle-Hub, Katalog, Generator, Profil, Statistik, Einstellungen und Regeln überarbeitet.
- Technische und generische Bezeichnungen durch kürzere, natürlichere Formulierungen ersetzt.
- Missionen und Erfolge neu benannt und verständlicher beschrieben.
- Begriffe vereinheitlicht: Katalog, freie Rätsel und Tagesrätsel.
- Abschluss-, Hinweis- und Löschdialoge freundlicher formuliert.
- Paketversion auf 0.7.3+27 erhöht.


## 0.7.1+25 – Spielerfortschritt

- Spielerprofil mit Level, XP und Rangtitel ergänzt.
- Vier Missionen mit dynamischem Fortschritt eingeführt.
- Zehn dauerhafte Erfolge ergänzt.
- Fortschrittsbalken animiert und vollständig aus vorhandenen Spieldaten berechnet.
- Neue, spielübergreifend nutzbare Progress-Architektur und Tests ergänzt.

## 0.7.0 – Tageskalender

- Archiv der letzten 30 Tagesrätsel ergänzt.
- Vergangene Tagesrätsel können nachgeholt werden.
- Gelöste und offene Tage werden im Kalender markiert.
- Nachholen verändert den historischen Spiel-Streak nicht.
- Datumsbezogene Titel und neue Regressionstests ergänzt.
- Version auf 0.7.0+24 erhöht.


## 0.6.8+22

- Globale Spielserie für mindestens ein abgeschlossenes Rätsel pro Tag.
- Aktuelle und beste Serie werden lokal gespeichert.
- Startseite zeigt den heutigen Streak-Status.
- Statistik ersetzt die Summe der Bestzeiten durch Gesamtspielzeit und Durchschnittszeit.
- Puzzle-Ergebnisse speichern zusätzlich die kumulierte Spielzeit.
- Bestehende v0.6.7-Daten werden sicher migriert.
- Datenmodell ist spielübergreifend für weitere Logikspiele vorbereitet.

## 0.6.7 - Spielerfortschritt

- Fortschrittsdaten speichern jetzt Rätselquelle, Schwierigkeit, Rastergröße und Anzahl der Abschlüsse.
- Wiederholtes Lösen desselben Rätsels erhöht die Zahl abgeschlossener Partien, während die Bestzeit erhalten bleibt.
- Bestehende Ergebnisdaten aus früheren Versionen bleiben lesbar.
- Metadaten alter generierter Rätsel werden aus ihrer Puzzle-ID rekonstruiert.
- Statistik für generierte Rätsel nach 4×4, 6×6 und 8×8 sowie Leicht, Mittel und Schwer ergänzt.
- Gesamtstatistik zählt abgeschlossene Partien statt nur unterschiedlicher Puzzle-IDs.
- Startseite und Binärpuzzle-Hub zählen beim Katalogfortschritt ausschließlich Katalogrätsel.
- Puzzle-Quellen für Katalog, Generator, Tagesrätsel, Events und Tutorials vorbereitet.
- Zusätzliche Regressionstests für Fortschrittsmetadaten und Wiederholungsabschlüsse ergänzt.
- Paketversion auf 0.6.7+21 erhöht.


## 0.6.6 - Binärpuzzle-Hub

### Added
- Eigener Binärpuzzle-Hub als zentrale Anlaufstelle für Katalogrätsel, Spielstände, Zufallsrätsel, Tagesrätsel und Statistik.
- Neuer Abschlussdialog-Ablauf für Generator-Rätsel mit direkter Erzeugung eines weiteren Rätsels derselben Größe und Schwierigkeit.
- Widget-Test für die neue Startseiten- und Hub-Navigation.

### Changed
- Die globale Startseite zeigt nur noch Spiele sowie globale Bereiche wie Statistik und Einstellungen.
- „Spiel fortsetzen“ und „Zufallsrätsel generieren“ wurden in den Binärpuzzle-Bereich verschoben.
- Paketversion auf 0.6.6+20 erhöht.

### Compatibility
- Bestehende Katalogrätsel, Generator-Rätsel und Savegames bleiben kompatibel.
- Persistenzformat und Spielregeln wurden nicht verändert.


## 0.6.5 - Generator-Qualität

### Added
- Generator-Diagnosedaten für Laufzeit, Solver-Aufrufe, abgelehnte Entfernungen und Vorgabenverteilung.
- Zusätzliche Tests für Diagnosekonsistenz und eine gleichmäßige Verteilung der Vorgaben.

### Changed
- Clues werden nun deterministisch und verteilungsbewusst entfernt.
- Reihen und Spalten mit vielen verbliebenen Vorgaben werden bevorzugt bearbeitet.
- Paketversion auf 0.6.5+19 erhöht.

### Compatibility
- Savegame-Format, Spielregeln und bestehende Rätsel bleiben unverändert.
- Gleiche Seeds bleiben innerhalb von v0.6.5 deterministisch; die konkrete Vorgabenverteilung kann sich gegenüber v0.6.4 verbessern.


## 0.6.4 - Stabilität & Modernisierung

### Added
- Versionierte Savegame-Struktur mit `schemaVersion: 2`.
- Zusätzliche Tests für alte, zukünftige, beschädigte und inkonsistente Spielstände.

### Changed
- Schwierigkeitsauswahl auf eine moderne Segment-Auswahl umgestellt.
- Veraltete `withOpacity`-Nutzung durch `withValues` ersetzt.
- Generator-Spielstände werden vor der Wiederherstellung strenger validiert.
- Paketversion auf 0.6.4+18 erhöht.

### Compatibility
- Bestehende v1-Spielstände ohne Schema-Feld bleiben lesbar.
- Nicht unterstützte zukünftige Savegame-Versionen werden sicher verworfen.


## 0.6.3 - Generator-Persistenz

### Added
- Generierte Binärpuzzles werden vollständig im aktiven Spielstand gespeichert.
- „Spiel fortsetzen“ stellt generierte Rätsel inklusive Lösung, Vorgaben, Größe, Schwierigkeit, Titel und Spielwerten wieder her.
- Speicherung beim Wechsel in den Hintergrund bzw. beim Schließen der App.
- Neue Serialisierungstests für generierte Puzzle-Definitionen.

### Changed
- Generator-Rätsel verwenden jetzt denselben zuverlässigen Speicher- und Fortsetzen-Workflow wie Katalogrätsel.
- Paketversion auf 0.6.3+17 erhöht.
- Bestehende ältere Spielstände bleiben kompatibel.

## 0.6.2 - Generator-UI

- Der Puzzle-Generator ist jetzt als reguläre Funktion auf der Startseite erreichbar.
- Neue Auswahl für Brettgrößen 4 × 4, 6 × 6 und 8 × 8.
- Neue Auswahl für die Schwierigkeitsgrade Leicht, Mittel und Schwer.
- Ladezustand und Fehleranzeige während der lokalen Generierung ergänzt.
- Generierte Rätsel öffnen direkt im bestehenden Spielbildschirm.
- Der temporäre Menüpunkt „Generator-Test“ wurde entfernt.
- Ausführliche manuelle Testanleitung für v0.6.2 ergänzt.

## v0.6.1-dev.3 – Unique Clue Removal

### Added
- Multi-clue removal in deterministic seeded order
- Solver-backed uniqueness check after every attempted clue removal
- Difficulty-specific clue targets for easy, medium, and hard puzzles
- Generation diagnostics for attempted and successful removals
- Tests for unique solvability, determinism, difficulty progression, and metadata

### Compatibility
- No UI, save-format, or existing puzzle-catalogue changes
- This is an internal development build toward v0.6.1

## v0.6.0 – Generator Core

### Added
- Seeded `BinaryBoardGenerator` for complete Binary Puzzle solution boards
- Line-based backtracking generation using the existing board validator
- `BinaryBoardGenerationResult` with seed and search diagnostics
- Automated generation tests for 4×4, 6×6, and 8×8 boards
- Determinism, balance, uniqueness, and invalid-size tests
- Generator architecture documentation

### Repository cleanup
- Removed old tracked push, test-guide, and update helper files from the release snapshot
- Generated ZIP contains only the maintained project tree

### Compatibility
- No UI, save-format, puzzle-catalogue, or gameplay changes
- Existing saves remain compatible

## v0.5.5 – Hint Quality

### Improved
- Direct rules remain prioritized before solver-based conclusions
- Hint dialogs now separate rule type, explanation, coordinate, and action
- Triple-rule hints highlight the three relevant cells
- Count-rule hints highlight the complete relevant row or column
- Uniqueness hints highlight both compared lines
- Solver conclusions are clearly labelled as a combination of several rules
- German explanations are more concrete and instructional

### Tests
- Added assertions for hint wording, badges, coordinates, and highlighted context
- Existing hint-safety regression tests remain active

### Compatibility
- No save format or puzzle catalogue changes

## v0.5.4 – Regression Safety

### Added
- Regression catalogue under `docs/REGRESSION_TESTS.md`
- Automated protection against hints that create duplicate rows
- Shared test assertion proving every returned hint leaves a valid, solvable board
- Additional representative hint-safety board states

### Repository cleanup
- Removed historical `GIT_PUSH_*`, `TESTANLEITUNG_*`, and `UPDATE_*` files that were still tracked
- Added ignore rules for generated release ZIPs and local Flutter run leftovers
- Future project ZIPs contain only the maintained project state

### Compatibility
- No gameplay, save format, puzzle catalogue, or UI flow changes
- Existing local saves remain compatible

## v0.5.3 – Hint Safety

### Fixed
- Jeder direkte Hinweis wird vor der Ausgabe gegen alle Binärpuzzle-Regeln geprüft.
- Hinweise werden verworfen, wenn sie doppelte vollständige Zeilen oder Spalten erzeugen.
- Hinweise werden verworfen, wenn der resultierende Spielstand nicht mehr lösbar ist.
- Für bereits unlösbare Spielstände wird kein scheinbar sicherer Hinweis mehr angeboten.
- Der Hinweisdialog unterscheidet jetzt klarer zwischen fehlenden und unsicheren Hinweisen.

### Repository cleanup
- Alte `GIT_PUSH_*`, `TESTANLEITUNG_*` und `UPDATE_*` Dateien werden ignoriert.
- Historische Hilfstextdateien wurden aus dem Release-Projekt entfernt.

## v0.5.2 – Solver Integration

### Added
- Priorisierte, erklärbare Hinweistypen für Dreier-Regel, Anzahl und eindeutige Linien
- Solver-Fallback für eindeutig lösbare aktuelle Spielstände
- Regeltyp und Koordinate im Hinweisdialog
- Tests für Priorisierung, Eindeutigkeit, Solver-Fallback und unsichere Spielstände

### Safety
- Keine geratenen Solver-Hinweise bei mehreren Lösungen
- Keine Solver-Hinweise bei widersprüchlichen Spielständen
- Bestehende Speicherstände und Bedienabläufe bleiben kompatibel

## v0.5.1 – Solver Foundation

### Added
- UI-unabhängiger Binärpuzzle-Validator
- Prüfung von Teilständen und vollständigen Spielfeldern
- Backtracking-Solver mit konfigurierbarer Lösungsgrenze
- Ergebnisobjekt für Lösbarkeit, Lösungszahl, Eindeutigkeit und untersuchte Zustände
- Isolierte Tests mit eigenen 4×4-Testpuzzles
- Solver-Dokumentation unter `docs/SOLVER.md`

### Validated rules
- Gleiche Anzahl von 0 und 1
- Keine drei gleichen Zahlen in Folge
- Keine identischen vollständigen Zeilen
- Keine identischen vollständigen Spalten

### Compatibility
- Keine UI-, Speicher- oder Rätselkatalogänderungen
- Bestehende Spielstände bleiben kompatibel

## v0.5.0 – Architecture Foundation

### Added
- Feature-orientierte Ordnerstruktur für Home, Binärpuzzle, Einstellungen und Statistik
- Eigenständige App-Schicht für Theme und MaterialApp-Konfiguration
- Wiederverwendbarer Zeitformatierer unter `core/`
- Architektur-Dokumentation unter `docs/ARCHITECTURE.md`
- Unit-Tests für Zeitformatierung

### Changed
- `main.dart` ist jetzt ein kleiner Bootstrap statt einer 1.400-Zeilen-Datei
- UI-Screens und Spielfeld-Widgets wurden in klar abgegrenzte Module verschoben
- Gemeinsame Zeitformatierung wurde aus den Screens herausgelöst
- Paketversion auf 0.5.0+7 erhöht

### Compatibility
- Keine Spielregeln, Rätseldaten oder Speicherformate wurden verändert
- Bestehende lokale Spielstände bleiben kompatibel

## v0.4.1 – Stabilitäts-Patch

### Fixed
- Ungültige `const`-Mengen mit `CellPosition` in den Hinweis-Tests entfernt.
- Die Hinweis-Tests lassen sich nun korrekt kompilieren und ausführen.
- Versionsanzeige und Paketversion auf v0.4.1 aktualisiert.

### Notes
- Keine Gameplay-Funktionen wurden gegenüber v0.4.0 verändert.
- Dieser Patch behebt ausschließlich den beim Teststart gefundenen Kompilierungsfehler.

## v0.4.0 – Gameplay Update

### Added
- Erste regelbasierte Hinweis-Engine für Binärpuzzles
- Hinweise erklären die verwendete Logik und können optional angewendet werden
- Ausgewählte Zeile und Spalte werden im Spielfeld hervorgehoben
- Hinweisfelder werden deutlich markiert
- Vollständige Einstellungsseite
- Farbschema: System, Hell oder Dunkel
- Animationen ein- und ausschaltbar
- Haptisches Feedback ein- und ausschaltbar
- Standardwert für Regelfehlermarkierungen
- Sicherer Dialog zum Löschen aller lokalen Spielstände und Bestzeiten
- Tests für Hinweisregeln und rückgängig machbare Hinweiszüge

### Changed
- Zahlenwechsel verwendet eine weichere Skalierungsanimation
- Gewinn-Dialog besitzt eine kleine Erfolgsanimation
- Einstellungen werden dauerhaft lokal gespeichert
- Paketversion auf 0.4.0+5 erhöht

## v0.3.1

### Fixed
- Der aktive Spielstand wird vor dem Zurücknavigieren vollständig gespeichert.
- Die Startseite erkennt „Spiel fortsetzen“ sofort, ohne dass der Browser neu geladen werden muss.
- Die zuletzt sichtbare Spielzeit wird beim Verlassen zuverlässig übernommen.
- Eine mögliche Race Condition zwischen Speichern und Aktualisieren der Startseite wurde entfernt.

## v0.3.0

### Added
- Automatisches lokales Speichern des aktuellen Binärpuzzles
- Schaltfläche „Spiel fortsetzen“ auf der Startseite
- Wiederherstellung von Spielfeld und verstrichener Zeit
- Dauerhafte Bestzeiten pro Rätsel
- Abschlussmarkierungen in der Rätselauswahl
- Erste Statistikseite mit Gesamt- und Schwierigkeitsfortschritt
- Speichertests und zusätzliche Logiktests

### Changed
- Fortschrittsanzeige lautet jetzt verständlicher „X von Y Feldern gelöst“
- Startseite zeigt die Anzahl abgeschlossener Rätsel
- Paketversion auf 0.3.0+3 erhöht

## v0.2.0

### Added
- Neun spielbare Binärpuzzles
- Drei Schwierigkeitsstufen
- Rätselauswahl
- Timer und Fortschrittsanzeige
- Nächstes Rätsel nach erfolgreichem Abschluss
- Developer-Testwerkzeuge

### v0.6.6 – Abnahme-Korrekturen
- Anzahl-Regel liefert weiterhin einen sicheren Hinweis, wenn an anderer Stelle bereits ein Widerspruch besteht.
- Statistik trennt Katalogrätsel und generierte Rätsel eindeutig.
- „Nächstes Rätsel“ funktioniert über Schwierigkeitsgrenzen hinweg und bleibt auch nach dem letzten Katalogrätsel nutzbar.

## 0.6.9 – Tagesrätsel

- Deterministisches tägliches Binärpuzzle auf Basis des Kalenderdatums.
- Eigener Tagesrätsel-Status im Binärpuzzle-Hub.
- Tagesrätsel-Savegames und korrekte Wiederherstellung der Rätselquelle.
- Eigener Abschlussdialog und eigener Statistikbereich.
- Tagesrätsel-Serie vorbereitet und sichtbar gemacht.
- Savegame-Schema auf Version 3 erweitert.
- Version auf 0.6.9+23 erhöht.
## v0.8.25 – Mehr Slitherlink-Rätsel

- Slitherlink-Sammlung von 48 auf 60 eindeutig lösbare Rätsel erweitert.
- Je vier neue Rätsel für Leicht, Mittel und Schwer ergänzt.
- Alle neuen Lösungen auf Zahlenregeln, eine einzige geschlossene Schleife und Eindeutigkeit geprüft.
- Paketversion auf 0.8.25+54 erhöht.
## v0.8.26 – Größere Rätselsammlungen

- Futoshiki-Sammlung von 60 auf 96 Rätsel erweitert: je 24 in allen vier Kapiteln.
- Hitori- und Zelte-Sammlungen von jeweils 60 auf jeweils 72 Rätsel erweitert.
- Bestehende Rätsel-IDs und gespeicherte Fortschritte bleiben unverändert.
- Alle neuen Katalogrätsel werden mit den jeweiligen Solvern auf eindeutige Lösbarkeit geprüft.
- Paketversion auf 0.8.26+55 erhöht.
## v0.8.27 – Appweiter Streak auf Eis

- Appweiten Monatskalender mit Markierungen für gespielte, eingefrorene und verpasste Tage ergänzt.
- Ein kostenloser Eiszapfen schützt automatisch genau einen verpassten Tag und hält die Spielserie am Leben.
- Verbrauchter Eiszapfen füllt sich nach zehn verschiedenen aktiven Spieltagen wieder auf.
- Bestehende Serien werden beim Update nicht rückwirkend verändert oder künstlich eingefroren.
- Eisbestand und Auffüllfortschritt werden lokal, in Backups und bei Wiederherstellungen mitgeführt.
- Paketversion auf 0.8.27+56 erhöht.
## v0.8.28 – Persönliche Rekorde

- Neue Rekordübersicht im Fortschrittsbereich mit Werten und zugehörigen Daten ergänzt.
- Längste Serie, stärkster XP-Tag, meiste Rätsel, längste Spielzeit, größte Spielartenvielfalt und stärkster Monat werden rückwirkend berechnet.
- Schnellstes Rätsel wird für jede bereits gespielte Spielart separat ausgewiesen.
- Eingesetzte Eiszapfen erscheinen ebenfalls in der persönlichen Bilanz.
- Gleichstände werden einheitlich zugunsten des jüngsten Rekordtages aufgelöst.
- Paketversion auf 0.8.28+57 erhöht.
## v0.8.29 – Intelligente Android-Erinnerungen

- Frei wählbare tägliche Spielerinnerung und separate Streak-Warnung ergänzt.
- Streak-Warnung startet mit 21:00 Uhr, beide Zeiten bleiben individuell veränderbar und standardmäßig ausgeschaltet.
- Benachrichtigungen erscheinen nur, wenn am jeweiligen Tag noch kein Rätsel gelöst wurde; die Warnung zusätzlich nur bei laufender Serie.
- Liegen beide Uhrzeiten höchstens 60 Minuten auseinander, verhindert die App eine doppelte Meldung.
- Warntext berücksichtigt, ob noch ein schützender Eiszapfen vorhanden ist.
- Android-Benachrichtigungsberechtigung wird erst beim Einschalten angefragt; Alarme werden nach Neustart sowie Zeit- oder Zeitzonenwechsel wiederhergestellt.
- Paketversion auf 0.8.29+58 erhöht.
## v0.8.40 – Monatliche Herausforderungen

- Drei appweite Monatsziele für Rätselmenge, aktive Tage und Spielartenvielfalt ergänzt.
- Monatsziele erhalten eigene XP-Belohnungen und einen einmaligen Komplettbonus.
- Monatsfortschritt bleibt sauber von Tages-, Wochen- und Langzeitzielen getrennt.
- Deutsche und englische Darstellung einschließlich XP-Verlauf ergänzt.
- Regressionstests für Monatsgrenzen, Fortschritt und einmalige XP-Gutschriften ergänzt.
- Paketversion auf 0.8.40+69 erhöht.
