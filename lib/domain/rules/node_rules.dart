import 'dart:math' as math;
import 'dart:ui';

import 'package:structlab/core/constants.dart';
import 'package:structlab/core/geometry.dart';
import 'package:structlab/domain/models/member.dart';
import 'package:structlab/domain/models/node.dart';
import 'package:structlab/domain/models/structural_model.dart';

/// Position info of a node that sits in the middle of a straight line of
/// members.
class NodeLineInfo {
  NodeLineInfo({
    required this.left,
    required this.right,
    required this.dir,
    required this.total,
    required this.fromLeft,
    required this.minFromLeft,
    required this.maxFromLeft,
  });

  final StructuralNode left;
  final StructuralNode right;

  /// Unit vector from left to right.
  final Offset dir;
  final double total;
  final double fromLeft;
  final double minFromLeft;
  final double maxFromLeft;
}

List<StructuralMember> membersAt(StructuralModel model, int nodeId) => model
    .members
    .where((m) => m.startNodeId == nodeId || m.endNodeId == nodeId)
    .toList();

int otherEnd(StructuralMember m, int nodeId) =>
    m.startNodeId == nodeId ? m.endNodeId : m.startNodeId;

/// Orders two nodes from left to right (for a vertical member: bottom to top).
(StructuralNode, StructuralNode) orderLeftRight(
    StructuralNode a, StructuralNode b) {
  final d = b.position - a.position;
  final aIsLeft = d.dx > 1e-9 || (d.dx.abs() <= 1e-9 && d.dy > 0);
  return aIsLeft ? (a, b) : (b, a);
}

/// Walks in a straight line from [startId] (already arrived via
/// [viaMemberId]) and returns the ids of the visited nodes.
List<int> walkStraightPath(
    StructuralModel model, int startId, int viaMemberId, Offset dir) {
  final path = <int>[startId];
  var curId = startId;
  var viaId = viaMemberId;
  for (var guard = 0; guard < 1000; guard++) {
    final cur = model.nodeById(curId);
    if (cur == null) break;
    StructuralMember? next;
    var nextId = -1;
    for (final m in membersAt(model, curId)) {
      if (m.id == viaId) continue;
      final oid = otherEnd(m, curId);
      final other = model.nodeById(oid);
      if (other == null) continue;
      final d = unitVec(other.position - cur.position);
      if (cross2(d, dir).abs() < collinearTol && dot2(d, dir) > 0) {
        next = m;
        nextId = oid;
        break;
      }
    }
    if (next == null) break;
    path.add(nextId);
    viaId = next.id;
    curId = nextId;
  }
  return path;
}

/// True if nodes [aId] and [bId] are on the same straight line of members.
bool isStraightConnected(StructuralModel model, int aId, int bId) {
  final a = model.nodeById(aId);
  if (a == null) return false;
  for (final m in membersAt(model, aId)) {
    final oid = otherEnd(m, aId);
    final o = model.nodeById(oid);
    if (o == null) continue;
    final dir = unitVec(o.position - a.position);
    if (walkStraightPath(model, oid, m.id, dir).contains(bId)) return true;
  }
  return false;
}

/// Position info for a node in the middle of a straight line of members
/// (two aligned members passing through it). Null otherwise.
NodeLineInfo? nodeLineInfo(StructuralModel model, int nodeId) {
  final node = model.nodeById(nodeId);
  if (node == null) return null;
  final ms = membersAt(model, nodeId);
  for (var i = 0; i < ms.length; i++) {
    for (var j = i + 1; j < ms.length; j++) {
      final o1 = model.nodeById(otherEnd(ms[i], nodeId));
      final o2 = model.nodeById(otherEnd(ms[j], nodeId));
      if (o1 == null || o2 == null) continue;
      final d1 = unitVec(o1.position - node.position);
      final d2 = unitVec(o2.position - node.position);
      if (cross2(d1, d2).abs() >= collinearTol || dot2(d1, d2) >= 0) {
        continue;
      }
      final p1 = walkStraightPath(model, o1.id, ms[i].id, d1);
      final p2 = walkStraightPath(model, o2.id, ms[j].id, d2);
      final end1 = model.nodeById(p1.last);
      final end2 = model.nodeById(p2.last);
      if (end1 == null || end2 == null) continue;
      final (left, right) = orderLeftRight(end1, end2);
      final dir = unitVec(right.position - left.position);
      double proj(Offset pt) => dot2(pt - left.position, dir);
      final f1 = proj(o1.position);
      final f2 = proj(o2.position);
      return NodeLineInfo(
        left: left,
        right: right,
        dir: dir,
        total: (right.position - left.position).distance,
        fromLeft: proj(node.position),
        minFromLeft: math.min(f1, f2),
        maxFromLeft: math.max(f1, f2),
      );
    }
  }
  return null;
}

/// True if the member is vertical (both nodes share the same X).
bool isVerticalMember(StructuralModel model, StructuralMember m) {
  final a = model.nodeById(m.startNodeId);
  final b = model.nodeById(m.endNodeId);
  if (a == null || b == null) return false;
  return (a.position.dx - b.position.dx).abs() < 1e-6;
}

/// True if every member that reaches [nodeId] is vertical.
bool nodeOnlyVertical(StructuralModel model, int nodeId) {
  final ms = membersAt(model, nodeId);
  return ms.isNotEmpty && ms.every((m) => isVerticalMember(model, m));
}