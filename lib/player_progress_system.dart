import 'daily_challenge.dart';
import 'game_logic.dart';
import 'game_storage.dart';

enum ProgressGoalKind { achievement, mission }

class ProgressSnapshot {
  const ProgressSnapshot({
    required this.results,
    required this.progress,
    required this.catalogPuzzleIds,
  });

  final Map<String, PuzzleResult> results;
  final PlayerProgress progress;
  final Set<String> catalogPuzzleIds;

  int get totalCompleted => progress.totalCompleted;

  int get catalogCompleted =>
      results.keys.where(catalogPuzzleIds.contains).length;

  int get generatedCompleted => results.values
      .where((result) => result.effectiveSource == PuzzleSource.generated)
      .fold(0, (sum, result) => sum + result.completionCount);

  int get dailyCompleted => results.values
      .where((result) => result.effectiveSource == PuzzleSource.daily)
      .length;

  int get hardCompleted => results.values
      .where((result) =>
          result.effectiveDifficulty == PuzzleDifficulty.hard)
      .fold(0, (sum, result) => sum + result.completionCount);

  int get largeBoardCompleted => results.values
      .where((result) => (result.effectiveBoardSize ?? 0) >= 10)
      .fold(0, (sum, result) => sum + result.completionCount);

  bool get dailyCompletedToday =>
      results.containsKey(const DailyChallengeService().today().puzzleId);

  int completionsTodayBySource(PuzzleSource source, DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return results.values
        .where((result) {
          final completed = result.completedAt;
          final completedDay = DateTime(completed.year, completed.month, completed.day);
          return result.effectiveSource == source && completedDay == day;
        })
        .length;
  }

  int get completionsToday {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    return results.values.where((result) {
      final completed = result.completedAt;
      return DateTime(completed.year, completed.month, completed.day) == day;
    }).length;
  }
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
  double get progress => target <= 0 ? 1 : (current / target).clamp(0, 1).toDouble();
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

  double get progress => nextLevelXp == 0
      ? 1
      : (currentXp / nextLevelXp).clamp(0, 1).toDouble();
}

class PlayerProgressService {
  const PlayerProgressService();

  List<ProgressGoal> achievements(ProgressSnapshot snapshot) => [
        _achievement(
          id: 'first-solve',
          title: 'Erste Schritte',
          description: 'Schließe dein erstes Rätsel ab.',
          iconName: 'flag',
          current: snapshot.totalCompleted,
          target: 1,
        ),
        _achievement(
          id: 'ten-solves',
          title: 'Logikfreund',
          description: 'Schließe 10 Rätsel ab.',
          iconName: 'psychology',
          current: snapshot.totalCompleted,
          target: 10,
        ),
        _achievement(
          id: 'fifty-solves',
          title: 'Ausdauernder Denker',
          description: 'Schließe 50 Rätsel ab.',
          iconName: 'workspace_premium',
          current: snapshot.totalCompleted,
          target: 50,
        ),
        _achievement(
          id: 'streak-three',
          title: 'Guter Rhythmus',
          description: 'Erreiche eine Spielserie von 3 Tagen.',
          iconName: 'local_fire_department',
          current: snapshot.progress.bestStreak,
          target: 3,
        ),
        _achievement(
          id: 'streak-seven',
          title: 'Eine starke Woche',
          description: 'Erreiche eine Spielserie von 7 Tagen.',
          iconName: 'calendar_month',
          current: snapshot.progress.bestStreak,
          target: 7,
        ),
        _achievement(
          id: 'daily-seven',
          title: 'Tagesrätsel-Fan',
          description: 'Löse 7 verschiedene Tagesrätsel.',
          iconName: 'today',
          current: snapshot.dailyCompleted,
          target: 7,
        ),
        _achievement(
          id: 'generator-ten',
          title: 'Unendliche Logik',
          description: 'Löse 10 generierte Rätsel.',
          iconName: 'auto_awesome',
          current: snapshot.generatedCompleted,
          target: 10,
        ),
        _achievement(
          id: 'catalog-complete',
          title: 'Katalogmeister',
          description: 'Löse alle Katalogrätsel.',
          iconName: 'collections_bookmark',
          current: snapshot.catalogCompleted,
          target: snapshot.catalogPuzzleIds.length,
        ),
        _achievement(
          id: 'hard-five',
          title: 'Harte Nuss',
          description: 'Löse 5 schwere Rätsel.',
          iconName: 'diamond',
          current: snapshot.hardCompleted,
          target: 5,
        ),
        _achievement(
          id: 'large-board',
          title: 'Großdenker',
          description: 'Löse ein Rätsel mit mindestens 10 × 10 Feldern.',
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
    final dailyPuzzleId = const DailyChallengeService().challengeFor(today).puzzleId;
    final completedDaily = snapshot.results.containsKey(dailyPuzzleId);
    final generatedToday =
        snapshot.completionsTodayBySource(PuzzleSource.generated, today);
    final catalogToday =
        snapshot.completionsTodayBySource(PuzzleSource.catalog, today);

    return [
      _mission(
        id: 'daily-${_dateKey(today)}-challenge',
        title: 'Tagesrätsel',
        description: 'Löse das heutige Tagesrätsel.',
        iconName: 'today',
        current: completedDaily ? 1 : 0,
        target: 1,
      ),
      _mission(
        id: 'daily-${_dateKey(today)}-generator',
        title: 'Frische Herausforderung',
        description: 'Löse heute ein Generatorrätsel.',
        iconName: 'auto_awesome',
        current: generatedToday,
        target: 1,
      ),
      _mission(
        id: 'daily-${_dateKey(today)}-catalog',
        title: 'Katalogrunde',
        description: 'Löse heute ein Katalogrätsel.',
        iconName: 'menu_book',
        current: catalogToday,
        target: 1,
      ),
    ];
  }

  List<ProgressGoal> missions(ProgressSnapshot snapshot) =>
      longTermMissions(snapshot);

  List<ProgressGoal> longTermMissions(ProgressSnapshot snapshot) => [
        _mission(
          id: 'catalog-five',
          title: 'Katalog erkunden',
          description: 'Löse 5 verschiedene Katalogrätsel.',
          iconName: 'menu_book',
          current: snapshot.catalogCompleted,
          target: 5,
        ),
        _mission(
          id: 'generator-three',
          title: 'Generator ausprobieren',
          description: 'Löse 3 generierte Rätsel.',
          iconName: 'auto_awesome',
          current: snapshot.generatedCompleted,
          target: 3,
        ),
        _mission(
          id: 'streak-three',
          title: 'Drei Tage Fokus',
          description: 'Baue eine Spielserie von 3 Tagen auf.',
          iconName: 'local_fire_department',
          current: snapshot.progress.currentStreak,
          target: 3,
        ),
      ];

  String _dateKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  PlayerRank rank(ProgressSnapshot snapshot) {
    final unlocked = achievements(snapshot).where((goal) => goal.isCompleted);
    final xp = snapshot.totalCompleted * 10 + unlocked.length * 50;
    final level = xp ~/ 200 + 1;
    final currentXp = xp % 200;
    return PlayerRank(
      level: level,
      title: _rankTitle(level),
      currentXp: currentXp,
      nextLevelXp: 200,
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
    if (level >= 10) return 'Logikmeister';
    if (level >= 7) return 'Rätselprofi';
    if (level >= 4) return 'Fortgeschrittener Denker';
    if (level >= 2) return 'Logikfreund';
    return 'Neugieriger Denker';
  }
}
