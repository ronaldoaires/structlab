import 'dart:math' as math;
import 'dart:ui';

import 'package:structlab/core/constants.dart';
import 'package:structlab/domain/models/load.dart';
import 'package:structlab/domain/models/node.dart';

/// Radius (px) of the arc that draws an applied moment.
const double momentRadiusPx = 28;

/// Arrow length (in px) of a load for intensity [q].
double loadArrowLengthPx(StructuralLoad load, double q) {
  final maxQ = math.max(load.q1.abs(), load.q2.abs());
  if (maxQ <= 0) return 0;
  return loadBasePx * q.abs() / maxQ;
}

/// Direction the load points to, in screen coordinates (y grows downward).
Offset loadScreenDir(StructuralLoad load) {
  final a = load.angleDegrees * math.pi / 180;
  return Offset(math.cos(a), -math.sin(a));
}

/// Height (px) taken up by distributed loads under the node of a concentrated
/// load. The concentrated arrow is drawn above this height.
double concentratedClearancePx(
  StructuralLoad load,
  List<StructuralLoad> loads,
  StructuralNode? Function(int id) nodeById,
) {
  final node = nodeById(load.nodeId);
  if (node == null) return 0;
  final ang = load.angleDegrees * math.pi / 180;
  final dirModel = Offset(math.cos(ang), math.sin(ang));
  var clearance = 0.0;

  for (final other in loads) {
    final endId = other.endNodeId;
    if (endId == null) continue;
    final a = nodeById(other.nodeId)?.position;
    final b = nodeById(endId)?.position;
    if (a == null || b == null) continue;
    final span = b - a;
    final len = span.distance;
    if (len == 0) continue;
    final u = span / len;
    final rel = node.position - a;
    if ((u.dx * rel.dy - u.dy * rel.dx).abs() > 0.02) continue;
    final t = u.dx * rel.dx + u.dy * rel.dy;
    if (t < -0.02 || t > len + 0.02) continue;

    final f = (t / len).clamp(0.0, 1.0);
    final px = loadArrowLengthPx(other, other.q1 + (other.q2 - other.q1) * f);
    if (px < 4) continue;

    final oa = other.angleDegrees * math.pi / 180;
    final along = math.cos(oa) * dirModel.dx + math.sin(oa) * dirModel.dy;
    if (along <= 0) continue;
    clearance = math.max(clearance, (px + 3) * along);
  }
  return clearance;
}
