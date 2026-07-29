import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/core/formatters/duration_formatter.dart';

void main() {
  group('formatClockDuration', () {
    test('formats minutes and seconds', () {
      expect(formatClockDuration(0), '0:00');
      expect(formatClockDuration(65), '1:05');
    });

    test('includes hours when needed', () {
      expect(formatClockDuration(3661), '1:01:01');
    });
  });
}
