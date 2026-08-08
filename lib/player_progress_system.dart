import 'daily_challenge.dart';
import 'game_logic.dart';
import 'game_storage.dart';
import 'core/progress/experience_event.dart';
import 'core/progress/experience_points_policy.dart';
import 'core/statistics/puzzle_attempt.dart';

enum ProgressGoalKind { achievement, mission }

class ProgressSnapshot {
  const ProgressSnapshot({
    required this.results,
    required this.progress,
    required this.catalogPuzzleIds,
    this.attempts = const [],
  });

  final Map<String, PuzzleResult> results;
  final PlayerProgress progress;
  final Set<String> catalogPuzzleIds;
  final List<PuzzleAttempt> attempts;

  int get totalCompleted => progress.totalCompleted;

  int completedForGame(GameType gameType) => results.values
      .where((result) => result.gameType == gameType)
      .fold(0, (sum, result) => sum + result.completionCount);

  int get catalogCompleted =>
      results.keys.where(catalogPuzzleIds.contains).length;

  int get generatedCompleted => results.values
      .where((result) => result.effectiveSource == PuzzleSource.generated)
      .fold(0, (sum, result) => sum + result.completionCount);

  int get dailyCompleted => results.values
      .where((result) => result.effectiveSource == PuzzleSource.daily)
      .length;

  int get hardCompleted => results.values
      .where((result) => result.effectiveDifficulty == PuzzleDifficulty.hard)
      .fold(0, (sum, result) => sum + result.completionCount);

  int get largeBoardCompleted => results.values
      .where((result) => (result.effectiveBoardSize ?? 0) >= 10)
      .fold(0, (sum, result) => sum + result.completionCount);

  bool get dailyCompletedToday {
    const service = DailyChallengeService();
    final ids = {
      for (final gameType in const [
        GameType.binairo,
        GameType.hashi,
        GameType.slitherlink,
        GameType.futoshiki,
        GameType.hitori,
        GameType.tents,
      ])
        service.summaryForGame(DateTime.now(), gameType).puzzleId,
    };
    return results.values.any(
      (result) =>
          result.effectiveSource == PuzzleSource.daily &&
          ids.contains(result.puzzleId),
    );
  }

  int completionsTodayBySource(PuzzleSource source, DateTime date) {
    if (attempts.isNotEmpty) {
      return attempts
          .where((attempt) =>
              attempt.mode == source && _isSameDay(attempt.completedAt, date))
          .length;
    }
    final day = DateTime(date.year, date.month, date.day);
    return results.values.where((result) {
      final completed = result.completedAt;
      final completedDay =
          DateTime(completed.year, completed.month, completed.day);
      return result.effectiveSource == source && completedDay == day;
    }).length;
  }

  List<PuzzleAttempt> attemptsOnDay(DateTime date) => attempts
      .where((attempt) => _isSameDay(attempt.completedAt, date))
      .toList(growable: false);

  List<PuzzleAttempt> attemptsInWeek(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final monday = day.subtract(Duration(days: day.weekday - 1));
    final sunday = monday.add(const Duration(days: 7));
    return attempts.where((attempt) {
      final completed = DateTime(
        attempt.completedAt.year,
        attempt.completedAt.month,
        attempt.completedAt.day,
      );
      return !completed.isBefore(monday) && completed.isBefore(sunday);
    }).toList(growable: false);
  }

  static bool _isSameDay(DateTime first, DateTime second) =>
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;

  int get completionsToday {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    return results.values.where((result) {
      final completed = result.completedAt;
      return DateTime(completed.year, completed.month, completed.day) == day;
    }).length;
  }

