# Changelog

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
