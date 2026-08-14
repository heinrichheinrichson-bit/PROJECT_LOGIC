import 'package:flutter/material.dart';

import '../../app_localizations.dart';

class PuzzleHubHeader extends StatelessWidget {
  const PuzzleHubHeader({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
    this.progress,
    this.progressLabel,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color accent;
  final double? progress;
  final String? progressLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          accent.withValues(alpha: isDark ? .18 : .10),
          colors.surfaceContainerLow,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: accent.withValues(alpha: isDark ? .34 : .22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? .24 : .16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: accent, size: 30),
          ),
          const SizedBox(height: 18),
          Text(context.strings.known(title),
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            context.strings.known(description),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.35,
                ),
          ),
          if (progress != null && progressLabel != null) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.strings.known(progressLabel!),
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Text('${(progress!.clamp(0, 1) * 100).round()} %'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress!.clamp(0, 1),
              minHeight: 7,
              color: accent,
              borderRadius: BorderRadius.circular(99),
            ),
          ],
        ],
      ),
    );
  }
}

class PuzzleHubAction extends StatelessWidget {
  const PuzzleHubAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    this.prominent = false,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback? onTap;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: prominent
          ? Color.alphaBlend(
              accent.withValues(alpha: .13), colors.surfaceContainerLow)
          : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.strings.known(title),
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(
                      context.strings.known(subtitle),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                            height: 1.25,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class PuzzleRulesScreen extends StatelessWidget {
  const PuzzleRulesScreen({
    required this.title,
    required this.introduction,
    required this.rules,
    required this.interaction,
    super.key,
  });

  final String title;
  final String introduction;
  final List<String> rules;
  final String interaction;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(context.strings.text(
            '$title-Regeln',
            '${context.strings.known(title)} rules',
          )),
        ),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(context.strings.known(introduction),
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            for (var index = 0; index < rules.length; index++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(radius: 16, child: Text('${index + 1}')),
                  const SizedBox(width: 14),
                  Expanded(child: Text(context.strings.known(rules[index]))),
                ],
              ),
              const SizedBox(height: 18),
            ],
            const Divider(height: 32),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.touch_app_outlined),
              title: Text(context.strings.text('Bedienung', 'Controls')),
              subtitle: Text(context.strings.known(interaction)),
            ),
          ],
        ),
      );
}

class PuzzleGameStatusChip extends StatelessWidget {
  const PuzzleGameStatusChip({
    required this.icon,
    required this.label,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    );
    if (onTap == null) return chip;
    return Tooltip(
      message: context.strings.text('Hinweis', 'Hint'),
      child: Semantics(
        button: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: chip,
        ),
      ),
    );
  }
}

class PuzzleGameRulesButton extends StatelessWidget {
  const PuzzleGameRulesButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.menu_book_outlined),
        label: Text(context.strings
            .text('Spielregeln & Bedienung', 'Rules & controls')),
      );
}

Future<void> showPuzzleGameOptions(
  BuildContext context, {
  required List<Widget> children,
}) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                sheetContext.strings.text('Spielhilfen', 'Game assists'),
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ...children,
            ],
          ),
        ),
      ),
    );
