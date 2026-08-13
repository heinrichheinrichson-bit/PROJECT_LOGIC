import '../domain/game_identity.dart';
import '../progress/experience_event.dart';
import 'puzzle_attempt.dart';

class DatedRecord {
  const DatedRecord(this.value, this.start, {this.end});
  final int value;
  final DateTime start;
  final DateTime? end;
}

class GameSpeedRecord {
  const GameSpeedRecord(this.gameType, this.seconds, this.date);
  final GameType gameType;
  final int seconds;
  final DateTime date;
}

class PersonalRecords {
  const PersonalRecords({
    this.longestStreak,
    this.mostXp,
    this.mostPuzzles,
    this.longestPlaytime,
    this.mostGameTypes,
    this.strongestMonth,
    this.fastestByGame = const [],
    this.usedFreezes = 0,
  });

  final DatedRecord? longestStreak;
  final DatedRecord? mostXp;
  final DatedRecord? mostPuzzles;
  final DatedRecord? longestPlaytime;
  final DatedRecord? mostGameTypes;
  final DatedRecord? strongestMonth;
  final List<GameSpeedRecord> fastestByGame;
  final int usedFreezes;
}

abstract final class PersonalRecordsCalculator {
  static PersonalRecords calculate({
    required Iterable<PuzzleAttempt> attempts,
    required Iterable<ExperienceEvent> experienceEvents,
    required Iterable<String> completedDays,
    required Iterable<String> frozenDays,
  }) {
    final attemptList = attempts.toList();
    final byDay = <DateTime, List<PuzzleAttempt>>{};
    for (final attempt in attemptList) {
      byDay.putIfAbsent(_day(attempt.completedAt), () => []).add(attempt);
    }
    final xpByDay = <DateTime, int>{};
    for (final event in experienceEvents) {
      if (event.points > 0) {
        xpByDay.update(_day(event.occurredAt), (value) => value + event.points,
            ifAbsent: () => event.points);
      }
    }
    final monthCounts = <DateTime, int>{};
    for (final attempt in attemptList) {
      final month =
          DateTime(attempt.completedAt.year, attempt.completedAt.month);
      monthCounts.update(month, (value) => value + 1, ifAbsent: () => 1);
    }
    final fastest = <GameType, PuzzleAttempt>{};
    for (final attempt in attemptList) {
      final existing = fastest[attempt.gameType];
      if (existing == null ||
          attempt.elapsedSeconds < existing.elapsedSeconds ||
          (attempt.elapsedSeconds == existing.elapsedSeconds &&
              attempt.completedAt.isAfter(existing.completedAt))) {
        fastest[attempt.gameType] = attempt;
      }
    }
    return PersonalRecords(
      longestStreak: _longestStreak([...completedDays, ...frozenDays]),
      mostXp: _maximum(xpByDay),
      mostPuzzles: _maximum({
        for (final entry in byDay.entries) entry.key: entry.value.length,
      }),
      longestPlaytime: _maximum({
        for (final entry in byDay.entries)
          entry.key:
              entry.value.fold(0, (sum, item) => sum + item.elapsedSeconds),
      }),
      mostGameTypes: _maximum({
        for (final entry in byDay.entries)
          entry.key: entry.value.map((item) => item.gameType).toSet().length,
      }),
      strongestMonth: _maximum(monthCounts),
      fastestByGame: [
        for (final gameType in GameType.values)
          if (fastest[gameType] case final attempt?)
            GameSpeedRecord(
                gameType, attempt.elapsedSeconds, _day(attempt.completedAt)),
      ],
      usedFreezes: frozenDays.toSet().length,
    );
  }

  static DatedRecord? _maximum(Map<DateTime, int> values) {
    if (values.isEmpty) return null;
    final entries = values.entries.toList()
      ..sort((a, b) {
        final byValue = b.value.compareTo(a.value);
        return byValue != 0 ? byValue : b.key.compareTo(a.key);
      });
    return DatedRecord(entries.first.value, entries.first.key);
  }

  static DatedRecord? _longestStreak(Iterable<String> rawDays) {
    final days = rawDays
        .map(DateTime.tryParse)
        .whereType<DateTime>()
        .map(_day)
        .toSet()
        .toList()
      ..sort();
    if (days.isEmpty) return null;
    var bestStart = days.first;
    var bestEnd = days.first;
    var runStart = days.first;
    for (var index = 1; index < days.length; index++) {
      if (days[index].difference(days[index - 1]).inDays != 1) {
        runStart = days[index];
      }
      final runLength = days[index].difference(runStart).inDays + 1;
      final bestLength = bestEnd.difference(bestStart).inDays + 1;
      if (runLength > bestLength ||
          (runLength == bestLength && days[index].isAfter(bestEnd))) {
        bestStart = runStart;
        bestEnd = days[index];
      }
    }
    return DatedRecord(
      bestEnd.difference(bestStart).inDays + 1,
      bestStart,
      end: bestEnd,
    );
  }

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
