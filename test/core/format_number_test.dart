import 'package:flutter_test/flutter_test.dart';
import 'package:structlab/core/format_number.dart';

void main() {
  test('formatNumber uses 2 decimals and a typographic minus', () {
    expect(formatNumber(12.5), '12.5');
    expect(formatNumber(-2.5), '−2.5');
  });

  test('formatNumber never shows negative zero', () {
    expect(formatNumber(-0.0001), '0');
    expect(formatNumber(-0.0), '0');
  });

  test('formatSigned adds + for non-negative values', () {
    expect(formatSigned(3), '+3');
    expect(formatSigned(0), '+0');
    expect(formatSigned(-3), '−3');
  });
}