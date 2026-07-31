# Project Logic v0.8.4 – Repository Cleanup

Diese Version räumt ausschließlich die Projektstruktur auf. Das Gameplay und
die gespeicherten Daten bleiben unverändert.

## Änderungen

- Historische Release Notes wurden unter `docs/releases/` geordnet.
- Technische Dokumentation liegt jetzt unter `docs/reference/`.
- Konzepte und ältere Hilfsdateien wurden in eigene Bereiche verschoben.
- README und Dokumentationsregeln wurden auf den aktuellen Projektstand gebracht.
- Die App-Version wurde auf `0.8.4+32` erhöht.

## Testschwerpunkt

Da keine Dart- oder Flutter-Logik geändert wurde, genügt zusätzlich zum normalen
Testlauf eine kurze Kontrolle, dass App-Start, Binärpuzzle-Hub und Hashi-Hub
weiterhin erreichbar sind.
