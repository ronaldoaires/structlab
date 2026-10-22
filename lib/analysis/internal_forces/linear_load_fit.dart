import 'package:structlab/analysis/internal_forces/polynomial.dart';

/// Function y = slope·x + intercept of a load that varies linearly between
/// the points (xa, ya) and (xb, yb), found with the matrix method:
///
///   | xa ya 1 |
///   | xb yb 1 | = 0   (Sarrus rule)
///   | x  y  1 |
///
/// Expanding the determinant gives  xCoefficient·x + yCoefficient·y +
/// constantTerm = 0, and isolating y gives Q(x).
class LinearLoadFit {
  const LinearLoadFit({
    required this.xa,
    required this.ya,
    required this.xb,
    required this.yb,
  });

  final double xa;
  final double ya;
  final double xb;
  final double yb;

  /// Sarrus: (xa·yb + ya·x + xb·y) − (yb·x + xa·y + ya·xb).
  double get xCoefficient => ya - yb;
  double get yCoefficient => xb - xa;
  double get constantTerm => xa * yb - ya * xb;

  double get slope => -xCoefficient / yCoefficient;
  double get intercept => -constantTerm / yCoefficient;

  /// Q(x) = intercept + slope·x.
  Polynomial get polynomial => Polynomial([intercept, slope]);
}