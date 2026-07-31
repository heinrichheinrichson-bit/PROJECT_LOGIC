/// Immutable hint allowance for one puzzle attempt.
///
/// Free players start with [baseHints] and can add individual hints through a
/// rewarded action. Premium bypasses this budget at the call site, so it never
/// needs to create artificial purchases or ad rewards.
class HintBudget {
  const HintBudget({
    this.baseHints = 3,
    this.usedHints = 0,
    this.rewardedHints = 0,
  })  : assert(baseHints >= 0),
        assert(usedHints >= 0),
        assert(rewardedHints >= 0);

  final int baseHints;
  final int usedHints;
  final int rewardedHints;

  int get availableHints => baseHints + rewardedHints;
  int get remainingHints => availableHints - usedHints;
  bool get canUseHint => remainingHints > 0;

  HintBudget useHint() {
    if (!canUseHint) {
      throw StateError('No hint is available.');
    }
    return HintBudget(
      baseHints: baseHints,
      usedHints: usedHints + 1,
      rewardedHints: rewardedHints,
    );
  }

  HintBudget earnRewardedHint() => HintBudget(
        baseHints: baseHints,
        usedHints: usedHints,
        rewardedHints: rewardedHints + 1,
      );
}
