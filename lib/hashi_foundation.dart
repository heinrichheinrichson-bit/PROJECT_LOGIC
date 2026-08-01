import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/domain/game_identity.dart';
import 'core/monetization/hint_economy.dart';
import 'core/presentation/confirm_restart_dialog.dart';
import 'core/statistics/game_statistics.dart';
import 'app_preferences.dart';
import 'game_storage.dart';
import 'features/hashi/domain/hashi_generator.dart';

part 'generated_hashi_catalog.dart';

@immutable
class HashiIsland {
  const HashiIsland({
    required this.row,
    required this.column,
    required this.bridges,
  });

  final int row;
  final int column;
  final int bridges;
}

@immutable
class HashiBridge {
  const HashiBridge({
    required this.from,
    required this.to,
    this.count = 1,
  }) : assert(count == 1 || count == 2);

  final int from;
  final int to;
  final int count;

  HashiBridge copyWith({int? count}) => HashiBridge(
        from: from,
        to: to,
        count: count ?? this.count,
      );
}

@immutable
class HashiPuzzle {
  const HashiPuzzle({
    this.id = '',
    required this.title,
    required this.size,
    required this.islands,
    this.solution = const [],
    this.difficulty = 1,
  });

  final String id;
  final String title;
  final int size;
  final int difficulty;
  final List<HashiIsland> islands;
  final List<HashiBridge> solution;

  PuzzleDifficulty get sharedDifficulty => switch (difficulty) {
        <= 1 => PuzzleDifficulty.easy,
        2 => PuzzleDifficulty.medium,
        _ => PuzzleDifficulty.hard,
      };
}

const hashiPreviewBridges = [
  HashiBridge(from: 0, to: 1),
  HashiBridge(from: 0, to: 2),
  HashiBridge(from: 1, to: 4),
  HashiBridge(from: 2, to: 3),
  HashiBridge(from: 2, to: 5),
  HashiBridge(from: 3, to: 4),
  HashiBridge(from: 4, to: 6),
  HashiBridge(from: 5, to: 6),
];

const hashiTutorialPuzzle = HashiPuzzle(
  id: 'hashi_01',
  title: 'Erste Brücken',
  difficulty: 1,
  size: 7,
  islands: [
    HashiIsland(row: 0, column: 1, bridges: 2),
    HashiIsland(row: 0, column: 5, bridges: 2),
    HashiIsland(row: 3, column: 1, bridges: 3),
    HashiIsland(row: 3, column: 3, bridges: 2),
    HashiIsland(row: 3, column: 5, bridges: 3),
    HashiIsland(row: 6, column: 1, bridges: 2),
    HashiIsland(row: 6, column: 5, bridges: 2),
  ],
  solution: hashiPreviewBridges,
);

const _originalHashiPuzzleCatalog = <HashiPuzzle>[
  hashiTutorialPuzzle,
  HashiPuzzle(
    id: 'hashi_02',
    title: 'Kleine Runde',
    difficulty: 1,
    size: 6,
    islands: [
      HashiIsland(row: 1, column: 1, bridges: 2),
      HashiIsland(row: 1, column: 4, bridges: 2),
      HashiIsland(row: 4, column: 1, bridges: 2),
      HashiIsland(row: 4, column: 4, bridges: 2),
    ],
    solution: [
      HashiBridge(from: 0, to: 1),
      HashiBridge(from: 0, to: 2),
      HashiBridge(from: 1, to: 3),
      HashiBridge(from: 2, to: 3),
    ],
  ),
  HashiPuzzle(
    id: 'hashi_03',
    title: 'Zwei Ufer',
    difficulty: 1,
    size: 7,
    islands: [
      HashiIsland(row: 1, column: 0, bridges: 2),
      HashiIsland(row: 1, column: 3, bridges: 2),
      HashiIsland(row: 1, column: 6, bridges: 2),
      HashiIsland(row: 5, column: 0, bridges: 2),
      HashiIsland(row: 5, column: 3, bridges: 2),
      HashiIsland(row: 5, column: 6, bridges: 2),
    ],
    solution: [
      HashiBridge(from: 0, to: 1),
      HashiBridge(from: 1, to: 2),
      HashiBridge(from: 3, to: 4),
      HashiBridge(from: 4, to: 5),
      HashiBridge(from: 0, to: 3),
      HashiBridge(from: 2, to: 5),
    ],
  ),
  HashiPuzzle(
    id: 'hashi_04',
    title: 'Doppelte Kante',
    difficulty: 2,
    size: 7,
    islands: [
      HashiIsland(row: 1, column: 1, bridges: 3),
      HashiIsland(row: 1, column: 5, bridges: 3),
      HashiIsland(row: 5, column: 1, bridges: 3),
      HashiIsland(row: 5, column: 5, bridges: 3),
    ],
    solution: [
      HashiBridge(from: 0, to: 1, count: 2),
      HashiBridge(from: 0, to: 2),
      HashiBridge(from: 1, to: 3),
      HashiBridge(from: 2, to: 3, count: 2),
    ],
  ),
  HashiPuzzle(
    id: 'hashi_05',
    title: 'Mittelpunkt',
    difficulty: 2,
    size: 7,
    islands: [
      HashiIsland(row: 0, column: 3, bridges: 1),
      HashiIsland(row: 3, column: 0, bridges: 1),
      HashiIsland(row: 3, column: 3, bridges: 4),
      HashiIsland(row: 3, column: 6, bridges: 1),
      HashiIsland(row: 6, column: 3, bridges: 1),
    ],
    solution: [
      HashiBridge(from: 0, to: 2),
      HashiBridge(from: 1, to: 2),
      HashiBridge(from: 2, to: 3),
      HashiBridge(from: 2, to: 4),
    ],
  ),
  HashiPuzzle(
    id: 'hashi_06',
    title: 'Inselring',
    difficulty: 3,
    size: 8,
    islands: [
      HashiIsland(row: 0, column: 1, bridges: 2),
      HashiIsland(row: 0, column: 6, bridges: 2),
      HashiIsland(row: 3, column: 1, bridges: 2),
      HashiIsland(row: 3, column: 6, bridges: 2),
      HashiIsland(row: 7, column: 1, bridges: 2),
      HashiIsland(row: 7, column: 6, bridges: 2),
    ],
    solution: [
      HashiBridge(from: 0, to: 1),
      HashiBridge(from: 0, to: 2),
      HashiBridge(from: 1, to: 3),
      HashiBridge(from: 2, to: 4),
      HashiBridge(from: 3, to: 5),
      HashiBridge(from: 4, to: 5),
    ],
  ),
  HashiPuzzle(
    id: 'hashi_07',
    title: 'Brückenleiter',
    difficulty: 2,
    size: 7,
    islands: [
      HashiIsland(row: 0, column: 1, bridges: 2),
      HashiIsland(row: 0, column: 5, bridges: 2),
      HashiIsland(row: 3, column: 1, bridges: 4),
      HashiIsland(row: 3, column: 5, bridges: 4),
      HashiIsland(row: 6, column: 1, bridges: 2),
      HashiIsland(row: 6, column: 5, bridges: 2),
    ],
    solution: [
      HashiBridge(from: 0, to: 1),
      HashiBridge(from: 0, to: 2),
      HashiBridge(from: 1, to: 3),
      HashiBridge(from: 2, to: 3, count: 2),
      HashiBridge(from: 2, to: 4),
      HashiBridge(from: 3, to: 5),
      HashiBridge(from: 4, to: 5),
    ],
  ),
  HashiPuzzle(
    id: 'hashi_08',
    title: 'Doppelkreuz',
    difficulty: 2,
    size: 7,
    islands: [
      HashiIsland(row: 0, column: 3, bridges: 2),
      HashiIsland(row: 3, column: 0, bridges: 1),
      HashiIsland(row: 3, column: 3, bridges: 6),
      HashiIsland(row: 3, column: 6, bridges: 1),
      HashiIsland(row: 6, column: 3, bridges: 2),
    ],
    solution: [
      HashiBridge(from: 0, to: 2, count: 2),
      HashiBridge(from: 1, to: 2),
      HashiBridge(from: 2, to: 3),
      HashiBridge(from: 2, to: 4, count: 2),
    ],
  ),
  HashiPuzzle(
    id: 'hashi_09',
    title: 'Der Rahmen',
    difficulty: 3,
    size: 9,
    islands: [
      HashiIsland(row: 0, column: 1, bridges: 4),
      HashiIsland(row: 0, column: 4, bridges: 3),
      HashiIsland(row: 0, column: 7, bridges: 2),
      HashiIsland(row: 4, column: 1, bridges: 3),
      HashiIsland(row: 4, column: 7, bridges: 3),
      HashiIsland(row: 8, column: 1, bridges: 3),
      HashiIsland(row: 8, column: 4, bridges: 3),
      HashiIsland(row: 8, column: 7, bridges: 3),
    ],
    solution: [
      HashiBridge(from: 0, to: 1, count: 2),
      HashiBridge(from: 1, to: 2),
      HashiBridge(from: 2, to: 4),
      HashiBridge(from: 4, to: 7, count: 2),
      HashiBridge(from: 7, to: 6),
      HashiBridge(from: 6, to: 5, count: 2),
      HashiBridge(from: 5, to: 3),
      HashiBridge(from: 3, to: 0, count: 2),
    ],
  ),
  HashiPuzzle(
    id: 'hashi_10',
    title: 'Neun Inseln',
    difficulty: 3,
    size: 9,
    islands: [
      HashiIsland(row: 0, column: 0, bridges: 2),
      HashiIsland(row: 0, column: 4, bridges: 3),
      HashiIsland(row: 0, column: 8, bridges: 2),
      HashiIsland(row: 4, column: 0, bridges: 3),
      HashiIsland(row: 4, column: 4, bridges: 4),
      HashiIsland(row: 4, column: 8, bridges: 3),
      HashiIsland(row: 8, column: 0, bridges: 2),
      HashiIsland(row: 8, column: 4, bridges: 3),
      HashiIsland(row: 8, column: 8, bridges: 2),
    ],
    solution: [
      HashiBridge(from: 0, to: 1),
      HashiBridge(from: 1, to: 2),
      HashiBridge(from: 3, to: 4),
      HashiBridge(from: 4, to: 5),
      HashiBridge(from: 6, to: 7),
      HashiBridge(from: 7, to: 8),
      HashiBridge(from: 0, to: 3),
      HashiBridge(from: 3, to: 6),
      HashiBridge(from: 1, to: 4),
      HashiBridge(from: 4, to: 7),
      HashiBridge(from: 2, to: 5),
      HashiBridge(from: 5, to: 8),
    ],
  ),
  HashiPuzzle(
    id: 'hashi_11',
    title: 'Schmale Pfade',
    difficulty: 2,
    size: 9,
    islands: [
      HashiIsland(row: 0, column: 0, bridges: 1),
      HashiIsland(row: 0, column: 4, bridges: 3),
      HashiIsland(row: 2, column: 4, bridges: 3),
      HashiIsland(row: 2, column: 1, bridges: 2),
      HashiIsland(row: 5, column: 1, bridges: 3),
      HashiIsland(row: 5, column: 6, bridges: 3),
      HashiIsland(row: 8, column: 6, bridges: 1),
    ],
    solution: [
      HashiBridge(from: 0, to: 1),
      HashiBridge(from: 1, to: 2, count: 2),
      HashiBridge(from: 2, to: 3),
      HashiBridge(from: 3, to: 4),
      HashiBridge(from: 4, to: 5, count: 2),
      HashiBridge(from: 5, to: 6),
    ],
  ),
  HashiPuzzle(
    id: 'hashi_12',
    title: 'Vier Tore',
    difficulty: 3,
    size: 9,
    islands: [
      HashiIsland(row: 0, column: 0, bridges: 3),
      HashiIsland(row: 0, column: 4, bridges: 5),
      HashiIsland(row: 0, column: 8, bridges: 3),
      HashiIsland(row: 4, column: 0, bridges: 3),
      HashiIsland(row: 4, column: 4, bridges: 4),
      HashiIsland(row: 4, column: 8, bridges: 3),
      HashiIsland(row: 8, column: 0, bridges: 3),
      HashiIsland(row: 8, column: 4, bridges: 5),
      HashiIsland(row: 8, column: 8, bridges: 3),
    ],
    solution: [
      HashiBridge(from: 0, to: 1, count: 2),
      HashiBridge(from: 1, to: 2, count: 2),
      HashiBridge(from: 3, to: 4),
      HashiBridge(from: 4, to: 5),
      HashiBridge(from: 6, to: 7, count: 2),
      HashiBridge(from: 7, to: 8, count: 2),
      HashiBridge(from: 0, to: 3),
      HashiBridge(from: 3, to: 6),
      HashiBridge(from: 1, to: 4),
      HashiBridge(from: 4, to: 7),
      HashiBridge(from: 2, to: 5),
      HashiBridge(from: 5, to: 8),
    ],
  ),
];

