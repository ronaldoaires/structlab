import 'dart:math' as math;
import 'dart:ui';

import 'package:structlab/analysis/naming/labels.dart';
import 'package:structlab/analysis/reactions/equivalent_loads.dart';
import 'package:structlab/domain/catalog/support_catalog.dart';
import 'package:structlab/domain/models/load.dart';
import 'package:structlab/domain/models/structural_model.dart';
import 'package:structlab/domain/models/support.dart';
import 'package:structlab/domain/validation/structure_validator.dart';
import 'package:structlab/domain/validation/validation_report.dart';

// All values here are in the INTERNAL convention: x → +, y ↑ +,
// counterclockwise +. The SignConvention only changes how they are shown.

/// Moment (counterclockwise +) about [pivot] of a force (fx, fy) applied at
/// [at]:  M = dx·fy − dy·fx.
double forceMoment(Offset at, double fx, double fy, Offset pivot) =>
    (at.dx - pivot.dx) * fy - (at.dy - pivot.dy) * fx;

enum ReactionKind { fx, fy, moment }

/// One support reaction (a single unknown of the problem).
class Reaction {
  const Reaction({
    required this.supportId,
    required this.nodeId,
    required this.point,
    required this.kind,
    required this.value,
  });

  final int supportId;
  final int nodeId;
  final Offset point;
  final ReactionKind kind;

  /// Positive = in the positive internal direction (→, ↑ or counterclockwise).
  final double value;

  double get fx => kind == ReactionKind.fx ? value : 0;
  double get fy => kind == ReactionKind.fy ? value : 0;

  double momentAbout(Offset pivot) => kind == ReactionKind.moment
      ? value
      : forceMoment(point, fx, fy, pivot);
}

enum ActionKind { concentrated, moment, distributed }

/// A load reduced to what the equilibrium equations need: a force (fx, fy)
/// at a point, plus a pure moment. A distributed load becomes its resultant.
class AppliedAction {
  const AppliedAction({
    required this.loadId,
    required this.kind,
    required this.nodeId,
    required this.point,
    this.fx = 0,
    this.fy = 0,
    this.moment = 0,
    this.equivalent,
  });

  final int loadId;
  final ActionKind kind;

  /// Concentrated/moment: application node. Distributed: start node.
  final int nodeId;
  final Offset point;
  final double fx;
  final double fy;
  final double moment;

  /// Only for distributed loads (R, centroid...), used by the step by step.
  final EquivalentLoad? equivalent;

  double momentAbout(Offset pivot) =>
      forceMoment(point, fx, fy, pivot) + moment;
}

class ReactionSolution {
  const ReactionSolution({required this.reactions, required this.actions});

  /// Ordered by node name (A, B, C...).
  final List<Reaction> reactions;
  final List<AppliedAction> actions;

  double get sumFx =>
      actions.fold(0.0, (s, a) => s + a.fx) +
      reactions.fold(0.0, (s, r) => s + r.fx);

  double get sumFy =>
      actions.fold(0.0, (s, a) => s + a.fy) +
      reactions.fold(0.0, (s, r) => s + r.fy);

  /// Sum of all moments about [pivot]. Zero when the structure is in
  /// equilibrium: this is the check shown at the end of the step by step.
  double momentAbout(Offset pivot) =>
      actions.fold(0.0, (s, a) => s + a.momentAbout(pivot)) +
      reactions.fold(0.0, (s, r) => s + r.momentAbout(pivot));
}

enum SolveFailure {
  /// The validation has errors (no supports, loose nodes...).
  invalidModel,
  hypostatic,

  /// Needs the stiffness method.
  hyperstatic,

  /// Numerical problem (should not happen after validation).
  singular,
}

class ReactionOutcome {
  const ReactionOutcome.success(ReactionSolution this.solution)
      : failure = null;
  const ReactionOutcome.failed(SolveFailure this.failure) : solution = null;

  final ReactionSolution? solution;
  final SolveFailure? failure;

  bool get isOk => solution != null;
}

class _Unknown {
  const _Unknown(this.supportId, this.nodeId, this.point, this.kind);

  final int supportId;
  final int nodeId;
  final Offset point;
  final ReactionKind kind;
}

double _clean(double v) => v.abs() < 1e-9 ? 0.0 : v;

