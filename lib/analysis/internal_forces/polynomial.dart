const double _eps = 1e-9;

/// A polynomial c0 + c1·x + c2·x² + ... (coefficients in ascending order).
class Polynomial {
  const Polynomial(this.coefficients);

  static const Polynomial zero = Polynomial([]);

  final List<double> coefficients;

  bool get isZero => coefficients.every((c) => c.abs() < _eps);

  double coefficient(int power) =>
      power < coefficients.length ? coefficients[power] : 0.0;

  /// Horner evaluation.
  double at(double x) {
    var result = 0.0;
    for (var i = coefficients.length - 1; i >= 0; i--) {
      result = result * x + coefficients[i];
    }
    return result;
  }

  Polynomial scaled(double k) =>
      Polynomial([for (final c in coefficients) c * k]);

  Polynomial operator +(Polynomial other) {
    final n = coefficients.length > other.coefficients.length
        ? coefficients.length
        : other.coefficients.length;
    return Polynomial([for (var i = 0; i < n; i++) coefficient(i) + other.coefficient(i)]);
  }

  /// Antiderivative whose constant term is [constant].
  Polynomial integral([double constant = 0]) => Polynomial([
        constant,
        for (var i = 0; i < coefficients.length; i++) coefficients[i] / (i + 1),
      ]);

  /// Same polynomial with the constant term replaced by [value].
  Polynomial withConstant(double value) => Polynomial(
        coefficients.isEmpty ? [value] : [value, ...coefficients.skip(1)],
      );
}