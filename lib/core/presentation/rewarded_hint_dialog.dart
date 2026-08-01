import 'package:flutter/material.dart';

Future<bool> showRewardedHintSimulation(BuildContext context) async {
  final simulateAd = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.ondemand_video_outlined),
      title: const Text('Keine Tipps mehr'),
      content: const Text(
        'Sieh dir in der kostenlosen Version freiwillig eine kurze Werbung '
        'an, um einen weiteren Tipp zu erhalten.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Später'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(dialogContext, true),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Werbung simulieren'),
        ),
      ],
    ),
  );
  if (simulateAd != true || !context.mounted) return false;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.smart_display_outlined),
      title: const Text('Simulierte Werbung'),
      content: const Text(
        'Hier wird später eine freiwillige Rewarded-Ad eingeblendet. Im '
        'Prototyp wird der zusätzliche Tipp sofort freigeschaltet.',
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Werbung abschließen'),
        ),
      ],
    ),
  );
  return context.mounted;
}
