/// Order in which the terms of an equation are listed in the step by step.
enum TermOrder { leftToRight, rightToLeft }

/// How signs are SHOWN to the student. All calculations run internally in the
/// mathematical convention (x → +, y ↑ +, counterclockwise +). To change the
/// convention, build another object: the solver does not change.
class SignConvention {
  const SignConvention({
    this.xSign = 1,
    this.ySign = 1,
    this.momentSign = 1,
    this.termOrder = TermOrder.leftToRight,
  });

  /// Default: → positive, ↑ positive, counterclockwise positive.
  static const SignConvention standard = SignConvention();

  /// 1 = force to the right is positive, -1 = to the left.
  final int xSign;

  /// 1 = force upward is positive, -1 = downward.
  final int ySign;

  /// 1 = counterclockwise is positive, -1 = clockwise.
  final int momentSign;

  final TermOrder termOrder;

  /// Converts an internal value to the displayed sign.
  double x(double internal) => internal * xSign;
  double y(double internal) => internal * ySign;
  double moment(double internal) => internal * momentSign;

  /// Sorts [terms] by their position along x, following [termOrder].
  /// Terms at the same position keep their original order.
  List<T> orderTerms<T>(List<T> terms, double Function(T) positionX) {
    final indexed = [for (var i = 0; i < terms.length; i++) (i, terms[i])];
    final dir = termOrder == TermOrder.leftToRight ? 1 : -1;
    indexed.sort((a, b) {
      final c = positionX(a.$2).compareTo(positionX(b.$2)) * dir;
      return c != 0 ? c : a.$1.compareTo(b.$1);
    });
    return [for (final e in indexed) e.$2];
  }
}