import 'package:flutter/material.dart';
import 'package:structlab/core/theme/colors.dart';
import 'package:structlab/results/load_formula.dart';

/// Renders a [FormulaLine] with real stacked fractions. Scales down when the
/// line does not fit the available width.
class FormulaLineView extends StatelessWidget {
  const FormulaLineView({
    super.key,
    required this.line,
    this.color = ink,
    this.bold = false,
    this.alignment = Alignment.centerLeft,
  });

  final FormulaLine line;
  final Color color;
  final bool bold;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 14,
      height: 1.2,
      color: color,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    final children = <Widget>[];
    for (var i = 0; i < line.length; i++) {
      if (i > 0) children.add(const SizedBox(width: 6));
      final part = line[i];
      children.add(switch (part) {
        FormulaText() => Text(part.text, style: style),
        FormulaFraction() => _Fraction(part: part, style: style, color: color),
      });
    }

    return SizedBox(
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: alignment,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: children,
        ),
      ),
    );
  }
}

class _Fraction extends StatelessWidget {
  const _Fraction({
    required this.part,
    required this.style,
    required this.color,
  });

  final FormulaFraction part;
  final TextStyle style;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(part.numerator, textAlign: TextAlign.center, style: style),
          Container(
            height: 1.3,
            margin: const EdgeInsets.symmetric(vertical: 2),
            color: color,
          ),
          Text(part.denominator, textAlign: TextAlign.center, style: style),
        ],
      ),
    );
  }
}