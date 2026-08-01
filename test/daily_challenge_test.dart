import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/core/domain/game_identity.dart';
import 'package:project_logic_prototype/daily_challenge.dart';

void main() {
  const service = DailyChallengeService();

  test('same calendar day creates the same daily challenge', () {
    final morning = service.challengeFor(DateTime(2026, 7, 30, 8));
    final evening = service.challengeFor(DateTime(2026, 7, 30, 21));

    expect(morning.puzzleId, 'daily-binary-2026-07-30');
    expect(evening.puzzleId, morning.puzzleId);
    expect(evening.seed, morning.seed);
    expect(evening.definition.solution, morning.definition.solution);
    expect(evening.definition.clues, morning.definition.clues);
  });

  test('a different calendar day creates a different daily identity', () {
    final first = service.challengeFor(DateTime(2026, 7, 30));
    final second = service.challengeFor(DateTime(2026, 7, 31));

    expect(second.puzzleId, isNot(first.puzzleId));
    expect(second.seed, isNot(first.seed));
  });

  test('daily rotation only uses supported sizes and difficulties', () {
    for (var offset = 0; offset < 3; offset++) {
      final challenge = service.challengeFor(
        DateTime(2026, 7, 1).add(Duration(days: offset)),
      );
      expect({4, 6, 8}, contains(challenge.size));
      expect(challenge.definition.id, startsWith('daily-binary-'));
    }
  });

  test('archive returns the requested days newest first', () {
    final archive = service.archiveSummaries(
      through: DateTime(2026, 7, 30, 23, 59),
      days: 30,
    );

    expect(archive, hasLength(30));
    expect(archive.first.dayKey, '2026-07-30');
    expect(archive.last.dayKey, '2026-07-01');
    expect(
        archive.map((challenge) => challenge.puzzleId).toSet(), hasLength(30));
  });

  test('archive rejects an empty lookback window', () {
    expect(
      () => service.archiveSummaries(through: DateTime(2026, 7, 30), days: 0),
      throwsArgumentError,
    );
  });

  test('daily title includes the archived calendar date', () {
    final challenge = service.challengeFor(DateTime(2026, 7, 30));

    expect(challenge.title, contains('30. Juli'));
    expect(challenge.title, contains('${challenge.size} × ${challenge.size}'));
  });

  test('every game receives an independent deterministic daily calendar', () {
    final date = DateTime(2026, 8, 1);
    final hashi = service.summaryForGame(date, GameType.hashi);
    final slitherlink = service.summaryForGame(date, GameType.slitherlink);
    final hitori = service.summaryForGame(date, GameType.hitori);
    final tents = service.summaryForGame(date, GameType.tents);

    expect(hashi.puzzleId, 'daily-hashi-2026-08-01');
    expect(slitherlink.puzzleId, 'daily-slitherlink-2026-08-01');
    expect(hitori.puzzleId, 'daily-hitori-2026-08-01');
    expect(tents.puzzleId, 'daily-tents-2026-08-01');
    expect(hitori.size, inInclusiveRange(5, 7));
    expect(tents.size, isIn(const [6, 8, 10]));
    expect(hashi.seed, isNot(slitherlink.seed));
    expect(
      service.archiveSummariesForGame(GameType.hashi, through: date, days: 30),
      hasLength(30),
    );
  });
}
