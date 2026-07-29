enum CellValue {
  zero,
  one;

  CellValue? get next => switch (this) {
        CellValue.zero => CellValue.one,
        CellValue.one => null,
      };

  String get label => this == CellValue.zero ? '0' : '1';
}

class CellPosition {
  const CellPosition(this.row, this.column);

  final int row;
  final int column;

  @override
  bool operator ==(Object other) =>
      other is CellPosition && row == other.row && column == other.column;

  @override
  int get hashCode => Object.hash(row, column);
}

class CellChange {
  const CellChange({
    required this.position,
    required this.before,
    required this.after,
  });

  final CellPosition position;
  final CellValue? before;
  final CellValue? after;
}

class RuleIssue {
  const RuleIssue(this.message, this.cells);

  final String message;
  final Set<CellPosition> cells;
}

class BinaryPuzzle {
  BinaryPuzzle({
    required this.solution,
    required this.clues,
  })  : size = solution.length,
        board = List.generate(
          solution.length,
          (row) => List<CellValue?>.generate(
            solution.length,
            (column) => clues.contains(CellPosition(row, column))
                ? solution[row][column]
                : null,
          ),
        ) {
    if (solution.isEmpty || solution.any((row) => row.length != solution.length)) {
      throw ArgumentError('The solution must be a non-empty square grid.');
    }
  }

  final int size;
  final List<List<CellValue>> solution;
  final Set<CellPosition> clues;
  final List<List<CellValue?>> board;

  final List<CellChange> _undoStack = [];
  final List<CellChange> _redoStack = [];

  bool isClue(int row, int column) => clues.contains(CellPosition(row, column));

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void cycleCell(int row, int column) {
    if (isClue(row, column)) return;

    final before = board[row][column];
    final after = before == null ? CellValue.zero : before.next;
    _apply(
      CellChange(
        position: CellPosition(row, column),
        before: before,
        after: after,
      ),
      clearRedo: true,
    );
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    final change = _undoStack.removeLast();
    board[change.position.row][change.position.column] = change.before;
    _redoStack.add(change);
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    final change = _redoStack.removeLast();
    board[change.position.row][change.position.column] = change.after;
    _undoStack.add(change);
  }

  void reset() {
    for (var row = 0; row < size; row++) {
      for (var column = 0; column < size; column++) {
        board[row][column] =
            isClue(row, column) ? solution[row][column] : null;
      }
    }
    _undoStack.clear();
    _redoStack.clear();
  }

  /// Development helper: fills every editable cell with the known solution.
  /// When [leaveOneEmpty] is true, exactly one editable cell stays empty so
  /// the completion flow can be tested with a single tap.
  void fillWithSolution({bool leaveOneEmpty = false}) {
    CellPosition? lastEditable;
    for (var row = 0; row < size; row++) {
      for (var column = 0; column < size; column++) {
        if (!isClue(row, column)) {
          lastEditable = CellPosition(row, column);
          board[row][column] = solution[row][column];
        }
      }
    }

    if (leaveOneEmpty && lastEditable != null) {
      board[lastEditable.row][lastEditable.column] = null;
    }
    _undoStack.clear();
    _redoStack.clear();
  }

  /// Development helper: creates an obvious rule violation.
  void createTestError() {
    reset();
    final editable = <CellPosition>[];
    for (var column = 0; column < size; column++) {
      final position = CellPosition(0, column);
      if (!clues.contains(position)) editable.add(position);
    }
    for (final position in editable.take(3)) {
      board[position.row][position.column] = CellValue.zero;
    }
    _undoStack.clear();
    _redoStack.clear();
  }

  void _apply(CellChange change, {required bool clearRedo}) {
    board[change.position.row][change.position.column] = change.after;
    _undoStack.add(change);
    if (clearRedo) _redoStack.clear();
  }

  List<RuleIssue> validate() {
    final issues = <RuleIssue>[];

    for (var row = 0; row < size; row++) {
      _checkLine(
        board[row],
        List.generate(size, (column) => CellPosition(row, column)),
        'Zeile ${row + 1}',
        issues,
      );
    }

    for (var column = 0; column < size; column++) {
      final values = List<CellValue?>.generate(
        size,
        (row) => board[row][column],
      );
      _checkLine(
        values,
        List.generate(size, (row) => CellPosition(row, column)),
        'Spalte ${column + 1}',
        issues,
      );
    }

    _checkDuplicateCompletedRows(issues);
    _checkDuplicateCompletedColumns(issues);

    return issues;
  }

