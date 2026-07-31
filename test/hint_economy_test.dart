import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/core/monetization/hint_economy.dart';

void main() {
  test('a free puzzle starts with three hints', () {
    const budget = HintBudget();

    expect(budget.remainingHints, 3);
  });

  test('using hints exhausts the free allowance', () {
    final budget = const HintBudget().useHint().useHint().useHint();

    expect(budget.remainingHints, 0);
    expect(budget.canUseHint, isFalse);
    expect(budget.useHint, throwsStateError);
  });

  test('a rewarded action adds exactly one hint', () {
    final exhausted = const HintBudget().useHint().useHint().useHint();
    final rewarded = exhausted.earnRewardedHint();

    expect(rewarded.remainingHints, 1);
    expect(rewarded.useHint().remainingHints, 0);
  });
}
