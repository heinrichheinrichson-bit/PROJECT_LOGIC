# Changelog

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
