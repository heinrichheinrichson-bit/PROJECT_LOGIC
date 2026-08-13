import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_preferences.dart';
import 'puzzle_haptics.dart';
import 'puzzle_sound.dart';

/// Central haptic language for every puzzle type.
///
/// Keeping this in one place prevents games from ignoring the global setting
/// or feeling needlessly different on the same device.
abstract final class PuzzleInteractionFeedback {
  static void warmUpSounds() {
    unawaited(PuzzleSoundPlayer.warmUp());
  }

  static bool _hapticsEnabled(BuildContext context) =>
      PreferencesScope.maybeOf(context)?.hapticsEnabled ?? false;

  static bool _soundsEnabled(BuildContext context) =>
      PreferencesScope.maybeOf(context)?.soundsEnabled ?? false;

  static void _sound(BuildContext context, PuzzleSound sound) {
    if (_soundsEnabled(context)) PuzzleSoundPlayer.playUnawaited(sound);
  }

  static void _haptic(BuildContext context, PuzzleHaptic haptic) {
    if (_hapticsEnabled(context)) PuzzleHapticPlayer.playUnawaited(haptic);
  }

  static void selection(BuildContext context) {
    _sound(context, PuzzleSound.move);
    _haptic(context, PuzzleHaptic.selection);
  }

  static void removal(BuildContext context) {
    _sound(context, PuzzleSound.remove);
    _haptic(context, PuzzleHaptic.selection);
  }

  static void hashiBridge(BuildContext context, {required bool removed}) {
    _sound(
      context,
      removed ? PuzzleSound.hashiRemove : PuzzleSound.hashiConnect,
    );
    _haptic(context, PuzzleHaptic.bridge);
  }

  static void hint(BuildContext context) {
    _sound(context, PuzzleSound.hint);
    _haptic(context, PuzzleHaptic.hint);
  }

  static void success(BuildContext context) {
    _sound(context, PuzzleSound.success);
    _haptic(context, PuzzleHaptic.success);
  }

  static void levelUp(BuildContext context) {
    _sound(context, PuzzleSound.levelUp);
    _haptic(context, PuzzleHaptic.levelUp);
  }
}