const _replacedHashiPuzzleIds = {
  'hashi_04',
  'hashi_07',
  'hashi_10',
  'hashi_12'
};

final hashiPuzzleCatalog = <HashiPuzzle>[
  ..._originalHashiPuzzleCatalog.where(
    (puzzle) => !_replacedHashiPuzzleIds.contains(puzzle.id),
  ),
  ...generatedHashiPuzzleCatalog,
]..sort((first, second) => first.id.compareTo(second.id));

class HashiProgressStore {
  static const _key = 'hashi_completed_puzzles';

  Future<Set<String>> loadCompleted() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(_key)?.toSet() ?? <String>{};
  }

  Future<void> markCompleted(String puzzleId) async {
    final preferences = await SharedPreferences.getInstance();
    final completed = preferences.getStringList(_key)?.toSet() ?? <String>{};
    completed.add(puzzleId);
    await preferences.setStringList(_key, completed.toList()..sort());
  }
}

class SavedHashiGame {
  const SavedHashiGame({
    required this.puzzle,
    required this.mode,
    required this.bridges,
    required this.elapsedSeconds,
    required this.moves,
    required this.hintsUsed,
    required this.rewardedHints,
  });

  static const schemaVersion = 1;
  final HashiPuzzle puzzle;
  final GameMode mode;
  final List<HashiBridge> bridges;
  final int elapsedSeconds;
  final int moves;
  final int hintsUsed;
  final int rewardedHints;

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'mode': mode.name,
        'elapsedSeconds': elapsedSeconds,
        'moves': moves,
        'hintsUsed': hintsUsed,
        'rewardedHints': rewardedHints,
        'puzzle': {
          'id': puzzle.id,
          'title': puzzle.title,
          'size': puzzle.size,
          'difficulty': puzzle.difficulty,
          'islands': [
            for (final island in puzzle.islands)
              {
                'row': island.row,
                'column': island.column,
                'bridges': island.bridges,
              },
          ],
          'solution': [
            for (final bridge in puzzle.solution) _bridgeJson(bridge)
          ],
        },
        'bridges': [for (final bridge in bridges) _bridgeJson(bridge)],
      };

  factory SavedHashiGame.fromJson(Map<String, Object?> json) {
    if (json['schemaVersion'] != schemaVersion) {
      throw const FormatException('Unsupported Hashi save version.');
    }
    final puzzleJson = Map<String, Object?>.from(json['puzzle']! as Map);
    final puzzle = HashiPuzzle(
      id: puzzleJson['id']! as String,
      title: puzzleJson['title']! as String,
      size: puzzleJson['size']! as int,
      difficulty: puzzleJson['difficulty']! as int,
      islands: (puzzleJson['islands']! as List).map((item) {
        final value = Map<String, Object?>.from(item as Map);
        return HashiIsland(
          row: value['row']! as int,
          column: value['column']! as int,
          bridges: value['bridges']! as int,
        );
      }).toList(growable: false),
      solution: (puzzleJson['solution']! as List)
          .map((item) => _bridgeFromJson(item as Map))
          .toList(growable: false),
    );
    return SavedHashiGame(
      puzzle: puzzle,
      mode: GameMode.values.byName(json['mode']! as String),
      bridges: (json['bridges']! as List)
          .map((item) => _bridgeFromJson(item as Map))
          .toList(growable: false),
      elapsedSeconds: json['elapsedSeconds']! as int,
      moves: json['moves']! as int,
      hintsUsed: json['hintsUsed']! as int,
      rewardedHints: json['rewardedHints']! as int,
    );
  }

  static Map<String, Object?> _bridgeJson(HashiBridge bridge) => {
        'from': bridge.from,
        'to': bridge.to,
        'count': bridge.count,
      };

  static HashiBridge _bridgeFromJson(Map<dynamic, dynamic> raw) {
    final value = Map<String, Object?>.from(raw);
    return HashiBridge(
      from: value['from']! as int,
      to: value['to']! as int,
      count: value['count']! as int,
    );
  }
}

