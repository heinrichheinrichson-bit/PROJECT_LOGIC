import 'package:flutter/material.dart';

import 'app_localizations.dart';
import 'app_theme.dart';
import 'features/futoshiki/domain/futoshiki_puzzle.dart';
import 'futoshiki_foundation.dart';
import 'game_storage.dart';
import 'hashi_foundation.dart';
import 'slitherlink_foundation.dart';

class DailySnapshotViewerScreen extends StatelessWidget {
  const DailySnapshotViewerScreen({
    required this.snapshot,
    required this.onReplay,
    super.key,
  });

  final DailyPuzzleSnapshot snapshot;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(context.strings
              .text('Gelöstes Tagesrätsel', 'Solved daily puzzle'))),
      body: SafeArea(
        child: Center(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Icon(Icons.verified_rounded,
                                color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${context.strings.known(snapshot.gameType.label)} · ${context.strings.known(snapshot.difficulty.label)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    '${snapshot.boardSize} × ${snapshot.boardSize} · '
                                    '${_formatDuration(snapshot.elapsedSeconds)}',
                                  ),
                                ],
                              ),
                            ),
                            Chip(
                                label: Text(
                                    context.strings.text('Archiv', 'Archive'))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SnapshotBoard(snapshot: snapshot),
                    const SizedBox(height: 16),
                    Text(
                      context.strings.text(
                          'Dieses gelöste Brett ist schreibgeschützt und bleibt auch nach späteren App-Updates erhalten.',
                          'This solved board is read-only and remains available after future app updates.'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: onReplay,
                      icon: const Icon(Icons.replay_rounded),
                      label: Text(context.strings
                          .text('Rätsel erneut spielen', 'Play puzzle again')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remaining = seconds % 60;
    return '$minutes:${remaining.toString().padLeft(2, '0')}';
  }
}

class _SnapshotBoard extends StatelessWidget {
  const _SnapshotBoard({required this.snapshot});

  final DailyPuzzleSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final kind = snapshot.puzzleData['kind'];
    if (kind == 'hashi') return _hashiBoard();
    if (kind == 'slitherlink') return _slitherlinkBoard();
    if (kind == 'futoshiki') return _futoshikiBoard();
    if (kind == 'tents') return _tentsBoard(context);
    final cells = _cells(context);
    if (cells == null) return const _UnavailableSnapshotCard();
    final size = snapshot.boardSize;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: size,
        ),
        itemCount: cells.length,
        itemBuilder: (context, index) => cells[index],
      ),
    );
  }

  Widget _hashiBoard() {
    final data = snapshot.puzzleData;
    final rawIslands = data['islands'];
    final rawBridges = data['bridges'];
    if (rawIslands is! List || rawBridges is! List) {
      return const _UnavailableSnapshotCard();
    }
    try {
      final islands = [
        for (final raw in rawIslands)
          HashiIsland(
            row: (raw as List)[0] as int,
            column: raw[1] as int,
            bridges: raw[2] as int,
          ),
      ];
      final bridges = [
        for (final raw in rawBridges)
          HashiBridge(
            from: (raw as List)[0] as int,
            to: raw[1] as int,
            count: raw[2] as int,
          ),
      ];
      final puzzle = HashiPuzzle(
        title: 'Tagesrätsel',
        size: snapshot.boardSize,
        islands: islands,
        solution: bridges,
        difficulty: snapshot.difficulty.index + 1,
      );
      return AspectRatio(
        aspectRatio: 1,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: HashiBoard(puzzle: puzzle, bridges: bridges),
          ),
        ),
      );
    } on Object {
      return const _UnavailableSnapshotCard();
    }
  }

  Widget _slitherlinkBoard() {
    final data = snapshot.puzzleData;
    final rows = (data['rows'] as num?)?.toInt();
    final columns = (data['columns'] as num?)?.toInt();
    final rawClues = data['clues'];
    final rawLines = data['lines'];
    if (rows == null ||
        columns == null ||
        rawClues is! List ||
        rawLines is! List) {
      return const _UnavailableSnapshotCard();
    }
    try {
      final clues = rawClues.length == rows && rawClues.every((e) => e is List)
          ? [
              for (final row in rawClues)
                [for (final value in row as List) (value as num?)?.toInt()],
            ]
          : [
              for (var row = 0; row < rows; row++)
                [
                  for (var column = 0; column < columns; column++)
                    (rawClues[row * columns + column] as num?)?.toInt(),
                ],
            ];
      final solution = rawLines.whereType<String>().toSet();
      final puzzle = SlitherlinkPuzzle(
        id: snapshot.puzzleId,
        title: 'Tagesrätsel',
        rows: rows,
        columns: columns,
        clues: clues,
        solution: solution,
        difficulty: snapshot.difficulty,
      );
      final state = SlitherlinkState(
        puzzle: puzzle,
        marks: {for (final id in solution) id: SlitherEdgeMark.line},
      );
      return AspectRatio(
        aspectRatio: columns / rows,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: SlitherlinkBoard(
              state: state,
              enabled: false,
              onEdgeTap: (_) {},
            ),
          ),
        ),
      );
    } on Object {
      return const _UnavailableSnapshotCard();
    }
  }

  Widget _futoshikiBoard() {
    final data = snapshot.puzzleData;
    final size = snapshot.boardSize;
    final solution = _matrix(data['solution'], size);
    final rawGivens = data['givens'];
    final rawInequalities = data['inequalities'];
    if (solution == null || rawGivens is! List || rawInequalities is! List) {
      return const _UnavailableSnapshotCard();
    }
    try {
      final givens = [
        for (final row in rawGivens)
          [for (final value in row as List) (value as num?)?.toInt()],
      ];
      final inequalities = [
        for (final raw in rawInequalities)
          FutoshikiInequality(
            firstRow: (raw as List)[0] as int,
            firstColumn: raw[1] as int,
            secondRow: raw[2] as int,
            secondColumn: raw[3] as int,
            firstIsLess: raw[4] as bool,
          ),
      ];
      final puzzle = FutoshikiPuzzle(
        id: snapshot.puzzleId,
        title: 'Tagesrätsel',
        size: size,
        givens: givens,
        inequalities: inequalities,
        solution: solution,
        difficulty: snapshot.difficulty,
      );
      return AspectRatio(
        aspectRatio: 1,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: FutoshikiBoard(
              state: FutoshikiState(
                puzzle: puzzle,
                values: [
                  for (final row in solution) [...row]
                ],
              ),
              selected: null,
              conflicts: const {},
              onSelect: (_, __) {},
            ),
          ),
        ),
      );
    } on Object {
      return const _UnavailableSnapshotCard();
    }
  }

  Widget _tentsBoard(BuildContext context) {
    final data = snapshot.puzzleData;
    final size = snapshot.boardSize;
    final trees = _pairs(data['trees']).toSet();
    final tents = _pairs(data['tents']).toSet();
    final rows = (data['rowCounts'] as List?)
        ?.whereType<num>()
        .map((e) => e.toInt())
        .toList();
    final columns = (data['columnCounts'] as List?)
        ?.whereType<num>()
        .map((e) => e.toInt())
        .toList();
    if (rows?.length != size || columns?.length != size) {
      return const _UnavailableSnapshotCard();
    }
    final palette =
        AppTheme.boardPalette('tents', Theme.of(context).brightness);
    return AspectRatio(
      aspectRatio: 1,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: size + 1),
          itemCount: (size + 1) * (size + 1),
          itemBuilder: (context, index) {
            final row = index ~/ (size + 1);
            final column = index % (size + 1);
            if (row == 0 && column == 0) {
              return const SizedBox.shrink();
            }
            if (row == 0) {
              return Center(
                  child: Text('${columns![column - 1]}',
                      style: TextStyle(
                          color: palette.accent, fontWeight: FontWeight.bold)));
            }
            if (column == 0) {
              return Center(
                  child: Text('${rows![row - 1]}',
                      style: TextStyle(
                          color: palette.accent, fontWeight: FontWeight.bold)));
            }
            final cell = (row - 1, column - 1);
            final tree = trees.contains(cell);
            final tent = tents.contains(cell);
            return Padding(
              padding: const EdgeInsets.all(1.5),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tree ? palette.cellStrong : palette.cell,
                  border:
                      Border.all(color: palette.muted.withValues(alpha: .62)),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(
                  child: tree
                      ? Icon(Icons.park_rounded,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF72F0A3)
                              : const Color(0xFF176A38))
                      : tent
                          ? CustomPaint(
                              size: const Size(30, 30),
                              painter: _ArchiveTentPainter(
                                  palette.accent, palette.foreground))
                          : null,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget>? _cells(BuildContext context) {
    final data = snapshot.puzzleData;
    final size = snapshot.boardSize;
    final kind = data['kind'];
    final colors = _SnapshotColors();
    if (kind == 'binairo') {
      final palette =
          AppTheme.boardPalette('binairo', Theme.of(context).brightness);
      final solution = _matrix(data['solution'], size);
      if (solution == null) return null;
      final clues = _pairs(data['clues']).map((e) => '${e.$1}:${e.$2}').toSet();
      return [
        for (var row = 0; row < size; row++)
          for (var column = 0; column < size; column++)
            _Cell(
              label: '${solution[row][column]}',
              background: clues.contains('$row:$column')
                  ? palette.cellStrong
                  : Color.alphaBlend(
                      (solution[row][column] == 0
                              ? palette.accent
                              : palette.accentAlt)
                          .withValues(alpha: .48),
                      palette.board,
                    ),
              foreground: palette.foreground,
              emphasized: clues.contains('$row:$column'),
            ),
      ];
    }
    if (kind == 'hitori') {
      final grid = _matrix(data['grid'], size);
      if (grid == null) return null;
      final shaded =
          _pairs(data['shaded']).map((e) => '${e.$1}:${e.$2}').toSet();
      return [
        for (var row = 0; row < size; row++)
          for (var column = 0; column < size; column++)
            _Cell(
              label: '${grid[row][column]}',
              background:
                  shaded.contains('$row:$column') ? colors.black : colors.plum,
              foreground:
                  shaded.contains('$row:$column') ? colors.muted : Colors.white,
            ),
      ];
    }
    final solution = _matrix(data['solution'], size);
    if (solution == null) return null;
    final givens = data['givens'] is List ? data['givens'] as List : const [];
    final validGivens = givens.length == size &&
        givens.every((row) => row is List && row.length == size);
    return [
      for (var row = 0; row < size; row++)
        for (var column = 0; column < size; column++)
          _Cell(
            label: '${solution[row][column]}',
            background: colors.amber,
            emphasized: validGivens && ((givens[row] as List)[column] != null),
          ),
    ];
  }
}

class _UnavailableSnapshotCard extends StatelessWidget {
  const _UnavailableSnapshotCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 10),
            Text(
              'Dieses archivierte Brett kann in dieser Version nicht '
              'dargestellt werden.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Dein Kalendereintrag und dein Fortschritt bleiben erhalten.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.label,
    required this.background,
    this.foreground = Colors.white,
    this.emphasized = false,
  });
  final String label;
  final Color background;
  final Color foreground;
  final bool emphasized;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: background,
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: .45),
            width: .6,
          ),
        ),
        alignment: Alignment.center,
        child: FittedBox(
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Text(
              label,
              style: TextStyle(
                color: foreground,
                fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
                fontSize: 22,
              ),
            ),
          ),
        ),
      );
}

