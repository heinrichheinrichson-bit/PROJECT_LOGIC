import 'game_logic.dart';
import 'features/binary_puzzle/domain/binary_puzzle_generator.dart';
import 'core/domain/game_identity.dart';

class DailyChallengeSummary {
  const DailyChallengeSummary({
    required this.dayKey,
    required this.day,
    required this.size,
    required this.difficulty,
    required this.seed,
    this.gameType = GameType.binairo,
  });

  final String dayKey;
  final DateTime day;
  final int size;
  final PuzzleDifficulty difficulty;
  final int seed;
  final GameType gameType;

  String get puzzleId => 'daily-${_gamePrefix(gameType)}-$dayKey';

  static String _gamePrefix(GameType gameType) => switch (gameType) {
        GameType.binairo => 'binary',
        GameType.hashi => 'hashi',
        GameType.slitherlink => 'slitherlink',
        _ => gameType.name,
      };
}

class DailyBinaryChallenge {
  const DailyBinaryChallenge({
    required this.dayKey,
    required this.definition,
    required this.seed,
  });

  final String dayKey;
  final BinaryPuzzleDefinition definition;
  final int seed;

  String get puzzleId => definition.id;
  int get size => definition.size;
  PuzzleDifficulty get difficulty => definition.difficulty;
  String get title =>
      'Tagesrätsel · ${DailyChallengeService.formatDate(day)} · ${difficulty.label} · $size × $size';

  DateTime get day => DateTime.parse(dayKey);
}

class DailyChallengeService {
  const DailyChallengeService({
    this.generator = const BinaryPuzzleGenerator(),
  });

  final BinaryPuzzleGenerator generator;

  static final Map<String, DailyBinaryChallenge> _cache = {};

  DailyBinaryChallenge challengeFor(DateTime date) {
    final localDay = DateTime(date.year, date.month, date.day);
    final dayKey = _dayKey(localDay);
    final cached = _cache[dayKey];
    if (cached != null) return cached;
    final summary = summaryFor(localDay);
    final generated = generator.generate(
      size: summary.size,
      difficulty: summary.difficulty,
      seed: summary.seed,
    );
    final definition = BinaryPuzzleDefinition(
      id: summary.puzzleId,
      number: 1,
      difficulty: summary.difficulty,
      solution: generated.definition.solution,
      clues: generated.definition.clues,
    );
    final challenge = DailyBinaryChallenge(
      dayKey: dayKey,
      definition: definition,
      seed: summary.seed,
    );
    _cache[dayKey] = challenge;
    return challenge;
  }

  DailyBinaryChallenge today() => challengeFor(DateTime.now());

  DailyChallengeSummary summaryFor(DateTime date) {
    return summaryForGame(date, GameType.binairo);
  }

  DailyChallengeSummary summaryForGame(DateTime date, GameType gameType) {
    final day = DateTime(date.year, date.month, date.day);
    final dayKey = _dayKey(day);
    final dayNumber = day.difference(DateTime(2020)).inDays;
    final sizes = switch (gameType) {
      GameType.binairo => const <int>[4, 6, 8],
      GameType.hashi => const <int>[6, 8, 9],
      GameType.slitherlink => const <int>[5, 6, 7],
      GameType.futoshiki => const <int>[4, 5, 6],
      _ => const <int>[6, 7, 8],
    };
    const difficulties = PuzzleDifficulty.values;
    return DailyChallengeSummary(
      dayKey: dayKey,
      day: day,
      size: sizes[dayNumber % sizes.length],
      difficulty:
          difficulties[(dayNumber ~/ sizes.length) % difficulties.length],
      seed: _stableSeed(
        gameType == GameType.binairo ? dayKey : '${gameType.name}:$dayKey',
      ),
      gameType: gameType,
    );
  }

  List<DailyChallengeSummary> archiveSummaries({
    DateTime? through,
    int days = 30,
  }) {
    return archiveSummariesForGame(
      GameType.binairo,
      through: through,
      days: days,
    );
  }

  List<DailyChallengeSummary> archiveSummariesForGame(
    GameType gameType, {
    DateTime? through,
    int days = 30,
  }) {
    if (days < 1) {
      throw ArgumentError.value(days, 'days', 'must be at least 1');
    }
    final endValue = through ?? DateTime.now();
    final end = DateTime(endValue.year, endValue.month, endValue.day);
    return List<DailyChallengeSummary>.generate(
      days,
      (index) => summaryForGame(
        end.subtract(Duration(days: index)),
        gameType,
      ),
      growable: false,
    );
  }

  static String formatDate(DateTime value) {
    const months = <String>[
      'Januar',
      'Februar',
      'März',
      'April',
      'Mai',
      'Juni',
      'Juli',
      'August',
      'September',
      'Oktober',
      'November',
      'Dezember',
    ];
    return '${value.day}. ${months[value.month - 1]}';
  }

  static String _dayKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  static int _stableSeed(String value) {
    var hash = 0x811C9DC5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
