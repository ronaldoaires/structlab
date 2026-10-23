import 'package:structlab/analysis/reactions/equivalent_loads.dart';
import 'package:structlab/core/format_number.dart';

/// A piece of a math line: plain text or a stacked fraction.
sealed class FormulaPart {
  const FormulaPart();
}

class FormulaText extends FormulaPart {
  const FormulaText(this.text);
  final String text;
}

class FormulaFraction extends FormulaPart {
  const FormulaFraction(this.numerator, this.denominator);
  final String numerator;
  final String denominator;
}

/// A square root drawn with a real radical sign over [radicand].
class FormulaRoot extends FormulaPart {
  const FormulaRoot(this.radicand);
  final String radicand;
}

typedef FormulaLine = List<FormulaPart>;

/// One quantity (resultant or CG) shown in three lines:
/// the symbolic formula, the formula with numbers, and the result.
class FormulaBlock {
  const FormulaBlock({
    required this.symbolic,
    required this.substituted,
    required this.result,
  });

  final FormulaLine symbolic;
  final FormulaLine substituted;
  final FormulaLine result;
}

class LoadFormulas {
  const LoadFormulas({required this.resultant, required this.centroid});

  final FormulaBlock resultant;
  final FormulaBlock centroid;
}

/// Pythagoras for the real length of an inclined segment:
///   L = √(Δx² + Δy²)
///   L = √(6² + 2²) = √(36 + 4)
///   L = √40 = 6.32 m
FormulaBlock buildPythagorasFormula(EquivalentLoad e) {
  String n(double v) => formatNumber(v);
  final dx = e.horizontalLeg;
  final dy = e.verticalLeg;
  final sum = dx * dx + dy * dy;
  return FormulaBlock(
    symbolic: const [FormulaText('L ='), FormulaRoot('Δx² + Δy²')],
    substituted: [
      const FormulaText('L ='),
      FormulaRoot('${n(dx)}² + ${n(dy)}²'),
      const FormulaText('='),
      FormulaRoot('${n(dx * dx)} + ${n(dy * dy)}'),
    ],
    result: [
      const FormulaText('L ='),
      FormulaRoot(n(sum)),
      FormulaText('= ${n(e.memberLength)} m'),
    ],
  );
}

/// Builds the textbook formulas of a distributed load. The CG is measured
/// from the side of the highest height (see [EquivalentLoad.centroidFromPeak]).
/// Pure data: the titles are built in l10n.
LoadFormulas buildLoadFormulas(EquivalentLoad e) {
  String n(double v) => formatNumber(v);
  final high = n(e.high);
  final low = n(e.low);
  final len = n(e.length);
  final r = n(e.resultant);
  final cg = n(e.centroidFromPeak);

  switch (e.shape) {
    case LoadShape.rectangle:
      return LoadFormulas(
        resultant: FormulaBlock(
          symbolic: const [FormulaText('R = q · L')],
          substituted: [FormulaText('R = $high · $len')],
          result: [FormulaText('R = $r kN')],
        ),
        centroid: FormulaBlock(
          symbolic: const [FormulaText('CG ='), FormulaFraction('L', '2')],
          substituted: [FormulaText('CG ='), FormulaFraction(len, '2')],
          result: [FormulaText('CG = $cg m')],
        ),
      );
    case LoadShape.triangle:
      return LoadFormulas(
        resultant: FormulaBlock(
          symbolic: const [FormulaText('R ='), FormulaFraction('q · L', '2')],
          substituted: [
            const FormulaText('R ='),
            FormulaFraction('$high · $len', '2'),
          ],
          result: [FormulaText('R = $r kN')],
        ),
        centroid: FormulaBlock(
          symbolic: const [FormulaText('CG ='), FormulaFraction('L', '3')],
          substituted: [FormulaText('CG ='), FormulaFraction(len, '3')],
          result: [FormulaText('CG = $cg m')],
        ),
      );
    case LoadShape.trapezoid:
      return LoadFormulas(
        resultant: FormulaBlock(
          symbolic: const [
            FormulaText('R ='),
            FormulaFraction('(H + h) · L', '2'),
          ],
          substituted: [
            const FormulaText('R ='),
            FormulaFraction('($high + $low) · $len', '2'),
          ],
          result: [FormulaText('R = $r kN')],
        ),
        centroid: FormulaBlock(
          symbolic: const [
            FormulaText('CG ='),
            FormulaFraction('(H + 2·h) · L', '3 · (H + h)'),
          ],
          substituted: [
            const FormulaText('CG ='),
            FormulaFraction('($high + 2·$low) · $len', '3 · ($high + $low)'),
          ],
          result: [FormulaText('CG = $cg m')],
        ),
      );
  }
}