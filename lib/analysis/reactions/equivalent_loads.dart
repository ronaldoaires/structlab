import 'dart:math' as math;
import 'dart:ui';

import 'package:structlab/domain/models/load.dart';
import 'package:structlab/domain/models/structural_model.dart';

/// What the kN/m of a distributed load is measured on.
/// The app follows FTool: kN per meter of the real member length.
enum DistributedBasis { memberLength, horizontalProjection }

const DistributedBasis distributedBasis = DistributedBasis.memberLength;

/// Resultant of a trapezoidal load (q1 at the start, q2 at the end).
/// Single formula; uniform (q, q) and triangular (0, q) / (q, 0) are special
/// cases. Returns null when q1 + q2 = 0 (no effect).
///
///   R  = (q1 + q2) · L / 2
///   x̄  = L · (q1 + 2·q2) / (3 · (q1 + q2))   (from the start)
({double force, double centroid})? trapezoidResultant(
  double q1,
  double q2,
  double length,
) {
  final sum = q1 + q2;
  if (sum.abs() < 1e-12 || length <= 0) return null;
  return (
    force: sum * length / 2,
    centroid: length * (q1 + 2 * q2) / (3 * sum),
  );
}

/// Shape of a distributed load. Decides which simple formula is shown.
enum LoadShape { rectangle, triangle, trapezoid }

/// A distributed load replaced by one concentrated force. Values are in the
/// internal convention (model coordinates, y up).
class EquivalentLoad {
  const EquivalentLoad({
    required this.loadId,
    required this.kind,
    required this.startNodeId,
    required this.endNodeId,
    required this.q1,
    required this.q2,
    required this.length,
    required this.resultant,
    required this.centroid,
    required this.point,
    required this.angleDegrees,
    required this.spanDx,
    required this.spanDy,
  });

  final int loadId;
  final LoadKind kind;
  final int startNodeId;
  final int endNodeId;
  final double q1;
  final double q2;

  /// Length used in the formula (see [distributedBasis]).
  final double length;

  /// Magnitude R (kN).
  final double resultant;

  /// Distance from the start node, along the member (m).
  final double centroid;

  /// Where R acts, in model coordinates.
  final Offset point;

  /// Direction R points to (same as the load).
  final double angleDegrees;

  /// Horizontal and vertical projections of the loaded segment, from the start
  /// node to the end node (model coordinates, y up). Used to explain the real
  /// length L with Pythagoras on inclined members.
  final double spanDx;
  final double spanDy;

  /// Horizontal leg Δx and vertical leg Δy (always positive).
  double get horizontalLeg => spanDx.abs();
  double get verticalLeg => spanDy.abs();

  /// Real length of the loaded segment: √(Δx² + Δy²).
  double get memberLength => math.sqrt(spanDx * spanDx + spanDy * spanDy);

  /// True when the segment is neither horizontal nor vertical, so its length
  /// comes from Pythagoras.
  bool get isInclined => horizontalLeg > 1e-9 && verticalLeg > 1e-9;

  /// True when the right end (larger x) is higher than the left end.
  bool get risesToRight => spanDx * spanDy > 0;

  double get fx => resultant * math.cos(angleDegrees * math.pi / 180);
  double get fy => resultant * math.sin(angleDegrees * math.pi / 180);

  /// Highest height (H) and lowest height (h), in kN/m.
  double get high => math.max(q1, q2);
  double get low => math.min(q1, q2);

  LoadShape get shape {
    if ((high - low).abs() < 1e-9) return LoadShape.rectangle;
    if (low.abs() < 1e-9) return LoadShape.triangle;
    return LoadShape.trapezoid;
  }

  /// True when the highest side is at the end node.
  bool get peakAtEnd => q2 > q1;

  /// Node on the side of the highest height.
  int get peakNodeId => peakAtEnd ? endNodeId : startNodeId;

  /// Centroid measured from the highest side, as in the textbook formulas.
  /// [centroid] is measured from the start node.
  double get centroidFromPeak => peakAtEnd ? length - centroid : centroid;
}

/// One [EquivalentLoad] for each distributed load of the model. Loads with no
/// effect (q1 + q2 = 0) or with missing nodes are skipped.
List<EquivalentLoad> equivalentLoads(StructuralModel model) {
  final result = <EquivalentLoad>[];
  for (final load in model.loads) {
    final endId = load.endNodeId;
    if (endId == null) continue;
    final a = model.nodeById(load.nodeId);
    final b = model.nodeById(endId);
    if (a == null || b == null) continue;

    final span = b.position - a.position;
    final memberLength = span.distance;
    if (memberLength == 0) continue;

    final basisLength = switch (distributedBasis) {
      DistributedBasis.memberLength => memberLength,
      DistributedBasis.horizontalProjection => span.dx.abs(),
    };

    final r = trapezoidResultant(load.q1, load.q2, basisLength);
    if (r == null) continue;

    // The centroid fraction is the same along the member in both bases.
    final alongMember = r.centroid * memberLength / basisLength;
    result.add(
      EquivalentLoad(
        loadId: load.id,
        kind: load.kind,
        startNodeId: a.id,
        endNodeId: b.id,
        q1: load.q1,
        q2: load.q2,
        length: basisLength,
        resultant: r.force,
        centroid: alongMember,
        point: a.position + span / memberLength * alongMember,
        angleDegrees: load.angleDegrees,
        spanDx: span.dx,
        spanDy: span.dy,
      ),
    );
  }
  return result;
}
