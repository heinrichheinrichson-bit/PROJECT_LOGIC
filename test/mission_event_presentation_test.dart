import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/core/presentation/mission_event_presentation.dart';

void main() {
  test('daily and weekly goals keep their visible names in XP history', () {
    expect(
      missionEventTitle('daily-2026-08-13-no-hint'),
      'Ganz ohne Hilfe',
    );
    expect(
      missionEventTitle('week-2026-08-10-no-hint'),
      'Aus eigener Kraft',
    );
    expect(
      missionEventTitle('daily-2026-08-12-variety'),
      'Doppelte Abwechslung',
    );
    expect(
      missionEventTitle('week-2026-08-10-variety'),
      'Abwechslungsreiche Woche',
    );
  });

  test('XP history clearly identifies mission scope', () {
    expect(missionEventDetail('daily-2026-08-13-catalog'), 'Tagesziel');
    expect(missionEventDetail('week-2026-08-10-no-hint'), 'Wochenziel');
    expect(
      missionEventDetail('daily-2026-08-13-daily-complete'),
      'Tages-Komplettbonus',
    );
    expect(
      missionEventDetail('week-2026-08-10-weekly-complete'),
      'Wochen-Komplettbonus',
    );
  });
}
