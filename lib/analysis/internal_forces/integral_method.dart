import 'dart:math' as math;
import 'dart:ui';

import 'package:structlab/analysis/internal_forces/internal_force_method.dart';
import 'package:structlab/analysis/internal_forces/internal_forces_model.dart';
import 'package:structlab/analysis/internal_forces/linear_load_fit.dart';
import 'package:structlab/analysis/internal_forces/polynomial.dart';
import 'package:structlab/analysis/naming/labels.dart';
import 'package:structlab/analysis/reactions/equivalent_loads.dart';
import 'package:structlab/analysis/reactions/reaction_solver.dart';
import 'package:structlab/core/geometry.dart';
import 'package:structlab/domain/models/node.dart';
import 'package:structlab/domain/models/structural_model.dart';
import 'package:structlab/domain/rules/node_rules.dart';

const double _eps = 1e-9;

double _clean(double v) => v.abs() < _eps ? 0.0 : v;

int _compareNames(String a, String b) =>
    a.length != b.length ? a.length.compareTo(b.length) : a.compareTo(b);

/// Method of the integrals (lecture notes):
///
/// 1. For each member, the distributed load becomes a function Q(x) with the
///    matrix method (Sarrus rule).
/// 2. V(x) = K1 + ∫Q⊥ dx, where K1 is the shear at the start of the member.
/// 3. M(x) = K2 + ∫V dx, where K2 is the moment at the start of the member.
/// 4. N(x) = K − ∫Q∥ dx (the normal of a member comes from the shear of the
///    previous one when the member turns).
///
/// K1, K2 and K are the effect, at the start node, of everything that acts
/// on the part of the structure before the member (found by cutting the
/// member). This works for any statically determinate structure without
/// closed loops, so frames with branches are supported too.
class IntegralMethod extends InternalForceMethod {
  const IntegralMethod();

  @override
  String get id => 'integral';

