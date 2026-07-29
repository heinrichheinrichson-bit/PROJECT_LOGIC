import '../../../game_logic.dart';

class BinaryBoardValidator {
  const BinaryBoardValidator();

  bool isValidPartial(List<List<CellValue?>> board) {
    _validateShape(board);
    final size = board.length;
    final maximumPerValue = size ~/ 2;

    for (final row in board) {
      if (!_lineIsValid(row, maximumPerValue)) return false;
    }

    for (var column = 0; column < size; column++) {
      final values = List<CellValue?>.generate(
        size,
        (row) => board[row][column],
      );
      if (!_lineIsValid(values, maximumPerValue)) return false;
    }

    if (_containsDuplicateCompleteRows(board)) return false;
    if (_containsDuplicateCompleteColumns(board)) return false;

    return true;
  }

  bool isValidComplete(List<List<CellValue?>> board) {
    if (!isValidPartial(board)) return false;
    return board.every(
      (row) => row.every((value) => value != null),
    );
  }

  void _validateShape(List<List<CellValue?>> board) {
    if (board.isEmpty ||
        board.length.isOdd ||
        board.any((row) => row.length != board.length)) {
      throw ArgumentError(
        'A binary puzzle board must be a non-empty, even-sized square.',
      );
    }
  }

  bool _lineIsValid(
    List<CellValue?> values,
    int maximumPerValue,
  ) {
    final zeroCount =
        values.where((value) => value == CellValue.zero).length;
    final oneCount =
        values.where((value) => value == CellValue.one).length;

    if (zeroCount > maximumPerValue || oneCount > maximumPerValue) {
      return false;
    }

    for (var index = 0; index <= values.length - 3; index++) {
      final value = values[index];
      if (value != null &&
          value == values[index + 1] &&
          value == values[index + 2]) {
        return false;
      }
    }

    return true;
  }

  bool _containsDuplicateCompleteRows(
    List<List<CellValue?>> board,
  ) {
    final completeRows = board
        .where((row) => row.every((value) => value != null))
        .map(_lineKey);

    return _containsDuplicateKeys(completeRows);
  }

  bool _containsDuplicateCompleteColumns(
    List<List<CellValue?>> board,
  ) {
    final completeColumns = <String>[];

    for (var column = 0; column < board.length; column++) {
      final values = List<CellValue?>.generate(
        board.length,
        (row) => board[row][column],
      );

      if (values.every((value) => value != null)) {
        completeColumns.add(_lineKey(values));
      }
    }

    return _containsDuplicateKeys(completeColumns);
  }

  String _lineKey(List<CellValue?> values) =>
      values.map((value) => value!.label).join();

  bool _containsDuplicateKeys(Iterable<String> keys) {
    final seen = <String>{};
    for (final key in keys) {
      if (!seen.add(key)) return true;
    }
    return false;
  }
}
