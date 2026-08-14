import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/player_progress_system.dart';
import 'package:project_logic_prototype/progress_goal_formatting.dart';

void main() {
  const playtimeGoal = ProgressGoal(
    id: 'play-hours-180000',
    title: 'Fünfzig Stunden Logik',
    description: 'Verbringe insgesamt 50 Stunden beim Rätseln.',
    iconName: 'timer',
    current: 17564,
    target: 180000,
    kind: ProgressGoalKind.achievement,
  );

  test('playtime counters convert internal seconds to readable German time',
      () {
    expect(
      formatProgressGoalCounter(playtimeGoal, isGerman: true),
      '4 Std. 52 Min. / 50 Std.',
    );
  });

  test('playtime counters convert internal seconds to readable English time',
      () {
    expect(
      formatProgressGoalCounter(playtimeGoal, isGerman: false),
      '4 h 52 min / 50 h',
    );
  });

  test('ordinary achievement counters remain unchanged', () {
    const goal = ProgressGoal(
      id: 'daily-100',
      title: 'Hundert Tage Logik',
      description: 'Löse 100 Tagesrätsel.',
      iconName: 'calendar_month',
      current: 21,
      target: 100,
      kind: ProgressGoalKind.achievement,
    );
    expect(
      formatProgressGoalCounter(goal, isGerman: false),
      '21 / 100',
    );
  });
}
