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
        BinaryHintType.count => 'Anzahl-Regel',
        BinaryHintType.uniqueLine => 'Eindeutigkeits-Regel',
        BinaryHintType.solver => 'Kombinierter Schluss',
      };

  String get badge => switch (this) {
        BinaryHintType.triple => 'Direkte Regel',
        BinaryHintType.count => 'Direkte Regel',
        BinaryHintType.uniqueLine => 'Direkte Regel',
        BinaryHintType.solver => 'Mehrere Regeln',
      };
}

class BinaryHint {
  const BinaryHint({
    required this.position,
    required this.value,
    required this.type,
    required this.reason,
    required this.relatedPositions,
  });

  final CellPosition position;
  final CellValue value;
  final BinaryHintType type;
  final String reason;
  final List<CellPosition> relatedPositions;

  String get title => type.title;
  String get badge => type.badge;
  String get coordinate =>
      'Zeile ${position.row + 1}, Spalte ${position.column + 1}';
  String get action => 'Trage dort eine ${value.label} ein.';
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

    final currentState = solver.solve(puzzle.board, solutionLimit: 1);
    if (!currentState.isSolvable) return null;

    final lines = _linesFor(puzzle.board);

    for (final line in lines) {
      final hint = _findTripleHint(line);
      if (hint != null && _isSafeCandidate(puzzle.board, hint)) return hint;
    }

    for (final line in lines) {
      final hint = _findCountHint(line);
      if (hint != null && _isSafeCandidate(puzzle.board, hint)) return hint;
    }

    for (final line in lines) {
      final hint = _findUniqueLineHint(line, lines);
      if (hint != null && _isSafeCandidate(puzzle.board, hint)) return hint;
    }

    return _findSolverHint(puzzle.board);
  }

  bool _isSafeCandidate(
    List<List<CellValue?>> board,
    BinaryHint hint,
  ) {
    final candidateBoard = [
      for (final row in board) [...row],
    ];
    candidateBoard[hint.position.row][hint.position.column] = hint.value;

    if (!validator.isValidPartial(candidateBoard)) return false;

    return solver.solve(candidateBoard, solutionLimit: 1).isSolvable;
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
              'Dreierfolge verhindern: In ${line.name} stehen bereits zwei gleiche Zahlen direkt nebeneinander. Eine dritte gleiche Zahl ist nicht erlaubt.',
          relatedPositions: line.positions.sublist(index, index + 3),
        );
      }

      if (second != null && second == third && first == null) {
        return BinaryHint(
          position: line.positions[index],
          value: _opposite(second),
          type: BinaryHintType.triple,
          reason:
              'Dreierfolge verhindern: In ${line.name} stehen bereits zwei gleiche Zahlen direkt nebeneinander. Eine dritte gleiche Zahl ist nicht erlaubt.',
          relatedPositions: line.positions.sublist(index, index + 3),
        );
      }

      if (first != null && first == third && second == null) {
        return BinaryHint(
          position: line.positions[index + 1],
          value: _opposite(first),
          type: BinaryHintType.triple,
          reason:
              'In ${line.name} liegen zwei gleiche Zahlen mit einer Lücke dazwischen. Damit keine Dreierfolge entsteht, muss in die Mitte die andere Zahl.',
          relatedPositions: line.positions.sublist(index, index + 3),
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
            '${line.name} enthält bereits die erlaubten $maximum Nullen. Damit Nullen und Einsen gleich häufig vorkommen, müssen alle freien Felder Einsen sein.',
        relatedPositions: line.positions,
      );
    }

    if (oneCount == maximum) {
      return BinaryHint(
        position: line.positions[empty],
        value: CellValue.zero,
        type: BinaryHintType.count,
        reason:
            '${line.name} enthält bereits die erlaubten $maximum Einsen. Damit Nullen und Einsen gleich häufig vorkommen, müssen alle freien Felder Nullen sein.',
        relatedPositions: line.positions,
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
            '${line.name} würde mit dem anderen Wert vollständig ${peer.name} entsprechen. Vollständige ${line.orientation == _LineOrientation.row ? 'Zeilen' : 'Spalten'} müssen sich unterscheiden.',
        relatedPositions: [...line.positions, ...peer.positions],
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
                'Keine einzelne Standardregel reicht hier allein aus. Betrachtet man alle Regeln gemeinsam, bleibt für dieses Feld nur ein zulässiger Wert.',
            relatedPositions: [CellPosition(row, column)],
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
