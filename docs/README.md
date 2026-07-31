# Dokumentation

Dieser Ordner bündelt die Projektdokumentation, damit der Repository-Hauptordner
übersichtlich bleibt.

## Struktur

- `concepts/` – Produkt- und Monetarisierungskonzepte
- `reference/` – Architektur, Solver, Generator und Regressionstests
- `releases/` – historische Release Notes
- `testing/` – ältere manuelle Testanleitungen
- `archive/` – nicht mehr aktive Hilfsdateien

## Regel für neue Releases

Für neue Versionen wird grundsätzlich nur `CHANGELOG.md` aktualisiert.
Eine zusätzliche Release-Datei wird nur erstellt, wenn sie wirklich mehr Inhalt
als der Changelog bietet. Solche Dateien gehören nach
`docs/releases/<Versionsbereich>/` und niemals in den Hauptordner.

Dateien mit Zusätzen wie `FIXED`, `FINAL` oder `NEW` sollen nicht als neue
Dokumente entstehen. Korrekturen werden in der bestehenden Datei vorgenommen;
die Historie bleibt über Git nachvollziehbar.
