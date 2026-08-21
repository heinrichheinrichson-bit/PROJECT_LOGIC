import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/core/domain/game_identity.dart';
import 'package:project_logic_prototype/core/progress/experience_points_policy.dart';

void main() {
  group('ExperiencePointsPolicy', () {
    test('rewards first completions by source and difficulty', () {
      expect(
        ExperiencePointsPolicy.puzzleCompletion(
          source: PuzzleSource.catalog,
          difficulty: PuzzleDifficulty.easy,
          hintsUsed: 1,
        ),
        20,
      );
      expect(
        ExperiencePointsPolicy.puzzleCompletion(
          source: PuzzleSource.generated,
          difficulty: PuzzleDifficulty.medium,
          hintsUsed: 1,
        ),
        35,
      );
      expect(
        ExperiencePointsPolicy.puzzleCompletion(
          source: PuzzleSource.daily,
          difficulty: PuzzleDifficulty.hard,
          hintsUsed: 1,
        ),
        60,
      );
    });

    test('adds ten points when no hint was used', () {
      expect(
        ExperiencePointsPolicy.puzzleCompletion(
          source: PuzzleSource.catalog,
          difficulty: PuzzleDifficulty.easy,
          hintsUsed: 0,
        ),
        30,
      );
    });

    test('prevents daily XP farming and limits other repeats', () {
      expect(
        ExperiencePointsPolicy.puzzleCompletion(
          source: PuzzleSource.daily,
          difficulty: PuzzleDifficulty.hard,
          hintsUsed: 0,
          repeated: true,
        ),
        0,
      );
      expect(
        ExperiencePointsPolicy.puzzleCompletion(
          source: PuzzleSource.generated,
          difficulty: PuzzleDifficulty.hard,
          hintsUsed: 0,
          repeated: true,
        ),
        5,
      );
    });

    test('keeps major achievements more valuable than first steps', () {
      expect(
        ExperiencePointsPolicy.achievement('thousand-solves'),
        greaterThan(ExperiencePointsPolicy.achievement('first-solve')),
      );
      expect(ExperiencePointsPolicy.achievement('catalog-complete'), 400);
    });

    test('rewards mission goals and their completion bonuses', () {
      expect(ExperiencePointsPolicy.mission('daily-2026-08-08-generated'), 5);
      expect(
        ExperiencePointsPolicy.mission(
          'daily-2026-08-08-daily-complete',
        ),
        15,
      );
      expect(ExperiencePointsPolicy.mission('week-2026-32-active-days'), 40);
      expect(
        ExperiencePointsPolicy.mission(
          'week-2026-32-weekly-complete',
        ),
        30,
      );
      expect(ExperiencePointsPolicy.mission('month-2026-08-puzzles'), 100);
      expect(
        ExperiencePointsPolicy.mission('month-2026-08-monthly-complete'),
        150,
      );
    });
  });

  test('rewards the newly extended long-term tiers progressively', () {
    expect(
      ExperiencePointsPolicy.achievement('game-hashi-500'),
      greaterThan(ExperiencePointsPolicy.achievement('game-hashi-250')),
    );
    expect(ExperiencePointsPolicy.achievement('daily-1000'), 1250);
    expect(
      ExperiencePointsPolicy.mission('longterm-generated-1000'),
      greaterThan(
        ExperiencePointsPolicy.mission('longterm-generated-500'),
      ),
    );
  });
}
