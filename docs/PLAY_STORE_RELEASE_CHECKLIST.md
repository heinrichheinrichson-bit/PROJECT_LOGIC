# Google Play Release Checklist – Thinkheim

Stand: 22. August 2026, Version 0.8.50 (Build 79)

## Technisch erledigt

- [x] finaler App-Name Thinkheim eingetragen
- [x] Paketname und Namespace auf `com.thinkheim.app` gesetzt
- [x] dauerhafter Release-Keystore eingerichtet
- [x] Release-Signierung konfiguriert
- [x] signierte APK erzeugt
- [x] signiertes AAB erzeugt
- [x] `targetSdk` 36 geprüft
- [x] Entwickler-Lösefunktionen im Release ausgeblendet
- [x] Premium-Simulation im Release ausgeblendet und deaktiviert
- [x] Release-Manifest ohne Internet-Berechtigung geprüft
- [x] statische Analyse erfolgreich
- [x] 285 automatisierte Tests erfolgreich
- [x] deutsche und englische Store-Texte vorbereitet
- [x] Datenschutzentwurf auf Deutsch und Englisch vorbereitet

## Angaben und Inhalte vorbereiten

- [ ] Entwickler-/Anbietername festlegen
- [ ] Support-E-Mail festlegen
- [ ] Platzhalter im Datenschutzentwurf ersetzen
- [ ] Datenschutzerklärung öffentlich per HTTPS bereitstellen
- [ ] Store-Symbol mit 512 × 512 Pixeln finalisieren
- [x] Feature-Grafik mit 1024 × 500 Pixeln erstellen (`docs/store_assets/thinkheim_feature_graphic_1024x500.png`)
- [x] zweisprachige Support-/Datenschutzseite lokal vorbereiten (`docs/site/`)
- [ ] Smartphone-Screenshots auf Deutsch und Englisch erstellen
- [ ] Tablet-Screenshots erstellen

## Google Play Console

- [ ] App mit Paketname `com.thinkheim.app` anlegen
- [ ] Standard- und Übersetzungs-Store-Eintrag ausfüllen
- [ ] App-Zugriff erklären: kein Konto erforderlich
- [ ] Werbung wahrheitsgemäß als nicht enthalten angeben, solange kein Werbe-SDK eingebaut ist
- [ ] Inhaltsfreigabe-Fragebogen ausfüllen
- [ ] Zielgruppe und Inhalte festlegen
- [ ] Datensicherheitsformular ausfüllen
- [ ] Datenschutz-URL eintragen
- [ ] AAB in den internen Testkanal hochladen
- [ ] interne Tester hinzufügen
- [ ] geschlossenen Test mit mindestens 12 dauerhaft angemeldeten Testern über 14 Tage durchführen

## Interner Test

- [ ] Installation über Google Play auf dem Samsung S22 testen
- [ ] Update über Google Play testen, ohne Fortschritt zu verlieren
- [ ] alle sechs Spiele starten und abschließen
- [ ] Tagesrätsel, Kalender, Ziele, XP, Streak und Erfolge prüfen
- [ ] Ton und Vibration getrennt prüfen
- [ ] Erinnerungen sowie Neustart des Geräts prüfen
- [ ] Import/Export der Sicherung prüfen
- [ ] Tablet oder große Android-Bildschirmgröße prüfen
- [ ] Pre-Launch-Bericht der Play Console prüfen
- [ ] bestätigen, dass keine Entwicklerwerkzeuge sichtbar sind

## Produktionsfreigabe

- [ ] offene Fehler aus internem Test und Pre-Launch-Bericht beheben
- [ ] bei jeder Codeänderung Versionscode erhöhen und neues AAB bauen
- [ ] finalen Store-Eintrag und alle Rechtstexte gegenlesen
- [ ] Produktionsfreigabe zunächst gestaffelt veröffentlichen
