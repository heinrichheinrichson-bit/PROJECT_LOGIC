# Thinkheim

Thinkheim ist eine ruhige, werbefreie Sammlung klassischer Logikspiele für Flutter.
Die App setzt auf vollständige Spiele ohne Energie, Timer-Zwang oder
Fortschritts-Paywalls.

## Aktueller Stand

### Binärpuzzle

- handverlesene Rätselsammlung
- Generator mit mehreren Größen und Schwierigkeitsstufen
- Solver und Hinweise
- Tagesrätsel und Kalender
- Spielstände, Statistik und Spielerfortschritt

### Hashi

- eigener Hub und Regelseite
- sechs spielbare Rätsel in drei Schwierigkeitsstufen
- einfache und doppelte Brücken
- Kreuzungs- und Inselprüfung
- Undo, Neustart, Timer und Zugzähler
- direkt antippbare Brücken zum intuitiven Entfernen
- gespeicherter Sammlungsfortschritt

Weitere geplante Spiele sind Sudoku, Hitori, Slitherlink und Kakuro.

## Projekt starten

Voraussetzung ist eine installierte Flutter-Umgebung.

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter run
```

## Qualitätsablauf

Eine Version wird erst veröffentlicht, wenn:

1. `flutter analyze` ohne Issues durchläuft,
2. alle automatisierten Tests bestehen,
3. die betroffenen Funktionen manuell geprüft wurden.

Danach folgen Commit, Tag und Push auf den Branch `master`.

## Dokumentation

Technische Unterlagen, Konzepte, Testhinweise und historische Release Notes
liegen gesammelt unter [`docs/`](docs/README.md). Der Repository-Hauptordner
bleibt bewusst auf die für Entwicklung und Build relevanten Dateien beschränkt.

## Version

Aktueller Entwicklungsstand: **v0.8.4**
