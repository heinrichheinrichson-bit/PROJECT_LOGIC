# Werbetipps ohne eigene Altersabfrage (0.8.56 / 86)

## Verhalten

Nach drei verbrauchten kostenlosen Tipps öffnet das Anfordern eines weiteren Tipps direkt die freiwillige Werbeauswahl. Es wird keine Altersgruppe abgefragt. Die alte Angabe unter `ad_age_group_v1` wird beim Android-App-Start entfernt und wird nirgendwo mehr zur Sperre des Werbetipps verwendet. Andere Einstellungen und Spielstände werden dabei nicht entfernt.

Für alle Nutzer wird einheitlich Googles strengste Anzeigenbehandlung angefordert: `AgeRestrictedTreatment.child`, `MaxAdContentRating.g` und nicht personalisierte Anzeigen. Das ist eine Einstellung für die Anzeigenbehandlung, keine neu erhobene Altersangabe. UMP erhält passend dazu `tagForUnderAgeOfConsent: true`. Die eigene Altersauswahl und ihr Sperrdialog wurden vollständig entfernt. Die übrige UMP-Prüfung und der Abbruch bei einem Fehler bleiben erhalten.

Google beschreibt diese Einstellungen unter [Flutter Targeting](https://developers.google.com/admob/flutter/targeting) und [UMP GDPR](https://developers.google.com/admob/flutter/privacy/gdpr). Diese technischen Einschränkungen ersetzen keine vollständige rechtliche Prüfung der App.

Ohne vorherigen Werbe-Opt-in wird beim Start keine UMP-Netzwerkabfrage angestoßen. Vor dem tatsächlichen Laden einer Anzeige wird die Sitzung wie bisher über UMP geprüft. Der zusätzliche Tipp wird weiterhin nur nach Googles Prämienbestätigung vergeben.

## Prüfung

- 310 automatisierte Tests bestanden, darunter Auswahl „unter 16“ aus einer Vorgängerversion, direkter Werbe-Opt-in, Ablehnung ohne Prämie und Erhalt der übrigen lokalen Daten.
- Codeanalyse ohne Issues.
- Minifizierte Release-APK 86 startet auf dem Android-36-Emulator mit 16-KB-Speicherseiten bis zur gerenderten Thinkheim-Startseite. Room-Konstruktor im fertigen APK geprüft.
- Datenschutzerklärung auf der bestehenden öffentlichen URL aktualisiert; Versionsgeschichte 0.8.53–0.8.55 bleibt beschrieben.

## Interner Test

Build 86 verwendet weiterhin ausschließlich Google-Testanzeigen. Die native Anzeigenauslieferung und Prämienvergabe auf dem physischen Nutzerhandy stehen zur Bestätigung aus. Der spätere Produktions-Build benötigt den Live-Anzeigenblock sowie die noch offene AdMob-Verifizierung.
