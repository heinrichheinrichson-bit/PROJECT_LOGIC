import 'game_logic.dart';

class BinaryHint {
  const BinaryHint({
    required this.position,
    required this.value,
    required this.reason,
  });

  final CellPosition position;
  final CellValue value;
  final String reason;
}

BinaryHint? findBinaryHint(BinaryPuzzle puzzle) {
  for (var row = 0; row < puzzle.size; row++) {
    final hint = _findInLine(
      values: puzzle.board[row],
      positions: List.generate(
        puzzle.size,
        (column) => CellPosition(row, column),
      ),
      lineName: 'Zeile ${row + 1}',
    );
    if (hint != null) return hint;
  }

  for (var column = 0; column < puzzle.size; column++) {
    final values = List<CellValue?>.generate(
      puzzle.size,
      (row) => puzzle.board[row][column],
    );
    final hint = _findInLine(
      values: values,
      positions: List.generate(
        puzzle.size,
        (row) => CellPosition(row, column),
      ),
      lineName: 'Spalte ${column + 1}',
    );
    if (hint != null) return hint;
  }

  return null;
}

BinaryHint? _findInLine({
  required List<CellValue?> values,
  required List<CellPosition> positions,
  required String lineName,
}) {
  final maximum = values.length ~/ 2;
  final zeroCount = values.where((value) => value == CellValue.zero).length;
  final oneCount = values.where((value) => value == CellValue.one).length;

  if (zeroCount == maximum) {
    final empty = values.indexWhere((value) => value == null);
    if (empty >= 0) {
      return BinaryHint(
        position: positions[empty],
        value: CellValue.one,
        reason:
            '$lineName enthält bereits $maximum Nullen. Alle übrigen Felder müssen Einsen sein.',
      );
    }
  }

  if (oneCount == maximum) {
    final empty = values.indexWhere((value) => value == null);
    if (empty >= 0) {
      return BinaryHint(
        position: positions[empty],
        value: CellValue.zero,
        reason:
            '$lineName enthält bereits $maximum Einsen. Alle übrigen Felder müssen Nullen sein.',
      );
    }
  }

  for (var index = 0; index <= values.length - 3; index++) {
    final first = values[index];
    final second = values[index + 1];
    final third = values[index + 2];

    if (first != null && first == second && third == null) {
      return BinaryHint(
        position: positions[index + 2],
        value: _opposite(first),
        reason:
            '$lineName darf keine drei gleichen Zahlen nebeneinander enthalten.',
      );
    }

    if (second != null && second == third && first == null) {
      return BinaryHint(
        position: positions[index],
        value: _opposite(second),
        reason:
            '$lineName darf keine drei gleichen Zahlen nebeneinander enthalten.',
      );
    }

    if (first != null && first == third && second == null) {
      return BinaryHint(
        position: positions[index + 1],
        value: _opposite(first),
        reason:
            'Zwischen zwei gleichen Zahlen muss in $lineName die andere Zahl stehen.',
      );
    }
  }

  return null;
}

CellValue _opposite(CellValue value) =>
    value == CellValue.zero ? CellValue.one : CellValue.zero;