  void _checkLine(
    List<CellValue?> values,
    List<CellPosition> positions,
    String label,
    List<RuleIssue> issues,
  ) {
    final zeroCount = values.where((value) => value == CellValue.zero).length;
    final oneCount = values.where((value) => value == CellValue.one).length;
    final maximum = size ~/ 2;

    if (zeroCount > maximum) {
      issues.add(
        RuleIssue(
          '$label enthält zu viele Nullen.',
          {
            for (var index = 0; index < size; index++)
              if (values[index] == CellValue.zero) positions[index],
          },
        ),
      );
    }

    if (oneCount > maximum) {
      issues.add(
        RuleIssue(
          '$label enthält zu viele Einsen.',
          {
            for (var index = 0; index < size; index++)
              if (values[index] == CellValue.one) positions[index],
          },
        ),
      );
    }

    for (var index = 0; index <= size - 3; index++) {
      final first = values[index];
      if (first != null &&
          first == values[index + 1] &&
          first == values[index + 2]) {
        issues.add(
          RuleIssue(
            '$label enthält drei gleiche Zahlen nebeneinander.',
            {
              positions[index],
              positions[index + 1],
              positions[index + 2],
            },
          ),
        );
      }
    }
  }

  void _checkDuplicateCompletedRows(List<RuleIssue> issues) {
    for (var first = 0; first < size; first++) {
      if (board[first].contains(null)) continue;

      for (var second = first + 1; second < size; second++) {
        if (board[second].contains(null)) continue;

        if (_sameLine(board[first], board[second])) {
          issues.add(
            RuleIssue(
              'Zeilen ${first + 1} und ${second + 1} sind identisch.',
              {
                for (var column = 0; column < size; column++)
                  CellPosition(first, column),
                for (var column = 0; column < size; column++)
                  CellPosition(second, column),
              },
            ),
          );
        }
      }
    }
  }

  void _checkDuplicateCompletedColumns(List<RuleIssue> issues) {
    for (var first = 0; first < size; first++) {
      final firstColumn = List<CellValue?>.generate(
        size,
        (row) => board[row][first],
      );
      if (firstColumn.contains(null)) continue;

      for (var second = first + 1; second < size; second++) {
        final secondColumn = List<CellValue?>.generate(
          size,
          (row) => board[row][second],
        );
        if (secondColumn.contains(null)) continue;

        if (_sameLine(firstColumn, secondColumn)) {
          issues.add(
            RuleIssue(
              'Spalten ${first + 1} und ${second + 1} sind identisch.',
              {
                for (var row = 0; row < size; row++)
                  CellPosition(row, first),
                for (var row = 0; row < size; row++)
                  CellPosition(row, second),
              },
            ),
          );
        }
      }
    }
  }

  bool _sameLine(List<CellValue?> first, List<CellValue?> second) {
    for (var index = 0; index < size; index++) {
      if (first[index] != second[index]) return false;
    }
    return true;
  }

  bool get isComplete =>
      board.every((row) => row.every((value) => value != null));

  bool get isSolved => isComplete && validate().isEmpty;
}

BinaryPuzzle createPrototypePuzzle() {
  const solution = [
    [
      CellValue.zero,
      CellValue.zero,
      CellValue.one,
      CellValue.zero,
      CellValue.one,
      CellValue.one,
    ],
    [
      CellValue.zero,
      CellValue.zero,
      CellValue.one,
      CellValue.one,
      CellValue.zero,
      CellValue.one,
    ],
    [
      CellValue.one,
      CellValue.one,
      CellValue.zero,
      CellValue.zero,
      CellValue.one,
      CellValue.zero,
    ],
    [
      CellValue.zero,
      CellValue.one,
      CellValue.zero,
      CellValue.zero,
      CellValue.one,
      CellValue.one,
    ],
    [
      CellValue.one,
      CellValue.zero,
      CellValue.one,
      CellValue.one,
      CellValue.zero,
      CellValue.zero,
    ],
    [
      CellValue.one,
      CellValue.one,
      CellValue.zero,
      CellValue.one,
      CellValue.zero,
      CellValue.zero,
    ],
  ];

  final clues = <CellPosition>{
    CellPosition(0, 4),
    CellPosition(0, 5),
    CellPosition(2, 2),
    CellPosition(2, 3),
    CellPosition(3, 2),
    CellPosition(3, 3),
    CellPosition(4, 0),
  };

  return BinaryPuzzle(solution: solution, clues: clues);
}
