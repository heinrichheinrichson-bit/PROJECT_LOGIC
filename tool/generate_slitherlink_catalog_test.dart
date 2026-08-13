import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/core/domain/game_identity.dart';
import 'package:project_logic_prototype/slitherlink_foundation.dart';

const _startMarker = '  // GENERATED CATALOG EXPANSION START';
const _endMarker = '  // GENERATED CATALOG EXPANSION END';

void main() {
  test('generate validated static Slitherlink catalog expansion', () {
    const generator = SlitherlinkGenerator();
    const solver = SlitherlinkSolver();
    final puzzles = <SlitherlinkPuzzle>[];
    const titles = {
      PuzzleDifficulty.easy: [
        'Ruhige Runde',
        'Klare Kanten',
        'Sanfter Umweg',
        'Sichere Kurve',
      ],
      PuzzleDifficulty.medium: [
        'Verdeckter Bogen',
        'Versetzte Spuren',
        'Langer Wendepunkt',
        'Kombinierte Runde',
      ],
      PuzzleDifficulty.hard: [
        'Tiefe Abzweigung',
        'Sparsame Hinweise',
        'Verborgener Verlauf',
        'Letzte Meisterrunde',
      ],
    };

    for (final difficulty in PuzzleDifficulty.values) {
      for (var offset = 0; offset < 4; offset++) {
        final seed = 31000 + difficulty.index * 100 + offset;
        final generated = generator.generate(
          seed: seed,
          difficulty: difficulty,
        );
        final puzzle = SlitherlinkPuzzle(
          id: 'slither_${difficulty.name}_${offset + 13}',
          title: titles[difficulty]![offset],
          rows: generated.rows,
          columns: generated.columns,
          clues: generated.clues,
          solution: generated.solution,
          difficulty: difficulty,
        );
        expect(solver.hasUniqueSolution(puzzle), isTrue, reason: puzzle.id);
        expect(
          SlitherlinkState(
            puzzle: puzzle,
            marks: {
              for (final id in puzzle.solution) id: SlitherEdgeMark.line,
            },
          ).isSolved,
          isTrue,
          reason: puzzle.id,
        );
        puzzles.add(puzzle);
      }
    }

    final file = File('lib/slitherlink_catalog.g.dart');
    var source = file.readAsStringSync();
    final existingStart = source.indexOf(_startMarker);
    if (existingStart >= 0) {
      final existingEnd = source.indexOf(_endMarker, existingStart);
      if (existingEnd < 0) throw StateError('Missing generated end marker.');
      source = source.replaceRange(
        existingStart,
        existingEnd + _endMarker.length,
        '',
      );
    }
    final closing = source.lastIndexOf('];');
    if (closing < 0) throw StateError('Catalog closing marker not found.');
    final generatedSection = StringBuffer('$_startMarker\n');
    for (final puzzle in puzzles) {
      generatedSection.write(_serialize(puzzle));
    }
    generatedSection.write(_endMarker);
    source = source.replaceRange(
      closing,
      closing,
      '${generatedSection.toString()}\n',
    );
    file.writeAsStringSync(source);
    expect(puzzles, hasLength(12));
  });
}

String _serialize(SlitherlinkPuzzle puzzle) {
  final solution = puzzle.solution.toList()..sort();
  final output = StringBuffer()
    ..writeln('  const SlitherlinkPuzzle(')
    ..writeln("    id: '${puzzle.id}',")
    ..writeln("    title: '${puzzle.title}',")
    ..writeln('    rows: ${puzzle.rows},')
    ..writeln('    columns: ${puzzle.columns},')
    ..writeln('    difficulty: PuzzleDifficulty.${puzzle.difficulty.name},')
    ..writeln('    clues: [');
  for (final row in puzzle.clues) {
    output
        .writeln('      [${row.map((value) => value ?? 'null').join(', ')}],');
  }
  output
    ..writeln('    ],')
    ..writeln('    solution: {');
  for (final id in solution) {
    output.writeln("      '$id',");
  }
  return (output
        ..writeln('    },')
        ..writeln('  ),'))
      .toString();
}
