# Thinkheim – technischer Release-Audit 0.8.50

Prüfstand: 22. August 2026

## Ergebnis

Der lokale Android-Release-Kandidat ist technisch für einen Upload in einen internen Google-Play-Test vorbereitet. Vor einer öffentlichen Veröffentlichung fehlen vor allem Play-Console-Angaben, veröffentlichte Rechtstexte, finale Store-Grafiken und ein Test des über Google Play ausgelieferten Builds.

## Geprüft und bestanden

- App-Name: Thinkheim
- Paketname und Android-Namespace: `com.thinkheim.app`
- Version: `0.8.50+79`
- Android `minSdk`: 24
- Android `targetSdk`: 36
- Release-Signierung vorhanden
- signiertes Release-AAB vorhanden: `build/app/outputs/bundle/release/app-release.aab`
- signierte Release-APK vorhanden: `build/app/outputs/flutter-apk/app-release.apk`
- Release-Manifest enthält keine Internet-Berechtigung
- lokale Erinnerungen verwenden nur die benötigten Android-Berechtigungen
- Entwickler-Lösemenüs sind in Release-Builds ausgeblendet
- Premium-Simulation ist in Release-Builds ausgeblendet und deaktiviert
- keine Analyse-, Werbe-, Tracking- oder In-App-Kauf-SDKs im aktuellen Release
- deutsche und englische Oberfläche vorhanden
- Android-Gerätesicherung und manuelle Sicherung sind im Datenschutzentwurf berücksichtigt
- statische Analyse ohne Befunde
- vollständige Testsuite mit 285 Tests bestanden

## Noch offen vor dem internen Play-Test

- Entwickler-/Anbietername festlegen
- Support-E-Mail festlegen und überwachen
- Platzhalter im Datenschutztext ersetzen
- Datenschutztext öffentlich per HTTPS bereitstellen
- App in der Google Play Console mit `com.thinkheim.app` anlegen
- Store-Eintrag auf Deutsch und Englisch eintragen
- 512 × 512 Store-Symbol hochladen
- 1024 × 500 Feature-Grafik erstellen und hochladen
- Smartphone- und Tablet-Screenshots hochladen
- Angaben zu Zielgruppe, Inhaltsfreigabe, Werbung und Datenverarbeitung ausfüllen
- AAB in den internen Testkanal laden

## Noch offen vor Produktion

- Installation und Update ausschließlich über den internen Play-Test prüfen
- Start, alle sechs Spiele und Abschlussdialoge testen
- Import/Export sowie Android-Sicherung nach Möglichkeit auf einem zweiten Gerät prüfen
- Erinnerungen, Neustart und Zeitzonenwechsel prüfen
- Smartphone und Tablet beziehungsweise mehrere Bildschirmgrößen prüfen
- Google-Play-Pre-Launch-Bericht kontrollieren
- final prüfen, dass keine Entwicklerfunktionen sichtbar sind
- Versionscode erhöhen, falls nach Build 79 noch Code geändert wird

## Hinweise zur Google-Play-Datensicherheit

Der aktuelle Release besitzt kein eigenes Backend und keine Internet-Berechtigung. Dennoch muss das Formular „Datensicherheit“ in Google Play vollständig ausgefüllt und eine Datenschutz-URL angegeben werden. Die Betriebssystem-Sicherung ist dabei getrennt von einer Datenübertragung an eigene Entwicklerserver zu betrachten und wahrheitsgemäß anhand der Fragen in der Play Console zu beantworten.
