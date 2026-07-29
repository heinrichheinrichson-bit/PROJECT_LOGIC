import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/features/binary_puzzle/domain/binary_puzzle_solver.dart';
import 'package:project_logic_prototype/game_logic.dart';

void main() {
  const solver = BinaryPuzzleSolver();

  group('BinaryPuzzleSolver', () {
    test('solves a uniquely defined 4x4 puzzle', () {
      final result = solver.solve(
        _values([
          [0, 0, null, null],
          [0, null, null, null],
          [null, null, 1, null],
          [null, null, null, null],
        ]),
        solutionLimit: 2,
      );

      expect(result.isSolvable, isTrue);
      expect(result.hasUniqueSolution, isTrue);
      expect(result.solutionCount, 1);
      expect(
        result.firstSolution,
        _completeValues([
          [0, 0, 1, 1],
          [0, 1, 0, 1],
          [1, 0, 1, 0],
          [1, 1, 0, 0],
        ]),
      );
      expect(result.exploredStates, greaterThan(0));
    });

    test('reports an invalid puzzle as unsolvable', () {
      final result = solver.solve(
        _values([
          [0, 0, 0, null],
          [null, null, null, null],
          [null, null, null, null],
          [null, null, null, null],
        ]),
      );

      expect(result.isSolvable, isFalse);
      expect(result.solutionCount, 0);
    });

    test('stops after the requested number of solutions', () {
      final result = solver.solve(
        _values([
          [null, null, null, null],
          [null, null, null, null],
          [null, null, null, null],
          [null, null, null, null],
        ]),
        solutionLimit: 2,
      );

      expect(result.solutionCount, 2);
      expect(result.wasLimited, isTrue);
      expect(result.hasUniqueSolution, isFalse);
    });

    test('rejects an invalid solution limit', () {
      expect(
        () => solver.solve(
          _values([
            [null, null, null, null],
            [null, null, null, null],
            [null, null, null, null],
            [null, null, null, null],
          ]),
          solutionLimit: 0,
        ),
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

List<List<CellValue>> _completeValues(List<List<int>> values) => [
      for (final row in values)
        [
          for (final value in row)
            value == 0 ? CellValue.zero : CellValue.one,
        ],
    ];
