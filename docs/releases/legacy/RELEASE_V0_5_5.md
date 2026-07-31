# v0.5.5 Test Checklist

Run:

```bash
flutter clean && flutter pub get && flutter test && flutter run -d chrome
```

Manual checks:

1. Home screen displays `Version 0.5.5 · Hint Quality`.
2. A triple hint highlights exactly the relevant three-cell segment.
3. A count hint highlights the relevant complete row or column.
4. The dialog shows rule category, explanation, coordinate, and proposed value.
5. `Nur markieren` leaves the contextual highlighting visible.
6. Applying or editing a cell clears the hint highlighting.
7. Unsafe or unsolvable states still show `Kein sicherer Hinweis`.