  @override
  InternalForcesOutcome solve(
    StructuralModel model,
    ReactionSolution reactions,
  ) {
    final members = _orient(model);
    if (members.isEmpty) {
      return const InternalForcesOutcome.failed(
        InternalForcesFailure.invalidModel,
      );
    }

    final pieces = _buildPieces(model, members);
    final baseActions = _baseActions(reactions);

    final cores = <int, _Core>{};
    for (final m in members) {
      final core = _buildCore(m, members, baseActions, pieces);
      if (core == null) {
        return const InternalForcesOutcome.failed(
          InternalForcesFailure.unsupportedStructure,
        );
      }
      cores[m.id] = core;
    }

    final labels = ModelLabels.of(model);
    final ordered = [...members]
      ..sort((a, b) => _compareNames(labels.member(a.id), labels.member(b.id)));

    return InternalForcesOutcome.success(
      InternalForcesResult(
        methodId: id,
        members: [for (final m in ordered) _finish(m, members, cores)],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Geometry
// -----------------------------------------------------------------------------

/// A member with its local axes: t from the left node to the right node,
/// n = t rotated 90° counterclockwise.
class _Oriented {
  _Oriented(this.id, this.left, this.right)
    : length = (right.position - left.position).distance,
      direction = unitVec(right.position - left.position);

  final int id;
  final StructuralNode left;
  final StructuralNode right;
  final double length;
  final Offset direction;

  Offset get normal => Offset(-direction.dy, direction.dx);
}

List<_Oriented> _orient(StructuralModel model) {
  final result = <_Oriented>[];
  for (final m in model.members) {
    final a = model.nodeById(m.startNodeId);
    final b = model.nodeById(m.endNodeId);
    if (a == null || b == null) continue;
    if ((b.position - a.position).distance < _eps) continue;
    final (left, right) = orderLeftRight(a, b);
    result.add(_Oriented(m.id, left, right));
  }
  return result;
}

// -----------------------------------------------------------------------------
// Distributed loads split by member
// -----------------------------------------------------------------------------

class _PieceData {
  const _PieceData(this.piece, this.action);

  final DistributedPiece piece;

  /// The piece as a single force (its resultant), for the equilibrium sums.
  final ExternalAction? action;
}

/// A distributed load may cover several members (it ends at nodes, not at
/// member ends), so it is cut into one piece per member. Each piece gets its
/// own Q(x) from the values of the load at the two ends of the member.
Map<int, List<_PieceData>> _buildPieces(
  StructuralModel model,
  List<_Oriented> members,
) {
  final result = <int, List<_PieceData>>{};
  for (final load in model.loads) {
    final endId = load.endNodeId;
    if (endId == null) continue;
    final a = model.nodeById(load.nodeId);
    final b = model.nodeById(endId);
    if (a == null || b == null) continue;

    final span = b.position - a.position;
    final spanLength = span.distance;
    if (spanLength < _eps) continue;
    final u = span / spanLength;
    final rad = load.angleDegrees * math.pi / 180;
    final dir = Offset(math.cos(rad), math.sin(rad));

    double q(double t) =>
        load.q1 +
        (load.q2 - load.q1) * (t / spanLength).clamp(0.0, 1.0).toDouble();

    for (final m in members) {
      final ra = m.left.position - a.position;
      final rb = m.right.position - a.position;
      if (cross2(u, ra).abs() > 0.02 || cross2(u, rb).abs() > 0.02) continue;
      final ta = dot2(ra, u);
      final tb = dot2(rb, u);
      final lo = math.min(ta, tb);
      final hi = math.max(ta, tb);
      if (lo < -0.02 || hi > spanLength + 0.02 || hi - lo < 0.01) continue;

      final fit = LinearLoadFit(xa: 0, ya: q(ta), xb: m.length, yb: q(tb));
      if (fit.ya.abs() < _eps && fit.yb.abs() < _eps) continue;

      final piece = DistributedPiece(
        loadId: load.id,
        kind: load.kind,
        length: m.length,
        angleDegrees: load.angleDegrees,
        normalFactor: _clean(dot2(dir, m.normal)),
        tangentialFactor: _clean(dot2(dir, m.direction)),
        fit: fit,
      );

      final r = trapezoidResultant(fit.ya, fit.yb, m.length);
      final action = r == null
          ? null
          : ExternalAction(
              kind: ExternalActionKind.distributed,
              nodeId: m.left.id,
              memberId: m.id,
              loadId: load.id,
              point: m.left.position + m.direction * r.centroid,
              fx: _clean(r.force * dir.dx),
              fy: _clean(r.force * dir.dy),
            );
      (result[m.id] ??= []).add(_PieceData(piece, action));
    }
  }
  return result;
}

// -----------------------------------------------------------------------------
// Free bodies
// -----------------------------------------------------------------------------

/// Reactions, concentrated loads and applied moments.
List<ExternalAction> _baseActions(ReactionSolution solution) => [
  for (final r in solution.reactions)
    ExternalAction(
      kind: ExternalActionKind.reaction,
      nodeId: r.nodeId,
      point: r.point,
      fx: r.fx,
      fy: r.fy,
      moment: r.kind == ReactionKind.moment ? r.value : 0,
      reaction: r,
    ),
  for (final a in solution.actions)
    if (a.kind != ActionKind.distributed)
      ExternalAction(
        kind: a.kind == ActionKind.moment
            ? ExternalActionKind.moment
            : ExternalActionKind.concentrated,
        nodeId: a.nodeId,
        point: a.point,
        fx: a.fx,
        fy: a.fy,
        moment: a.moment,
        loadId: a.loadId,
      ),
];

/// Nodes on the start side of [m] when [m] is cut. Null if the other end of
/// the member is reachable some other way (closed loop).
Set<int>? _startSide(List<_Oriented> members, _Oriented m) {
  final reached = <int>{m.left.id};
  final queue = [m.left.id];
  while (queue.isNotEmpty) {
    final id = queue.removeLast();
    for (final o in members) {
      if (o.id == m.id) continue;
      final int next;
      if (o.left.id == id) {
        next = o.right.id;
      } else if (o.right.id == id) {
        next = o.left.id;
      } else {
        continue;
      }
      if (reached.add(next)) queue.add(next);
    }
  }
  return reached.contains(m.right.id) ? null : reached;
}

/// Moves an action to the start node of [m] and writes it in local axes.
StartContribution _project(ExternalAction a, _Oriented m) {
  final force = Offset(a.fx, a.fy);
  final r = a.point - m.left.position;
  final moment = a.moment + (r.dx * a.fy - r.dy * a.fx);
  return StartContribution(
    action: a,
    tangential: _clean(dot2(force, m.direction)),
    normal: _clean(dot2(force, m.normal)),
    moment: _clean(moment),
  );
}

class _Core {
  const _Core({
    required this.member,
    required this.contributions,
    required this.pieces,
    required this.tangential,
    required this.normal,
    required this.moment,
  });

  final _Oriented member;

  /// Everything on the start side, in local axes.
  final List<StartContribution> contributions;
  final List<DistributedPiece> pieces;

  /// Totals at the start node: Ft, Fn and Mz (counterclockwise).
  final double tangential;
  final double normal;
  final double moment;

  double get startNormal => _clean(-tangential);
  double get startShear => normal;
  double get startMoment => _clean(-moment);

  Polynomial get _loadNormal =>
      pieces.fold(Polynomial.zero, (s, p) => s + p.normalLoad);
  Polynomial get _loadTangential =>
      pieces.fold(Polynomial.zero, (s, p) => s + p.tangentialLoad);

  /// N, V and M at the end of the member.
  ({double n, double v, double m}) endValues() {
    final shear = _loadNormal.integral().withConstant(startShear);
    final moment = shear.integral().withConstant(startMoment);
    final normal = _loadTangential
        .integral()
        .scaled(-1)
        .withConstant(startNormal);
    final x = member.length;
    return (n: normal.at(x), v: shear.at(x), m: moment.at(x));
  }
}

_Core? _buildCore(
  _Oriented m,
  List<_Oriented> members,
  List<ExternalAction> base,
  Map<int, List<_PieceData>> pieces,
) {
  final side = _startSide(members, m);
  if (side == null) return null;

  final actions = <ExternalAction>[
    for (final a in base)
      if (side.contains(a.nodeId)) a,
    for (final o in members)
      if (o.id != m.id && side.contains(o.left.id))
        for (final p in pieces[o.id] ?? const <_PieceData>[])
          if (p.action != null) p.action!,
  ];

  final contributions = [for (final a in actions) _project(a, m)];
  var ft = 0.0, fn = 0.0, mz = 0.0;
  for (final c in contributions) {
    ft += c.tangential;
    fn += c.normal;
    mz += c.moment;
  }

  return _Core(
    member: m,
    contributions: contributions,
    pieces: [for (final p in pieces[m.id] ?? const <_PieceData>[]) p.piece],
    tangential: _clean(ft),
    normal: _clean(fn),
    moment: _clean(mz),
  );
}

/// Builds the final result of [m]. When a single member arrives at its start
/// node, the start values are explained as coming from the end of that
/// member (the way it is done by hand); otherwise they are listed as the
/// actions of the whole part before the member.
MemberInternalForces _finish(
  _Oriented m,
  List<_Oriented> members,
  Map<int, _Core> cores,
) {
  final core = cores[m.id]!;
  final s = m.left.id;

  final touching = [
    for (final o in members)
      if (o.id != m.id && (o.left.id == s || o.right.id == s)) o,
  ];

  PreviousMemberTransfer? previous;
  var contributions = core.contributions;

  if (touching.length == 1 && touching.first.right.id == s) {
    final p = touching.first;
    final end = cores[p.id]!.endValues();

    // What the part before the node pushes with, in global axes.
    final global = p.direction * (-end.n) + p.normal * end.v;
    final turn =
        math.atan2(
          cross2(p.direction, m.direction),
          dot2(p.direction, m.direction),
        ) *
        180 /
        math.pi;

    previous = PreviousMemberTransfer(
      memberId: p.id,
      endNormal: _clean(end.n),
      endShear: _clean(end.v),
      endMoment: _clean(end.m),
      angleDegrees: turn.abs() < 1e-6 ? 0.0 : turn,
      tangential: _clean(dot2(global, m.direction)),
      normal: _clean(dot2(global, m.normal)),
      moment: _clean(-end.m),
    );
    contributions = [
      for (final c in core.contributions)
        if (c.action.nodeId == s &&
            c.action.kind != ExternalActionKind.distributed)
          c,
    ];
  }

  return MemberInternalForces(
    memberId: m.id,
    startNodeId: m.left.id,
    endNodeId: m.right.id,
    length: m.length,
    angleDegrees: math.atan2(m.direction.dy, m.direction.dx) * 180 / math.pi,
    vertical: m.direction.dx.abs() < 1e-6,
    contributions: contributions,
    previous: previous,
    pieces: core.pieces,
    startNormal: core.startNormal,
    startShear: core.startShear,
    startMoment: core.startMoment,
  );
}
