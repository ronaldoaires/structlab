import 'package:structlab/core/geometry.dart';
import 'package:structlab/domain/catalog/support_catalog.dart';
import 'package:structlab/domain/models/member.dart';
import 'package:structlab/domain/models/structural_model.dart';
import 'package:structlab/domain/models/support.dart';
import 'package:structlab/domain/rules/node_rules.dart';
import 'package:structlab/domain/validation/validation_report.dart';

/// Checks whether [model] can be handed to the solver (2D frames and beams
/// with rigid joints). Pure function: no UI, no state.
ValidationReport validateStructure(StructuralModel model) {
  final issues = <ValidationIssue>[];

  // Members whose two nodes exist.
  final members = model.members
      .where(
        (m) =>
            model.nodeById(m.startNodeId) != null &&
            model.nodeById(m.endNodeId) != null,
      )
      .toList();

  if (members.isEmpty) {
    issues.add(
      const ValidationIssue(
        code: IssueCode.noMembers,
        severity: IssueSeverity.error,
      ),
    );
    return ValidationReport(issues: issues, staticity: Staticity.unknown);
  }

  // --- Connectivity (union-find over the nodes that have members) ----------
  final parent = <int, int>{};
  int find(int x) {
    while (parent[x] != x) {
      parent[x] = parent[parent[x]!]!;
      x = parent[x]!;
    }
    return x;
  }

  for (final m in members) {
    parent.putIfAbsent(m.startNodeId, () => m.startNodeId);
    parent.putIfAbsent(m.endNodeId, () => m.endNodeId);
  }
  for (final m in members) {
    parent[find(m.startNodeId)] = find(m.endNodeId);
  }

  // --- Loose nodes ----------------------------------------------------------
  for (final node in model.nodes) {
    if (parent.containsKey(node.id)) continue;
    final attached =
        model.supports.any((s) => s.nodeId == node.id) ||
        model.loads.any((l) => l.nodeId == node.id || l.endNodeId == node.id);
    issues.add(
      ValidationIssue(
        code: IssueCode.looseNode,
        severity: attached ? IssueSeverity.error : IssueSeverity.warning,
        nodeIds: [node.id],
      ),
    );
  }

  // --- Disconnected parts ---------------------------------------------------
  final memberCountByRoot = <int, int>{};
  for (final m in members) {
    final root = find(m.startNodeId);
    memberCountByRoot[root] = (memberCountByRoot[root] ?? 0) + 1;
  }
  final partCount = memberCountByRoot.length;
  if (partCount > 1) {
    final biggest = memberCountByRoot.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
    issues.add(
      ValidationIssue(
        code: IssueCode.disconnected,
        severity: IssueSeverity.error,
        memberIds: [
          for (final m in members)
            if (find(m.startNodeId) != biggest) m.id,
        ],
        args: [partCount],
      ),
    );
  }

  // --- Crossings and nodes sitting on a member ------------------------------
  _checkGeometry(model, members, issues);

  // --- Supports and loads ---------------------------------------------------
  if (model.supports.isEmpty) {
    issues.add(
      const ValidationIssue(
        code: IssueCode.noSupports,
        severity: IssueSeverity.error,
      ),
    );
  }
  if (model.loads.isEmpty) {
    issues.add(
      const ValidationIssue(
        code: IssueCode.noLoads,
        severity: IssueSeverity.warning,
      ),
    );
  }
  for (final load in model.loads) {
    final endId = load.endNodeId;
    if (endId != null &&
        model.nodeById(load.nodeId) != null &&
        model.nodeById(endId) != null &&
        !isStraightConnected(model, load.nodeId, endId)) {
      issues.add(
        ValidationIssue(
          code: IssueCode.invalidDistributedLoad,
          severity: IssueSeverity.error,
          nodeIds: [load.nodeId, endId],
        ),
      );
    }
    if (load.q1 == 0 && load.q2 == 0) {
      issues.add(
        ValidationIssue(
          code: IssueCode.zeroLoad,
          severity: IssueSeverity.warning,
          nodeIds: [load.nodeId, ?endId],
        ),
      );
    }
  }

  // --- Staticity (only for a single connected structure) --------------------
  if (partCount != 1) {
    return ValidationReport(issues: issues, staticity: Staticity.unknown);
  }

  final cells = members.length - parent.length + 1; // closed loops
  final cols = <List<double>>[]; // equilibrium matrix columns [Fx, Fy, M]
  final supportNodeIds = <int>[];
  var reactions = 0;

  for (final s in model.supports) {
    final node = model.nodeById(s.nodeId);
    if (node == null || !parent.containsKey(node.id)) continue;
    supportNodeIds.add(node.id);
    reactions += supportSpec(s.type).reactionCount;
    final x = node.position.dx;
    final y = node.position.dy;
    // Moment about the origin of a force at (x, y): M = x*Fy - y*Fx.
    final fx = [1.0, 0.0, -y];
    final fy = [0.0, 1.0, x];
    final mz = [0.0, 0.0, 1.0];
    switch (s.type) {
      case SupportType.fixed:
        cols
          ..add(fx)
          ..add(fy)
          ..add(mz);
      case SupportType.pin:
        cols
          ..add(fx)
          ..add(fy);
      case SupportType.roller:
        cols.add(restrainsVertical(s) ? fy : fx);
    }
  }

  if (supportNodeIds.isEmpty) {
    // "No supports" is already reported above.
    return ValidationReport(
      issues: issues,
      staticity: Staticity.hypostatic,
      reactions: 0,
    );
  }

  if (_rank3(cols) < 3) {
    issues.add(
      ValidationIssue(
        code: reactions < 3
            ? IssueCode.hypostaticCount
            : IssueCode.unstableGeometry,
        severity: IssueSeverity.error,
        nodeIds: supportNodeIds,
        args: [reactions],
      ),
    );
    return ValidationReport(
      issues: issues,
      staticity: Staticity.hypostatic,
      reactions: reactions,
    );
  }

  // Degree of hyperstaticity of a plane frame with rigid joints:
  // g = r + 3c - 3 (hinges, when they exist, will subtract here).
  final degree = reactions + 3 * cells - 3;
  return ValidationReport(
    issues: issues,
    staticity: degree == 0 ? Staticity.isostatic : Staticity.hyperstatic,
    degree: degree,
    reactions: reactions,
  );
}

