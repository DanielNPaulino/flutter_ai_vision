import 'package:flutter_ai_vision/utils/weight_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseWeightKg', () {
    test('parses kilogram ranges using the high end', () {
      expect(parseWeightKg('3-6.7 kg'), 6.7);
    });

    test('converts grams to kilograms', () {
      expect(parseWeightKg('70-100 g'), closeTo(0.1, 1e-9));
    });

    test('returns 0 for null, empty and unknown values', () {
      expect(parseWeightKg(null), 0);
      expect(parseWeightKg(''), 0);
      expect(parseWeightKg('Unknown'), 0);
    });

    test('orders heavy birds before light ones', () {
      expect(parseWeightKg('3-6 kg'), greaterThan(parseWeightKg('500 g')));
    });
  });
}