/// Calculates the support reactions of a statically determinate structure.
/// Pure function: no UI, no strings.
ReactionOutcome solveReactions(StructuralModel model) {
  final report = validateStructure(model);
  if (report.hasErrors) {
    return const ReactionOutcome.failed(SolveFailure.invalidModel);
  }
  switch (report.staticity) {
    case Staticity.isostatic:
      break;
    case Staticity.hyperstatic:
      return const ReactionOutcome.failed(SolveFailure.hyperstatic);
    case Staticity.hypostatic:
      return const ReactionOutcome.failed(SolveFailure.hypostatic);
    case Staticity.unknown:
      return const ReactionOutcome.failed(SolveFailure.invalidModel);
  }

  final actions = _buildActions(model);
  final unknowns = _buildUnknowns(model);
  if (unknowns.length != 3) {
    return const ReactionOutcome.failed(SolveFailure.singular);
  }

  // Equilibrium about the origin: rows = ΣFx, ΣFy, ΣM; columns = unknowns.
  const pivot = Offset.zero;
  final a = [
    for (var row = 0; row < 3; row++)
      [
        for (final u in unknowns)
          switch ((row, u.kind)) {
            (0, ReactionKind.fx) => 1.0,
            (1, ReactionKind.fy) => 1.0,
            (2, ReactionKind.fx) => forceMoment(u.point, 1, 0, pivot),
            (2, ReactionKind.fy) => forceMoment(u.point, 0, 1, pivot),
            (2, ReactionKind.moment) => 1.0,
            _ => 0.0,
          },
      ],
  ];
  final b = [
    -actions.fold(0.0, (s, x) => s + x.fx),
    -actions.fold(0.0, (s, x) => s + x.fy),
    -actions.fold(0.0, (s, x) => s + x.momentAbout(pivot)),
  ];

  final x = _solve3(a, b);
  if (x == null) return const ReactionOutcome.failed(SolveFailure.singular);

  return ReactionOutcome.success(ReactionSolution(
    reactions: [
      for (var i = 0; i < unknowns.length; i++)
        Reaction(
          supportId: unknowns[i].supportId,
          nodeId: unknowns[i].nodeId,
          point: unknowns[i].point,
          kind: unknowns[i].kind,
          value: _clean(x[i]),
        ),
    ],
    actions: actions,
  ));
}

List<AppliedAction> _buildActions(StructuralModel model) {
  final equivalents = {
    for (final e in equivalentLoads(model)) e.loadId: e,
  };
  final result = <AppliedAction>[];
  for (final load in model.loads) {
    final node = model.nodeById(load.nodeId);
    if (node == null) continue;
    switch (load.kind) {
      case LoadKind.concentrated:
        final rad = load.angleDegrees * math.pi / 180;
        result.add(AppliedAction(
          loadId: load.id,
          kind: ActionKind.concentrated,
          nodeId: node.id,
          point: node.position,
          fx: _clean(load.q1 * math.cos(rad)),
          fy: _clean(load.q1 * math.sin(rad)),
        ));
      case LoadKind.moment:
        result.add(AppliedAction(
          loadId: load.id,
          kind: ActionKind.moment,
          nodeId: node.id,
          point: node.position,
          moment: load.q1,
        ));
      case LoadKind.uniform:
      case LoadKind.triangular:
      case LoadKind.trapezoidal:
        final eq = equivalents[load.id];
        if (eq == null) continue;
        result.add(AppliedAction(
          loadId: load.id,
          kind: ActionKind.distributed,
          nodeId: node.id,
          point: eq.point,
          fx: _clean(eq.fx),
          fy: _clean(eq.fy),
          equivalent: eq,
        ));
    }
  }
  return result;
}

List<_Unknown> _buildUnknowns(StructuralModel model) {
  final labels = ModelLabels.of(model);
  // Node names grow by length, then alphabetically (A..Z, AA, AB...).
  int byName(int a, int b) {
    final la = labels.node(a);
    final lb = labels.node(b);
    return la.length != lb.length
        ? la.length.compareTo(lb.length)
        : la.compareTo(lb);
  }

  final supports = [...model.supports]
    ..sort((s, t) => byName(s.nodeId, t.nodeId));

  final result = <_Unknown>[];
  for (final s in supports) {
    final node = model.nodeById(s.nodeId);
    if (node == null) continue;
    _Unknown u(ReactionKind k) => _Unknown(s.id, node.id, node.position, k);
    switch (s.type) {
      case SupportType.fixed:
        result
          ..add(u(ReactionKind.fx))
          ..add(u(ReactionKind.fy))
          ..add(u(ReactionKind.moment));
      case SupportType.pin:
        result
          ..add(u(ReactionKind.fx))
          ..add(u(ReactionKind.fy));
      case SupportType.roller:
        result.add(u(restrainsVertical(s) ? ReactionKind.fy : ReactionKind.fx));
    }
  }
  return result;
}

/// Gaussian elimination with partial pivoting. Null if singular.
List<double>? _solve3(List<List<double>> a, List<double> b) {
  const n = 3;
  final m = [
    for (var i = 0; i < n; i++) [...a[i], b[i]],
  ];
  for (var col = 0; col < n; col++) {
    var pivot = col;
    for (var r = col + 1; r < n; r++) {
      if (m[r][col].abs() > m[pivot][col].abs()) pivot = r;
    }
    if (m[pivot][col].abs() < 1e-9) return null;
    final tmp = m[col];
    m[col] = m[pivot];
    m[pivot] = tmp;
    for (var r = col + 1; r < n; r++) {
      final f = m[r][col] / m[col][col];
      for (var k = col; k <= n; k++) {
        m[r][k] -= f * m[col][k];
      }
    }
  }
  final x = List<double>.filled(n, 0);
  for (var i = n - 1; i >= 0; i--) {
    var s = m[i][n];
    for (var k = i + 1; k < n; k++) {
      s -= m[i][k] * x[k];
    }
    x[i] = s / m[i][i];
  }
  return x;
}