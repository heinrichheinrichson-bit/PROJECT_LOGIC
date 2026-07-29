import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/game_logic.dart';

void main() {
  group('BinaryPuzzle', () {
    test('starts with exactly the fixed clues', () {
      final puzzle = createPrototypePuzzle();

      final filledCells = puzzle.board
          .expand((row) => row)
          .where((value) => value != null)
          .length;

      expect(filledCells, puzzle.clues.length);
      expect(puzzle.isSolved, isFalse);
    });

    test('cycles editable cells and supports undo/redo', () {
      final puzzle = createPrototypePuzzle();
      const position = CellPosition(0, 0);

      expect(puzzle.board[position.row][position.column], isNull);

      puzzle.cycleCell(position.row, position.column);
      expect(
        puzzle.board[position.row][position.column],
        CellValue.zero,
      );

      puzzle.cycleCell(position.row, position.column);
      expect(
        puzzle.board[position.row][position.column],
        CellValue.one,
      );

      puzzle.undo();
      expect(
        puzzle.board[position.row][position.column],
        CellValue.zero,
      );

      puzzle.redo();
      expect(
        puzzle.board[position.row][position.column],
        CellValue.one,
      );
    });

    test('does not change clue cells', () {
      final puzzle = createPrototypePuzzle();
      const clue = CellPosition(0, 4);
      final before = puzzle.board[clue.row][clue.column];

      puzzle.cycleCell(clue.row, clue.column);

      expect(puzzle.board[clue.row][clue.column], before);
      expect(puzzle.canUndo, isFalse);
    });

    test('detects three equal adjacent values', () {
      final puzzle = createPrototypePuzzle();

      puzzle.board[1][0] = CellValue.zero;
      puzzle.board[1][1] = CellValue.zero;
      puzzle.board[1][2] = CellValue.zero;

      expect(
        puzzle.validate().any(
              (issue) => issue.message.contains('drei gleiche Zahlen'),
            ),
        isTrue,
      );
    });

    test('recognizes the known valid solution', () {
      final puzzle = createPrototypePuzzle();

      for (var row = 0; row < puzzle.size; row++) {
        for (var column = 0; column < puzzle.size; column++) {
          puzzle.board[row][column] = puzzle.solution[row][column];
        }
      }

      expect(puzzle.validate(), isEmpty);
      expect(puzzle.isSolved, isTrue);
    });
  });
}
