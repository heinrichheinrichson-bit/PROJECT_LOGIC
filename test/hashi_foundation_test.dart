import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/hashi_foundation.dart';

void main() {
  test('Hashi preview puzzle only references existing islands', () {
    expect(hashiPreviewPuzzle.hasValidReferences, isTrue);
  });

  test('Hashi bridge count supports one or two bridges', () {
    expect(const HashiBridge(from: 0, to: 1).count, 1);
    expect(const HashiBridge(from: 0, to: 1, count: 2).count, 2);
  });
}
