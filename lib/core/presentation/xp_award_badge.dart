import 'package:flutter/material.dart';

class XpAwardBadge extends StatelessWidget {
  const XpAwardBadge({required this.points, super.key});

  final int points;

  @override
  Widget build(BuildContext context) => Chip(
        avatar: Icon(
          points > 0 ? Icons.auto_awesome_rounded : Icons.replay_rounded,
        ),
        label: Text(points > 0 ? '+$points XP' : 'Wiederholung · keine XP'),
      );
}
