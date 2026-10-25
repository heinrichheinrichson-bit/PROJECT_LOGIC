import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_logic_prototype/app_localizations.dart';
import 'package:project_logic_prototype/core/monetization/rewarded_hint_ads.dart';
import 'package:project_logic_prototype/core/presentation/rewarded_hint_dialog.dart';

class FakeProvider implements HintAdProvider {
  @override
  bool isSupported = true;
  @override
  bool requiresAgeCheck = false;
  int calls = 0;
  HintAdResult result = HintAdResult.earned;
  Completer<HintAdResult>? pending;
  @override
  Future<HintAdResult> show({required bool Function() mayShow}) async {
    calls++;
    if (pending != null) return await pending!.future;
    return result;
  }
}

Future<void> mount(WidgetTester tester, FakeProvider provider,
    void Function(bool) completed) async {
  await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [AppLocalizationsDelegate()],
      home: Builder(
          builder: (context) => Scaffold(
              body: FilledButton(
                  onPressed: () async {
                    completed(
                        await requestRewardedHint(context, provider: provider));
                  },
                  child: const Text('Request hint'))))));
  await tester.tap(find.text('Request hint'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('cancel opt-in without any ad request or reward', (tester) async {
    final provider = FakeProvider();
    bool? rewarded;
    await mount(tester, provider, (result) {
      rewarded = result;
    });
    expect(find.text('Simulate ad'), findsNothing);
    expect(find.text('Watch ad'), findsOneWidget);
    expect(provider.calls, 0);
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    expect(rewarded, isFalse);
    expect(provider.calls, 0);
  });
  testWidgets('only a confirmed reward closes the dialog with a hint',
      (tester) async {
    final provider = FakeProvider();
    bool? rewarded;
    await mount(tester, provider, (result) {
      rewarded = result;
    });
    await tester.tap(find.text('Watch ad'));
    await tester.pumpAndSettle();
    expect(rewarded, isTrue);
    expect(provider.calls, 1);
  });
  for (final result in [
    HintAdResult.closed,
    HintAdResult.unavailable,
    HintAdResult.consentUnavailable
  ]) {
    testWidgets('$result keeps hint locked and allows closing', (tester) async {
      final provider = FakeProvider()..result = result;
      bool? rewarded;
      await mount(tester, provider, (value) {
        rewarded = value;
      });
      await tester.tap(find.text('Watch ad'));
      await tester.pumpAndSettle();
      expect(rewarded, isNull);
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();
      expect(rewarded, isFalse);
    });
  }
  testWidgets('under-16 users never contact ad provider', (tester) async {
    final provider = FakeProvider()..requiresAgeCheck = true;
    bool? rewarded;
    await mount(tester, provider, (value) {
      rewarded = value;
    });
    expect(find.text('Your age group'), findsOneWidget);
    await tester.tap(find.text('Under 16'));
    await tester.pumpAndSettle();
    expect(provider.calls, 0);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(rewarded, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(RewardedHintAds.agePreferenceKey), 'under16');
  });
  testWidgets('duplicate taps and cancellation during loading grant no hint',
      (tester) async {
    final provider = FakeProvider()..pending = Completer<HintAdResult>();
    bool? rewarded;
    await mount(tester, provider, (value) {
      rewarded = value;
    });
    await tester.tap(find.text('Watch ad'));
    await tester.pump();
    await tester.tap(find.text('Watch ad'));
    await tester.pump();
    expect(provider.calls, 1);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    provider.pending!.complete(HintAdResult.earned);
    await tester.pumpAndSettle();
    expect(rewarded, isFalse);
    expect(tester.takeException(), isNull);
  });
}
