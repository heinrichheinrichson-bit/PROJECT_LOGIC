# v0.5.4 Test Checklist

Run from the project root:

```bash
flutter clean && flutter pub get && flutter test && flutter run -d chrome
```

Expected test result:

```text
All tests passed!
```

Manual checks:

1. Confirm the home screen shows `Version 0.5.4 · Regression Safety`.
2. Start a Binary Puzzle.
3. Create a deliberately incorrect but not immediately invalid state.
4. Request a logical hint.
5. Confirm no hint creates a duplicate row or column.
6. Confirm an unsolvable state displays `Kein sicherer Hinweis`.
7. Confirm Undo, Redo, save/continue, settings, and statistics still work.