class HashiGameStore {
  static const _key = 'active_hashi_game_v1';

  Future<SavedHashiGame?> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null) return null;
    try {
      final saved = SavedHashiGame.fromJson(
        Map<String, Object?>.from(jsonDecode(raw) as Map),
      );
      if (HashiGameState(
        puzzle: saved.puzzle,
        bridges: saved.bridges,
      ).isSolved) {
        await preferences.remove(_key);
        return null;
      }
      return saved;
    } on Object {
      await preferences.remove(_key);
      return null;
    }
  }

  Future<void> save(SavedHashiGame game) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, jsonEncode(game.toJson()));
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key);
  }
}

class HashiGameState {
  HashiGameState({required this.puzzle, List<HashiBridge>? bridges})
      : bridges = List<HashiBridge>.unmodifiable(bridges ?? const []);

  final HashiPuzzle puzzle;
  final List<HashiBridge> bridges;

  int bridgeCountAt(int islandIndex) {
    return bridges
        .where(
            (bridge) => bridge.from == islandIndex || bridge.to == islandIndex)
        .fold(0, (total, bridge) => total + bridge.count);
  }

  int bridgeCountBetween(int first, int second) {
    for (final bridge in bridges) {
      if (_sameConnection(bridge, first, second)) return bridge.count;
    }
    return 0;
  }

  bool canConnect(int first, int second) {
    if (first == second ||
        first < 0 ||
        second < 0 ||
        first >= puzzle.islands.length ||
        second >= puzzle.islands.length) {
      return false;
    }

    final a = puzzle.islands[first];
    final b = puzzle.islands[second];
    final aligned = a.row == b.row || a.column == b.column;
    if (!aligned || _islandBetween(first, second)) return false;

    return !bridges.any(
      (bridge) =>
          !_sameConnection(bridge, first, second) &&
          _connectionsCross(first, second, bridge.from, bridge.to),
    );
  }

  HashiGameState cycleConnection(int first, int second) {
    if (!canConnect(first, second)) return this;

    final current = bridgeCountBetween(first, second);
    final next = (current + 1) % 3;
    final updated = bridges
        .where((bridge) => !_sameConnection(bridge, first, second))
        .toList();
    if (next > 0) {
      updated.add(HashiBridge(from: first, to: second, count: next));
    }
    return HashiGameState(puzzle: puzzle, bridges: updated);
  }

  HashiGameState removeConnection(int first, int second) {
    if (bridgeCountBetween(first, second) == 0) return this;
    return HashiGameState(
      puzzle: puzzle,
      bridges: bridges
          .where((bridge) => !_sameConnection(bridge, first, second))
          .toList(),
    );
  }

  bool isSolutionConnection(HashiBridge bridge) {
    for (final solutionBridge in puzzle.solution) {
      if (_sameConnection(solutionBridge, bridge.from, bridge.to) &&
          solutionBridge.count == bridge.count) {
        return true;
      }
    }
    return false;
  }

  List<HashiBridge> get incorrectBridges =>
      bridges.where((bridge) => !isSolutionConnection(bridge)).toList();

  Set<int> get incorrectIslandIndices {
    final incorrect = <int>{};
    for (final bridge in incorrectBridges) {
      incorrect
        ..add(bridge.from)
        ..add(bridge.to);
    }
    for (var index = 0; index < puzzle.islands.length; index++) {
      if (bridgeCountAt(index) > puzzle.islands[index].bridges) {
        incorrect.add(index);
      }
    }
    return incorrect;
  }

  HashiBridge? get nextHintBridge {
    for (final solutionBridge in puzzle.solution) {
      if (bridgeCountBetween(solutionBridge.from, solutionBridge.to) !=
          solutionBridge.count) {
        return solutionBridge;
      }
    }
    return null;
  }

  HashiGameState applyHint() {
    final hint = nextHintBridge;
    if (hint == null) return this;
    final updated = bridges
        .where((bridge) => !_sameConnection(bridge, hint.from, hint.to))
        .toList()
      ..add(hint);
    return HashiGameState(puzzle: puzzle, bridges: updated);
  }

  bool get numbersAreSatisfied {
    for (var index = 0; index < puzzle.islands.length; index++) {
      if (bridgeCountAt(index) != puzzle.islands[index].bridges) return false;
    }
    return true;
  }

  bool get allIslandsConnected {
    if (puzzle.islands.isEmpty) return true;
    final visited = <int>{0};
    final pending = <int>[0];
    while (pending.isNotEmpty) {
      final current = pending.removeLast();
      for (final bridge in bridges) {
        final neighbor = bridge.from == current
            ? bridge.to
            : bridge.to == current
                ? bridge.from
                : null;
        if (neighbor != null && visited.add(neighbor)) pending.add(neighbor);
      }
    }
    return visited.length == puzzle.islands.length;
  }

  bool get isSolved => numbersAreSatisfied && allIslandsConnected;

  bool _islandBetween(int first, int second) {
    final a = puzzle.islands[first];
    final b = puzzle.islands[second];
    for (var index = 0; index < puzzle.islands.length; index++) {
      if (index == first || index == second) continue;
      final candidate = puzzle.islands[index];
      if (a.row == b.row &&
          candidate.row == a.row &&
          _strictlyBetween(candidate.column, a.column, b.column)) {
        return true;
      }
      if (a.column == b.column &&
          candidate.column == a.column &&
          _strictlyBetween(candidate.row, a.row, b.row)) {
        return true;
      }
    }
    return false;
  }

  bool _connectionsCross(int aIndex, int bIndex, int cIndex, int dIndex) {
    final a = puzzle.islands[aIndex];
    final b = puzzle.islands[bIndex];
    final c = puzzle.islands[cIndex];
    final d = puzzle.islands[dIndex];
    final firstHorizontal = a.row == b.row;
    final secondHorizontal = c.row == d.row;
    if (firstHorizontal == secondHorizontal) return false;

    final horizontalA = firstHorizontal ? a : c;
    final horizontalB = firstHorizontal ? b : d;
    final verticalA = firstHorizontal ? c : a;
    final verticalB = firstHorizontal ? d : b;

    return _strictlyBetween(
          verticalA.column,
          horizontalA.column,
          horizontalB.column,
        ) &&
        _strictlyBetween(
          horizontalA.row,
          verticalA.row,
          verticalB.row,
        );
  }

  static bool _sameConnection(HashiBridge bridge, int first, int second) {
    return (bridge.from == first && bridge.to == second) ||
        (bridge.from == second && bridge.to == first);
  }

  static bool _strictlyBetween(int value, int edgeA, int edgeB) {
    return value > math.min(edgeA, edgeB) && value < math.max(edgeA, edgeB);
  }
}

class HashiHubScreen extends StatefulWidget {
  const HashiHubScreen({this.onOpenDaily, this.onOpenStatistics, super.key});

  final AsyncCallback? onOpenDaily;
  final AsyncCallback? onOpenStatistics;

  @override
  State<HashiHubScreen> createState() => _HashiHubScreenState();
}

class _HashiHubScreenState extends State<HashiHubScreen> {
  final HashiProgressStore _progressStore = HashiProgressStore();
  Set<String> _completed = <String>{};

  @override
  void initState() {
    super.initState();
    _refreshProgress();
  }

  Future<void> _refreshProgress() async {
    final completed = await _progressStore.loadCompleted();
    if (!mounted) return;
    setState(() => _completed = completed);
  }

