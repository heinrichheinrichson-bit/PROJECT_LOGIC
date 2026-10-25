import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app_localizations.dart';
import '../monetization/rewarded_hint_ads.dart';

class HintAdScope extends InheritedWidget {
  const HintAdScope({required this.provider, required super.child, super.key});
  final HintAdProvider provider;
  @override
  bool updateShouldNotify(HintAdScope oldWidget) =>
      provider != oldWidget.provider;
}

/// Returns true only for a reward confirmed by the advertising provider.
Future<bool> requestRewardedHint(BuildContext context,
    {HintAdProvider? provider}) async {
  final ads = provider ??
      context.getInheritedWidgetOfExactType<HintAdScope>()?.provider ??
      RewardedHintAds.provider;
  if (!ads.isSupported) {
    await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text(
                    context.strings.text('Keine Tipps mehr', 'No hints left')),
                content: Text(context.strings.text(
                    'Du hast deine kostenlosen Tipps verbraucht. Zusätzliche Tipps mit Werbung sind in der Android-App verfügbar.',
                    'You have used your free hints. Additional hints with ads are available in the Android app.')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(context.strings.text('Schließen', 'Close')))
                ]));
    return false;
  }
  if (ads.requiresAgeCheck && !await _checkAdAge(context)) return false;
  if (!context.mounted) return false;
  return await showDialog<bool>(
          context: context,
          builder: (_) => _RewardedHintDialog(provider: ads)) ??
      false;
}

Future<bool> _checkAdAge(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  var group = prefs.getString(RewardedHintAds.agePreferenceKey);
  if (!context.mounted) return false;
  if (group == null) {
    group = await showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
                title: Text(context.strings
                    .text('Deine Altersgruppe', 'Your age group')),
                children: [
                  Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                      child: Text(context.strings.text(
                          'Wähle deine Altersgruppe für die Datenschutzeinstellungen. Die Angabe wird lokal gespeichert.',
                          'Choose your age group for the privacy settings. Your answer is stored locally.'))),
                  for (final option in ['under16', '16-17', '18+'])
                    SimpleDialogOption(
                        onPressed: () => Navigator.pop(context, option),
                        child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(switch (option) {
                              'under16' => context.strings
                                  .text('Unter 16 Jahre', 'Under 16'),
                              '16-17' =>
                                context.strings.text('16–17 Jahre', '16–17'),
                              _ => context.strings
                                  .text('18 Jahre und älter', '18 or older'),
                            }))),
                ]));
    if (group == null) return false;
    await prefs.setString(RewardedHintAds.agePreferenceKey, group);
  }
  if (group == '16-17' || group == '18+') return true;
  if (!context.mounted) return false;
  await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
              title: Text(context.strings
                  .text('Zusätzliche Tipps', 'Additional hints')),
              content: Text(context.strings.text(
                  'Für deine Altersgruppe laden wir keine Werbung. Du kannst alle Rätsel weiterhin mit den kostenlosen Tipps spielen.',
                  'We do not load ads for your age group. You can continue playing all puzzles with the free hints.')),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(context.strings.text('Schließen', 'Close')))
              ]));
  return false;
}

class _RewardedHintDialog extends StatefulWidget {
  const _RewardedHintDialog({required this.provider});
  final HintAdProvider provider;
  @override
  State<_RewardedHintDialog> createState() => _RewardedHintDialogState();
}

class _RewardedHintDialogState extends State<_RewardedHintDialog> {
  bool _loading = false;
  HintAdResult? _result;
  Future<void> _watch() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _result = null;
    });
    final result = await widget.provider.show(
        mayShow: () => mounted && (ModalRoute.of(context)?.isCurrent ?? false));
    if (!mounted) return;
    if (result == HintAdResult.earned) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _loading = false;
        _result = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    return AlertDialog(
        icon: const Icon(Icons.ondemand_video_outlined),
        title:
            Text(strings.text('Ein zusätzlicher Tipp', 'One additional hint')),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(strings.text(
              'Sieh dir freiwillig eine Werbung vollständig an und erhalte einen zusätzlichen Tipp für dieses Rätsel.',
              'Choose to watch an ad to completion and receive one additional hint for this puzzle.')),
          if (_loading) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Text(strings.text('Werbung wird vorbereitet …', 'Preparing ad …')),
          ],
          if (_result != null) ...[
            const SizedBox(height: 12),
            Text(_result == HintAdResult.closed
                ? strings.text(
                    'Die Werbung wurde ohne Prämie beendet. Es wurde kein Tipp freigeschaltet.',
                    'The ad ended without a reward. No hint was unlocked.')
                : _result == HintAdResult.consentUnavailable
                    ? strings.text(
                        'Die Datenschutzeinstellungen konnten nicht abgeschlossen werden. Bitte versuche es später erneut.',
                        'Privacy settings could not be completed. Please try again later.')
                    : strings.text(
                        'Zurzeit ist keine Werbung verfügbar. Bitte versuche es später erneut.',
                        'No ad is available right now. Please try again later.')),
          ],
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(strings.text(_loading ? 'Abbrechen' : 'Später',
                  _loading ? 'Cancel' : 'Later'))),
          FilledButton.icon(
              onPressed: _loading ? null : _watch,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(strings.text('Werbung ansehen', 'Watch ad'))),
        ]);
  }
}
