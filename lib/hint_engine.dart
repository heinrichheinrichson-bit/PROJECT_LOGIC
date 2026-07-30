import 'features/binary_puzzle/domain/binary_board_validator.dart';
import 'features/binary_puzzle/domain/binary_puzzle_solver.dart';
import 'game_logic.dart';

enum BinaryHintType {
  triple,
  count,
  uniqueLine,
  solver;

  String get title => switch (this) {
        BinaryHintType.triple => 'Dreier-Regel',
        BinaryHintType.count => 'Gleiche Anzahl',
        BinaryHintType.uniqueLine => 'Eindeutige Linie',
        BinaryHintType.solver => 'Logische Kombination',
      };
}

class BinaryHint {
  const BinaryHint({
    required this.position,
    required this.value,
    required this.type,
    required this.reason,
  });

  final CellPosition position;
  final CellValue value;
  final BinaryHintType type;
  final String reason;

  String get title => type.title;
}

class BinaryHintEngine {
  const BinaryHintEngine({
    this.solver = const BinaryPuzzleSolver(),
    this.validator = const BinaryBoardValidator(),
  });

  final BinaryPuzzleSolver solver;
  final BinaryBoardValidator validator;

  BinaryHint? findHint(BinaryPuzzle puzzle) {
    if (!validator.isValidPartial(puzzle.board)) return null;

    final lines = _linesFor(puzzle.board);

    for (final line in lines) {
      final hint = _findTripleHint(line);
      if (hint != null) return hint;
    }

    for (final line in lines) {
      final hint = _findCountHint(line);
      if (hint != null) return hint;
    }

    for (final line in lines) {
      final hint = _findUniqueLineHint(line, lines);
      if (hint != null) return hint;
    }

    return _findSolverHint(puzzle.board);
  }

  BinaryHint? _findTripleHint(_BinaryLine line) {
    final values = line.values;

    for (var index = 0; index <= values.length - 3; index++) {
      final first = values[index];
      final second = values[index + 1];
      final third = values[index + 2];

      if (first != null && first == second && third == null) {
        return BinaryHint(
          position: line.positions[index + 2],
          value: _opposite(first),
          type: BinaryHintType.triple,
          reason:
              '${line.name} darf keine drei gleichen Zahlen direkt hintereinander enthalten.',
        );
      }

      if (second != null && second == third && first == null) {
        return BinaryHint(
          position: line.positions[index],
          value: _opposite(second),
          type: BinaryHintType.triple,
          reason:
              '${line.name} darf keine drei gleichen Zahlen direkt hintereinander enthalten.',
        );
      }

      if (first != null && first == third && second == null) {
        return BinaryHint(
          position: line.positions[index + 1],
          value: _opposite(first),
          type: BinaryHintType.triple,
          reason:
              'Zwischen zwei gleichen Zahlen muss in ${line.name} die andere Zahl stehen.',
        );
      }
    }

    return null;
  }

  BinaryHint? _findCountHint(_BinaryLine line) {
    final maximum = line.values.length ~/ 2;
    final zeroCount =
        line.values.where((value) => value == CellValue.zero).length;
    final oneCount =
        line.values.where((value) => value == CellValue.one).length;
    final empty = line.values.indexWhere((value) => value == null);

    if (empty < 0) return null;

    if (zeroCount == maximum) {
      return BinaryHint(
        position: line.positions[empty],
        value: CellValue.one,
        type: BinaryHintType.count,
        reason:
            '${line.name} enthält bereits $maximum Nullen. Alle übrigen Felder müssen Einsen sein.',
      );
    }

    if (oneCount == maximum) {
      return BinaryHint(
        position: line.positions[empty],
        value: CellValue.zero,
        type: BinaryHintType.count,
        reason:
            '${line.name} enthält bereits $maximum Einsen. Alle übrigen Felder müssen Nullen sein.',
      );
    }

    return null;
  }