  Future<void> _openPuzzle(HashiPuzzle puzzle) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HashiGameScreen(puzzle: puzzle),
      ),
    );
    await _refreshProgress();
  }

  HashiPuzzle get _nextPuzzle => hashiPuzzleCatalog.firstWhere(
        (puzzle) => !_completed.contains(puzzle.id),
        orElse: () => hashiTutorialPuzzle,
      );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Hashi')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colors.secondaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.hub_rounded,
                        size: 54,
                        color: colors.onSecondaryContainer,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Baue ein gemeinsames Brückennetz',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_completed.length} von ${hashiPuzzleCatalog.length} Rätseln gelöst',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          minHeight: 8,
                          value: _completed.length / hashiPuzzleCatalog.length,
                          backgroundColor:
                              colors.surface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Eine kleine Inselwelt',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Verbinde sichtbare Inseln – ohne Kreuzungen.',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 16),
                        const AspectRatio(
                          aspectRatio: 1,
                          child: HashiBoard(
                            puzzle: hashiTutorialPuzzle,
                            bridges: hashiPreviewBridges,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => _openPuzzle(_nextPuzzle),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    _completed.isEmpty
                        ? 'Erste Herausforderung'
                        : _completed.length == hashiPuzzleCatalog.length
                            ? 'Noch einmal spielen'
                            : 'Nächstes ungelöstes Rätsel',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const HashiCatalogScreen(),
                      ),
                    );
                    await _refreshProgress();
                  },
                  icon: const Icon(Icons.apps_rounded),
                  label: const Text('Rätselsammlung'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const HashiRandomSetupScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Zufallsrätsel'),
                ),
                if (widget.onOpenDaily != null) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: widget.onOpenDaily,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: const Text('Tagesrätsel & Kalender'),
                  ),
                ],
                if (widget.onOpenStatistics != null) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: widget.onOpenStatistics,
                    icon: const Icon(Icons.insights_outlined),
                    label: const Text('Hashi-Statistik'),
                  ),
                ],
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const HashiRulesScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.menu_book_rounded),
                  label: const Text('Regeln ansehen'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HashiCatalogScreen extends StatefulWidget {
  const HashiCatalogScreen({super.key});

  @override
  State<HashiCatalogScreen> createState() => _HashiCatalogScreenState();
}

class HashiPuzzleChapter {
  const HashiPuzzleChapter({
    required this.id,
    required this.title,
    required this.description,
    required this.puzzles,
  });

  final String id;
  final String title;
  final String description;
  final List<HashiPuzzle> puzzles;
}

class HashiRandomSetupScreen extends StatefulWidget {
  const HashiRandomSetupScreen({super.key});

  @override
  State<HashiRandomSetupScreen> createState() => _HashiRandomSetupScreenState();
}

class _HashiRandomSetupScreenState extends State<HashiRandomSetupScreen> {
  int _difficulty = 1;
  bool _generating = false;
  String? _error;

  Future<void> _generate() async {
    if (_generating) return;
    setState(() {
      _generating = true;
      _error = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 50));
    try {
      final seed = DateTime.now().microsecondsSinceEpoch & 0x7fffffff;
      final generated = const HashiGenerator().generate(
        seed: seed,
        number: 1,
        difficulty: _difficulty,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => HashiGameScreen(
            puzzle: generated.puzzle,
            mode: GameMode.generated,
          ),
        ),
      );
    } on Object {
      if (!mounted) return;
      setState(() {
        _generating = false;
        _error = 'Das Rätsel konnte gerade nicht erstellt werden.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hashi-Zufallsrätsel')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 54,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Ein neues Brückennetz',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Jedes Board wird neu erzeugt und auf eine eindeutige Lösung geprüft.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 1, label: Text('Leicht')),
                    ButtonSegment(value: 2, label: Text('Mittel')),
                    ButtonSegment(value: 3, label: Text('Schwer')),
                  ],
                  selected: {_difficulty},
                  onSelectionChanged: _generating
                      ? null
                      : (selection) =>
                          setState(() => _difficulty = selection.first),
                ),
                const SizedBox(height: 18),
                if (_error != null) ...[
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                FilledButton.icon(
                  onPressed: _generating ? null : _generate,
                  icon: _generating
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.casino_outlined),
                  label: Text(
                    _generating ? 'Rätsel wird geprüft …' : 'Rätsel erstellen',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

List<HashiPuzzleChapter> hashiChaptersFor({int difficulty = 0}) {
  const chapterSize = 10;
  final difficulties = difficulty == 0 ? const [1, 2, 3] : [difficulty];
  final chapters = <HashiPuzzleChapter>[];
  for (final level in difficulties) {
    final puzzles = hashiPuzzleCatalog
        .where((puzzle) => puzzle.difficulty == level)
        .toList(growable: false);
    for (var start = 0; start < puzzles.length; start += chapterSize) {
      final part = start ~/ chapterSize + 1;
      final baseTitle = switch (level) {
        1 => 'Brücken bauen',
        2 => 'Netze planen',
        _ => 'Inselmeister',
      };
      chapters.add(HashiPuzzleChapter(
        id: 'hashi-$level-$part',
        title: part == 1 ? baseTitle : '$baseTitle · Kapitel $part',
        description: switch (level) {
          1 => 'Klare Verbindungen und kleine Inselgruppen',
          2 => 'Mehrere Wege und größere zusammenhängende Netze',
          _ => 'Komplexe Abhängigkeiten und anspruchsvolle Brückennetze',
        },
        puzzles: List.unmodifiable(puzzles.skip(start).take(chapterSize)),
      ));
    }
  }
  return List.unmodifiable(chapters);
}

class _HashiCatalogScreenState extends State<HashiCatalogScreen> {
  final HashiProgressStore _progressStore = HashiProgressStore();
  Set<String> _completed = <String>{};
  int _difficultyFilter = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final completed = await _progressStore.loadCompleted();
    if (!mounted) return;
    setState(() => _completed = completed);
  }

  Future<void> _open(HashiPuzzle puzzle) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HashiGameScreen(puzzle: puzzle),
      ),
    );
    await _refresh();
  }

  String _difficultyName(int difficulty) => switch (difficulty) {
        1 => 'Leicht',
        2 => 'Mittel',
        3 => 'Schwer',
        _ => 'Alle',
      };

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final chapters = hashiChaptersFor(difficulty: _difficultyFilter);
    return Scaffold(
      appBar: AppBar(title: const Text('Hashi-Rätsel')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: chapters.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '${_completed.length} von ${hashiPuzzleCatalog.length} geschafft',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              minHeight: 8,
                              value:
                                  _completed.length / hashiPuzzleCatalog.length,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(4, (difficulty) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              selected: _difficultyFilter == difficulty,
                              onSelected: (_) => setState(
                                () => _difficultyFilter = difficulty,
                              ),
                              label: Text(_difficultyName(difficulty)),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                );
              }

              final chapter = chapters[index - 1];
              final completed = chapter.puzzles
                  .where((puzzle) => _completed.contains(puzzle.id))
                  .length;
              return Card(
                clipBehavior: Clip.antiAlias,
                child: ExpansionTile(
                  initiallyExpanded: index == 1,
                  leading: CircleAvatar(
                    child: Text('$index'),
                  ),
                  title: Text(
                    chapter.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${chapter.description}\n$completed von ${chapter.puzzles.length} gelöst',
                  ),
                  children: [
                    const Divider(height: 1),
                    for (final puzzle in chapter.puzzles)
                      _HashiCatalogPuzzleTile(
                        puzzle: puzzle,
                        completed: _completed.contains(puzzle.id),
                        onTap: () => _open(puzzle),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HashiCatalogPuzzleTile extends StatelessWidget {
  const _HashiCatalogPuzzleTile({
    required this.puzzle,
    required this.completed,
    required this.onTap,
  });

  final HashiPuzzle puzzle;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final catalogIndex = hashiPuzzleCatalog.indexOf(puzzle);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: CircleAvatar(
        backgroundColor: completed
            ? colors.primaryContainer
            : colors.surfaceContainerHighest,
        child: completed
            ? Icon(Icons.check_rounded, color: colors.primary)
            : Text('${catalogIndex + 1}'),
      ),
      title: Text(
        puzzle.title,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${puzzle.size} × ${puzzle.size} · ${puzzle.islands.length} Inseln',
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

class HashiTutorialScreen extends StatelessWidget {
  const HashiTutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const HashiGameScreen(puzzle: hashiTutorialPuzzle);
  }
}

enum _ExistingHashiChoice { resume, startNew }

enum _HashiDeveloperAction {
  almostSolved,
  solve,
  error,
  reset,
}

class HashiGameScreen extends StatefulWidget {
  const HashiGameScreen({
    required this.puzzle,
    this.mode = GameMode.catalog,
    this.savedGame,
    super.key,
  });

  final HashiPuzzle puzzle;
  final GameMode mode;
  final SavedHashiGame? savedGame;

  @override
  State<HashiGameScreen> createState() => _HashiGameScreenState();
}

class _HashiGameScreenState extends State<HashiGameScreen> {
  final HashiProgressStore _progressStore = HashiProgressStore();
  final GameStorage _gameStorage = GameStorage();
  final HashiGameStore _saveStore = HashiGameStore();
  late HashiGameState _game;
  final List<HashiGameState> _history = [];
  final List<HashiGameState> _redoHistory = [];
  Timer? _timer;
  Timer? _messageTimer;
  int? _selectedIsland;
  String? _actionMessage;
  int _elapsedSeconds = 0;
  int _moves = 0;
  bool _restartUndoPending = false;
  bool _restartRedoPending = false;
  int _movesBeforeRestart = 0;
  int _elapsedBeforeRestart = 0;
  bool _completionShown = false;
  bool _showMistakes = false;
  HintBudget _hintBudget = const HintBudget();
  int _hintsUsed = 0;
  bool _checkingExistingGame = false;
  bool _developerCompletion = false;

  @override
  void initState() {
    super.initState();
    final saved = widget.savedGame;
    _game = HashiGameState(
      puzzle: widget.puzzle,
      bridges: saved?.bridges,
    );
    if (saved != null) {
      _elapsedSeconds = saved.elapsedSeconds;
      _moves = saved.moves;
      _hintsUsed = saved.hintsUsed;
      _hintBudget = HintBudget(
        usedHints: saved.hintsUsed,
        rewardedHints: saved.rewardedHints,
      );
    } else {
      _checkingExistingGame = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_protectExistingGame());
      });
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !_completionShown && !_checkingExistingGame) {
        setState(() => _elapsedSeconds++);
        if (_elapsedSeconds % 10 == 0) unawaited(_saveGame());
      }
    });
  }

  @override
  void dispose() {
    if (!_completionShown && !_checkingExistingGame) unawaited(_saveGame());
    _timer?.cancel();
    _messageTimer?.cancel();
    super.dispose();
  }

  Future<void> _saveGame() => _saveStore.save(SavedHashiGame(
        puzzle: widget.puzzle,
        mode: widget.mode,
        bridges: _game.bridges,
        elapsedSeconds: _elapsedSeconds,
        moves: _moves,
        hintsUsed: _hintsUsed,
        rewardedHints: _hintBudget.rewardedHints,
      ));

  Future<void> _protectExistingGame() async {
    final existing = await _saveStore.load();
    if (!mounted) return;
    if (existing == null) {
      _checkingExistingGame = false;
      await _saveGame();
      return;
    }
    final choice = await showDialog<_ExistingHashiChoice>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.save_outlined),
        title: const Text('Offene Hashi-Partie'),
        content: const Text(
          'Du hast bereits ein begonnenes Hashi-Rätsel. Möchtest du es fortsetzen oder mit dem neuen Rätsel beginnen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(
              _ExistingHashiChoice.startNew,
            ),
            child: const Text('Neu beginnen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(
              _ExistingHashiChoice.resume,
            ),
            child: const Text('Fortsetzen'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (choice == null) {
      Navigator.of(context).pop();
      return;
    }
    if (choice == _ExistingHashiChoice.resume) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => HashiGameScreen(
            puzzle: existing.puzzle,
            mode: existing.mode,
            savedGame: existing,
          ),
        ),
      );
      return;
    }
    _checkingExistingGame = false;
    await _saveStore.clear();
    await _saveGame();
  }

  List<int> get _possibleTargets {
    final selected = _selectedIsland;
    if (selected == null) return const [];
    return List<int>.generate(_game.puzzle.islands.length, (index) => index)
        .where((index) => _game.canConnect(selected, index))
        .toList();
  }

  String get _timeLabel {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _handleIslandTap(int index) async {
    if (_completionShown) return;
    if (_selectedIsland == null) {
      setState(() => _selectedIsland = index);
      return;
    }
    if (_selectedIsland == index) {
      setState(() => _selectedIsland = null);
      return;
    }

    final first = _selectedIsland!;
    final previous = _game;
    final previousCount = previous.bridgeCountBetween(first, index);
    final next = previous.cycleConnection(first, index);
    setState(() {
      if (!identical(previous, next)) {
        _history.add(previous);
        _redoHistory.clear();
        _restartRedoPending = false;
        _game = next;
        _moves++;
      }
      _selectedIsland = null;
    });
    if (!identical(previous, next)) {
      final nextCount = next.bridgeCountBetween(first, index);
      _showActionMessage(
        nextCount == 0
            ? 'Brücke entfernt'
            : nextCount == 2 && previousCount == 1
                ? 'Doppelte Brücke'
                : 'Brücke gesetzt',
      );
    }

    if (!identical(previous, next)) unawaited(_saveGame());
    await _showCompletionIfSolved();
  }

  Future<void> _showCompletionIfSolved() async {
    if (!_game.isSolved || _completionShown) return;
    _completionShown = true;
    int? previousBestSeconds;
    String? collectionProgress;
    if (!_developerCompletion && widget.mode == GameMode.catalog) {
      previousBestSeconds = (await _gameStorage
              .loadResults())['${GameType.hashi.name}:${widget.puzzle.id}']
          ?.bestSeconds;
    } else if (!_developerCompletion) {
      previousBestSeconds = GameStatistics.fromAttempts(
        await _gameStorage.loadAttempts(),
        gameType: GameType.hashi,
      )
          .filtered(
            mode: widget.mode,
            difficulty: widget.puzzle.sharedDifficulty,
            boardSize: widget.puzzle.size,
          )
          .bestSeconds;
    }
    if (!_developerCompletion && widget.mode == GameMode.catalog) {
      await _progressStore.markCompleted(widget.puzzle.id);
      final completed = await _progressStore.loadCompleted();
      final chapter = hashiChaptersFor().firstWhere(
        (chapter) =>
            chapter.puzzles.any((puzzle) => puzzle.id == widget.puzzle.id),
      );
      final chapterSolved = chapter.puzzles
          .where((puzzle) => completed.contains(puzzle.id))
          .length;
      collectionProgress =
          '${chapter.title}: $chapterSolved/${chapter.puzzles.length} · '
          'Sammlung: ${completed.length}/${hashiPuzzleCatalog.length}';
    }
    final countsForTesting =
        _developerCompletion && widget.mode == GameMode.daily;
    if (!_developerCompletion || countsForTesting) {
      await _gameStorage.recordCompletion(
        puzzleId: widget.puzzle.id,
        elapsedSeconds: _elapsedSeconds,
        gameType: GameType.hashi,
        source: widget.mode,
        difficulty: widget.puzzle.sharedDifficulty,
        boardSize: widget.puzzle.size,
        moves: _moves,
        hintsUsed: _hintsUsed,
        rewardedHints: _hintBudget.rewardedHints,
      );
      await _saveStore.clear();
    }
    if (!mounted) return;
    final isNewRecord =
        previousBestSeconds == null || _elapsedSeconds < previousBestSeconds;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.celebration_rounded),
        title: const Text('Brückennetz vollendet!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Alle Zahlen stimmen und jede Insel gehört zum selben Netz.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            if (isNewRecord && !_developerCompletion) ...[
              const Chip(
                avatar: Icon(Icons.workspace_premium_outlined),
                label: Text('Neue Bestzeit'),
              ),
              const SizedBox(height: 10),
            ],
            if (_developerCompletion) ...[
              Chip(
                avatar: const Icon(Icons.science_outlined),
                label: Text(
                  widget.mode == GameMode.daily
                      ? 'Testabschluss · im Kalender gewertet'
                      : 'Testabschluss · keine Statistik',
                ),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ResultValue(icon: Icons.timer_outlined, value: _timeLabel),
                _ResultValue(
                  icon: Icons.touch_app_outlined,
                  value: '$_moves Züge',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '$_hintsUsed Hinweise · Bisherige Bestzeit: '
              '${previousBestSeconds == null ? '–' : _formatHashiTime(previousBestSeconds)}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (collectionProgress != null) ...[
              const SizedBox(height: 12),
              Text(
                collectionProgress,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Brett ansehen'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
            child: Text(widget.mode == GameMode.generated
                ? 'Hashi verlassen'
                : 'Zur Sammlung'),
          ),
          if (widget.mode == GameMode.generated)
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _startNextRandomPuzzle();
              },
              child: const Text('Noch eins'),
            )
          else if (_nextPuzzle != null)
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => HashiGameScreen(puzzle: _nextPuzzle!),
                  ),
                );
              },
              child: const Text('Nächstes Rätsel'),
            )
          else
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Geschafft'),
            ),
        ],
      ),
    );
  }

  String _formatHashiTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final rest = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$rest';
  }

  Future<void> _runDeveloperAction(_HashiDeveloperAction action) async {
    switch (action) {
      case _HashiDeveloperAction.almostSolved:
        final solution = widget.puzzle.solution;
        setState(() {
          final almostSolved = solution.isEmpty
              ? const <HashiBridge>[]
              : <HashiBridge>[
                  ...solution.take(solution.length - 1),
                  if (solution.last.count == 2)
                    solution.last.copyWith(count: 1),
                ];
          _game = HashiGameState(
            puzzle: widget.puzzle,
            bridges: almostSolved,
          );
          _history.clear();
          _redoHistory.clear();
          _selectedIsland = null;
          _completionShown = false;
          _moves = 0;
          _developerCompletion = true;
        });
        _showActionMessage('Bis auf eine Brücke gelöst');
        return;
      case _HashiDeveloperAction.solve:
        setState(() {
          _game = HashiGameState(
            puzzle: widget.puzzle,
            bridges: widget.puzzle.solution,
          );
          _history.clear();
          _redoHistory.clear();
          _selectedIsland = null;
          _completionShown = false;
          _moves = 0;
          _developerCompletion = true;
        });
        await _showCompletionIfSolved();
        return;
      case _HashiDeveloperAction.error:
        final solution = widget.puzzle.solution;
        final invalid = solution.isEmpty
            ? const <HashiBridge>[]
            : <HashiBridge>[
                solution.first.copyWith(
                  count: solution.first.count == 1 ? 2 : 1,
                ),
                ...solution.skip(1),
              ];
        setState(() {
          _game = HashiGameState(puzzle: widget.puzzle, bridges: invalid);
          _history.clear();
          _redoHistory.clear();
          _selectedIsland = null;
          _completionShown = false;
          _moves = 0;
          _developerCompletion = true;
        });
        _showActionMessage('Fehlerzustand erzeugt');
        return;
      case _HashiDeveloperAction.reset:
        await _restart(confirm: false);
        _showActionMessage('Testzustand gelöscht');
        return;
    }
  }

  void _showActionMessage(String message) {
    _messageTimer?.cancel();
    if (mounted) setState(() => _actionMessage = message);
    _messageTimer = Timer(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() => _actionMessage = null);
    });
  }

  void _handleBridgeTap(HashiBridge bridge) {
    if (_completionShown) return;
    final previous = _game;
    final next = previous.removeConnection(bridge.from, bridge.to);
    if (identical(previous, next)) return;
    setState(() {
      _history.add(previous);
      _redoHistory.clear();
      _restartRedoPending = false;
      _game = next;
      _moves++;
      _selectedIsland = null;
    });
    _showActionMessage('Brücke entfernt');
  }

  HashiPuzzle? get _nextPuzzle {
    if (widget.mode != GameMode.catalog) return null;
    final group = hashiPuzzleCatalog
        .where((puzzle) =>
            puzzle.sharedDifficulty == widget.puzzle.sharedDifficulty)
        .toList(growable: false);
    final index = group.indexWhere((puzzle) => puzzle.id == widget.puzzle.id);
    if (index < 0 || index + 1 >= group.length) return null;
    return group[index + 1];
  }

  Future<void> _startNextRandomPuzzle() async {
    await _saveStore.clear();
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(width: 18),
            Expanded(child: Text('Neues Brückennetz wird geprüft …')),
          ],
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    try {
      final seed = DateTime.now().microsecondsSinceEpoch & 0x7fffffff;
      final generated = const HashiGenerator().generate(
        seed: seed,
        number: 1,
        difficulty: widget.puzzle.difficulty,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => HashiGameScreen(
            puzzle: generated.puzzle,
            mode: GameMode.generated,
          ),
        ),
      );
    } on Object {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Das nächste Rätsel konnte nicht erstellt werden.'),
        ),
      );
    }
  }

  void _undo() {
    if (_completionShown || _history.isEmpty) return;
    final restoresRestart = _restartUndoPending && _history.length == 1;
    setState(() {
      _redoHistory.add(_game);
      _game = _history.removeLast();
      _selectedIsland = null;
      _actionMessage = null;
      _completionShown = false;
      _developerCompletion = false;
      if (restoresRestart) {
        _moves = _movesBeforeRestart;
        _elapsedSeconds = _elapsedBeforeRestart;
        _restartUndoPending = false;
        _restartRedoPending = true;
      } else if (_moves > 0) {
        _moves--;
      }
    });
    unawaited(_saveGame());
  }

  void _redo() {
    if (_completionShown || _redoHistory.isEmpty) return;
    final reappliesRestart = _restartRedoPending && _redoHistory.length == 1;
    setState(() {
      _history.add(_game);
      _game = _redoHistory.removeLast();
      _selectedIsland = null;
      _actionMessage = null;
      _completionShown = false;
      if (reappliesRestart) {
        _moves = 0;
        _elapsedSeconds = 0;
        _restartUndoPending = true;
        _restartRedoPending = false;
      } else {
        _moves++;
      }
    });
    unawaited(_saveGame());
    _showCompletionIfSolved();
  }

  Future<void> _useHint() async {
    if (_completionShown) return;
    final next = _game.applyHint();
    if (identical(next, _game)) {
      _showActionMessage('Kein weiterer Tipp nötig');
      return;
    }
    final preferences = PreferencesScope.of(context);
    if (!preferences.premiumSimulationEnabled && !_hintBudget.canUseHint) {
      await _showHashiHintRewardDialog();
      return;
    }
    if (!preferences.premiumSimulationEnabled) {
      setState(() => _hintBudget = _hintBudget.useHint());
    }
    _hintsUsed++;
    setState(() {
      _history.add(_game);
      _redoHistory.clear();
      _restartRedoPending = false;
      _game = next;
      _selectedIsland = null;
      _moves++;
    });
    _showActionMessage('Eine passende Brücke wurde ergänzt');
    unawaited(_saveGame());
    await _showCompletionIfSolved();
  }

  Future<void> _showHashiHintRewardDialog() async {
    final simulateAd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.ondemand_video_outlined),
        title: const Text('Keine Tipps mehr'),
        content: const Text(
          'Sieh dir in der kostenlosen Version freiwillig eine kurze Werbung an, um einen weiteren Tipp zu erhalten.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Später'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Werbung simulieren'),
          ),
        ],
      ),
    );
    if (simulateAd != true || !mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.smart_display_outlined),
        title: const Text('Simulierte Werbung'),
        content: const Text(
          'Die echte Werbeintegration folgt erst später. Im Prototyp wird der zusätzliche Tipp sofort vergeben.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Werbung abschließen'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => _hintBudget = _hintBudget.earnRewardedHint());
    unawaited(_saveGame());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Ein zusätzlicher Tipp wurde freigeschaltet.')),
    );
  }

  Future<void> _restart({bool confirm = true}) async {
    if (confirm && (!await confirmPuzzleRestart(context) || !mounted)) return;
    setState(() {
      _movesBeforeRestart = _moves;
      _elapsedBeforeRestart = _elapsedSeconds;
      _history
        ..clear()
        ..add(_game);
      _restartUndoPending = true;
      _restartRedoPending = false;
      _game = HashiGameState(puzzle: widget.puzzle);
      _redoHistory.clear();
      _selectedIsland = null;
      _actionMessage = null;
      _completionShown = false;
      _developerCompletion = false;
      _elapsedSeconds = 0;
      _moves = 0;
    });
    unawaited(_saveGame());
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final premium = PreferencesScope.of(context).premiumSimulationEnabled;
    final hintLabel = premium
        ? 'Tipp · Premium'
        : 'Tipp · ${_hintBudget.remainingHints} übrig';
    final bridgeCounts = List<int>.generate(
      _game.puzzle.islands.length,
      _game.bridgeCountAt,
    );
    final fulfilledIslands = List<int>.generate(
      _game.puzzle.islands.length,
      (index) => index,
    )
        .where((index) =>
            bridgeCounts[index] == _game.puzzle.islands[index].bridges)
        .length;
    final instruction = _actionMessage ??
        (_selectedIsland == null
            ? 'Wähle eine Insel.'
            : 'Wähle eine leuchtende Zielinsel.');

    return Scaffold(
      bottomNavigationBar: _completionShown
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 6, 16, 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (widget.mode == GameMode.generated)
                        FilledButton.icon(
                          onPressed: _startNextRandomPuzzle,
                          icon: const Icon(Icons.auto_awesome_rounded),
                          label: const Text('Noch eins'),
                        )
                      else if (_nextPuzzle != null)
                        FilledButton.icon(
                          onPressed: () async {
                            await _saveStore.clear();
                            if (!context.mounted) return;
                            await Navigator.of(context).pushReplacement(
                              MaterialPageRoute<void>(
                                builder: (_) => HashiGameScreen(
                                  puzzle: _nextPuzzle!,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text('Nächstes Rätsel'),
                        ),
                      OutlinedButton.icon(
                        onPressed: _restart,
                        icon: const Icon(Icons.replay_rounded),
                        label: const Text('Noch einmal'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
      appBar: AppBar(
        title: Text(widget.mode == GameMode.generated
            ? '${widget.puzzle.sharedDifficulty.label} · Zufallsrätsel'
            : widget.puzzle.title),
        actions: [
          if (kDebugMode)
            PopupMenuButton<_HashiDeveloperAction>(
              tooltip: 'Testwerkzeuge',
              icon: const Icon(Icons.bug_report_outlined),
              onSelected: _runDeveloperAction,
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _HashiDeveloperAction.almostSolved,
                  child: Text('Bis auf 1 Brücke lösen'),
                ),
                PopupMenuItem(
                  value: _HashiDeveloperAction.solve,
                  child: Text('Sofort lösen'),
                ),
                PopupMenuItem(
                  value: _HashiDeveloperAction.error,
                  child: Text('Fehlerzustand erzeugen'),
                ),
                PopupMenuItem(
                  value: _HashiDeveloperAction.reset,
                  child: Text('Testzustand löschen'),
                ),
              ],
            ),
          IconButton(
            tooltip: hintLabel,
            onPressed: _completionShown ? null : _useHint,
            icon: const Icon(Icons.lightbulb_outline_rounded),
          ),
          IconButton(
            tooltip: 'Rückgängig',
            onPressed: _completionShown || _history.isEmpty ? null : _undo,
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            tooltip: 'Wiederholen',
            onPressed: _completionShown || _redoHistory.isEmpty ? null : _redo,
            icon: const Icon(Icons.redo_rounded),
          ),
          IconButton(
            tooltip: _showMistakes
                ? 'Fehleranzeige ausschalten'
                : 'Fehleranzeige einschalten',
            onPressed: () {
              setState(() => _showMistakes = !_showMistakes);
              _showActionMessage(
                _showMistakes
                    ? 'Fehleranzeige aktiviert'
                    : 'Fehleranzeige deaktiviert',
              );
            },
            icon: Icon(
              _showMistakes
                  ? Icons.fact_check_rounded
                  : Icons.fact_check_outlined,
            ),
          ),
          IconButton(
            tooltip: 'Neu starten',
            onPressed: _restart,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              child: Column(
                children: [
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatusChip(
                        icon: Icons.timer_outlined,
                        label: _timeLabel,
                      ),
                      _StatusChip(
                        icon: Icons.touch_app_outlined,
                        label: '$_moves Züge',
                      ),
                      _StatusChip(
                        icon: Icons.hub_outlined,
                        label:
                            '$fulfilledIslands/${_game.puzzle.islands.length} Inseln',
                      ),
                      _StatusChip(
                        icon: Icons.lightbulb_outline_rounded,
                        label: premium
                            ? 'Tipps · Premium'
                            : '${_hintBudget.remainingHints} Tipps',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.15),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: Container(
                      key: ValueKey(instruction),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _actionMessage == null
                            ? colors.surfaceContainerHighest
                            : colors.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        instruction,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: _actionMessage == null
                                  ? colors.onSurfaceVariant
                                  : colors.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: colors.outlineVariant.withValues(alpha: 0.7),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colors.shadow.withValues(alpha: 0.08),
                              blurRadius: 22,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: HashiBoard(
                              puzzle: _game.puzzle,
                              bridges: _game.bridges,
                              selectedIsland: _selectedIsland,
                              possibleTargets: _possibleTargets,
                              bridgeCounts: bridgeCounts,
                              incorrectBridges: _showMistakes
                                  ? _game.incorrectBridges
                                  : const [],
                              incorrectIslands: _showMistakes
                                  ? _game.incorrectIslandIndices
                                  : const <int>{},
                              onIslandTap: _handleIslandTap,
                              onBridgeTap: _handleBridgeTap,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 20,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '1× verbinden, 2× doppeln, 3× entfernen. Tipp, Undo, Redo und optionale Fehleranzeige helfen beim Lösen.',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colors.onSurfaceVariant,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _ResultValue extends StatelessWidget {
  const _ResultValue({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class HashiRulesScreen extends StatelessWidget {
  const HashiRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('So funktioniert Hashi')),
      body: Center(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _RuleSection(
                    number: '1',
                    title: 'Inseln verbinden',
                    text:
                        'Verbinde Inseln, die sich in derselben Zeile oder Spalte direkt sehen können.',
                  ),
                  _RuleSection(
                    number: '2',
                    title: 'Zahlen erfüllen',
                    text:
                        'Die Zahl einer Insel entspricht der Summe aller einfachen und doppelten Brücken an dieser Insel.',
                  ),
                  _RuleSection(
                    number: '3',
                    title: 'Keine Kreuzungen',
                    text:
                        'Brücken verlaufen waagerecht oder senkrecht. Sie dürfen weder Inseln durchqueren noch andere Brücken kreuzen.',
                  ),
                  _RuleSection(
                    number: '4',
                    title: 'Brücken korrigieren',
                    text:
                        'Wähle dieselben zwei Inseln erneut: eine, zwei, keine Brücke. Eine gesetzte Brücke kannst du außerdem direkt antippen, um sie zu entfernen.',
                  ),
                  _RuleSection(
                    number: '5',
                    title: 'Ein gemeinsames Netz',
                    text:
                        'Alle Inseln müssen miteinander verbunden sein. Mehrere getrennte Gruppen sind keine gültige Lösung.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HashiBoard extends StatelessWidget {
  const HashiBoard({
    required this.puzzle,
    required this.bridges,
    this.selectedIsland,
    this.possibleTargets = const [],
    this.bridgeCounts,
    this.incorrectBridges = const [],
    this.incorrectIslands = const <int>{},
    this.onIslandTap,
    this.onBridgeTap,
    super.key,
  });

  final HashiPuzzle puzzle;
  final List<HashiBridge> bridges;
  final int? selectedIsland;
  final List<int> possibleTargets;
  final List<int>? bridgeCounts;
  final List<HashiBridge> incorrectBridges;
  final Set<int> incorrectIslands;
  final ValueChanged<int>? onIslandTap;
  final ValueChanged<HashiBridge>? onBridgeTap;

  HashiBridge? _bridgeAtPosition(Offset position, Size size) {
    if (bridges.isEmpty) return null;
    final cell = size.shortestSide / puzzle.size;
    final offsetX = (size.width - cell * puzzle.size) / 2;
    final offsetY = (size.height - cell * puzzle.size) / 2;
    final threshold = math.max(14.0, cell * 0.22);
    final islandRadius = cell * 0.34;

    Offset point(HashiIsland island) => Offset(
          offsetX + (island.column + 0.5) * cell,
          offsetY + (island.row + 0.5) * cell,
        );

    HashiBridge? closest;
    var closestDistance = double.infinity;
    for (final bridge in bridges) {
      final start = point(puzzle.islands[bridge.from]);
      final end = point(puzzle.islands[bridge.to]);
      if ((position - start).distance <= islandRadius ||
          (position - end).distance <= islandRadius) {
        continue;
      }
      final distance = _distanceToSegment(position, start, end);
      if (distance <= threshold && distance < closestDistance) {
        closest = bridge;
        closestDistance = distance;
      }
    }
    return closest;
  }

  static double _distanceToSegment(Offset point, Offset start, Offset end) {
    final segment = end - start;
    final lengthSquared = segment.dx * segment.dx + segment.dy * segment.dy;
    if (lengthSquared == 0) return (point - start).distance;
    final projection = ((point.dx - start.dx) * segment.dx +
            (point.dy - start.dy) * segment.dy) /
        lengthSquared;
    final t = projection.clamp(0.0, 1.0).toDouble();
    final nearest =
        Offset(start.dx + segment.dx * t, start.dy + segment.dy * t);
    return (point - nearest).distance;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, constraints.maxHeight);
        return SizedBox.square(
          dimension: side,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: onBridgeTap == null
                      ? null
                      : (details) {
                          final bridge = _bridgeAtPosition(
                            details.localPosition,
                            Size.square(side),
                          );
                          if (bridge != null) onBridgeTap!(bridge);
                        },
                  child: CustomPaint(
                    painter: _HashiBoardPainter(
                      puzzle: puzzle,
                      bridges: bridges,
                      selectedIsland: selectedIsland,
                      possibleTargets: possibleTargets,
                      bridgeCounts: bridgeCounts,
                      incorrectBridges: incorrectBridges,
                      incorrectIslands: incorrectIslands,
                      colorScheme: Theme.of(context).colorScheme,
                    ),
                  ),
                ),
              ),
              if (onIslandTap != null)
                ...List.generate(puzzle.islands.length, (index) {
                  final island = puzzle.islands[index];
                  final cell = side / puzzle.size;
                  final diameter = cell * 0.72;
                  return Positioned(
                    left: (island.column + 0.5) * cell - diameter / 2,
                    top: (island.row + 0.5) * cell - diameter / 2,
                    width: diameter,
                    height: diameter,
                    child: Semantics(
                      button: true,
                      label: 'Insel ${island.bridges}',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => onIslandTap!(index),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _HashiBoardPainter extends CustomPainter {
  const _HashiBoardPainter({
    required this.puzzle,
    required this.bridges,
    required this.selectedIsland,
    required this.possibleTargets,
    required this.bridgeCounts,
    required this.incorrectBridges,
    required this.incorrectIslands,
    required this.colorScheme,
  });

  final HashiPuzzle puzzle;
  final List<HashiBridge> bridges;
  final int? selectedIsland;
  final List<int> possibleTargets;
  final List<int>? bridgeCounts;
  final List<HashiBridge> incorrectBridges;
  final Set<int> incorrectIslands;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.shortestSide / puzzle.size;
    final offsetX = (size.width - cell * puzzle.size) / 2;
    final offsetY = (size.height - cell * puzzle.size) / 2;

    Offset point(HashiIsland island) => Offset(
          offsetX + (island.column + 0.5) * cell,
          offsetY + (island.row + 0.5) * cell,
        );

    final guidePaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    final guideRadius = (cell * 0.018).clamp(0.8, 1.6).toDouble();
    for (var row = 0; row < puzzle.size; row++) {
      for (var column = 0; column < puzzle.size; column++) {
        canvas.drawCircle(
          Offset(
            offsetX + (column + 0.5) * cell,
            offsetY + (row + 0.5) * cell,
          ),
          guideRadius,
          guidePaint,
        );
      }
    }

    final bridgeWidth = (cell * 0.075).clamp(2.4, 5.2).toDouble();
    final bridgeUnderlay = Paint()
      ..color = colorScheme.surfaceContainerLowest
      ..strokeWidth = bridgeWidth + (cell * 0.075).clamp(2.0, 4.5).toDouble()
      ..strokeCap = StrokeCap.round;
    void drawBridgeLine(Offset start, Offset end, Color color) {
      final bridgePaint = Paint()
        ..color = color
        ..strokeWidth = bridgeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(start, end, bridgeUnderlay);
      canvas.drawLine(start, end, bridgePaint);
    }

    for (final bridge in bridges) {
      final isIncorrect = incorrectBridges.any(
        (candidate) => HashiGameState._sameConnection(
          candidate,
          bridge.from,
          bridge.to,
        ),
      );
      final bridgeColor = isIncorrect ? colorScheme.error : colorScheme.primary;
      final start = point(puzzle.islands[bridge.from]);
      final end = point(puzzle.islands[bridge.to]);
      if (bridge.count == 1) {
        drawBridgeLine(start, end, bridgeColor);
      } else {
        final horizontal = (start.dy - end.dy).abs() < 0.01;
        final shift = cell * 0.095;
        final delta = horizontal ? Offset(0, shift) : Offset(shift, 0);
        drawBridgeLine(start - delta, end - delta, bridgeColor);
        drawBridgeLine(start + delta, end + delta, bridgeColor);
      }
    }

    for (var index = 0; index < puzzle.islands.length; index++) {
      final island = puzzle.islands[index];
      final center = point(island);
      final current = bridgeCounts?[index];
      final fulfilled = current == island.bridges;
      final incorrect = incorrectIslands.contains(index);
      final selected = selectedIsland == index;
      final possibleTarget = possibleTargets.contains(index);
      final radius = cell * 0.32;

      if (selected || possibleTarget) {
        final haloPaint = Paint()
          ..color = (selected ? colorScheme.primary : colorScheme.tertiary)
              .withValues(alpha: selected ? 0.18 : 0.13);
        canvas.drawCircle(center, radius + cell * 0.14, haloPaint);
      }

      final shadowPath = Path()
        ..addOval(Rect.fromCircle(
          center: center + Offset(0, cell * 0.045),
          radius: radius,
        ));
      canvas.drawShadow(
        shadowPath,
        colorScheme.shadow.withValues(alpha: 0.28),
        cell * 0.07,
        false,
      );

      final islandPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.25, -0.35),
          radius: 1.15,
          colors: incorrect
              ? [colorScheme.errorContainer, colorScheme.errorContainer]
              : fulfilled
                  ? [
                      colorScheme.primaryContainer,
                      colorScheme.primaryContainer.withValues(alpha: 0.82),
                    ]
                  : [
                      colorScheme.secondaryContainer,
                      colorScheme.secondaryContainer.withValues(alpha: 0.82),
                    ],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      final outlinePaint = Paint()
        ..color = selected
            ? colorScheme.primary
            : possibleTarget
                ? colorScheme.tertiary
                : incorrect
                    ? colorScheme.error
                    : fulfilled
                        ? colorScheme.primary
                        : colorScheme.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = (selected || possibleTarget)
            ? (cell * 0.085).clamp(3.0, 6.0).toDouble()
            : (cell * 0.045).clamp(1.6, 3.4).toDouble();

      canvas.drawCircle(center, radius, islandPaint);
      canvas.drawCircle(center, radius, outlinePaint);

      if (fulfilled && !incorrect) {
        final checkPaint = Paint()
          ..color = colorScheme.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = (cell * 0.04).clamp(1.6, 3.0).toDouble()
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        final checkCenter = center + Offset(radius * 0.68, -radius * 0.68);
        canvas.drawCircle(
          checkCenter,
          cell * 0.105,
          Paint()..color = colorScheme.surfaceContainerLowest,
        );
        final checkPath = Path()
          ..moveTo(checkCenter.dx - cell * 0.045, checkCenter.dy)
          ..lineTo(checkCenter.dx - cell * 0.01, checkCenter.dy + cell * 0.035)
          ..lineTo(checkCenter.dx + cell * 0.055, checkCenter.dy - cell * 0.04);
        canvas.drawPath(checkPath, checkPaint);
      }

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${island.bridges}',
          style: TextStyle(
            color: incorrect
                ? colorScheme.onErrorContainer
                : fulfilled
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSecondaryContainer,
            fontSize: cell * 0.33,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        center - Offset(textPainter.width / 2, textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HashiBoardPainter oldDelegate) {
    return oldDelegate.puzzle != puzzle ||
        oldDelegate.bridges != bridges ||
        oldDelegate.selectedIsland != selectedIsland ||
        oldDelegate.possibleTargets != possibleTargets ||
        oldDelegate.bridgeCounts != bridgeCounts ||
        oldDelegate.incorrectBridges != incorrectBridges ||
        oldDelegate.colorScheme != colorScheme;
  }
}

class _RuleSection extends StatelessWidget {
  const _RuleSection({
    required this.number,
    required this.title,
    required this.text,
  });

  final String number;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(child: Text(number)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 5),
                  Text(text),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
