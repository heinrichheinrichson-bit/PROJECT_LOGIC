import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/features/binary_puzzle/domain/binary_board_generator.dart';
import 'package:project_logic_prototype/features/binary_puzzle/domain/binary_board_validator.dart';
import 'package:project_logic_prototype/game_logic.dart';

void main() {
  const generator = BinaryBoardGenerator();
  const validator = BinaryBoardValidator();

  group('BinaryBoardGenerator', () {
    for (final size in [4, 6, 8]) {
      test('generates a valid ${size}x$size board', () {
        final result = generator.generate(
          size: size,
          seed: 6000 + size,
        );

        expect(result.size, size);
        expect(
          validator.isValidComplete(
            result.board
                .map<List<CellValue?>>((row) => [...row])
                .toList(),
          ),
          isTrue,
        );
        expect(result.exploredStates, greaterThan(0));
        expect(result.candidateLineCount, greaterThanOrEqualTo(size));
      });
    }

    test('uses exactly half zeroes and half ones in every line', () {
      final result = generator.generate(size: 6, seed: 6061);

      for (final row in result.board) {
        expect(
          row.where((value) => value == CellValue.zero).length,
          3,
        );
        expect(
          row.where((value) => value == CellValue.one).length,
          3,
        );
      }

      for (var column = 0; column < result.size; column++) {
        final values = [
          for (final row in result.board) row[column],
        ];
        expect(
          values.where((value) => value == CellValue.zero).length,
          3,
        );
        expect(
          values.where((value) => value == CellValue.one).length,
          3,
        );
      }
    });

    test('does not generate duplicate rows or columns', () {
      final result = generator.generate(size: 8, seed: 6082);

      final rowKeys = result.board.map(_lineKey).toSet();
      final columnKeys = <String>{
        for (var column = 0; column < result.size; column++)
          _lineKey([
            for (final row in result.board) row[column],
          ]),
      };

      expect(rowKeys.length, result.size);
      expect(columnKeys.length, result.size);
    });

    test('is deterministic for the same seed', () {
      final first = generator.generate(size: 6, seed: 123456);
      final second = generator.generate(size: 6, seed: 123456);

      expect(second.seed, first.seed);
      expect(second.board, first.board);
      expect(second.exploredStates, first.exploredStates);
    });

    test('rejects odd and too-small board sizes', () {
      expect(
        () => generator.generate(size: 3, seed: 1),
        throwsArgumentError,
      );
      expect(
        () => generator.generate(size: 5, seed: 1),
        throwsArgumentError,
      );
      expect(
        () => generator.generate(size: 2, seed: 1),
        throwsArgumentError,
      );
    });
  });
}

String _lineKey(List<CellValue> values) =>
    values.map((value) => value.label).join();
