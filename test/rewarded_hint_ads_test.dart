import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/core/monetization/rewarded_hint_ads.dart';

class FakeAd implements HintAd {
  VoidCallback? reward, dismissed, failed;
  bool shown = false, disposed = false;
  @override
  Future<void> show(
      {required VoidCallback onReward,
      required VoidCallback onDismissed,
      required VoidCallback onFailed}) async {
    shown = true;
    reward = onReward;
    dismissed = onDismissed;
    failed = onFailed;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

class FakeDriver implements HintAdDriver {
  bool consent = true;
  int loads = 0, initializations = 0;
  final loaded = Completer<HintAd?>();
  @override
  Future<bool> prepareConsent() async => consent;
  @override
  Future<void> initialize() async {
    initializations++;
  }

  @override
  Future<HintAd?> load() {
    loads++;
    return loaded.future;
  }
}

Future<void> nextTurn() => Future<void>.delayed(Duration.zero);

void main() {
  test('dismissal without reward never unlocks a hint', () async {
    final driver = FakeDriver();
    final ad = FakeAd();
    driver.loaded.complete(ad);
    final result = RewardedHintController(driver).show(mayShow: () => true);
    await nextTurn();
    ad.dismissed!();
    expect(await result, HintAdResult.closed);
    expect(ad.disposed, isTrue);
  });
  test('reward is returned once, only after dismissal', () async {
    final driver = FakeDriver();
    final ad = FakeAd();
    driver.loaded.complete(ad);
    var completed = false;
    final result = RewardedHintController(driver).show(mayShow: () => true)
      ..then((_) {
        completed = true;
      });
    await nextTurn();
    ad.reward!();
    ad.reward!();
    await nextTurn();
    expect(completed, isFalse);
    ad.dismissed!();
    ad.dismissed!();
    expect(await result, HintAdResult.earned);
  });
  test('no request is sent when consent preparation fails', () async {
    final driver = FakeDriver()..consent = false;
    expect(await RewardedHintController(driver).show(mayShow: () => true),
        HintAdResult.consentUnavailable);
    expect(driver.initializations, 0);
    expect(driver.loads, 0);
  });
  test('no fill and show failures cannot produce rewards', () async {
    final noFill = FakeDriver()..loaded.complete(null);
    expect(await RewardedHintController(noFill).show(mayShow: () => true),
        HintAdResult.unavailable);
    final driver = FakeDriver();
    final ad = FakeAd();
    driver.loaded.complete(ad);
    final result = RewardedHintController(driver).show(mayShow: () => true);
    await nextTurn();
    ad.failed!();
    expect(await result, HintAdResult.unavailable);
    expect(ad.disposed, isTrue);
  });
  test('cancelled screen cannot show an ad that finishes loading later',
      () async {
    final driver = FakeDriver();
    final ad = FakeAd();
    var active = true;
    final result = RewardedHintController(driver).show(mayShow: () => active);
    await nextTurn();
    active = false;
    driver.loaded.complete(ad);
    expect(await result, HintAdResult.cancelled);
    expect(ad.shown, isFalse);
    expect(ad.disposed, isTrue);
  });
  test('late native callback after timeout disposes the ad without showing it',
      () async {
    final driver = FakeDriver();
    final ad = FakeAd();
    final result = RewardedHintController(driver,
            loadTimeout: const Duration(milliseconds: 5))
        .show(mayShow: () => true);
    expect(await result, HintAdResult.unavailable);
    driver.loaded.complete(ad);
    await nextTurn();
    expect(ad.shown, isFalse);
    expect(ad.disposed, isTrue);
  });
  test('overlapping requests cannot show two rewarded ads', () async {
    final driver = FakeDriver();
    final controller = RewardedHintController(driver);
    final first = controller.show(mayShow: () => true);
    expect(await controller.show(mayShow: () => true), HintAdResult.busy);
    driver.loaded.complete(null);
    await first;
    expect(driver.loads, 1);
  });
  test('unsupported platforms do not contact the provider', () async {
    final driver = FakeDriver();
    expect(
        await RewardedHintController(driver, isSupported: false)
            .show(mayShow: () => true),
        HintAdResult.unavailable);
    expect(driver.loads, 0);
    expect(driver.initializations, 0);
  });
}
