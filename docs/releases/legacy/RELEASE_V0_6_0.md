# v0.6.0 Test Checklist

Run:

```bash
flutter clean && flutter pub get && flutter test && flutter run -d chrome
```

Expected:

```text
All tests passed!
```

Manual regression:

1. Home screen shows `Version 0.6.0 · Generator Core`.
2. Existing catalogue puzzles still start normally.
3. Hints, Undo, Redo, save/continue, settings, and statistics still work.

The generator has no UI in this release. It is tested as isolated domain code.


## Generator validation detail

During generation, incomplete row sets are padded with empty rows before they
are sent to `BinaryBoardValidator`. This preserves the validator's square-board
contract while allowing safe validation of intermediate generator states.
