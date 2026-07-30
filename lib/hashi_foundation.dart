import 'package:flutter/material.dart';

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
}

@immutable
class HashiPreviewPuzzle {
  const HashiPreviewPuzzle({
    required this.title,
    required this.size,
    required this.islands,
    required this.bridges,
  });

  final String title;
  final int size;
  final List<HashiIsland> islands;
  final List<HashiBridge> bridges;

  bool get hasValidReferences => bridges.every(
        (bridge) =>
            bridge.from >= 0 &&
            bridge.from < islands.length &&
            bridge.to >= 0 &&
            bridge.to < islands.length &&
            bridge.from != bridge.to,
      );
}

const hashiPreviewPuzzle = HashiPreviewPuzzle(
  title: 'Eine kleine Inselwelt',
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
  bridges: [
    HashiBridge(from: 0, to: 1),
    HashiBridge(from: 0, to: 2),
    HashiBridge(from: 1, to: 4),
    HashiBridge(from: 2, to: 3),
    HashiBridge(from: 2, to: 5),
    HashiBridge(from: 3, to: 4),
    HashiBridge(from: 4, to: 6),
    HashiBridge(from: 5, to: 6),
  ],
);

class HashiHubScreen extends StatelessWidget {
  const HashiHubScreen({super.key});

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
                        'Verbinde die Inseln',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Brücken dürfen nur gerade verlaufen, sich nicht kreuzen und müssen am Ende alle Inseln zu einem Netz verbinden.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
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
                          hashiPreviewPuzzle.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'So sieht ein gelöstes Hashi-Rätsel aus.',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 16),
                        const AspectRatio(
                          aspectRatio: 1,
                          child: HashiPreviewBoard(puzzle: hashiPreviewPuzzle),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const _HashiInfoCard(
                  icon: Icons.looks_one_rounded,
                  title: 'Die Zahl ist das Ziel',
                  text:
                      'Jede Insel zeigt, wie viele Brücken sie insgesamt berühren müssen.',
                ),
                const SizedBox(height: 10),
                const _HashiInfoCard(
                  icon: Icons.horizontal_rule_rounded,
                  title: 'Einfach oder doppelt',
                  text:
                      'Zwischen zwei Inseln sind höchstens zwei parallele Brücken erlaubt.',
                ),
                const SizedBox(height: 10),
                const _HashiInfoCard(
                  icon: Icons.share_rounded,
                  title: 'Alles gehört zusammen',
                  text:
                      'Die Lösung ist erst vollständig, wenn jede Insel vom gemeinsamen Netz erreichbar ist.',
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const HashiRulesScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.menu_book_rounded),
                  label: const Text('Regeln ansehen'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Der nächste Schritt'),
                      content: const Text(
                        'Das Fundament steht. Als Nächstes kommen ein echtes Spielfeld, das Setzen von Brücken und die erste spielbare Einführung.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Alles klar'),
                        ),
                      ],
                    ),
                  ),
                  icon: const Icon(Icons.construction_rounded),
                  label: const Text('Spielbare Einführung folgt'),
                ),
              ],
            ),
          ),
        ),
      ),
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
                        'Brücken verlaufen waagerecht oder senkrecht. Sie dürfen weder andere Inseln durchqueren noch andere Brücken kreuzen.',
                  ),
                  _RuleSection(
                    number: '4',
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

class HashiPreviewBoard extends StatelessWidget {
  const HashiPreviewBoard({required this.puzzle, super.key});

  final HashiPreviewPuzzle puzzle;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HashiPreviewPainter(
        puzzle: puzzle,
        colorScheme: Theme.of(context).colorScheme,
      ),
    );
  }
}

class _HashiPreviewPainter extends CustomPainter {
  const _HashiPreviewPainter({
    required this.puzzle,
    required this.colorScheme,
  });

  final HashiPreviewPuzzle puzzle;
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

    final bridgePaint = Paint()
      ..color = colorScheme.primary
      ..strokeWidth = (cell * 0.07).clamp(2.0, 5.0).toDouble()
      ..strokeCap = StrokeCap.round;

    for (final bridge in puzzle.bridges) {
      final start = point(puzzle.islands[bridge.from]);
      final end = point(puzzle.islands[bridge.to]);
      if (bridge.count == 1) {
        canvas.drawLine(start, end, bridgePaint);
      } else {
        final horizontal = start.dy == end.dy;
        final shift = cell * 0.08;
        final delta = horizontal ? Offset(0, shift) : Offset(shift, 0);
        canvas.drawLine(start - delta, end - delta, bridgePaint);
        canvas.drawLine(start + delta, end + delta, bridgePaint);
      }
    }

    final islandPaint = Paint()..color = colorScheme.secondaryContainer;
    final outlinePaint = Paint()
      ..color = colorScheme.secondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = (cell * 0.05).clamp(1.5, 4.0).toDouble();

    for (final island in puzzle.islands) {
      final center = point(island);
      final radius = cell * 0.29;
      canvas.drawCircle(center, radius, islandPaint);
      canvas.drawCircle(center, radius, outlinePaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${island.bridges}',
          style: TextStyle(
            color: colorScheme.onSecondaryContainer,
            fontSize: cell * 0.3,
            fontWeight: FontWeight.w800,
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
  bool shouldRepaint(covariant _HashiPreviewPainter oldDelegate) =>
      oldDelegate.puzzle != puzzle || oldDelegate.colorScheme != colorScheme;
}

class _HashiInfoCard extends StatelessWidget {
  const _HashiInfoCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(text),
      ),
    );
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
