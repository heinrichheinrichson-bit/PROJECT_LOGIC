import 'game_logic.dart';
import 'features/binary_puzzle/domain/binary_puzzle_generator.dart';

class DailyChallengeSummary {
  const DailyChallengeSummary({
    required this.dayKey,
    required this.day,
    required this.size,
    required this.difficulty,
    required this.seed,
  });

  final String dayKey;
  final DateTime day;
  final int size;
  final PuzzleDifficulty difficulty;
  final int seed;

  String get puzzleId => 'daily-binary-$dayKey';
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
    final day = DateTime(date.year, date.month, date.day);
    final dayKey = _dayKey(day);
    final dayNumber = day.difference(DateTime(2020)).inDays;
    const sizes = <int>[4, 6, 8];
    const difficulties = PuzzleDifficulty.values;
    return DailyChallengeSummary(
      dayKey: dayKey,
      day: day,
      size: sizes[dayNumber % sizes.length],
      difficulty:
          difficulties[(dayNumber ~/ sizes.length) % difficulties.length],
      seed: _stableSeed(dayKey),
    );
  }

  List<DailyChallengeSummary> archiveSummaries({
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
      (index) => summaryFor(end.subtract(Duration(days: index))),
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
