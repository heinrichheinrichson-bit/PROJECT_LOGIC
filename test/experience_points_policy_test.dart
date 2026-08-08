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
  });
}
