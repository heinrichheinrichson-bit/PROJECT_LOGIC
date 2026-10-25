# Android-Startabsturz 0.8.53/0.8.54

## Nachgewiesene Ursache

Sowohl die lokal signierte APK 84 als auch Googles signierte APK 84 stürzten auf einem Android-24-Emulator bereits in `androidx.startup.InitializationProvider` ab. WorkManager konnte `androidx.work.impl.WorkDatabase` nicht erzeugen. Der Fehler trat vor Flutter auf und war unabhängig von der Signatur.

`apkanalyzer dex code` zeigte, dass `WorkDatabase_Impl` in APK 84 keinen Konstruktor mehr enthielt. Room erzeugt diese Datenbank per Reflection. R8 full mode behält den parameterlosen Konstruktor nicht automatisch, selbst wenn die Klasse erhalten bleibt. Siehe [Android-Dokumentation](https://developer.android.com/topic/performance/app-optimization/full-mode#default-constructor).

## Korrektur

`android/app/proguard-rules.pro` erhält gezielt den öffentlichen parameterlosen Konstruktor von `androidx.work.impl.WorkDatabase_Impl`. Die Release-Konfiguration lädt diese Datei zusätzlich zu den bestehenden Regeln. Der Optimierer bleibt aktiv.

Der Tippablauf aus 0.8.54 bleibt erhalten: drei kostenlose Tipps, danach öffnet erst das nächste Anfordern das freiwillige Werbeangebot. Verbrauchte sowie durch Werbung verdiente Tipps bleiben im gespeicherten Binairo-Spielstand erhalten.

## Prüfung von Version 85

- Fertige minifizierte Release-APK mit `tool/check_android_release.ps1` geprüft; benötigter Konstruktor vorhanden.
- Android 24, x86_64, Google-APIs-Emulator: Installation, Start, laufender Prozess, MainActivity und gerenderte Thinkheim-Startseite geprüft.
- Android 36, x86_64, 16-KB-Speicherseiten: dieselben Prüfungen erfolgreich; Screenshot zeigt gerenderte Startseite.
- Keine Startabstürze in den erfassten Protokollen.
- APK-Manifest: `com.thinkheim.app`, 0.8.55, Versionscode 85.
- Internes Test-AAB enthält in allen drei ABIs ausschließlich Googles Rewarded-Testanzeigenblock, keinen Live-Anzeigenblock.

Die Skriptausgaben und Screenshots liegen im Aufgaben-Ausgabeordner unter `Android-24-Starttest` und `Android-36-16KB-Starttest`.

## Installation und Veröffentlichung

Der interne Play-Test ist für das vom Nutzer genannte Google-Konto vorgesehen. Installation über Google Play vermeidet den Signaturkonflikt zwischen lokalem Upload-Schlüssel und Play-App-Signaturschlüssel. Der Start auf dem physischen Nutzerhandy sowie das Ansehen einer Testanzeige und die Prämienvergabe stehen noch zur Prüfung durch den Nutzer aus.

Version 85 mit Testanzeigen ausschließlich intern verwenden. Einen späteren Produktions-Build ohne `ADMOB_TEST_ADS=true` mit höherem Versionscode bauen. Die AdMob-App-Verifizierung ist weiterhin separat offen.
