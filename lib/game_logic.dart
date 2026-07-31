export 'core/domain/game_identity.dart' show PuzzleDifficulty;

import 'core/domain/game_identity.dart';

enum CellValue {
  zero,
  one;

  CellValue? get next => switch (this) {
        CellValue.zero => CellValue.one,
        CellValue.one => null,
      };

  String get label => this == CellValue.zero ? '0' : '1';
}

enum BinaryPuzzleSize {
  small(4, '4 × 4'),
  standard(6, '6 × 6'),
  large(8, '8 × 8'),
  expert(10, '10 × 10');

  const BinaryPuzzleSize(this.value, this.label);

  final int value;
  final String label;
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

class _HistoryEntry {
  const _HistoryEntry(this.changes, {this.isReset = false});

  final List<CellChange> changes;
  final bool isReset;
}

class RuleIssue {
  const RuleIssue(this.message, this.cells);

  final String message;
  final Set<CellPosition> cells;
}

class BinaryPuzzleDefinition {
  const BinaryPuzzleDefinition({
    required this.id,
    required this.number,
    required this.difficulty,
    required this.solution,
    required this.clues,
  });

  final String id;
  final int number;
  final PuzzleDifficulty difficulty;
  final List<List<CellValue>> solution;
  final Set<CellPosition> clues;

  String get displayName => 'Rätsel $number';
  int get size => solution.length;
  int get clueCount => clues.length;

  BinaryPuzzle createPuzzle() => BinaryPuzzle(
        solution: solution,
        clues: clues,
      );
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
    if (solution.isEmpty ||
        solution.any((row) => row.length != solution.length)) {
      throw ArgumentError('The solution must be a non-empty square grid.');
    }
  }

  final int size;
  final List<List<CellValue>> solution;
  final Set<CellPosition> clues;
  final List<List<CellValue?>> board;

  final List<_HistoryEntry> _undoStack = [];
  final List<_HistoryEntry> _redoStack = [];

  bool isClue(int row, int column) => clues.contains(CellPosition(row, column));

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  bool get nextUndoIsReset => canUndo && _undoStack.last.isReset;
  bool get nextRedoIsReset => canRedo && _redoStack.last.isReset;
  int get editableCellCount => size * size - clues.length;
  int get filledEditableCellCount {
    var count = 0;
    for (var row = 0; row < size; row++) {
      for (var column = 0; column < size; column++) {
        if (!isClue(row, column) && board[row][column] != null) count++;
      }
    }
    return count;
  }

  double get progress =>
      editableCellCount == 0 ? 1 : filledEditableCellCount / editableCellCount;

  List<int?> exportEditableValues() {
    final values = <int?>[];
    for (var row = 0; row < size; row++) {
      for (var column = 0; column < size; column++) {
        if (!isClue(row, column)) {
          values.add(switch (board[row][column]) {
            CellValue.zero => 0,
            CellValue.one => 1,
            null => null,
          });
        }
      }
    }
    return values;
  }

  void restoreEditableValues(List<int?> values) {
    if (values.length != editableCellCount) {
      throw ArgumentError(
        'Expected $editableCellCount editable values, got ${values.length}.',
      );
    }

    var index = 0;
    for (var row = 0; row < size; row++) {
      for (var column = 0; column < size; column++) {
        if (!isClue(row, column)) {
          board[row][column] = switch (values[index]) {
            0 => CellValue.zero,
            1 => CellValue.one,
            _ => null,
          };
          index++;
        }
      }
    }
    _undoStack.clear();
    _redoStack.clear();
  }

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

  void setCell(int row, int column, CellValue value) {
    if (isClue(row, column) || board[row][column] == value) return;

    _apply(
      CellChange(
        position: CellPosition(row, column),
        before: board[row][column],
        after: value,
      ),
      clearRedo: true,
    );
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    final entry = _undoStack.removeLast();
    for (final change in entry.changes.reversed) {
      board[change.position.row][change.position.column] = change.before;
    }
    _redoStack.add(entry);
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    final entry = _redoStack.removeLast();
    for (final change in entry.changes) {
      board[change.position.row][change.position.column] = change.after;
    }
    _undoStack.add(entry);
  }

