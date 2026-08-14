import 'player_progress_system.dart';

/// Formats counters without exposing internal storage units to the player.
String formatProgressGoalCounter(
  ProgressGoal goal, {
  required bool isGerman,
}) {
  final current = goal.current.clamp(0, goal.target);
  final isPlaytimeGoal = goal.id == 'play-hour' ||
      goal.id == 'play-ten-hours' ||
      goal.id.startsWith('play-hours-');
  if (!isPlaytimeGoal) {
    return '$current / ${goal.target}';
  }

  return '${_formatDuration(current, isGerman: isGerman)} / '
      '${_formatDuration(goal.target, isGerman: isGerman)}';
}

String _formatDuration(int seconds, {required bool isGerman}) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final hourUnit = isGerman ? 'Std.' : 'h';
  final minuteUnit = isGerman ? 'Min.' : 'min';
  if (minutes == 0) return '$hours $hourUnit';
  return '$hours $hourUnit $minutes $minuteUnit';
}
