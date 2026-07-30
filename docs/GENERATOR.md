# Binary Board Generator

`BinaryBoardGenerator` creates complete valid Binary Puzzle solution boards.

## Algorithm

1. Create every legal row for the requested size.
2. Shuffle the legal rows with a seeded random number generator.
3. Add unique rows recursively.
4. Validate the partial board after every addition.
5. Return only a complete board accepted by `BinaryBoardValidator`.

This line-based approach is substantially smaller than a cell-by-cell search
space and keeps the generator independent from the user interface.

## Determinism

Supplying the same `size` and `seed` produces the same board. This makes bugs
and generated boards reproducible.

## Supported scope in v0.6.0

- Complete solution boards
- Even sizes of at least 4
- Seeded generation
- Generation diagnostics
- Unit tests for 4x4, 6x6, and 8x8

## Not included yet

- Removing clues
- Uniqueness checks for incomplete puzzles
- Difficulty analysis
- App integration
