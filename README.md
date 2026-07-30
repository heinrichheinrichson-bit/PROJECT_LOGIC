# Project Logic – erster Flutter-Prototyp

Dieser Prototyp enthält ein festes, eindeutig lösbares 6×6-Binärpuzzle.

## Enthalten

- Antippen eines Feldes: leer → 0 → 1 → leer
- unveränderliche Vorgabefelder
- direkte Prüfung der drei Kernregeln
- Markierung widersprüchlicher Felder
- Undo und Redo
- Zurücksetzen
- Lösungserkennung
- Light- und Dark-Mode über das Betriebssystem
- getrennte Spiellogik in `lib/game_logic.dart`
- Unit-Tests für Grundfunktionen

## Bewusst noch nicht enthalten

- Rätselgenerator
- Solver und intelligente Hinweise
- Datenbank und Autosave
- Tagesrätsel
- Hitori
- Hashi
- endgültiges Branding

## Starten

Flutter muss installiert sein.

```bash
flutter create .
flutter pub get
flutter test
flutter run
```

`flutter create .` ergänzt die plattformspezifischen Android-/iOS-Verzeichnisse,
ohne die vorhandenen Dateien unter `lib/` zu ersetzen.

## Bedienung

Ein freies Feld wird durch Antippen zyklisch geändert:

1. leer
2. 0
3. 1
4. wieder leer

Stärker hervorgehobene Felder sind Vorgaben und können nicht verändert werden.

## Nächster sinnvoller Entwicklungsschritt

Ein exakter Solver, der:

1. die Eindeutigkeit eines Rätsels prüft,
2. als Grundlage für den Generator dient,
3. später durch einen menschlich erklärenden Regel-Solver ergänzt wird.

## Stand v0.6.7

Die Fortschrittsdaten unterscheiden Katalog-, Generator- und künftig auch
Tages-, Event- und Tutorialrätsel. Generierte Abschlüsse werden nach Rastergröße
und Schwierigkeit ausgewertet; wiederholte Abschlüsse werden separat gezählt,
während die persönliche Bestzeit erhalten bleibt.