  int activeDaysInWeek(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final monday = day.subtract(Duration(days: day.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    return progress.completedDays
        .map(DateTime.tryParse)
        .whereType<DateTime>()
        .where(
      (value) {
        final completed = DateTime(value.year, value.month, value.day);
        return !completed.isBefore(monday) && !completed.isAfter(sunday);
      },
    ).length;
  }

  int get distinctGamesCompleted => GameType.values
      .where((gameType) => completedForGame(gameType) > 0)
      .length;
}

class ProgressGoal {
  const ProgressGoal({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.target,
    required this.current,
    required this.kind,
  });

  final String id;
  final String title;
  final String description;
  final String iconName;
  final int target;
  final int current;
  final ProgressGoalKind kind;

  bool get isCompleted => current >= target;
  double get progress =>
      target <= 0 ? 1 : (current / target).clamp(0, 1).toDouble();
  int get remaining => (target - current).clamp(0, target).toInt();
}

class PlayerRank {
  const PlayerRank({
    required this.level,
    required this.title,
    required this.currentXp,
    required this.nextLevelXp,
  });

  final int level;
  final String title;
  final int currentXp;
  final int nextLevelXp;

  double get progress =>
      nextLevelXp == 0 ? 1 : (currentXp / nextLevelXp).clamp(0, 1).toDouble();
}

class PlayerProgressService {
  const PlayerProgressService();

  /// XP required to advance from [level] to the following level.
  /// Early levels rise clearly; later growth is gentler and capped.
  static int xpRequiredForLevel(int level) {
    if (level < 1) throw ArgumentError.value(level, 'level');
    if (level <= 9) return 150 + level * 50;
    if (level <= 19) return 650 + (level - 10) * 25;
    if (level <= 29) return 950 + (level - 20) * 25;
    return (1200 + (level - 30) * 25).clamp(1200, 1500);
  }

  static int totalXpRequiredForLevel(int level) {
    if (level < 1) throw ArgumentError.value(level, 'level');
    var total = 0;
    for (var currentLevel = 1; currentLevel < level; currentLevel++) {
      total += xpRequiredForLevel(currentLevel);
    }
    return total;
  }

  List<ProgressGoal> achievements(ProgressSnapshot snapshot) => [
        _achievement(
          id: 'first-solve',
          title: 'Der Anfang ist gemacht',
          description: 'Löse dein erstes Rätsel.',
          iconName: 'flag',
          current: snapshot.totalCompleted,
          target: 1,
        ),
        _achievement(
          id: 'ten-solves',
          title: 'Gut im Denken',
          description: 'Löse 10 Rätsel.',
          iconName: 'psychology',
          current: snapshot.totalCompleted,
          target: 10,
        ),
        _achievement(
          id: 'fifty-solves',
          title: 'Nicht aufzuhalten',
          description: 'Löse 50 Rätsel.',
          iconName: 'workspace_premium',
          current: snapshot.totalCompleted,
          target: 50,
        ),
        _achievement(
          id: 'hundred-solves',
          title: 'Hundertmal geknobelt',
          description: 'Löse 100 Rätsel.',
          iconName: 'workspace_premium',
          current: snapshot.totalCompleted,
          target: 100,
        ),
        _achievement(
          id: 'two-fifty-solves',
          title: 'Ausdauernder Denker',
          description: 'Löse 250 Rätsel.',
          iconName: 'workspace_premium',
          current: snapshot.totalCompleted,
          target: 250,
        ),
        _achievement(
          id: 'five-hundred-solves',
          title: 'Logik gehört zum Alltag',
          description: 'Löse 500 Rätsel.',
          iconName: 'diamond',
          current: snapshot.totalCompleted,
          target: 500,
        ),
        _achievement(
          id: 'thousand-solves',
          title: 'Tausend Rätsel',
          description: 'Löse 1.000 Rätsel.',
          iconName: 'diamond',
          current: snapshot.totalCompleted,
          target: 1000,
        ),
        _achievement(
          id: 'binairo-first',
          title: 'Binairo entdeckt',
          description: 'Löse dein erstes Binairo-Rätsel.',
          iconName: 'grid_on',
          current: snapshot.completedForGame(GameType.binairo),
          target: 1,
        ),
        _achievement(
          id: 'hashi-first',
          title: 'Brückenbauer',
          description: 'Vollende dein erstes Hashi-Rätsel.',
          iconName: 'hub',
          current: snapshot.completedForGame(GameType.hashi),
          target: 1,
        ),
        _achievement(
          id: 'slitherlink-first',
          title: 'Schleifenkünstler',
          description: 'Vollende dein erstes Slitherlink-Rätsel.',
          iconName: 'gesture',
          current: snapshot.completedForGame(GameType.slitherlink),
          target: 1,
        ),
        _achievement(
          id: 'futoshiki-first',
          title: 'Ungleichungen gemeistert',
          description: 'Vollende dein erstes Futoshiki-Rätsel.',
          iconName: 'compare_arrows',
          current: snapshot.completedForGame(GameType.futoshiki),
          target: 1,
        ),
        _achievement(
          id: 'hitori-first',
          title: 'Einzelgänger',
          description: 'Vollende dein erstes Hitori-Rätsel.',
          iconName: 'filter_b_and_w',
          current: snapshot.completedForGame(GameType.hitori),
          target: 1,
        ),
        _achievement(
          id: 'tents-first',
          title: 'Lager aufgeschlagen',
          description: 'Vollende dein erstes Zelte-&-B\u00e4ume-R\u00e4tsel.',
          iconName: 'park',
          current: snapshot.completedForGame(GameType.tents),
          target: 1,
        ),
        _achievement(
          id: 'streak-three',
          title: 'Dranbleiben',
          description: 'Spiele an 3 Tagen in Folge.',
          iconName: 'local_fire_department',
          current: snapshot.progress.bestStreak,
          target: 3,
        ),
        _achievement(
          id: 'streak-seven',
          title: 'Eine ganze Woche',
          description: 'Spiele an 7 Tagen in Folge.',
          iconName: 'calendar_month',
          current: snapshot.progress.bestStreak,
          target: 7,
        ),
        _achievement(
          id: 'streak-thirty',
          title: 'Fester Bestandteil',
          description: 'Spiele an 30 Tagen in Folge.',
          iconName: 'local_fire_department',
          current: snapshot.progress.bestStreak,
          target: 30,
        ),
        _achievement(
          id: 'daily-seven',
          title: 'Jeden Tag ein Rätsel',
          description: 'Löse 7 Tagesrätsel.',
          iconName: 'today',
          current: snapshot.dailyCompleted,
          target: 7,
        ),
        _achievement(
          id: 'daily-thirty',
          title: 'Kalenderfreund',
          description: 'Löse 30 Tagesrätsel.',
          iconName: 'calendar_month',
          current: snapshot.dailyCompleted,
          target: 30,
        ),
        _achievement(
          id: 'generator-ten',
          title: 'Freie Wahl',
          description: 'Löse 10 generierte Rätsel.',
          iconName: 'auto_awesome',
          current: snapshot.generatedCompleted,
          target: 10,
        ),
        _achievement(
          id: 'generator-fifty',
          title: 'Immer etwas Neues',
          description: 'Löse 50 frei erzeugte Rätsel.',
          iconName: 'auto_awesome',
          current: snapshot.generatedCompleted,
          target: 50,
        ),
        _achievement(
          id: 'all-games',
          title: 'Vielseitiger Denker',
          description: 'Löse mindestens ein Rätsel in jeder Spielart.',
          iconName: 'category',
          current: snapshot.distinctGamesCompleted,
          target: GameType.values.length,
        ),
        _achievement(
          id: 'play-hour',
          title: 'Eine Stunde Logik',
          description: 'Verbringe insgesamt eine Stunde beim Rätseln.',
          iconName: 'timer',
          current: snapshot.progress.totalPlaySeconds,
          target: 60 * 60,
        ),
        _achievement(
          id: 'play-ten-hours',
          title: 'Zeit für klare Gedanken',
          description: 'Verbringe insgesamt zehn Stunden beim Rätseln.',
          iconName: 'timer',
          current: snapshot.progress.totalPlaySeconds,
          target: 10 * 60 * 60,
        ),
        _achievement(
          id: 'catalog-complete',
          title: 'Alles gesehen',
          description: 'Löse jedes Rätsel der Sammlung.',
          iconName: 'collections_bookmark',
          current: snapshot.catalogCompleted,
          // An empty catalog is an incomplete configuration, not an
          // achievement the player unlocked for free.
          target: snapshot.catalogPuzzleIds.isEmpty
              ? 1
              : snapshot.catalogPuzzleIds.length,
        ),
        _achievement(
          id: 'hard-five',
          title: 'Harte Nüsse',
          description: 'Knacke 5 schwere Rätsel.',
          iconName: 'diamond',
          current: snapshot.hardCompleted,
          target: 5,
        ),
        _achievement(
          id: 'large-board',
          title: 'Großes Raster',
          description: 'Löse ein Rätsel auf einem Raster ab 10 × 10.',
          iconName: 'grid_on',
          current: snapshot.largeBoardCompleted,
          target: 1,
        ),
      ];

  List<ProgressGoal> dailyMissions(
    ProgressSnapshot snapshot, {
    DateTime? date,
  }) {
    final today = date ?? DateTime.now();
    const dailyService = DailyChallengeService();
    final dailyPuzzleIds = {
      for (final gameType in const [
        GameType.binairo,
        GameType.hashi,
        GameType.slitherlink,
        GameType.futoshiki,
        GameType.hitori,
        GameType.tents,
      ])
        dailyService.summaryForGame(today, gameType).puzzleId,
    };
    final dayAttempts = snapshot.attemptsOnDay(today);
    final completedDaily = dayAttempts.isNotEmpty
        ? dayAttempts.any(
            (attempt) =>
                attempt.mode == GameMode.daily &&
                dailyPuzzleIds.contains(attempt.puzzleId),
          )
        : snapshot.results.values.any(
            (result) =>
                result.effectiveSource == PuzzleSource.daily &&
                dailyPuzzleIds.contains(result.puzzleId),
          );
    final generatedToday =
        snapshot.completionsTodayBySource(PuzzleSource.generated, today);
    final catalogToday =
        snapshot.completionsTodayBySource(PuzzleSource.catalog, today);

    final optional = [
      _mission(
        id: 'daily-${_dateKey(today)}-generator',
        title: 'Neue Herausforderung',
        description: 'Löse heute ein frei erzeugtes Rätsel.',
        iconName: 'auto_awesome',
        current: generatedToday,
        target: 1,
      ),
      _mission(
        id: 'daily-${_dateKey(today)}-catalog',
        title: 'Aus der Sammlung',
        description: 'Löse heute ein Rätsel aus der Sammlung.',
        iconName: 'menu_book',
        current: catalogToday,
        target: 1,
      ),
      _mission(
        id: 'daily-${_dateKey(today)}-no-hint',
        title: 'Ganz ohne Hilfe',
        description: 'Löse heute ein Rätsel ohne Hinweis.',
        iconName: 'psychology',
        current: dayAttempts.where((attempt) => attempt.hintsUsed == 0).length,
        target: 1,
      ),
      _mission(
        id: 'daily-${_dateKey(today)}-variety',
        title: 'Doppelte Abwechslung',
        description: 'Löse heute zwei verschiedene Spielarten.',
        iconName: 'category',
        current: dayAttempts.map((attempt) => attempt.gameType).toSet().length,
        target: 2,
      ),
    ];
    final rotation =
        today.difference(DateTime(2026)).inDays.abs() % optional.length;
    return [
      _mission(
        id: 'daily-${_dateKey(today)}-challenge',
        title: 'Heute dran',
        description: 'Löse das heutige Tagesrätsel.',
        iconName: 'today',
        current: completedDaily ? 1 : 0,
        target: 1,
      ),
      optional[rotation],
      optional[(rotation + 1) % optional.length],
    ];
  }

  List<ProgressGoal> missions(ProgressSnapshot snapshot) =>
      longTermMissions(snapshot);

  List<ProgressGoal> weeklyMissions(
    ProgressSnapshot snapshot, {
    DateTime? date,
  }) {
    final today = date ?? DateTime.now();
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekId = _dateKey(weekStart);
    final attempts = snapshot.attemptsInWeek(today);
    final activeDays = attempts.isEmpty
        ? snapshot.activeDaysInWeek(today)
        : attempts
            .map((attempt) => _dateKey(attempt.completedAt))
            .toSet()
            .length;
    final optional = [
      _mission(
        id: 'week-$weekId-active-days',
        title: 'Dreimal Zeit zum Denken',
        description:
            'Löse an drei verschiedenen Tagen dieser Woche ein Rätsel.',
        iconName: 'date_range',
        current: activeDays,
        target: 3,
      ),
      _mission(
        id: 'week-$weekId-variety',
        title: 'Abwechslungsreiche Woche',
        description: 'Löse diese Woche drei verschiedene Spielarten.',
        iconName: 'category',
        current: attempts.map((attempt) => attempt.gameType).toSet().length,
        target: 3,
      ),
      _mission(
        id: 'week-$weekId-five-puzzles',
        title: 'Fünf klare Momente',
        description: 'Löse diese Woche fünf Rätsel.',
        iconName: 'extension',
        current: attempts.length,
        target: 5,
      ),
      _mission(
        id: 'week-$weekId-no-hint',
        title: 'Aus eigener Kraft',
        description: 'Löse diese Woche drei Rätsel ohne Hinweis.',
        iconName: 'psychology',
        current: attempts.where((attempt) => attempt.hintsUsed == 0).length,
        target: 3,
      ),
      _mission(
        id: 'week-$weekId-hard',
        title: 'Schwere Kost',
        description: 'Löse diese Woche zwei schwere Rätsel.',
        iconName: 'local_fire_department',
        current: attempts
            .where((attempt) => attempt.difficulty == PuzzleDifficulty.hard)
            .length,
        target: 2,
      ),
    ];
    final rotation = (weekStart.difference(DateTime(2026)).inDays.abs() ~/ 7) %
        optional.length;
    return [optional[rotation], optional[(rotation + 1) % optional.length]];
  }

  List<ProgressGoal> longTermMissions(ProgressSnapshot snapshot) => [
        _mission(
          id: 'catalog-five',
          title: 'Sammlung entdecken',
          description: 'Löse 5 verschiedene Rätsel aus der Sammlung.',
          iconName: 'menu_book',
          current: snapshot.catalogCompleted,
          target: 5,
        ),
        _mission(
          id: 'generator-three',
          title: 'Eigene Auswahl',
          description: 'Löse 3 frei erzeugte Rätsel.',
          iconName: 'auto_awesome',
          current: snapshot.generatedCompleted,
          target: 3,
        ),
        _mission(
          id: 'streak-three',
          title: 'Drei Tage dabei',
          description: 'Spiele an 3 Tagen in Folge.',
          iconName: 'local_fire_department',
          current: snapshot.progress.currentStreak,
          target: 3,
        ),
      ];

  String _dateKey(DateTime value) => '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  List<ExperienceEvent> synchronizeAchievementXp(
    ProgressSnapshot snapshot,
    Iterable<ExperienceEvent> existing, {
    DateTime? now,
  }) {
    final events = {for (final event in existing) event.id: event};
    for (final goal
        in achievements(snapshot).where((goal) => goal.isCompleted)) {
      final id = 'achievement:${goal.id}';
      events.putIfAbsent(
        id,
        () => ExperienceEvent(
          id: id,
          kind: ExperienceEventKind.achievementUnlocked,
          points: ExperiencePointsPolicy.achievement(goal.id),
          occurredAt: now ?? DateTime.now(),
          referenceId: goal.id,
        ),
      );
    }
    return events.values.toList(growable: false)
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
  }

  List<ExperienceEvent> synchronizeMissionXp(
    ProgressSnapshot snapshot,
    Iterable<ExperienceEvent> existing, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final events = {for (final event in existing) event.id: event};
    final dates = <String, DateTime>{
      _dateKey(current): DateTime(current.year, current.month, current.day),
      for (final attempt in snapshot.attempts)
        _dateKey(attempt.completedAt): DateTime(
          attempt.completedAt.year,
          attempt.completedAt.month,
          attempt.completedAt.day,
        ),
    };

    for (final day in dates.values) {
      final goals = dailyMissions(snapshot, date: day);
      final occurredAt = _latestAttemptAt(snapshot.attemptsOnDay(day), current);
      for (final goal in goals.where((goal) => goal.isCompleted)) {
        _addMissionEvent(events, goal.id, occurredAt);
      }
      if (goals.every((goal) => goal.isCompleted)) {
        _addMissionEvent(
          events,
          'daily-${_dateKey(day)}-daily-complete',
          occurredAt,
        );
      }
    }

    final weeks = <String, DateTime>{};
    for (final day in dates.values) {
      final start = day.subtract(Duration(days: day.weekday - 1));
      weeks[_dateKey(start)] = start;
    }
    for (final week in weeks.values) {
      final goals = weeklyMissions(snapshot, date: week);
      final occurredAt =
          _latestAttemptAt(snapshot.attemptsInWeek(week), current);
      for (final goal in goals.where((goal) => goal.isCompleted)) {
        _addMissionEvent(events, goal.id, occurredAt);
      }
      if (goals.every((goal) => goal.isCompleted)) {
        _addMissionEvent(
          events,
          'week-${_dateKey(week)}-weekly-complete',
          occurredAt,
        );
      }
    }

    return events.values.toList(growable: false)
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
  }

  void _addMissionEvent(
    Map<String, ExperienceEvent> events,
    String missionId,
    DateTime occurredAt,
  ) {
    final points = ExperiencePointsPolicy.mission(missionId);
    if (points <= 0) return;
    final id = 'mission:$missionId';
    events.putIfAbsent(
      id,
      () => ExperienceEvent(
        id: id,
        kind: ExperienceEventKind.missionCompleted,
        points: points,
        occurredAt: occurredAt,
        referenceId: missionId,
      ),
    );
  }

  DateTime _latestAttemptAt(
    Iterable<PuzzleAttempt> attempts,
    DateTime fallback,
  ) {
    DateTime? latest;
    for (final attempt in attempts) {
      if (latest == null || attempt.completedAt.isAfter(latest)) {
        latest = attempt.completedAt;
      }
    }
    return latest ?? fallback;
  }

  PlayerRank rank(
    ProgressSnapshot snapshot, {
    Iterable<ExperienceEvent>? experienceEvents,
  }) {
    final xp = experienceEvents == null
        ? snapshot.totalCompleted * 10 +
            achievements(snapshot).where((goal) => goal.isCompleted).length * 50
        : experienceEvents.fold<int>(0, (sum, event) => sum + event.points);
    var level = 1;
    var currentXp = xp;
    var requiredXp = xpRequiredForLevel(level);
    while (currentXp >= requiredXp) {
      currentXp -= requiredXp;
      level++;
      requiredXp = xpRequiredForLevel(level);
    }
    return PlayerRank(
      level: level,
      title: _rankTitle(level),
      currentXp: currentXp,
      nextLevelXp: requiredXp,
    );
  }

  ProgressGoal _achievement({
    required String id,
    required String title,
    required String description,
    required String iconName,
    required int current,
    required int target,
  }) =>
      ProgressGoal(
        id: id,
        title: title,
        description: description,
        iconName: iconName,
        target: target,
        current: current,
        kind: ProgressGoalKind.achievement,
      );

  ProgressGoal _mission({
    required String id,
    required String title,
    required String description,
    required String iconName,
    required int current,
    required int target,
  }) =>
      ProgressGoal(
        id: id,
        title: title,
        description: description,
        iconName: iconName,
        target: target,
        current: current,
        kind: ProgressGoalKind.mission,
      );

  String _rankTitle(int level) {
    if (level >= 50) return 'Logiklegende';
    if (level >= 30) return 'Meisterdenker';
    if (level >= 20) return 'Rätselstratege';
    if (level >= 10) return 'Logiktalent';
    if (level >= 5) return 'Musterfinder';
    if (level >= 2) return 'Logikfreund';
    return 'Neugieriger Denker';
  }
}
