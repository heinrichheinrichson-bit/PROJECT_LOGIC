import 'dart:io';

import 'package:project_logic_prototype/features/binary_puzzle/domain/binary_puzzle_generator.dart';
import 'package:project_logic_prototype/game_logic.dart';

void main() {
  const generator = BinaryPuzzleGenerator();
  for (final size in [4, 6, 8, 10]) {
    for (final requested in PuzzleDifficulty.values) {
      final counts = <PuzzleDifficulty, int>{
        for (final difficulty in PuzzleDifficulty.values) difficulty: 0,
      };
      var logical = 0;
      var totalClues = 0;
      for (var sample = 0; sample < 20; sample++) {
        final generated = generator.generate(
          size: size,
          seed: size * 100000 + requested.index * 1000 + sample,
          difficulty: requested,
        );
        counts.update(
          generated.difficultyAnalysis.inferredDifficulty,
          (value) => value + 1,
        );
        if (generated.difficultyAnalysis.solvedLogically) logical++;
        totalClues += generated.definition.clueCount;
      }
      stdout.writeln(
        '$size ${requested.name}: inferred=$counts, '
        'logical=$logical/20, averageClues=${totalClues / 20}',
      );
    }
  }
}
