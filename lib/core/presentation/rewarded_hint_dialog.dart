import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app_localizations.dart';

/// Requests one additional hint from the rewarded-ad flow.
///
/// Until a real rewarded-ad provider is connected, simulations are available
/// in debug builds only. Release builds never grant a hint from this flow.
Future<bool> requestRewardedHint(
  BuildContext context, {
  bool allowSimulation = kDebugMode,
}) async {
  if (!allowSimulation) {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.lightbulb_outline_rounded),
        title: Text(
          dialogContext.strings.text('Keine Tipps mehr', 'No hints left'),
        ),
        content: Text(
          dialogContext.strings.text(
            'Du hast deine kostenlosen Tipps verbraucht.',
            'You have used all of your free hints.',
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(dialogContext.strings.text('Schließen', 'Close')),
          ),
        ],
      ),
    );
    return false;
  }

  final simulateAd = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.ondemand_video_outlined),
      title:
          Text(dialogContext.strings.text('Keine Tipps mehr', 'No hints left')),
      content: Text(
        dialogContext.strings.text(
          'Sieh dir in der kostenlosen Version freiwillig eine kurze Werbung an, um einen weiteren Tipp zu erhalten.',
          'In the free version, you can optionally watch a short ad to receive another hint.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(dialogContext.strings.text('Später', 'Later')),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(dialogContext, true),
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(
              dialogContext.strings.text('Werbung simulieren', 'Simulate ad')),
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
      title: Text(
          dialogContext.strings.text('Simulierte Werbung', 'Simulated ad')),
      content: Text(
        dialogContext.strings.text(
          'Hier wird später eine freiwillige Rewarded-Ad eingeblendet. Im Prototyp wird der zusätzliche Tipp sofort freigeschaltet.',
          'An optional rewarded ad will appear here later. In the prototype, the additional hint is unlocked immediately.',
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(
              dialogContext.strings.text('Werbung abschließen', 'Finish ad')),
        ),
      ],
    ),
  );
  return context.mounted;
}
