import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app_preferences.dart';
import 'puzzle_interaction_feedback.dart';

/// Plays the shared success feedback while keeping the solved board visible.
///
/// The returned future completes when the success dialog may be shown. The
/// overlay absorbs input so a second completion cannot be triggered while the
/// board is celebrating.
Future<void> showPuzzleCompletionCelebration(BuildContext context) async {
  PuzzleInteractionFeedback.success(context);

  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  final animationsEnabled =
      PreferencesScope.maybeOf(context)?.animationsEnabled ?? true;
  final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  if (overlay == null || !animationsEnabled || reduceMotion) {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return;
  }

  late final OverlayEntry entry;
  entry = OverlayEntry(builder: (_) => const _CompletionSparkOverlay());
  overlay.insert(entry);
  try {
    await Future<void>.delayed(const Duration(milliseconds: 1400));
  } finally {
    entry.remove();
  }
}

class _CompletionSparkOverlay extends StatefulWidget {
  const _CompletionSparkOverlay();

  @override
  State<_CompletionSparkOverlay> createState() =>
      _CompletionSparkOverlayState();
}

class _CompletionSparkOverlayState extends State<_CompletionSparkOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1250),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: AbsorbPointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _CompletionSparkPainter(
                progress: Curves.easeOutCubic.transform(_controller.value),
                colorScheme: Theme.of(context).colorScheme,
              ),
            ),
          ),
        ),
      );
}

class _CompletionSparkPainter extends CustomPainter {
  const _CompletionSparkPainter({
    required this.progress,
    required this.colorScheme,
  });

  final double progress;
  final ColorScheme colorScheme;

  static const _sparkCount = 26;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.43);
    final fade = (1 - progress).clamp(0.0, 1.0);
    final colors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      Colors.amber,
    ];
    for (var index = 0; index < _sparkCount; index++) {
      final angle = (math.pi * 2 * index / _sparkCount) + index * 0.17;
      final distance = (36 + (index % 6) * 13) * progress;
      final position =
          center + Offset(math.cos(angle), math.sin(angle)) * distance;
      final radius = (2.2 + index % 3) * fade;
      final paint = Paint()
        ..color = colors[index % colors.length].withValues(alpha: fade)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      final tail = Offset(math.cos(angle), math.sin(angle)) * (10 * fade);
      canvas.drawLine(position - tail, position + tail * 0.25, paint);
      canvas.drawCircle(position, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CompletionSparkPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.colorScheme != colorScheme;
}
