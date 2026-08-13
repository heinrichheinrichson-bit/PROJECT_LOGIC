import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/app_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sounds are enabled by default and persist independently', () async {
    SharedPreferences.setMockInitialValues({
      'setting_haptics_v1': true,
    });

    final preferences = await AppPreferences.load();
    expect(preferences.soundsEnabled, isTrue);
    expect(preferences.hapticsEnabled, isTrue);

    await preferences.setSoundsEnabled(false);
    final reloaded = await AppPreferences.load();

    expect(reloaded.soundsEnabled, isFalse);
    expect(reloaded.hapticsEnabled, isTrue);
  });

  test('reminders default off with useful independent times', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await AppPreferences.load();

    expect(preferences.dailyReminderEnabled, isFalse);
    expect(preferences.dailyReminderMinutes, 18 * 60);
    expect(preferences.streakWarningEnabled, isFalse);
    expect(preferences.streakWarningMinutes, 21 * 60);

    await preferences.setDailyReminderEnabled(true);
    await preferences.setDailyReminderMinutes(17 * 60 + 30);
    await preferences.setStreakWarningEnabled(true);
    await preferences.setStreakWarningMinutes(22 * 60);
    final restored = await AppPreferences.load();

    expect(restored.dailyReminderEnabled, isTrue);
    expect(restored.dailyReminderMinutes, 17 * 60 + 30);
    expect(restored.streakWarningEnabled, isTrue);
    expect(restored.streakWarningMinutes, 22 * 60);
  });

  test('all bundled sounds are valid wave assets', () async {
    const assets = [
      'assets/sounds/move.wav',
      'assets/sounds/remove.wav',
      'assets/sounds/hint.wav',
      'assets/sounds/success.wav',
      'assets/sounds/level_up.wav',
      'assets/sounds/hashi_connect.wav',
      'assets/sounds/hashi_remove.wav',
    ];

    for (final asset in assets) {
      final data = await rootBundle.load(asset);
      expect(data.lengthInBytes, greaterThan(44), reason: asset);
      expect(
        String.fromCharCodes(data.buffer.asUint8List(0, 4)),
        'RIFF',
        reason: asset,
      );
      expect(
        String.fromCharCodes(data.buffer.asUint8List(8, 4)),
        'WAVE',
        reason: asset,
      );
    }
  });
}
