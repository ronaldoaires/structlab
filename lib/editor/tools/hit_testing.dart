import 'dart:math' as math;
import 'dart:ui';

import 'package:structlab/core/constants.dart';
import 'package:structlab/core/geometry.dart';
import 'package:structlab/domain/models/load.dart';
import 'package:structlab/domain/models/member.dart';
import 'package:structlab/domain/models/node.dart';
import 'package:structlab/domain/models/structural_model.dart';
import 'package:structlab/editor/painting/load_geometry.dart';

/// Nearest node to [position] (model coordinates) within [tolerance] meters.
StructuralNode? nearestNode(
  StructuralModel model,
  Offset position, {
  double tolerance = 0.45,
}) {
  StructuralNode? nearest;
  var best = tolerance;
  for (final node in model.nodes) {
    final d = (node.position - position).distance;
    if (d < best) {
      nearest = node;
      best = d;
    }
  }
  return nearest;
}

/// Nearest member to [position] within [tolerance] meters.
StructuralMember? nearestMember(
  StructuralModel model,
  Offset position, {
  double tolerance = 0.28,
}) {
  StructuralMember? nearest;
  var best = tolerance;
  for (final member in model.members) {
    final start = model.nodeById(member.startNodeId)?.position;
    final end = model.nodeById(member.endNodeId)?.position;
    if (start == null || end == null) continue;
    final d = distanceToSegment(position, start, end);
    if (d < best) {
      best = d;
      nearest = member;
    }
  }
  return nearest;
}

/// Distance (meters) from [position] to the drawn arrow of a concentrated
/// load.
double distanceToConcentratedLoad(
  StructuralModel model,
  StructuralLoad load,
  Offset position,
) {
  final n = model.nodeById(load.nodeId);
  if (n == null) return double.infinity;
  final a = load.angleDegrees * math.pi / 180;
  final d = Offset(math.cos(a), math.sin(a));
  final clearance = concentratedClearancePx(load, model.loads, model.nodeById);
  final endM = (clearance > 0 ? clearance + 8 : 5) / pixelsPerMeter;
  final startM = endM + 33 / pixelsPerMeter;
  return distanceToSegment(
      position, n.position - d * endM, n.position - d * startM);
}

/// Area covered by a distributed load, in model coordinates. Null for
/// concentrated loads.
List<Offset>? loadPolygon(StructuralModel model, StructuralLoad load) {
  if (load.endNodeId == null) return null;
  final a = model.nodeById(load.nodeId)?.position;
  final b = model.nodeById(load.endNodeId!)?.position;
  if (a == null || b == null) return null;
  final ang = load.angleDegrees * math.pi / 180;
  final dir = Offset(math.cos(ang), math.sin(ang));
  final h1 = loadArrowLengthPx(load, load.q1) / pixelsPerMeter;
  final h2 = loadArrowLengthPx(load, load.q2) / pixelsPerMeter;
  return [a, b, b - dir * h2, a - dir * h1];
}