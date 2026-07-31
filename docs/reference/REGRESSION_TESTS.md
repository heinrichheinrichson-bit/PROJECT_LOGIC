# Regression Catalogue

This catalogue records bugs that must never return.

## HINT-001 – A hint creates a duplicate column

**Original symptom**

A locally correct triple-rule hint completed a column that was identical to
another completed column.

**Required behaviour**

A hint candidate is only valid when:

1. the complete candidate board remains valid under every binary-puzzle rule;
2. the candidate board still has at least one valid solution.

**Automated coverage**

- `hint_engine_test.dart`
  - rejects hints that create duplicate columns
  - rejects hints that create duplicate rows
  - verifies every returned hint leaves a valid, solvable board

## HINT-002 – A hint is offered for an unsolvable state

**Required behaviour**

When the current state has no valid continuation, the hint engine returns no
hint instead of presenting a locally plausible move.

**Automated coverage**

- `hint_engine_test.dart`
  - rule-valid but unsolvable board returns no hint
  - invalid board returns no hint

## Repository hygiene

Historical release helper files are not application source files and must not
be committed:

- `GIT_PUSH_*.txt`
- `TESTANLEITUNG_*.txt`
- `UPDATE_*.txt`
- generated ZIP archives
