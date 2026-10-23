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
        FormulaRoot() => _Root(part: part, style: style, color: color),
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

/// Radical sign drawn around the radicand: a short tick, the long stroke up
/// and the bar over the whole radicand.
class _Root extends StatelessWidget {
  const _Root({required this.part, required this.style, required this.color});

  final FormulaRoot part;
  final TextStyle style;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RadicalPainter(color),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 4, 2, 0),
        child: Text(part.radicand, style: style),
      ),
    );
  }
}

class _RadicalPainter extends CustomPainter {
  _RadicalPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(1, h * 0.6)
        ..lineTo(4, h * 0.52)
        ..lineTo(7.5, h - 1)
        ..lineTo(11.5, 1)
        ..lineTo(size.width, 1),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RadicalPainter old) => old.color != color;
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