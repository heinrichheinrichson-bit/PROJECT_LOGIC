import 'dart:math';

import '../../../game_logic.dart';
import 'binary_board_validator.dart';

class BinaryBoardGenerationResult {
  const BinaryBoardGenerationResult({
    required this.board,
    required this.seed,
    required this.exploredStates,
    required this.candidateLineCount,
  });

  final List<List<CellValue>> board;
  final int seed;
  final int exploredStates;
  final int candidateLineCount;

  int get size => board.length;
}

/// Generates complete Binary Puzzle solution boards.
///
/// The generator first creates every legal line for the requested size. It
/// then combines unique lines while validating the growing board after every
/// inserted row. This avoids filling the board cell by cell and keeps
/// generation deterministic when a seed is supplied.
class BinaryBoardGenerator {
  const BinaryBoardGenerator({
    this.validator = const BinaryBoardValidator(),
  });

  final BinaryBoardValidator validator;

  BinaryBoardGenerationResult generate({
    required int size,
    int? seed,
  }) {
    _validateSize(size);

    final effectiveSeed =
        seed ?? DateTime.now().microsecondsSinceEpoch & 0x7fffffff;
    final random = Random(effectiveSeed);
    final candidateLines = _createCandidateLines(size)..shuffle(random);

    final board = <List<CellValue?>>[];
    var exploredStates = 0;

    bool search() {
      if (board.length == size) {
        return validator.isValidComplete(board);
      }

      final candidates = [...candidateLines]..shuffle(random);
      for (final candidate in candidates) {
        exploredStates++;
        board.add([...candidate]);

        final partialBoard = <List<CellValue?>>[
          for (final row in board) [...row],
          for (var row = board.length; row < size; row++)
            List<CellValue?>.filled(size, null),
        ];

        if (validator.isValidPartial(partialBoard) && search()) {
          return true;
        }

        board.removeLast();
      }

      return false;
    }

    if (!search()) {
      throw StateError(
        'No valid binary board could be generated for size $size.',
      );
    }

    return BinaryBoardGenerationResult(
      board: [
        for (final row in board) [for (final value in row) value!],
      ],
      seed: effectiveSeed,
      exploredStates: exploredStates,
      candidateLineCount: candidateLines.length,
    );
  }

  List<List<CellValue>> _createCandidateLines(int size) {
    final lines = <List<CellValue>>[];
    final current = <CellValue>[];
    final maximumPerValue = size ~/ 2;

    void build(int zeroCount, int oneCount) {
      if (current.length == size) {
        if (zeroCount == maximumPerValue && oneCount == maximumPerValue) {
          lines.add([...current]);
        }
        return;
      }

      for (final value in CellValue.values) {
        final nextZeroCount = zeroCount + (value == CellValue.zero ? 1 : 0);
        final nextOneCount = oneCount + (value == CellValue.one ? 1 : 0);

        if (nextZeroCount > maximumPerValue || nextOneCount > maximumPerValue) {
          continue;
        }

        if (current.length >= 2 &&
            current[current.length - 1] == value &&
            current[current.length - 2] == value) {
          continue;
        }

        current.add(value);
        build(nextZeroCount, nextOneCount);
        current.removeLast();
      }
    }

    build(0, 0);
    return lines;
  }

  void _validateSize(int size) {
    if (size < 4 || size.isOdd) {
      throw ArgumentError.value(
        size,
        'size',
        'A binary puzzle size must be even and at least 4.',
      );
    }
  }
}
