import 'dart:math' as math;

import 'package:structlab/core/geometry.dart';
import 'package:structlab/domain/models/load.dart';
import 'package:structlab/domain/models/node.dart';
import 'package:structlab/domain/models/structural_model.dart';

/// Directions tried (in order) when adding a concentrated load to a node.
/// -90 = downward, 90 = upward, 0 = pointing right, 180 = pointing left.
const List<double> concentratedDefaultAngles = [-90, 90, 0, 180];

/// True if two angles (degrees) point to the same direction.
bool sameDirection(double a, double b) {
  final diff = ((a - b) % 360 + 360) % 360;
  return diff < 0.5 || diff > 359.5;
}

/// True if [nodeId] already has a concentrated load pointing to [angle].
/// Use [ignoreId] to skip the load being edited.
bool concentratedConflict(
  List<StructuralLoad> loads,
  int nodeId,
  double angle, {
  int? ignoreId,
}) {
  return loads.any((l) =>
      l.kind == LoadKind.concentrated &&
      l.nodeId == nodeId &&
      l.id != ignoreId &&
      sameDirection(l.angleDegrees, angle));
}

/// First default direction not yet used by a concentrated load at [nodeId].
/// Returns null when all default directions are taken.
double? firstFreeConcentratedAngle(List<StructuralLoad> loads, int nodeId) {
  for (final angle in concentratedDefaultAngles) {
    if (!concentratedConflict(loads, nodeId, angle)) return angle;
  }
  return null;
}

/// True if the span [a]-[b] overlaps (with length greater than zero) the span
/// of an existing distributed load [other]. Spans that only touch at a node
/// do not count as overlap.
bool distributedOverlap(
  StructuralModel model,
  StructuralNode a,
  StructuralNode b,
  StructuralLoad other,
) {
  final endId = other.endNodeId;
  if (endId == null) return false;
  final o1 = model.nodeById(other.nodeId);
  final o2 = model.nodeById(endId);
  if (o1 == null || o2 == null) return false;

  final va = b.position - a.position;
  final lenA = va.distance;
  if (lenA == 0) return false;
  final dir = va / lenA;

  // Both ends of the other load must lie on the same line.
  final off1 = cross2(dir, o1.position - a.position).abs();
  final off2 = cross2(dir, o2.position - a.position).abs();
  if (off1 > 0.02 || off2 > 0.02) return false;

  final t1 = dot2(o1.position - a.position, dir);
  final t2 = dot2(o2.position - a.position, dir);
  final lo = math.min(t1, t2);
  final hi = math.max(t1, t2);
  final overlap = math.min(hi, lenA) - math.max(lo, 0.0);
  return overlap > 0.01;
}