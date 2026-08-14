import 'package:flutter/material.dart';

import '../../app_localizations.dart';

class XpAwardBadge extends StatelessWidget {
  const XpAwardBadge({required this.points, super.key});

  final int points;

  @override
  Widget build(BuildContext context) => Chip(
        avatar: Icon(
          points > 0 ? Icons.auto_awesome_rounded : Icons.replay_rounded,
        ),
        label: Text(points > 0
            ? '+$points XP'
            : context.strings
                .text('Wiederholung · keine XP', 'Replay · no XP')),
      );
}
