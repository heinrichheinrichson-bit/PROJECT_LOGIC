import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/game_logic.dart';

void main() {
  group('BinaryPuzzle', () {
    test('starts with exactly the fixed clues', () {
      final puzzle = binaryPuzzleCatalog.first.createPuzzle();

      final filledCells = puzzle.board
          .expand((row) => row)
          .where((value) => value != null)
          .length;

      expect(filledCells, puzzle.clues.length);
      expect(puzzle.isSolved, isFalse);
    });

    test('cycles editable cells and supports undo/redo', () {
      final puzzle = binaryPuzzleCatalog.first.createPuzzle();
      const position = CellPosition(0, 1);

      expect(puzzle.board[position.row][position.column], isNull);

      puzzle.cycleCell(position.row, position.column);
      expect(puzzle.board[position.row][position.column], CellValue.zero);

      puzzle.cycleCell(position.row, position.column);
      expect(puzzle.board[position.row][position.column], CellValue.one);

      puzzle.undo();
      expect(puzzle.board[position.row][position.column], CellValue.zero);

      puzzle.redo();
      expect(puzzle.board[position.row][position.column], CellValue.one);
    });

    test('reset can be undone and redone as one action', () {
      final puzzle = binaryPuzzleCatalog.first.createPuzzle();
      final editable = <CellPosition>[];
      for (var row = 0; row < puzzle.size; row++) {
        for (var column = 0; column < puzzle.size; column++) {
          if (!puzzle.isClue(row, column)) {
            editable.add(CellPosition(row, column));
          }
        }
      }

      puzzle.setCell(editable[0].row, editable[0].column, CellValue.zero);
      puzzle.setCell(editable[1].row, editable[1].column, CellValue.one);
      puzzle.reset();

      expect(puzzle.nextUndoIsReset, isTrue);
      expect(puzzle.filledEditableCellCount, 0);

      puzzle.undo();
      expect(puzzle.board[editable[0].row][editable[0].column], CellValue.zero);
      expect(puzzle.board[editable[1].row][editable[1].column], CellValue.one);
      expect(puzzle.nextRedoIsReset, isTrue);

      puzzle.redo();
      expect(puzzle.filledEditableCellCount, 0);
    });

    test('does not change clue cells', () {
      final puzzle = binaryPuzzleCatalog.first.createPuzzle();
      const clue = CellPosition(0, 0);
      final before = puzzle.board[clue.row][clue.column];

      puzzle.cycleCell(clue.row, clue.column);

      expect(puzzle.board[clue.row][clue.column], before);
      expect(puzzle.canUndo, isFalse);
    });

    test('detects three equal adjacent values', () {
      final puzzle = binaryPuzzleCatalog.first.createPuzzle();

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
      final puzzle = binaryPuzzleCatalog.first.createPuzzle();
      puzzle.fillWithSolution();

      expect(puzzle.validate(), isEmpty);
      expect(puzzle.isSolved, isTrue);
    });

    test('tracks progress of editable cells', () {
      final puzzle = binaryPuzzleCatalog.first.createPuzzle();
      expect(puzzle.filledEditableCellCount, 0);
      expect(puzzle.progress, 0);

      puzzle.cycleCell(0, 1);
      expect(puzzle.filledEditableCellCount, 1);
      expect(puzzle.progress, greaterThan(0));

      puzzle.cycleCell(0, 1);
      puzzle.cycleCell(0, 1);
      expect(puzzle.filledEditableCellCount, 0);
    });
  });

  group('Puzzle catalog', () {
    test('contains the planned 80-puzzle launch collection', () {
      expect(binaryPuzzleCatalog, hasLength(80));
      expect(puzzlesFor(PuzzleDifficulty.easy), hasLength(26));
      expect(puzzlesFor(PuzzleDifficulty.medium), hasLength(28));
      expect(puzzlesFor(PuzzleDifficulty.hard), hasLength(26));
      expect(
        binaryPuzzleCatalog.map((puzzle) => puzzle.size).toSet(),
        {4, 6, 8, 10},
      );
    });

    test('all catalog solutions satisfy the rules', () {
      for (final definition in binaryPuzzleCatalog) {
        final puzzle = definition.createPuzzle();
        puzzle.fillWithSolution();
        expect(puzzle.isSolved, isTrue, reason: definition.id);
      }
    });

    test('all puzzle ids are unique', () {
      final ids = binaryPuzzleCatalog.map((puzzle) => puzzle.id).toSet();
      expect(ids.length, binaryPuzzleCatalog.length);
    });

    test('next puzzle stays inside the selected difficulty', () {
      final hard = puzzlesFor(PuzzleDifficulty.hard);

      expect(nextPuzzleInDifficulty(hard.first), hard[1]);
      expect(nextPuzzleInDifficulty(hard[1]), hard[2]);
      expect(nextPuzzleInDifficulty(hard.last), isNull);
    });

    test('catalog chapters keep every puzzle in order', () {
      final puzzles = puzzlesFor(PuzzleDifficulty.easy);
      final chapters = chaptersFor(
        PuzzleDifficulty.easy,
        chapterSize: 2,
      );

      expect(chapters, hasLength((puzzles.length / 2).ceil()));
      expect(chapters.expand((chapter) => chapter.puzzles), puzzles);
      expect(chapters.first.title, 'Grundlagen');
      expect(chapters.first.description, contains('Direkte Regeln'));
    });
  });

  test('editable values can be exported and restored', () {
    final definition = binaryPuzzleCatalog.first;
    final first = definition.createPuzzle();

    for (var row = 0; row < first.size; row++) {
      for (var column = 0; column < first.size; column++) {
        if (!first.isClue(row, column)) {
          first.cycleCell(row, column);
          break;
        }
      }
      if (first.filledEditableCellCount > 0) break;
    }

    final saved = first.exportEditableValues();
    final second = definition.createPuzzle();
    second.restoreEditableValues(saved);

    expect(second.exportEditableValues(), saved);
    expect(second.filledEditableCellCount, 1);
    expect(second.canUndo, isFalse);
  });

  test('restore rejects data for another puzzle shape', () {
    final puzzle = binaryPuzzleCatalog.first.createPuzzle();

    expect(
      () => puzzle.restoreEditableValues([0, 1]),
      throwsArgumentError,
    );
  });

  test('setCell records a reversible hint move', () {
    final puzzle = binaryPuzzleCatalog.first.createPuzzle();
    CellPosition? editable;

    for (var row = 0; row < puzzle.size && editable == null; row++) {
      for (var column = 0; column < puzzle.size; column++) {
        if (!puzzle.isClue(row, column)) {
          editable = CellPosition(row, column);
          break;
        }
      }
    }

    puzzle.setCell(editable!.row, editable.column, CellValue.one);
    expect(puzzle.board[editable.row][editable.column], CellValue.one);
    expect(puzzle.canUndo, isTrue);

    puzzle.undo();
    expect(puzzle.board[editable.row][editable.column], isNull);
  });
}