  BinaryHint? _findUniqueLineHint(
    _BinaryLine line,
    List<_BinaryLine> allLines,
  ) {
    final emptyIndices = <int>[
      for (var index = 0; index < line.values.length; index++)
        if (line.values[index] == null) index,
    ];
    if (emptyIndices.length != 1) return null;

    final emptyIndex = emptyIndices.single;
    final peers = allLines.where(
      (candidate) =>
          candidate.orientation == line.orientation &&
          candidate.index != line.index &&
          candidate.values.every((value) => value != null),
    );

    for (final peer in peers) {
      var matchesKnownValues = true;
      for (var index = 0; index < line.values.length; index++) {
        if (index == emptyIndex) continue;
        if (line.values[index] != peer.values[index]) {
          matchesKnownValues = false;
          break;
        }
      }
      if (!matchesKnownValues) continue;

      final value = _opposite(peer.values[emptyIndex]!);
      final candidateBoard = _copyBoardFromLines(allLines);
      final position = line.positions[emptyIndex];
      candidateBoard[position.row][position.column] = value;
      if (!validator.isValidPartial(candidateBoard)) continue;

      return BinaryHint(
        position: position,
        value: value,
        type: BinaryHintType.uniqueLine,
        reason:
            '${line.name} wäre sonst identisch mit ${peer.name}. Vollständige ${line.orientation == _LineOrientation.row ? 'Zeilen' : 'Spalten'} müssen verschieden sein.',
      );
    }

    return null;
  }

  BinaryHint? _findSolverHint(List<List<CellValue?>> board) {
    final result = solver.solve(board, solutionLimit: 2);
    if (!result.hasUniqueSolution) return null;

    final solution = result.firstSolution!;
    for (var row = 0; row < board.length; row++) {
      for (var column = 0; column < board.length; column++) {
        if (board[row][column] == null) {
          return BinaryHint(
            position: CellPosition(row, column),
            value: solution[row][column],
            type: BinaryHintType.solver,
            reason:
                'Aus der Kombination aller Binärpuzzle-Regeln ergibt sich für dieses Feld nur ein möglicher Wert.',
          );
        }
      }
    }

    return null;
  }

  List<_BinaryLine> _linesFor(List<List<CellValue?>> board) {
    final lines = <_BinaryLine>[];

    for (var row = 0; row < board.length; row++) {
      lines.add(
        _BinaryLine(
          orientation: _LineOrientation.row,
          index: row,
          name: 'Zeile ${row + 1}',
          values: board[row],
          positions: List.generate(
            board.length,
            (column) => CellPosition(row, column),
          ),
        ),
      );
    }

    for (var column = 0; column < board.length; column++) {
      lines.add(
        _BinaryLine(
          orientation: _LineOrientation.column,
          index: column,
          name: 'Spalte ${column + 1}',
          values: List<CellValue?>.generate(
            board.length,
            (row) => board[row][column],
          ),
          positions: List.generate(
            board.length,
            (row) => CellPosition(row, column),
          ),
        ),
      );
    }

    return lines;
  }

  List<List<CellValue?>> _copyBoardFromLines(List<_BinaryLine> lines) {
    final rows = lines
        .where((line) => line.orientation == _LineOrientation.row)
        .toList()
      ..sort((first, second) => first.index.compareTo(second.index));
    return [
      for (final row in rows) [...row.values],
    ];
  }
}

BinaryHint? findBinaryHint(BinaryPuzzle puzzle) =>
    const BinaryHintEngine().findHint(puzzle);

CellValue _opposite(CellValue value) =>
    value == CellValue.zero ? CellValue.one : CellValue.zero;

enum _LineOrientation { row, column }

class _BinaryLine {
  const _BinaryLine({
    required this.orientation,
    required this.index,
    required this.name,
    required this.values,
    required this.positions,
  });

  final _LineOrientation orientation;
  final int index;
  final String name;
  final List<CellValue?> values;
  final List<CellPosition> positions;
}
