import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/core/presentation/puzzle_haptics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bridge feedback sends a short dedicated vibration pattern', () async {
    MethodCall? received;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(PuzzleHapticPlayer.channel, (call) async {
      received = call;
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(PuzzleHapticPlayer.channel, null);
    });

    await PuzzleHapticPlayer.play(PuzzleHaptic.bridge);

    expect(received?.method, 'vibrate');
    expect(received?.arguments, {
      'pattern': [0, 24],
      'amplitudes': [0, 88],
    });
  });

  test('success feedback contains two distinct pulses', () async {
    MethodCall? received;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(PuzzleHapticPlayer.channel, (call) async {
      received = call;
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(PuzzleHapticPlayer.channel, null);
    });

    await PuzzleHapticPlayer.play(PuzzleHaptic.success);

    expect(received?.arguments, {
      'pattern': [0, 32, 48, 58],
      'amplitudes': [0, 105, 0, 145],
    });
  });
}
