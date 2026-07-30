import 'game_logic.dart';
import 'features/binary_puzzle/domain/binary_puzzle_generator.dart';

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
  String get title => 'Tagesrätsel · ${difficulty.label} · $size × $size';
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
    final dayNumber = localDay.difference(DateTime(2020)).inDays;
    final sizes = <int>[4, 6, 8];
    const difficulties = PuzzleDifficulty.values;
    final size = sizes[dayNumber % sizes.length];
    final difficulty = difficulties[(dayNumber ~/ sizes.length) % difficulties.length];
    final seed = _stableSeed(dayKey);
    final generated = generator.generate(
      size: size,
      difficulty: difficulty,
      seed: seed,
    );
    final definition = BinaryPuzzleDefinition(
      id: 'daily-binary-$dayKey',
      number: 1,
      difficulty: difficulty,
      solution: generated.definition.solution,
      clues: generated.definition.clues,
    );
    final challenge = DailyBinaryChallenge(
      dayKey: dayKey,
      definition: definition,
      seed: seed,
    );
    _cache[dayKey] = challenge;
    return challenge;
  }

  DailyBinaryChallenge today() => challengeFor(DateTime.now());

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
