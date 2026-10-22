import 'dart:math' as math;

double _round(double v) => (v * 1e6).round() / 1e6;

/// Which points of a member are listed in the results: from [from] to [to]
/// (null = end of the member) every [step] meters.
class SamplingConfig {
  const SamplingConfig({this.from = 0, this.to, this.step = 1});

  final double from;
  final double? to;
  final double step;

  /// Default: the whole member, every 1 m.
  static const SamplingConfig standard = SamplingConfig();

  /// Safety cap so a tiny step never freezes the screen.
  static const int maxPoints = 400;

  /// Positions (m, measured from the start of the member). The last point
  /// of the range is always included, even when the step does not fit.
  List<double> points(double length) {
    final end = math.min(to ?? length, length);
    final start = math.max(0.0, math.min(from, end));
    final span = end - start;
    if (span < 1e-9 || step <= 0) return [_round(start)];

    final effectiveStep = math.max(step, span / maxPoints);
    final count = (span / effectiveStep + 1e-9).floor();
    final result = [
      for (var i = 0; i <= count; i++) _round(start + i * effectiveStep),
    ];
    if ((end - result.last).abs() > 1e-6) result.add(_round(end));
    return result;
  }
}