  void reset() {
    final changes = <CellChange>[];
    for (var row = 0; row < size; row++) {
      for (var column = 0; column < size; column++) {
        if (!isClue(row, column) && board[row][column] != null) {
          changes.add(CellChange(
            position: CellPosition(row, column),
            before: board[row][column],
            after: null,
          ));
          board[row][column] = null;
        }
      }
    }
    _undoStack.add(_HistoryEntry(changes, isReset: true));
    _redoStack.clear();
  }

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
    _undoStack.add(_HistoryEntry([change]));
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
      issues.add(RuleIssue('$label enthält zu viele Nullen.', {
        for (var index = 0; index < size; index++)
          if (values[index] == CellValue.zero) positions[index],
      }));
    }

    if (oneCount > maximum) {
      issues.add(RuleIssue('$label enthält zu viele Einsen.', {
        for (var index = 0; index < size; index++)
          if (values[index] == CellValue.one) positions[index],
      }));
    }

    for (var index = 0; index <= size - 3; index++) {
      final first = values[index];
      if (first != null &&
          first == values[index + 1] &&
          first == values[index + 2]) {
        issues.add(RuleIssue(
          '$label enthält drei gleiche Zahlen nebeneinander.',
          {positions[index], positions[index + 1], positions[index + 2]},
        ));
      }
    }
  }

  void _checkDuplicateCompletedRows(List<RuleIssue> issues) {
    for (var first = 0; first < size; first++) {
      if (board[first].contains(null)) continue;
      for (var second = first + 1; second < size; second++) {
        if (board[second].contains(null)) continue;
        if (_sameLine(board[first], board[second])) {
          issues.add(RuleIssue(
            'Zeilen ${first + 1} und ${second + 1} sind identisch.',
            {
              for (var column = 0; column < size; column++)
                CellPosition(first, column),
              for (var column = 0; column < size; column++)
                CellPosition(second, column),
            },
          ));
        }
      }
    }
  }

  void _checkDuplicateCompletedColumns(List<RuleIssue> issues) {
    for (var first = 0; first < size; first++) {
      final firstColumn =
          List<CellValue?>.generate(size, (row) => board[row][first]);
      if (firstColumn.contains(null)) continue;

      for (var second = first + 1; second < size; second++) {
        final secondColumn =
            List<CellValue?>.generate(size, (row) => board[row][second]);
        if (secondColumn.contains(null)) continue;

        if (_sameLine(firstColumn, secondColumn)) {
          issues.add(RuleIssue(
            'Spalten ${first + 1} und ${second + 1} sind identisch.',
            {
              for (var row = 0; row < size; row++) CellPosition(row, first),
              for (var row = 0; row < size; row++) CellPosition(row, second),
            },
          ));
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

const _baseSolution = [
  [
    CellValue.zero,
    CellValue.zero,
    CellValue.one,
    CellValue.zero,
    CellValue.one,
    CellValue.one
  ],
  [
    CellValue.zero,
    CellValue.zero,
    CellValue.one,
    CellValue.one,
    CellValue.zero,
    CellValue.one
  ],
  [
    CellValue.one,
    CellValue.one,
    CellValue.zero,
    CellValue.zero,
    CellValue.one,
    CellValue.zero
  ],
  [
    CellValue.zero,
    CellValue.one,
    CellValue.zero,
    CellValue.zero,
    CellValue.one,
    CellValue.one
  ],
  [
    CellValue.one,
    CellValue.zero,
    CellValue.one,
    CellValue.one,
    CellValue.zero,
    CellValue.zero
  ],
  [
    CellValue.one,
    CellValue.one,
    CellValue.zero,
    CellValue.one,
    CellValue.zero,
    CellValue.zero
  ],
];

List<List<CellValue>> _invert(List<List<CellValue>> source) => [
      for (final row in source)
        [
          for (final value in row)
            value == CellValue.zero ? CellValue.one : CellValue.zero
        ],
    ];

List<List<CellValue>> _transpose(List<List<CellValue>> source) => [
      for (var column = 0; column < source.length; column++)
        [for (var row = 0; row < source.length; row++) source[row][column]],
    ];

List<List<CellValue>> _reverseRows(List<List<CellValue>> source) =>
    source.reversed.map((row) => List<CellValue>.from(row)).toList();

Set<CellPosition> _positions(List<(int, int)> values) =>
    {for (final value in values) CellPosition(value.$1, value.$2)};

final List<BinaryPuzzleDefinition> binaryPuzzleCatalog = [
  BinaryPuzzleDefinition(
    id: 'easy-01',
    number: 1,
    difficulty: PuzzleDifficulty.easy,
    solution: _baseSolution,
    clues: _positions([
      (0, 0),
      (0, 2),
      (0, 4),
      (1, 1),
      (1, 3),
      (2, 2),
      (2, 5),
      (3, 0),
      (3, 3),
      (4, 1),
      (4, 4),
      (5, 5)
    ]),
  ),
  BinaryPuzzleDefinition(
    id: 'easy-02',
    number: 2,
    difficulty: PuzzleDifficulty.easy,
    solution: _invert(_baseSolution),
    clues: _positions([
      (0, 1),
      (0, 5),
      (1, 0),
      (1, 2),
      (1, 4),
      (2, 1),
      (2, 3),
      (3, 2),
      (3, 5),
      (4, 0),
      (4, 3),
      (5, 4)
    ]),
  ),
  BinaryPuzzleDefinition(
    id: 'easy-03',
    number: 3,
    difficulty: PuzzleDifficulty.easy,
    solution: _transpose(_baseSolution),
    clues: _positions([
      (0, 0),
      (0, 3),
      (1, 1),
      (1, 4),
      (2, 0),
      (2, 2),
      (2, 5),
      (3, 1),
      (3, 4),
      (4, 2),
      (5, 0),
      (5, 5)
    ]),
  ),
  BinaryPuzzleDefinition(
    id: 'medium-01',
    number: 1,
    difficulty: PuzzleDifficulty.medium,
    solution: _reverseRows(_baseSolution),
    clues: _positions([
      (0, 0),
      (0, 5),
      (1, 2),
      (2, 1),
      (2, 4),
      (3, 3),
      (4, 0),
      (4, 5),
      (5, 2)
    ]),
  ),
  BinaryPuzzleDefinition(
    id: 'medium-02',
    number: 2,
    difficulty: PuzzleDifficulty.medium,
    solution: _transpose(_invert(_baseSolution)),
    clues: _positions([
      (0, 2),
      (1, 0),
      (1, 5),
      (2, 3),
      (3, 1),
      (3, 4),
      (4, 2),
      (5, 0),
      (5, 5)
    ]),
  ),
  BinaryPuzzleDefinition(
    id: 'medium-03',
    number: 3,
    difficulty: PuzzleDifficulty.medium,
    solution: _invert(_reverseRows(_baseSolution)),
    clues: _positions([
      (0, 1),
      (0, 4),
      (1, 3),
      (2, 0),
      (2, 5),
      (3, 2),
      (4, 1),
      (4, 4),
      (5, 3)
    ]),
  ),
  BinaryPuzzleDefinition(
    id: 'hard-01',
    number: 1,
    difficulty: PuzzleDifficulty.hard,
    solution: _baseSolution,
    clues: _positions([(0, 4), (1, 1), (2, 3), (3, 0), (4, 5), (5, 2), (5, 4)]),
  ),
  BinaryPuzzleDefinition(
    id: 'hard-02',
    number: 2,
    difficulty: PuzzleDifficulty.hard,
    solution: _transpose(_baseSolution),
    clues: _positions([(0, 0), (1, 4), (2, 2), (3, 5), (4, 1), (5, 3), (5, 5)]),
  ),
  BinaryPuzzleDefinition(
    id: 'hard-03',
    number: 3,
    difficulty: PuzzleDifficulty.hard,
    solution: _invert(_baseSolution),
    clues: _positions([(0, 5), (1, 2), (2, 0), (3, 4), (4, 1), (5, 3), (5, 4)]),
  ),
];

List<BinaryPuzzleDefinition> puzzlesFor(PuzzleDifficulty difficulty) =>
    binaryPuzzleCatalog
        .where((puzzle) => puzzle.difficulty == difficulty)
        .toList();

class BinaryPuzzleChapter {
  const BinaryPuzzleChapter({
    required this.index,
    required this.title,
    required this.puzzles,
  });

  final int index;
  final String title;
  final List<BinaryPuzzleDefinition> puzzles;
}

List<BinaryPuzzleChapter> chaptersFor(
  PuzzleDifficulty difficulty, {
  int chapterSize = 10,
}) {
  if (chapterSize <= 0) throw ArgumentError.value(chapterSize, 'chapterSize');
  final puzzles = puzzlesFor(difficulty);
  const titles = [
    'Erste Schritte',
    'Sicher kombiniert',
    'Neue Muster',
    'Vorausgedacht',
    'Große Herausforderungen',
    'Meisterrunde',
  ];
  return [
    for (var start = 0; start < puzzles.length; start += chapterSize)
      BinaryPuzzleChapter(
        index: start ~/ chapterSize + 1,
        title: start ~/ chapterSize < titles.length
            ? titles[start ~/ chapterSize]
            : 'Kapitel ${start ~/ chapterSize + 1}',
        puzzles: List.unmodifiable(
          puzzles.skip(start).take(chapterSize),
        ),
      ),
  ];
}

BinaryPuzzleDefinition? nextPuzzleInDifficulty(
  BinaryPuzzleDefinition current,
) {
  final group = puzzlesFor(current.difficulty);
  final index = group.indexWhere((puzzle) => puzzle.id == current.id);
  if (index < 0 || index + 1 >= group.length) return null;
  return group[index + 1];
}
