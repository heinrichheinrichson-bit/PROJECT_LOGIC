import 'dart:async';

import 'package:flutter/services.dart';

enum PuzzleSound {
  move('sounds/move.wav', 0.18),
  remove('sounds/remove.wav', 0.16),
  hint('sounds/hint.wav', 0.28),
  success('sounds/success.wav', 0.38),
  levelUp('sounds/level_up.wav', 0.42),
  hashiConnect('sounds/hashi_connect.wav', 0.27),
  hashiRemove('sounds/hashi_remove.wav', 0.22);

  const PuzzleSound(this.asset, this.volume);

  final String asset;
  final double volume;
}

/// Small, reusable players for the app's short interaction sounds.
///
/// Playback failures are deliberately swallowed: a muted, interrupted or
/// unsupported audio device must never interrupt a puzzle move.
abstract final class PuzzleSoundPlayer {
  static const _channel = MethodChannel('project_logic/sounds');

  static Future<void> warmUp() async {
    try {
      await _channel.invokeMethod<void>(
        'preload',
        {'assets': PuzzleSound.values.map((sound) => sound.asset).toList()},
      );
    } on Object {
      // The app remains fully usable on devices without audio output.
    }
  }

  static Future<void> play(PuzzleSound sound) async {
    try {
      await _channel.invokeMethod<void>(
        'play',
        {'asset': sound.asset, 'volume': sound.volume},
      );
    } on Object {
      // Audio feedback is optional and must remain fail-safe.
    }
  }

  static void playUnawaited(PuzzleSound sound) {
    unawaited(play(sound));
  }
}
