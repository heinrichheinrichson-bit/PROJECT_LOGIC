# Project Logic v0.6.1-dev.3

## Ziel

Dieser Entwicklungsschritt erweitert den Generator von einem einzelnen
entfernten Feld zu einem echten, eindeutig lösbaren Binary Puzzle.

## Neu

- Mehrere Hinweise werden in einer per Seed reproduzierbaren Reihenfolge entfernt.
- Nach jedem Entfernen prüft der Solver mit einem Limit von zwei Lösungen die
  Eindeutigkeit.
- Ein Feld bleibt nur dann leer, wenn genau eine Lösung existiert.
- Leicht, Mittel und Schwer verwenden unterschiedliche Zielwerte für die Anzahl
  verbleibender Hinweise.
- Das Ergebnis meldet Versuche, erfolgreiche Entfernungen und den Zielwert.

## Testumfang

- Eindeutig lösbares 4×4-Rätsel
- identisches Ergebnis bei gleichem Seed
- abgestufte Schwierigkeitsziele
- korrekte Metadaten

## Abgrenzung

Dieser Build integriert den Generator noch nicht in die Benutzeroberfläche.
Die finale Version v0.6.1 folgt erst nach erfolgreichem lokalem Test und
weiterem Generator-Feinschliff.
