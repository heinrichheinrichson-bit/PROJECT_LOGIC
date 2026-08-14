import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/app_localizations.dart';
import 'package:project_logic_prototype/app_preferences.dart';
import 'package:project_logic_prototype/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('language selection updates the app immediately', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await AppPreferences.load();

    await tester.pumpWidget(ProjectLogicApp(preferences: preferences));
    await tester.pumpAndSettle();
    expect(find.text('Deine Spiele'), findsOneWidget);

    await preferences.setLanguage(AppLanguagePreference.english);
    await tester.pumpAndSettle();

    expect(find.text('Your games'), findsOneWidget);
    expect(find.text('Your space'), findsOneWidget);
    expect(find.byTooltip('Settings'), findsOneWidget);
  });

  test('system language falls back to German for unsupported locales', () {
    expect(
      AppLocalizations.resolve(
        const Locale('fr'),
        AppLocalizations.supportedLocales,
      ),
      const Locale('de'),
    );
  });
}
