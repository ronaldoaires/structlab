/// Decimal separator shown to the user. Change it here to use a comma.
const String decimalSeparator = '.';

/// Minus sign shown to the user (typographic, easier to read than "-").
const String minusSign = '−';

/// Formats a number for display. Trailing zeros are dropped (50.00 -> 50,
/// 12.50 -> 12.5) and it never shows a negative zero.
String formatNumber(double v, {int decimals = 2}) {
  var s = v.toStringAsFixed(decimals);
  if (double.parse(s) == 0) s = '0';
  if (s.contains('.')) {
    // Remove trailing zeros, then a dangling decimal point.
    s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }
  return s.replaceAll('.', decimalSeparator).replaceFirst('-', minusSign);
}

/// Same as [formatNumber] but with an explicit "+" for non-negative values.
String formatSigned(double v, {int decimals = 2}) {
  final s = formatNumber(v, decimals: decimals);
  return s.startsWith(minusSign) ? s : '+$s';
}