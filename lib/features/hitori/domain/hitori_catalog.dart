import '../../../core/domain/game_identity.dart';
import 'hitori_generator.dart';
import 'hitori_puzzle.dart';

class HitoriChapter {
  const HitoriChapter({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.difficulty,
    required this.puzzles,
  });

  final int number;
  final String title;
  final String subtitle;
  final PuzzleDifficulty difficulty;
  final List<HitoriPuzzle> puzzles;
}

final List<HitoriChapter> hitoriChapters = _buildChapters();

final List<HitoriPuzzle> hitoriPuzzleCatalog = [
  for (final chapter in hitoriChapters) ...chapter.puzzles,
];

List<HitoriChapter> _buildChapters() {
  const definitions = [
    (
      title: 'Doppelte entdecken',
      subtitle: 'Eindeutige Zahlenpaare sicher auflösen',
      difficulty: PuzzleDifficulty.easy,
      count: 10,
      names: [
        'Erste Schatten',
        'Klares Paar',
        'Ruhige Reihen',
        'Einzelne Spur',
        'Sicherer Abstand',
        'Helle Nachbarn',
        'Doppelt gesehen',
        'Freie Mitte',
        'Saubere Trennung',
        'Erster Überblick',
      ],
    ),
    (
      title: 'Flächen sichern',
      subtitle: 'Schwarze Felder und helle Wege gemeinsam planen',
      difficulty: PuzzleDifficulty.medium,
      count: 10,
      names: [
        'Neue Verbindungen',
        'Versetzte Paare',
        'Schmale Passage',
        'Heller Korridor',
        'Geteilte Zeile',
        'Sichere Inseln',
        'Verdeckte Ordnung',
        'Rund um die Mitte',
        'Zwei Richtungen',
        'Stabile Fläche',
      ],
    ),
    (
      title: 'Verbundene Wege',
      subtitle: 'Mehrere Bedingungen über das ganze Raster kombinieren',
      difficulty: PuzzleDifficulty.hard,
      count: 8,
      names: [
        'Dichte Spuren',
        'Langer Zusammenhang',
        'Knappe Wege',
        'Tiefe Entscheidung',
        'Verborgene Brücke',
        'Mehrfach gedacht',
        'Letzte Sicherheit',
        'Große Prüfung',
      ],
    ),
  ];
  const generator = HitoriGenerator();
  return [
    for (var chapterIndex = 0;
        chapterIndex < definitions.length;
        chapterIndex++)
      HitoriChapter(
        number: chapterIndex + 1,
        title: definitions[chapterIndex].title,
        subtitle: definitions[chapterIndex].subtitle,
        difficulty: definitions[chapterIndex].difficulty,
        puzzles: [
          for (var index = 0; index < definitions[chapterIndex].count; index++)
            generator.generate(
              seed: 15000 + chapterIndex * 100 + index,
              difficulty: definitions[chapterIndex].difficulty,
              id: 'hitori-catalog-${definitions[chapterIndex].difficulty.name}-${index + 1}',
              title: definitions[chapterIndex].names[index],
            ),
        ],
      ),
  ];
}