void _checkGeometry(
  StructuralModel model,
  List<StructuralMember> members,
  List<ValidationIssue> issues,
) {
  // Members crossing each other with no shared node.
  for (var i = 0; i < members.length; i++) {
    for (var j = i + 1; j < members.length; j++) {
      final a = members[i];
      final b = members[j];
      if (a.startNodeId == b.startNodeId ||
          a.startNodeId == b.endNodeId ||
          a.endNodeId == b.startNodeId ||
          a.endNodeId == b.endNodeId) {
        continue;
      }
      final p1 = model.nodeById(a.startNodeId)!.position;
      final p2 = model.nodeById(a.endNodeId)!.position;
      final q1 = model.nodeById(b.startNodeId)!.position;
      final q2 = model.nodeById(b.endNodeId)!.position;
      final d1 = cross2(p2 - p1, q1 - p1);
      final d2 = cross2(p2 - p1, q2 - p1);
      final d3 = cross2(q2 - q1, p1 - q1);
      final d4 = cross2(q2 - q1, p2 - q1);
      if (d1 * d2 < 0 && d3 * d4 < 0) {
        issues.add(
          ValidationIssue(
            code: IssueCode.crossingMembers,
            severity: IssueSeverity.warning,
            memberIds: [a.id, b.id],
          ),
        );
      }
    }
  }

  // A node on top of a member that it does not belong to.
  for (final m in members) {
    final a = model.nodeById(m.startNodeId)!.position;
    final b = model.nodeById(m.endNodeId)!.position;
    for (final n in model.nodes) {
      if (n.id == m.startNodeId || n.id == m.endNodeId) continue;
      if (distanceToSegment(n.position, a, b) < 0.02) {
        issues.add(
          ValidationIssue(
            code: IssueCode.nodeOnMember,
            severity: IssueSeverity.warning,
            nodeIds: [n.id],
            memberIds: [m.id],
          ),
        );
      }
    }
  }
}

/// Rank of a matrix with 3 rows, given by its columns (Gaussian elimination).
/// Rank 3 means the reactions can resist any load on a rigid body.
int _rank3(List<List<double>> cols) {
  final n = cols.length;
  final m = [
    for (var i = 0; i < 3; i++) [for (final c in cols) c[i]],
  ];
  var rank = 0;
  for (var col = 0; col < n && rank < 3; col++) {
    var pivot = rank;
    for (var r = rank + 1; r < 3; r++) {
      if (m[r][col].abs() > m[pivot][col].abs()) pivot = r;
    }
    if (m[pivot][col].abs() < 1e-7) continue;
    final tmp = m[rank];
    m[rank] = m[pivot];
    m[pivot] = tmp;
    for (var r = rank + 1; r < 3; r++) {
      final f = m[r][col] / m[rank][col];
      for (var k = col; k < n; k++) {
        m[r][k] -= f * m[rank][k];
      }
    }
    rank++;
  }
  return rank;
}
