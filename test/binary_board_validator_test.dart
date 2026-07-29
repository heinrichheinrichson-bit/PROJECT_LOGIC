import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/features/binary_puzzle/domain/binary_board_validator.dart';
import 'package:project_logic_prototype/game_logic.dart';

void main() {
  const validator = BinaryBoardValidator();

  group('BinaryBoardValidator', () {
    test('accepts a valid complete board', () {
      final board = _values([
        [0, 0, 1, 1],
        [0, 1, 0, 1],
        [1, 0, 1, 0],
        [1, 1, 0, 0],
      ]);

      expect(validator.isValidComplete(board), isTrue);
    });

    test('rejects three equal adjacent values', () {
      final board = _values([
        [0, 0, 0, null],
        [null, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
      ]);

      expect(validator.isValidPartial(board), isFalse);
    });

    test('rejects too many equal values in a line', () {
      final board = _values([
        [1, null, 1, 1],
        [null, null, null, null],
        [null, null, null, null],
        [null, null, null, null],
      ]);

      expect(validator.isValidPartial(board), isFalse);
    });

    test('rejects duplicate complete rows', () {
      final board = _values([
        [0, 0, 1, 1],
        [0, 0, 1, 1],
        [null, null, null, null],
        [null, null, null, null],
      ]);

      expect(validator.isValidPartial(board), isFalse);
    });

    test('rejects invalid board shapes', () {
      expect(
        () => validator.isValidPartial([
          [CellValue.zero, null],
        ]),
        throwsArgumentError,
      );
    });
  });
}

List<List<CellValue?>> _values(List<List<int?>> values) => [
      for (final row in values)
        [
          for (final value in row)
            switch (value) {
              0 => CellValue.zero,
              1 => CellValue.one,
              _ => null,
            },
        ],
    ];
