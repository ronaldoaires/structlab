/// Decimal separator shown to the user. Change it here to use a comma.
const String decimalSeparator = '.';

/// Minus sign shown to the user (typographic, easier to read than "-").
const String minusSign = '−';

/// Formats a number for display. Never shows "-0.00".
String formatNumber(double v, {int decimals = 2}) {
  var s = v.toStringAsFixed(decimals);
  if (double.parse(s) == 0) s = 0.0.toStringAsFixed(decimals);
  return s.replaceAll('.', decimalSeparator).replaceFirst('-', minusSign);
}

/// Same as [formatNumber] but with an explicit "+" for non-negative values.
String formatSigned(double v, {int decimals = 2}) {
  final s = formatNumber(v, decimals: decimals);
  return s.startsWith(minusSign) ? s : '+$s';
}