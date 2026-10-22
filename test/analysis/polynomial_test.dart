import 'package:flutter_test/flutter_test.dart';
import 'package:structlab/analysis/internal_forces/linear_load_fit.dart';
import 'package:structlab/analysis/internal_forces/polynomial.dart';
import 'package:structlab/core/format_polynomial.dart';

void main() {
  test('integral and evaluation', () {
    // ∫ -10x dx = -5x²
    final v = const Polynomial([0, -10]).integral().withConstant(19);
    expect(v.at(0), 19);
    expect(v.at(3), closeTo(-26, 1e-9));
  });

  test('matrix method gives the lecture-notes functions', () {
    const up = LinearLoadFit(xa: 0, ya: 0, xb: 3, yb: 30);
    expect(up.slope, closeTo(10, 1e-9));
    expect(up.intercept, closeTo(0, 1e-9));

    const down = LinearLoadFit(xa: 0, ya: 30, xb: 2, yb: 0);
    // 30x + 2y - 60 = 0
    expect(down.xCoefficient, 30);
    expect(down.yCoefficient, 2);
    expect(down.constantTerm, -60);
    expect(down.slope, closeTo(-15, 1e-9));
    expect(down.intercept, closeTo(30, 1e-9));
  });

  test('formatting', () {
    expect(formatPolynomial(const Polynomial([19, 0, -5])), '−5x² + 19');
    expect(formatPolynomial(const Polynomial([0, 19, 0, -5 / 3])),
        '−1.667x³ + 19x');
    expect(
      formatPolynomial(const Polynomial([0, 0, -5]), constantName: 'K1'),
      '−5x² + K1',
    );
    expect(formatPolynomialAt(const Polynomial([19, 0, -5]), 2), '−5·2² + 19');
    expect(formatLinearEquation(30, 2, -60), '30x + 2y − 60 = 0');
  });
}