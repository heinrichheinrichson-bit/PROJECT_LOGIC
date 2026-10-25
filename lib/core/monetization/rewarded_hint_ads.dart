import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum HintAdResult {
  earned,
  closed,
  unavailable,
  consentUnavailable,
  cancelled,
  busy
}

abstract interface class HintAdProvider {
  bool get isSupported;
  Future<HintAdResult> show({required bool Function() mayShow});
}

/// Only the provider's reward event unlocks a hint; dismissal alone never does.
abstract interface class HintAd {
  Future<void> show(
      {required VoidCallback onReward,
      required VoidCallback onDismissed,
      required VoidCallback onFailed});
  Future<void> dispose();
}

abstract interface class HintAdDriver {
  Future<bool> prepareConsent();
  Future<void> initialize();
  Future<HintAd?> load();
}

class RewardedHintController implements HintAdProvider {
  RewardedHintController(this.driver,
      {this.isSupported = true,
      this.loadTimeout = const Duration(seconds: 25)});
  final HintAdDriver driver;
  final Duration loadTimeout;
  @override
  final bool isSupported;
  bool _busy = false;

  @override
  Future<HintAdResult> show({required bool Function() mayShow}) async {
    if (!isSupported) return HintAdResult.unavailable;
    if (_busy) return HintAdResult.busy;
    _busy = true;
    HintAd? loaded;
    var waitingForLoad = true;
    try {
      if (!mayShow()) return HintAdResult.cancelled;
      if (!await driver.prepareConsent()) {
        return HintAdResult.consentUnavailable;
      }
      if (!mayShow()) return HintAdResult.cancelled;
      await driver.initialize().timeout(const Duration(seconds: 20));
      if (!mayShow()) return HintAdResult.cancelled;
      final pending = driver.load().then((ad) {
        // Native callbacks can arrive after the load timeout.
        if (!waitingForLoad) {
          if (ad != null) unawaited(ad.dispose());
          return null;
        }
        return ad;
      });
      loaded = await pending.timeout(loadTimeout);
      waitingForLoad = false;
      if (loaded == null) return HintAdResult.unavailable;
      if (!mayShow()) return HintAdResult.cancelled;
      final dismissed = Completer<HintAdResult>();
      var earned = false;
      await loaded.show(
        onReward: () {
          earned = true;
        },
        onDismissed: () {
          if (!dismissed.isCompleted) {
            dismissed
                .complete(earned ? HintAdResult.earned : HintAdResult.closed);
          }
        },
        onFailed: () {
          if (!dismissed.isCompleted) {
            dismissed.complete(HintAdResult.unavailable);
          }
        },
      );
      return await dismissed.future;
    } catch (error) {
      debugPrint('Rewarded hint ad unavailable: $error');
      return HintAdResult.unavailable;
    } finally {
      waitingForLoad = false;
      if (loaded != null) unawaited(loaded.dispose());
      _busy = false;
    }
  }
}

class RewardedHintAds {
  static const liveAdUnitId = 'ca-app-pub-2541162065593575/9506715032';
  static const testAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const useTestAds =
      !kReleaseMode || bool.fromEnvironment('ADMOB_TEST_ADS');
  // Legacy selections must not leave users locked out after this update.
  static const legacyAgePreferenceKey = 'ad_age_group_v1';
  static const _hasRequestedAdsKey = 'has_requested_rewarded_ads_v1';
  // Apply the strictest treatment to everyone rather than collecting ages.
  static RequestConfiguration get requestConfiguration => RequestConfiguration(
        maxAdContentRating: MaxAdContentRating.g,
        ageRestrictedTreatment: AgeRestrictedTreatment.child,
      );
  static ConsentRequestParameters get consentParameters =>
      ConsentRequestParameters(tagForUnderAgeOfConsent: true);
  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  static final privacyOptionsRequired = ValueNotifier<bool>(false);
  static final _driver = _GoogleHintAdDriver();
  static final HintAdProvider provider =
      RewardedHintController(_driver, isSupported: supported);

  /// Remove obsolete age selections; refresh UMP only after a previous ad opt-in.
  static Future<void> refreshPrivacyAtLaunch() async {
    if (!supported) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(legacyAgePreferenceKey);
      if (prefs.getBool(_hasRequestedAdsKey) == true) {
        await _driver.updateConsent();
      }
    } catch (error) {
      debugPrint('Ad privacy update unavailable: $error');
    }
  }

  static Future<bool> showPrivacyOptions() async {
    try {
      if (!supported) return false;
      final done = Completer<bool>();
      await ConsentForm.showPrivacyOptionsForm((error) {
        if (!done.isCompleted) done.complete(error == null);
      });
      await _driver.refreshPrivacyRequirement();
      return await done.future;
    } catch (_) {
      return false;
    }
  }
}

class _GoogleHintAdDriver implements HintAdDriver {
  Future<bool>? _consentUpdate;
  bool _initialized = false;

  Future<void> refreshPrivacyRequirement() async {
    RewardedHintAds.privacyOptionsRequired.value = await ConsentInformation
            .instance
            .getPrivacyOptionsRequirementStatus() ==
        PrivacyOptionsRequirementStatus.required;
  }

  Future<bool> updateConsent() => _consentUpdate ??= _updateConsent();

  Future<bool> _updateConsent() async {
    final done = Completer<bool>();
    ConsentInformation.instance
        .requestConsentInfoUpdate(RewardedHintAds.consentParameters, () {
      if (!done.isCompleted) done.complete(true);
    }, (_) {
      if (!done.isCompleted) done.complete(false);
    });
    final updated = await done.future.timeout(const Duration(seconds: 20));
    await refreshPrivacyRequirement();
    return updated;
  }

  @override
  Future<bool> prepareConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(RewardedHintAds._hasRequestedAdsKey, true);
      final updated = await updateConsent();
      if (!updated) {
        _consentUpdate = null;
        return false;
      }
      final done = Completer<bool>();
      await ConsentForm.loadAndShowConsentFormIfRequired((error) {
        if (!done.isCompleted) done.complete(error == null);
      });
      final formSucceeded = await done.future;
      await refreshPrivacyRequirement();
      return formSucceeded && await ConsentInformation.instance.canRequestAds();
    } catch (_) {
      _consentUpdate = null;
      return false;
    }
  }

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    await MobileAds.instance
        .updateRequestConfiguration(RewardedHintAds.requestConfiguration);
    await MobileAds.instance.initialize();
    _initialized = true;
  }

  @override
  Future<HintAd?> load() async {
    final done = Completer<HintAd?>();
    await RewardedAd.load(
        adUnitId: RewardedHintAds.useTestAds
            ? RewardedHintAds.testAdUnitId
            : RewardedHintAds.liveAdUnitId,
        request: const AdRequest(nonPersonalizedAds: true),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: (ad) => done.complete(_GoogleHintAd(ad)),
            onAdFailedToLoad: (error) {
              debugPrint('Rewarded hint load: ${error.code}');
              done.complete(null);
            }));
    return done.future;
  }
}

class _GoogleHintAd implements HintAd {
  _GoogleHintAd(this.ad);
  final RewardedAd ad;
  @override
  Future<void> show(
      {required VoidCallback onReward,
      required VoidCallback onDismissed,
      required VoidCallback onFailed}) {
    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
        onAdDismissedFullScreenContent: (_) => onDismissed(),
        onAdFailedToShowFullScreenContent: (_, __) => onFailed());
    return ad.show(onUserEarnedReward: (_, __) => onReward());
  }

  @override
  Future<void> dispose() => ad.dispose();
}
