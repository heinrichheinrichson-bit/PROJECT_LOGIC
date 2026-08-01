/// Stable identifiers for every game supported by Project Logic.
///
/// Values are persisted by name. Existing values therefore must not be renamed.
enum GameType {
  binairo('Binairo'),
  hashi('Hashi'),
  slitherlink('Slitherlink'),
  hitori('Hitori'),
  futoshiki('Futoshiki'),
  kakuro('Kakuro'),
  nurikabe('Nurikabe'),
  tents('Zelte & Bäume');

  const GameType(this.label);

  final String label;
}

/// The context in which a puzzle is played.
///
/// [generated] is shown to players as "Endlosmodus". Its serialized name is
/// retained because released versions already store it in local save data.
enum GameMode {
  catalog,
  generated,
  daily,
  event,
  tutorial,
}

/// Shared difficulty bands. Individual games may add more precise ratings to
/// their own puzzle definitions while still mapping them to these bands.
enum PuzzleDifficulty {
  easy('Leicht', 'Ruhiger Einstieg'),
  medium('Mittel', 'Mehrere Schritte vorausdenken'),
  hard('Schwer', 'Für erfahrene Rätselfans');

  const PuzzleDifficulty(this.label, this.description);

  final String label;
  final String description;
}

/// Compatibility name used by save data and the existing Binairo UI.
/// New platform code should use [GameMode].
typedef PuzzleSource = GameMode;
