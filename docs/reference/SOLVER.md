# Binary Solver Foundation

The solver foundation is intentionally independent from the UI.

## Files

- `binary_board_validator.dart`: validates partial and complete boards.
- `binary_puzzle_solver.dart`: enumerates valid solutions with a configurable limit.

## Current scope

- equal counts of 0 and 1
- no triples
- no duplicate completed rows
- no duplicate completed columns
- backtracking solution search
- solution count and uniqueness signal

## Not included yet

- UI integration
- hint generation
- catalog uniqueness enforcement
- puzzle generation

Those are separate follow-up milestones so the solver can first be tested in isolation.
