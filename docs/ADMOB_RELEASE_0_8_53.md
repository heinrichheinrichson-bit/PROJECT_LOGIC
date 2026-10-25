# Thinkheim 0.8.53+83 – AdMob

## Eingerichtet

- Android-Paket `com.thinkheim.app` mit dem öffentlichen Play-Eintrag verknüpft.
- AdMob-App-ID `ca-app-pub-2541162065593575~3132878375` im Android-Manifest.
- Rewarded-Anzeigenblock `ca-app-pub-2541162065593575/9506715032` (1 Tipp).
- app-ads.txt: https://heinrichheinrichson-bit.github.io/app-ads.txt
- UMP-Mitteilung „Thinkheim – Datenschutz für freiwillige Werbetipps“, Englisch und Deutsch, direkte Ablehnen-Option in allen Ländern aktiviert.
- Datenschutzseite für diese Version: https://heinrichheinrichson-bit.github.io/PROJECT_LOGIC/privacy.html

## Verhalten

Nach drei kostenlosen Tipps kann ein zusätzlicher Tipp durch eine freiwillige Anzeige freigeschaltet werden. Alle sechs Spiele verwenden denselben Ablauf. Ausschließlich `onUserEarnedReward` gibt den Tipp frei; der Aufrufer erhält das Ergebnis erst nach dem Schließen der Anzeige. Abbruch, Lade-/Anzeigefehler und fehlende Einwilligungsbereitschaft ergeben keine Prämie. Pro App kann höchstens ein Werbeablauf gleichzeitig laufen. Ein verspäteter Lade-Callback wird entsorgt, wenn der Dialog inzwischen geschlossen wurde oder die Ladefrist ablief.

Die neutrale Altersabfrage speichert ausschließlich eine lokale Altersgruppe. Unter 16 werden weder AdMob noch UMP kontaktiert. Es gibt dadurch keine zusätzlichen/unbegrenzten Tipps. Ab 16 aktualisiert UMP die Einwilligungsinformationen; vor jeder Anzeige muss `canRequestAds` erfüllt sein. Bei erforderlichen Datenschutzoptionen erscheint ein Eintrag in den Einstellungen. Angefordert werden nicht personalisierte Anzeigen mit Inhaltsfreigabe G. Nicht-Android-Plattformen schalten keine Werbung.

## Build

- Produktion: `flutter build appbundle --release` verwendet die echte Anzeigenblock-ID.
- Sichere Geräteprüfung: `flutter build apk --release --dart-define=ADMOB_TEST_ADS=true` verwendet echte SDK-Testanzeigen von Google, keine Simulation.
- Debug-/Profil-Builds verwenden automatisch Google-Testanzeigen.
- Die Test-Kennung ist `ca-app-pub-3940256099942544/5224354917`.
- Der Testschalter darf beim Produktions-AAB nicht gesetzt werden.

## Verifikation

`flutter analyze`: keine Issues. 307 Tests bestanden, darunter Reward-Callback, Schließen ohne Reward, Einwilligungsfehler, No-fill, Anzeigefehler, parallele Anfragen, Abbruch während des Ladens und verspätete Callback-Entsorgung. Spieltests für Futoshiki, Hitori, Slitherlink und Zelte prüfen die Übergabe des bestätigten Rewards an den Tippestand.

Ein echter Android-Gerätetest steht noch aus; beim Build war kein ADB-Gerät verbunden. Für die Store-Veröffentlichung müssen zusätzlich die AdMob-App-/Kontofreigabe und aktualisierte Store-Deklarationen abgeschlossen sein. Die bisherige Live-Version enthält das SDK noch nicht.

Test-APK und Produktions-AAB wurden erfolgreich gebaut. In allen drei enthaltenen ABI-Bibliotheken wurde geprüft: Test-APK enthält ausschließlich die Google-Test-Anzeigenblock-ID, Produktions-AAB ausschließlich die echte Thinkheim-Anzeigenblock-ID. Paketversion 0.8.53, Android-Versioncode 83. Die irreführende Flutter-Konsolenzeile mit einem älteren AAB-Dateinamen ist kein Produktionsnachweis; geprüft und kopiert wurde das neu erzeugte `app-release.aab`.

Werbung („Ja“), Werbe-ID („Ja“, Zwecke Analyse/Werbung/Betrugsprävention) und Datensicherheit wurden in der Play Console gespeichert. Ausgewählt sind ungefährer Standort, Diagnosedaten, App-Interaktionen und Geräte-/andere IDs; jeweils erhoben und geteilt, nicht ausschließlich sitzungsspezifisch, optional durch die freiwillige Werbenutzung. Die Änderungen sind noch nicht zur Prüfung eingereicht.

Der Android-Build benötigte für HTTPS-Downloads eine auf diesen Build begrenzte Kopie des Java-Vertrauensspeichers mit dem bereits von Windows vertrauten Norton-Web/Mail-Shield-Zertifikat. TLS wurde nicht deaktiviert. Die Projekt-Gradle-Einstellungen wurden danach vollständig wiederhergestellt.

## Store-Deklarationen vor Veröffentlichung

- Enthält Werbung: Ja (freiwillige Rewarded-Anzeigen).
- Werbe-ID: Ja, soweit die zusammengeführte Release-Manifestdatei `com.google.android.gms.permission.AD_ID` enthält (SDK-Standard).
- Datensicherheit: Die bisherige Angabe „keine Daten erhoben/weitergegeben“ gilt nicht mehr für diese Version. Google dokumentiert IP-Adresse/ungefähren Standort, Produktinteraktionen, Diagnoseinformationen und Geräte-/Kontokennungen. Zwecke: Werbung, Messung/Analyse und Betrugsvermeidung; verschlüsselte Übertragung. Die Datenverarbeitung ist an die optionale Werbenutzung gekoppelt. Nicht als ausschließlich flüchtige Verarbeitung deklarieren.
- Keine Erhebung von Namen, E-Mail, Kontakten oder Rätsellösungen durch Thinkheim hinzuerfinden. Altersgruppe und Spielstände werden lokal gespeichert; Android-Sicherung ist gesondert beschrieben.
- Details anhand der tatsächlich eingebauten SDK-Version und Googles Anleitung ausfüllen: https://developers.google.com/admob/android/privacy/play-data-disclosure

## Gerätetest mit Google-Testanzeigen

1. Test-APK als Update installieren; bestehende Spielstände prüfen.
2. In einem Rätsel drei Tipps verbrauchen, dann einen zusätzlichen Tipp anfordern.
3. Altersgruppe und gegebenenfalls Einwilligung auswählen.
4. Anzeige abbrechen: kein zusätzlicher Tipp.
5. Google-Testanzeige bis zum Reward ansehen: exakt ein zusätzlicher Tipp.
6. Offline und beim Schließen während des Ladens: kein später aufspringendes Video, kein geschenkter Tipp.
7. Datenschutzoptionen in den Einstellungen öffnen und ändern, sofern UMP sie verlangt.

Keine eigenen Live-Anzeigen anklicken, um die Implementierung zu testen. Dafür die separat erzeugte Test-APK verwenden.