class _ArchiveTentPainter extends CustomPainter {
  const _ArchiveTentPainter(this.fabric, this.opening);

  final Color fabric;
  final Color opening;

  @override
  void paint(Canvas canvas, Size size) {
    final tent = Path()
      ..moveTo(size.width * .08, size.height * .82)
      ..lineTo(size.width * .5, size.height * .12)
      ..lineTo(size.width * .92, size.height * .82)
      ..close();
    canvas.drawPath(tent, Paint()..color = fabric);
    final entrance = Path()
      ..moveTo(size.width * .38, size.height * .82)
      ..lineTo(size.width * .5, size.height * .42)
      ..lineTo(size.width * .64, size.height * .82)
      ..close();
    canvas.drawPath(entrance, Paint()..color = opening);
  }

  @override
  bool shouldRepaint(covariant _ArchiveTentPainter oldDelegate) =>
      fabric != oldDelegate.fabric || opening != oldDelegate.opening;
}

List<List<int>>? _matrix(Object? raw, int size) {
  if (size <= 0 || raw is! List || raw.length != size) return null;
  final result = <List<int>>[];
  for (final rawRow in raw) {
    if (rawRow is! List || rawRow.length != size) return null;
    final row = <int>[];
    for (final value in rawRow) {
      if (value is! num) return null;
      row.add(value.toInt());
    }
    result.add(row);
  }
  return result;
}

List<(int, int)> _pairs(Object? raw) => [
      for (final item in raw is List ? raw : const [])
        if (item is List &&
            item.length >= 2 &&
            item[0] is num &&
            item[1] is num)
          (
            (item[0] as num).toInt(),
            (item[1] as num).toInt(),
          ),
    ];

class _SnapshotColors {
  final teal = const Color(0xff00796b);
  final indigo = const Color(0xff4f46a5);
  final plum = const Color(0xff594353);
  final black = const Color(0xff111116);
  final muted = const Color(0xff9b9ba3);
  final amber = const Color(0xff8a5a24);
}
