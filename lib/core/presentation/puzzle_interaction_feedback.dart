import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_preferences.dart';
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

  static void selection(BuildContext context) {
    _sound(context, PuzzleSound.move);
    if (_hapticsEnabled(context)) unawaited(HapticFeedback.selectionClick());
  }

  static void removal(BuildContext context) {
    _sound(context, PuzzleSound.remove);
    if (_hapticsEnabled(context)) unawaited(HapticFeedback.selectionClick());
  }

  static void hashiBridge(BuildContext context, {required bool removed}) {
    _sound(
      context,
      removed ? PuzzleSound.hashiRemove : PuzzleSound.hashiConnect,
    );
    if (_hapticsEnabled(context)) unawaited(HapticFeedback.selectionClick());
  }

  static void hint(BuildContext context) {
    _sound(context, PuzzleSound.hint);
    if (_hapticsEnabled(context)) unawaited(HapticFeedback.lightImpact());
  }

  static void success(BuildContext context) {
    _sound(context, PuzzleSound.success);
    if (_hapticsEnabled(context)) unawaited(HapticFeedback.mediumImpact());
  }

  static void levelUp(BuildContext context) {
    _sound(context, PuzzleSound.levelUp);
    if (_hapticsEnabled(context)) unawaited(HapticFeedback.heavyImpact());
  }
}
