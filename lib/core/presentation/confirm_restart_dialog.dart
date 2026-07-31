import 'package:flutter/material.dart';

Future<bool> confirmPuzzleRestart(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: const Icon(Icons.restart_alt_rounded),
      title: const Text('Rätsel neu starten?'),
      content: const Text(
        'Alle eigenen Einträge werden entfernt. Du kannst das Zurücksetzen danach einmal rückgängig machen.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Neu starten'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
