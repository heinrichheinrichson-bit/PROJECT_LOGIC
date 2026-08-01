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
    for (var index = 0; index < 20; index++)
      const TentsGenerator().generate(
        seed: 23000 + difficulty.index * 100 + index,
        difficulty: difficulty,
        id: 'tents-${difficulty.name}-${index + 1}',
        title: _tentsPuzzleTitles[index],
      ),
];

const _tentsPuzzleTitles = <String>[
  'Am Waldrand',
  'Freie Wiese',
  'Zwischen den B\u00e4umen',
  'Kleine Lichtung',
  'Ruhiger Morgen',
  'Schmale Pfade',
  'Verteilte Lager',
  'Tiefe Spuren',
  'Weiter Weg',
  'Erstes Etappenziel',
  'Versteckte Lichtung',
  'Unter hohen Kronen',
  'Am stillen Bach',
  'Dichter Wald',
  'Lange Wanderung',
  'Unruhiges Gel\u00e4nde',
  'Viele Abzweigungen',
  'Abgelegener Platz',
  'Letzte Wegmarken',
  'Expedition vollendet',
];
