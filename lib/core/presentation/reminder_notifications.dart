import 'package:flutter/services.dart';

abstract final class ReminderNotifications {
  static const _channel = MethodChannel('project_logic/reminders');

  static Future<bool> configure({
    required bool dailyEnabled,
    required int dailyMinutes,
    required bool streakEnabled,
    required int streakMinutes,
    bool requestPermission = false,
  }) async {
    try {
      return await _channel.invokeMethod<bool>('configure', {
            'dailyEnabled': dailyEnabled,
            'dailyMinutes': dailyMinutes,
            'streakEnabled': streakEnabled,
            'streakMinutes': streakMinutes,
            'requestPermission': requestPermission,
          }) ??
          false;
    } on Object {
      return false;
    }
  }
}
