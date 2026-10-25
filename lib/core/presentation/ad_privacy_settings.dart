import 'package:flutter/material.dart';
import '../../app_localizations.dart';
import '../monetization/rewarded_hint_ads.dart';

class AdPrivacySettings extends StatelessWidget {
  const AdPrivacySettings({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
      valueListenable: RewardedHintAds.privacyOptionsRequired,
      builder: (context, required, _) {
        if (!required) return const SizedBox.shrink();
        return Card(
            child: ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(context.strings
                    .text('Datenschutz für Werbung', 'Ad privacy choices')),
                subtitle: Text(context.strings.text(
                    'Einwilligung prüfen oder ändern',
                    'Review or change consent')),
                onTap: () async {
                  final success = await RewardedHintAds.showPrivacyOptions();
                  if (!success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(context.strings.text(
                            'Datenschutzeinstellungen sind gerade nicht verfügbar.',
                            'Privacy settings are currently unavailable.'))));
                  }
                }));
      });
}
