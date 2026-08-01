import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app_preferences.dart';

/// Central haptic language for every puzzle type.
///
/// Keeping this in one place prevents games from ignoring the global setting
/// or feeling needlessly different on the same device.
abstract final class PuzzleInteractionFeedback {
  static bool _enabled(BuildContext context) =>
      PreferencesScope.maybeOf(context)?.hapticsEnabled ?? false;

  static void selection(BuildContext context) {
    if (!_enabled(context)) return;
    unawaited(HapticFeedback.selectionClick());
  }

  static void hint(BuildContext context) {
    if (!_enabled(context)) return;
    unawaited(HapticFeedback.lightImpact());
  }

  static void success(BuildContext context) {
    if (!_enabled(context)) return;
    unawaited(HapticFeedback.mediumImpact());
  }
}
