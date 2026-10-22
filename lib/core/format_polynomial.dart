import 'package:structlab/analysis/internal_forces/polynomial.dart';
import 'package:structlab/core/format_number.dart';

const double _eps = 1e-9;

String _power(int p) => switch (p) {
      0 || 1 => '',
      2 => '²',
      3 => '³',
      _ => '^$p',
    };

/// Joins signed terms: [(true, "5x²"), (false, "19")] -> "−5x² + 19".
String joinSignedTerms(List<(bool, String)> terms) {
  if (terms.isEmpty) return '0';
  final buf = StringBuffer();
  for (var i = 0; i < terms.length; i++) {
    final (negative, body) = terms[i];
    if (i == 0) {
      buf.write(negative ? '$minusSign$body' : body);
    } else {
      buf.write(negative ? ' $minusSign $body' : ' + $body');
    }
  }
  return buf.toString();
}

/// "−5x² + 19". When [constantName] is given, it replaces the constant term
/// (e.g. "−5x² + K1").
String formatPolynomial(
  Polynomial p, {
  String variable = 'x',
  String? constantName,
  int decimals = 3,
}) {
  final terms = <(bool, String)>[];
  for (var i = p.coefficients.length - 1; i >= 1; i--) {
    final c = p.coefficients[i];
    if (c.abs() < _eps) continue;
    final mag = formatNumber(c.abs(), decimals: decimals);
    final v = '$variable${_power(i)}';
    terms.add((c < 0, mag == '1' ? v : '$mag$v'));
  }
  if (constantName != null) {
    terms.add((false, constantName));
  } else {
    final c0 = p.coefficient(0);
    if (c0.abs() >= _eps) {
      terms.add((c0 < 0, formatNumber(c0.abs(), decimals: decimals)));
    }
  }
  return joinSignedTerms(terms);
}

/// The polynomial with [x] written in it: "−5·2² + 19".
String formatPolynomialAt(Polynomial p, double x, {int decimals = 3}) {
  final xs = formatNumber(x);
  final terms = <(bool, String)>[];
  for (var i = p.coefficients.length - 1; i >= 0; i--) {
    final c = p.coefficients[i];
    if (c.abs() < _eps) continue;
    final mag = formatNumber(c.abs(), decimals: decimals);
    final body = switch (i) {
      0 => mag,
      1 => '$mag·$xs',
      _ => '$mag·$xs${_power(i)}',
    };
    terms.add((c < 0, body));
  }
  return joinSignedTerms(terms);
}

/// "30x + 2y − 60 = 0"
String formatLinearEquation(double cx, double cy, double c0) {
  final terms = <(bool, String)>[];
  void add(double c, String variable) {
    if (c.abs() < _eps) return;
    final mag = formatNumber(c.abs());
    final body = variable.isEmpty ? mag : (mag == '1' ? variable : '$mag$variable');
    terms.add((c < 0, body));
  }

  add(cx, 'x');
  add(cy, 'y');
  add(c0, '');
  return '${joinSignedTerms(terms)} = 0';
}