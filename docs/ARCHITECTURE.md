# Architecture

Project Logic uses a feature-oriented Flutter structure.

```text
lib/
├── main.dart
├── app/
│   └── project_logic_app.dart
├── core/
│   └── formatters/
│       └── duration_formatter.dart
├── features/
│   ├── home/
│   │   └── presentation/
│   ├── binary_puzzle/
│   │   └── presentation/
│   ├── settings/
│   │   └── presentation/
│   └── statistics/
│       └── presentation/
├── app_preferences.dart
├── game_logic.dart
├── game_storage.dart
└── hint_engine.dart
```

## Boundaries

- `main.dart` only initializes Flutter and starts the app.
- `app/` owns theme and top-level application configuration.
- `features/` owns screens and feature-specific widgets.
- `core/` contains reusable, feature-neutral helpers.
- Existing puzzle domain and persistence files stay stable during this refactor.

Future solver and generator work should live below
`features/binary_puzzle/domain/` and `features/binary_puzzle/data/`
instead of being added to the app bootstrap or home screen.
