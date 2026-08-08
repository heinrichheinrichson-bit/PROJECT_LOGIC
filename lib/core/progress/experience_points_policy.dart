import '../domain/game_identity.dart';

/// Central, versioned balancing table for all experience rewards.
class ExperiencePointsPolicy {
  const ExperiencePointsPolicy._();

  static const int version = 2;

  static int puzzleCompletion({
    required PuzzleSource source,
    required PuzzleDifficulty difficulty,
    required int hintsUsed,
    bool repeated = false,
  }) {
    if (repeated) return source == PuzzleSource.daily ? 0 : 5;
    final base = switch (source) {
      PuzzleSource.catalog => 20,
      PuzzleSource.generated => 25,
      PuzzleSource.daily => 35,
      PuzzleSource.event => 35,
      PuzzleSource.tutorial => 10,
    };
    final difficultyBonus = switch (difficulty) {
      PuzzleDifficulty.easy => 0,
      PuzzleDifficulty.medium => 10,
      PuzzleDifficulty.hard => 25,
    };
    final noHintBonus = hintsUsed == 0 ? 10 : 0;
    return base + difficultyBonus + noHintBonus;
  }

  static int achievement(String id) => switch (id) {
        'first-solve' => 25,
        'ten-solves' => 50,
        'fifty-solves' => 100,
        'hundred-solves' => 175,
        'two-fifty-solves' => 250,
        'five-hundred-solves' => 400,
        'thousand-solves' => 750,
        'binairo-first' ||
        'hashi-first' ||
        'slitherlink-first' ||
        'futoshiki-first' ||
        'hitori-first' ||
        'tents-first' =>
          25,
        'streak-three' => 40,
        'streak-seven' => 90,
        'streak-thirty' => 250,
        'daily-seven' => 75,
        'daily-thirty' => 200,
        'generator-ten' => 75,
        'generator-fifty' => 200,
        'all-games' => 150,
        'play-hour' => 75,
        'play-ten-hours' => 250,
        'catalog-complete' => 400,
        'hard-five' => 100,
        'large-board' => 50,
        _ => 50,
      };

  static int mission(String id) {
    if (id.endsWith('-daily-complete')) return 15;
    if (id.endsWith('-weekly-complete')) return 30;
    if (id.startsWith('daily-')) return 5;
    if (id.startsWith('week-')) return 40;
    return 0;
  }
}
