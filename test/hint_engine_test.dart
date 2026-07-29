import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/game_logic.dart';
import 'package:project_logic_prototype/hint_engine.dart';

void main() {
  test('hint completes a line that already contains half zeros', () {
    final solution = [
      [CellValue.zero, CellValue.zero, CellValue.one, CellValue.one],
      [CellValue.zero, CellValue.one, CellValue.zero, CellValue.one],
      [CellValue.one, CellValue.zero, CellValue.one, CellValue.zero],
      [CellValue.one, CellValue.one, CellValue.zero, CellValue.zero],
    ];
    final puzzle = BinaryPuzzle(
      solution: solution,
      clues: {
        CellPosition(0, 0),
        CellPosition(0, 1),
      },
    );

    final hint = findBinaryHint(puzzle);

    expect(hint, isNotNull);
    expect(hint!.position, const CellPosition(0, 2));
    expect(hint.value, CellValue.one);
  });

  test('hint detects the equal-gap-equal rule', () {
    final solution = [
      [CellValue.zero, CellValue.one, CellValue.zero, CellValue.one],
      [CellValue.zero, CellValue.zero, CellValue.one, CellValue.one],
      [CellValue.one, CellValue.one, CellValue.zero, CellValue.zero],
      [CellValue.one, CellValue.zero, CellValue.one, CellValue.zero],
    ];
    final puzzle = BinaryPuzzle(
      solution: solution,
      clues: {
        CellPosition(0, 0),
        CellPosition(0, 2),
      },
    );

    final hint = findBinaryHint(puzzle);

    expect(hint, isNotNull);
    expect(hint!.position, const CellPosition(0, 1));
    expect(hint.value, CellValue.one);
  });
}
