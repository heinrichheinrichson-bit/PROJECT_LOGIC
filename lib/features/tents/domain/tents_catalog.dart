import '../../../core/domain/game_identity.dart';
import 'tents_generator.dart';
import 'tents_puzzle.dart';

const tentsChapterTitles = {
  PuzzleDifficulty.easy: 'Erste Lagerpl\u00e4tze',
  PuzzleDifficulty.medium: 'Wald und Wiesen',
  PuzzleDifficulty.hard: 'Gro\u00dfe Expedition',
};

final List<TentsPuzzle> tentsPuzzleCatalog = [
  for (final difficulty in PuzzleDifficulty.values)
    for (var index = 0;
        index < (difficulty == PuzzleDifficulty.hard ? 8 : 10);
        index++)
      const TentsGenerator().generate(
        seed: 23000 + difficulty.index * 100 + index,
        difficulty: difficulty,
        id: 'tents-${difficulty.name}-${index + 1}',
        title: switch (index) {
          0 => 'Am Waldrand',
          1 => 'Freie Wiese',
          2 => 'Zwischen den B\u00e4umen',
          3 => 'Kleine Lichtung',
          4 => 'Ruhiger Morgen',
          5 => 'Schmale Pfade',
          6 => 'Verteilte Lager',
          7 => 'Tiefe Spuren',
          8 => 'Weiter Weg',
          _ => 'Kapitelabschluss',
        },
      ),
];
