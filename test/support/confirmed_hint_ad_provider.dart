import 'package:project_logic_prototype/core/monetization/rewarded_hint_ads.dart';

/// Boundary fake: the SDK reward lifecycle is covered by rewarded_hint_ads_test.
class ConfirmedHintAdProvider implements HintAdProvider {
  const ConfirmedHintAdProvider();
  @override
  bool get isSupported => true;
  @override
  Future<HintAdResult> show({required bool Function() mayShow}) async =>
      mayShow() ? HintAdResult.earned : HintAdResult.cancelled;
}
