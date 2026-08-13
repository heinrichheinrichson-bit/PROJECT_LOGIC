import 'dart:async';

import 'package:flutter/services.dart';

enum PuzzleHaptic {
  selection([0, 18], [0, 72]),
  bridge([0, 24], [0, 88]),
  hint([0, 34], [0, 112]),
  success([0, 32, 48, 58], [0, 105, 0, 145]),
  levelUp([0, 34, 42, 48, 42, 82], [0, 110, 0, 135, 0, 175]);

  const PuzzleHaptic(this.pattern, this.amplitudes);

  final List<int> pattern;
  final List<int> amplitudes;
}

abstract final class PuzzleHapticPlayer {
  static const channel = MethodChannel('project_logic/haptics');

  static Future<void> play(PuzzleHaptic haptic) async {
    try {
      await channel.invokeMethod<void>('vibrate', {
        'pattern': haptic.pattern,
        'amplitudes': haptic.amplitudes,
      });
    } on Object {
      // Feedback remains optional on devices without a vibrator.
    }
  }

  static void playUnawaited(PuzzleHaptic haptic) {
    unawaited(play(haptic));
  }
}
