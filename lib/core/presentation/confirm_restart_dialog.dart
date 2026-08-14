import 'package:flutter/material.dart';

import '../../app_localizations.dart';

Future<bool> confirmPuzzleRestart(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.restart_alt_rounded),
      title: Text(
          context.strings.text('Rätsel neu starten?', 'Restart the puzzle?')),
      content: Text(
        context.strings.text(
          'Alle eigenen Einträge werden entfernt. Du kannst das Zurücksetzen danach einmal rückgängig machen.',
          'All your entries will be removed. You can undo the reset once afterwards.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.strings.text('Abbrechen', 'Cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(context.strings.text('Neu starten', 'Restart')),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
