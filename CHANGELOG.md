# Changelog

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
