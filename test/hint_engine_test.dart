import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/features/binary_puzzle/domain/binary_board_validator.dart';
import 'package:project_logic_prototype/features/binary_puzzle/domain/binary_puzzle_solver.dart';
import 'package:project_logic_prototype/game_logic.dart';
import 'package:project_logic_prototype/hint_engine.dart';

void main() {
  group('BinaryHintEngine', () {
    test('prioritizes the triple rule before the count rule', () {
      final puzzle = _puzzle([
        [0, 0, null, null],
        [1, null, 1, null],
        [null, null, null, null],
        [null, null, null, null],
      ]);

      final hint = findBinaryHint(puzzle);

      expect(hint, isNotNull);
      expect(hint!.type, BinaryHintType.triple);
      expect(hint.position, const CellPosition(0, 2));
      expect(hint.value, CellValue.one);
    });

    test('triple hints explain the rule and highlight three cells', () {
      final puzzle = _puzzle([
        [0, 0, null, null],
        [1, null, 1, null],
        [null, null, null, null],
        [null, null, null, null],
      ]);

      final hint = findBinaryHint(puzzle)!;

      expect(hint.badge, 'Direkte Regel');
      expect(hint.reason, contains('Dreierfolge'));
      expect(hint.relatedPositions, hasLength(3));
      expect(hint.coordinate, 'Zeile 1, Spalte 3');
      expect(hint.action, 'Trage dort eine 1 ein.');
    });

    test('uses the count rule when half of a line is filled', () {
      final puzzle = _puzzle([
        [0, null, null, 0],
        [null, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
      ]);

      final hint = findBinaryHint(puzzle);

      expect(hint, isNotNull);
      expect(hint!.type, BinaryHintType.count);
      expect(hint.position, const CellPosition(0, 1));
      expect(hint.value, CellValue.one);
    });

    test('count hint remains available despite an unrelated contradiction', () {
      final puzzle = _puzzle([
        [0, null, null, 0],
        [1, 1, 1, null],
        [null, null, null, null],
        [null, null, null, null],
      ]);

      final hint = findBinaryHint(puzzle);

      expect(hint, isNotNull);
      expect(hint!.type, BinaryHintType.count);
      expect(hint.position, const CellPosition(0, 1));
      expect(hint.value, CellValue.one);
    });

    test('count hints highlight the complete relevant line', () {
      final puzzle = _puzzle([
        [0, null, null, 0],
        [null, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
      ]);

      final hint = findBinaryHint(puzzle)!;

      expect(hint.type, BinaryHintType.count);
      expect(hint.relatedPositions, hasLength(4));
      expect(hint.reason, contains('gleich häufig'));
    });

    test('falls back to the solver for a uniquely solvable board', () {
      final puzzle = _puzzle([
        [0, null, 1, null],
        [null, null, 0, 1],
        [1, 0, null, null],
        [null, 1, null, 0],
      ]);

      final hint = findBinaryHint(puzzle);

      expect(hint, isNotNull);
      expect(hint!.type, BinaryHintType.solver);
      expect(hint.badge, 'Mehrere Regeln');
      expect(hint.relatedPositions, [const CellPosition(0, 1)]);
      expect(hint.position, const CellPosition(0, 1));
      expect(hint.value, CellValue.zero);
    });

    test('returns no hint for a board with several solutions', () {
      final puzzle = _puzzle([
        [null, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
      ]);

      expect(findBinaryHint(puzzle), isNull);
    });

    test('never returns a hint that creates duplicate columns', () {
      final puzzle = _puzzle([
        [0, 0, null, 1],
        [null, null, 0, 0],
        [null, null, 1, 1],
        [null, null, 0, 0],
      ]);

      final hint = findBinaryHint(puzzle);

      if (hint != null) {
        final candidateBoard = [
          for (final row in puzzle.board) [...row],
        ];
        candidateBoard[hint.position.row][hint.position.column] = hint.value;

        expect(
          const BinaryBoardValidator().isValidPartial(candidateBoard),
          isTrue,
        );
      }

      expect(
        hint?.position == const CellPosition(0, 2) &&
            hint?.value == CellValue.one,
        isFalse,
      );
    });

    test('returns no hint for a rule-valid but unsolvable board', () {
      final puzzle = _puzzle([
        [null, null, null, 1],
        [null, 1, 1, null],
        [null, null, null, null],
        [0, null, null, 0],
      ]);

      expect(findBinaryHint(puzzle), isNull);
    });

    test('returns no solver hint for an invalid board', () {
      final puzzle = _puzzle([
        [0, 0, 0, null],
        [null, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
      ]);

      expect(findBinaryHint(puzzle), isNull);
    });

    test('never returns a hint that creates duplicate rows', () {
      final puzzle = _puzzle([
        [0, 0, 1, null],
        [0, 0, 1, 1],
        [1, 1, 0, 0],
        [1, null, 0, null],
      ]);

      final hint = findBinaryHint(puzzle);

      _expectReturnedHintIsSafe(puzzle, hint);
      expect(
        hint?.position == const CellPosition(0, 3) &&
            hint?.value == CellValue.one,
        isFalse,
      );
    });

    test('every returned hint keeps the board valid and solvable', () {
      final boards = <List<List<int?>>>[
        [
          [0, 0, null, null],
          [1, null, 1, null],
          [null, null, null, null],
          [null, null, null, null],
        ],
        [
          [0, null, 1, null],
          [null, null, 0, 1],
          [1, 0, null, null],
          [null, 1, null, 0],
        ],
        [
          [0, null, null, 1],
          [null, 1, null, 0],
          [1, null, 0, null],
          [null, 0, 1, null],
        ],
      ];

      for (final board in boards) {
        final puzzle = _puzzle(board);
        final hint = findBinaryHint(puzzle);
        _expectReturnedHintIsSafe(puzzle, hint);
      }
    });

  });
}

BinaryPuzzle _puzzle(List<List<int?>> board) {
  const fallbackSolution = [
    [CellValue.zero, CellValue.zero, CellValue.one, CellValue.one],
    [CellValue.zero, CellValue.one, CellValue.zero, CellValue.one],
    [CellValue.one, CellValue.zero, CellValue.one, CellValue.zero],
    [CellValue.one, CellValue.one, CellValue.zero, CellValue.zero],
  ];
  final puzzle = BinaryPuzzle(solution: fallbackSolution, clues: const {});
  puzzle.restoreEditableValues([
    for (final row in board)
      for (final value in row) value,
  ]);
  return puzzle;
}

void _expectReturnedHintIsSafe(
  BinaryPuzzle puzzle,
  BinaryHint? hint,
) {
  if (hint == null) return;

  final candidateBoard = [
    for (final row in puzzle.board) [...row],
  ];
  candidateBoard[hint.position.row][hint.position.column] = hint.value;

  expect(
    const BinaryBoardValidator().isValidPartial(candidateBoard),
    isTrue,
  );
  expect(
    const BinaryPuzzleSolver()
        .solve(candidateBoard, solutionLimit: 1)
        .isSolvable,
    isTrue,
  );
}

