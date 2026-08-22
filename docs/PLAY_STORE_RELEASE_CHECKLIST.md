# Thinkheim – Google Play release checklist

This checklist separates the tested app from the one-time production identity
and store setup. It deliberately does not change the current test installation
until the final production choices are confirmed.

## Completed in the app

- Thinkheim name, wordmark, launcher icon, splashscreen, and web metadata
- German and English interface
- six playable puzzle families with offline saves
- daily puzzles, catalogs, random puzzles, hints, statistics, XP, achievements,
  streaks, streak freeze, reminders, sound, and vibration
- automated Flutter regression suite and static analysis
- Android debug build for real-device testing

## Required before the first Play upload

- choose a permanent Android application ID, for example `at.thinkheim.app` or
  `com.thinkheim.app`; it cannot be changed after the first Play release
- create and securely archive the production upload keystore and passwords
- replace debug signing with the production signing configuration
- build and verify a signed release Android App Bundle (`.aab`)
- decide whether existing prototype test data needs an export/import migration
  into the final production application ID
- complete the Play Console app-content, data-safety, target-audience, content
  rating, ads, and privacy-policy declarations
- prepare store title, short and long descriptions, screenshots, feature
  graphic, app icon, support contact, and privacy-policy URL in German and English
- run internal/closed testing and test installation plus update from Play
- smoke-test notifications, timezone changes, backup/restore, all six games,
  purchases or paid streak repair once monetization is enabled, and common
  phone/tablet sizes

## Release gate

Do not upload a production bundle while the package still uses
`com.example.project_logic_prototype` or the Android release build still uses
the debug signing key.
