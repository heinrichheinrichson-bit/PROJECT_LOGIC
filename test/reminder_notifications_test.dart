import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/core/presentation/reminder_notifications.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('project_logic/reminders');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('passes both independent reminder schedules to Android', () async {
    MethodCall? received;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      received = call;
      return true;
    });

    final configured = await ReminderNotifications.configure(
      dailyEnabled: true,
      dailyMinutes: 17 * 60 + 45,
      streakEnabled: true,
      streakMinutes: 21 * 60,
      requestPermission: true,
    );

    expect(configured, isTrue);
    expect(received?.method, 'configure');
    expect(received?.arguments, {
      'dailyEnabled': true,
      'dailyMinutes': 1065,
      'streakEnabled': true,
      'streakMinutes': 1260,
      'requestPermission': true,
    });
  });

  test('completion dismisses already delivered reminders', () async {
    String? method;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      method = call.method;
      return null;
    });

    await ReminderNotifications.dismissForCompletedDay();

    expect(method, 'completedToday');
  });

  test('notification integration never interrupts the app', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'unavailable');
    });

    expect(
      await ReminderNotifications.configure(
        dailyEnabled: true,
        dailyMinutes: 1080,
        streakEnabled: false,
        streakMinutes: 1260,
      ),
      isFalse,
    );
    await ReminderNotifications.dismissForCompletedDay();
  });
}
