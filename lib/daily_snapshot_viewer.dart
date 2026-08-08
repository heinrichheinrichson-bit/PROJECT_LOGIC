import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'game_storage.dart';

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
      appBar: AppBar(title: const Text('Gelöstes Tagesrätsel')),
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
                                    '${snapshot.gameType.label} · ${snapshot.difficulty.label}',
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
                            const Chip(label: Text('Archiv')),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SnapshotBoard(snapshot: snapshot),
                    const SizedBox(height: 16),
                    Text(
                      'Dieses gelöste Brett ist schreibgeschützt und bleibt auch nach späteren App-Updates erhalten.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: onReplay,
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('Rätsel erneut spielen'),
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
    if (kind == 'hashi' || kind == 'slitherlink') {
      return AspectRatio(
        aspectRatio: 1,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: CustomPaint(
            painter: kind == 'hashi'
                ? _HashiSnapshotPainter(snapshot.puzzleData, context)
                : _SlitherlinkSnapshotPainter(snapshot.puzzleData, context),
          ),
        ),
      );
    }
    final cells = _cells(context);
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

  List<Widget> _cells(BuildContext context) {
    final data = snapshot.puzzleData;
    final size = snapshot.boardSize;
    final kind = data['kind'];
    final colors = _SnapshotColors();
    if (kind == 'binairo') {
      final palette =
          AppTheme.boardPalette('binairo', Theme.of(context).brightness);
      final solution = _matrix(data['solution']);
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
      final grid = _matrix(data['grid']);
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
    if (kind == 'tents') {
      final trees = _pairs(data['trees']).map((e) => '${e.$1}:${e.$2}').toSet();
      final tents = _pairs(data['tents']).map((e) => '${e.$1}:${e.$2}').toSet();
      return [
        for (var row = 0; row < size; row++)
          for (var column = 0; column < size; column++)
            _Cell(
              label: trees.contains('$row:$column')
                  ? '♣'
                  : tents.contains('$row:$column')
                      ? '▲'
                      : '',
              background: trees.contains('$row:$column')
                  ? colors.green
                  : tents.contains('$row:$column')
                      ? colors.sky
                      : colors.empty,
            ),
      ];
    }
    final solution = _matrix(data['solution']);
    final givens = data['givens'] is List ? data['givens'] as List : const [];
    return [
      for (var row = 0; row < size; row++)
        for (var column = 0; column < size; column++)
          _Cell(
            label: '${solution[row][column]}',
            background: colors.amber,
            emphasized:
                givens.isNotEmpty && ((givens[row] as List)[column] != null),
          ),
    ];
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

class _HashiSnapshotPainter extends CustomPainter {
  _HashiSnapshotPainter(this.data, BuildContext context)
      : color = Theme.of(context).colorScheme.primary;
  final Map<String, Object?> data;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final islands = data['islands'] as List? ?? const [];
    final bridges = data['bridges'] as List? ?? const [];
    if (islands.isEmpty) return;
    final parsed = islands
        .map((item) => (item as List).map((e) => (e as num).toInt()).toList())
        .toList();
    final maxRow = parsed.map((e) => e[0]).reduce(math.max).clamp(1, 100);
    final maxColumn = parsed.map((e) => e[1]).reduce(math.max).clamp(1, 100);
    Offset point(int index) {
      final island = parsed[index];
      return Offset(28 + island[1] / maxColumn * (size.width - 56),
          28 + island[0] / maxRow * (size.height - 56));
    }

    final line = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final raw in bridges) {
      final bridge = (raw as List).map((e) => (e as num).toInt()).toList();
      final a = point(bridge[0]);
      final b = point(bridge[1]);
      final count = bridge[2];
      if (count == 1) canvas.drawLine(a, b, line);
      if (count == 2) {
        final direction = b - a;
        final normal =
            Offset(-direction.dy, direction.dx) / direction.distance * 4;
        canvas.drawLine(a + normal, b + normal, line);
        canvas.drawLine(a - normal, b - normal, line);
      }
    }
    final fill = Paint()..color = color.withValues(alpha: .18);
    final outline = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (var index = 0; index < parsed.length; index++) {
      final p = point(index);
      canvas.drawCircle(p, 20, fill);
      canvas.drawCircle(p, 20, outline);
      final text = TextPainter(
        text: TextSpan(
            text: '${parsed[index][2]}',
            style: TextStyle(
                color: color, fontSize: 18, fontWeight: FontWeight.w800)),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, p - Offset(text.width / 2, text.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SlitherlinkSnapshotPainter extends CustomPainter {
  _SlitherlinkSnapshotPainter(this.data, BuildContext context)
      : color = Theme.of(context).colorScheme.primary,
        muted = Theme.of(context).colorScheme.onSurfaceVariant;
  final Map<String, Object?> data;
  final Color color;
  final Color muted;

  @override
  void paint(Canvas canvas, Size size) {
    final rows = (data['rows'] as num).toInt();
    final columns = (data['columns'] as num).toInt();
    final clues = (data['clues'] as List)
        .map((e) => e == null ? null : (e as num).toInt())
        .toList();
    final lines = (data['lines'] as List).whereType<String>().toSet();
    const padding = 24.0;
    final dx = (size.width - padding * 2) / columns;
    final dy = (size.height - padding * 2) / rows;
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (var row = 0; row <= rows; row++) {
      for (var column = 0; column < columns; column++) {
        if (lines.contains('h:$row:$column')) {
          canvas.drawLine(
              Offset(padding + column * dx, padding + row * dy),
              Offset(padding + (column + 1) * dx, padding + row * dy),
              linePaint);
        }
      }
    }
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column <= columns; column++) {
        if (lines.contains('v:$row:$column')) {
          canvas.drawLine(
              Offset(padding + column * dx, padding + row * dy),
              Offset(padding + column * dx, padding + (row + 1) * dy),
              linePaint);
        }
      }
    }
    for (var row = 0; row <= rows; row++) {
      for (var column = 0; column <= columns; column++) {
        canvas.drawCircle(Offset(padding + column * dx, padding + row * dy), 3,
            Paint()..color = muted);
      }
    }
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        final clue = clues[row * columns + column];
        if (clue == null) continue;
        final painter = TextPainter(
            text: TextSpan(
                text: '$clue',
                style: TextStyle(
                    color: muted,
                    fontSize: math.min(dx, dy) * .42,
                    fontWeight: FontWeight.w700)),
            textDirection: TextDirection.ltr)
          ..layout();
        painter.paint(
            canvas,
            Offset(padding + (column + .5) * dx - painter.width / 2,
                padding + (row + .5) * dy - painter.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

List<List<int>> _matrix(Object? raw) => (raw as List)
    .map((row) => (row as List).map((value) => (value as num).toInt()).toList())
    .toList();

List<(int, int)> _pairs(Object? raw) => [
      for (final item in raw as List? ?? const [])
        (
          ((item as List)[0] as num).toInt(),
          (item[1] as num).toInt(),
        ),
    ];

class _SnapshotColors {
  final teal = const Color(0xff00796b);
  final indigo = const Color(0xff4f46a5);
  final plum = const Color(0xff594353);
  final black = const Color(0xff111116);
  final muted = const Color(0xff9b9ba3);
  final green = const Color(0xff167044);
  final sky = const Color(0xff1689b5);
  final empty = const Color(0xff29332f);
  final amber = const Color(0xff8a5a24);
}
