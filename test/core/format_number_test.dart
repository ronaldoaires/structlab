import 'package:flutter_test/flutter_test.dart';
import 'package:structlab/core/format_number.dart';

void main() {
  test('formatNumber uses 2 decimals and a typographic minus', () {
    expect(formatNumber(12.5), '12.50');
    expect(formatNumber(-2.5), '−2.50');
  });

  test('formatNumber never shows negative zero', () {
    expect(formatNumber(-0.0001), '0.00');
    expect(formatNumber(-0.0), '0.00');
  });

  test('formatSigned adds + for non-negative values', () {
    expect(formatSigned(3), '+3.00');
    expect(formatSigned(0), '+0.00');
    expect(formatSigned(-3), '−3.00');
  });
}