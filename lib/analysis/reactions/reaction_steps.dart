import 'dart:ui';

import 'package:structlab/analysis/conventions/sign_convention.dart';
import 'package:structlab/analysis/naming/labels.dart';
import 'package:structlab/analysis/reactions/equivalent_loads.dart';
import 'package:structlab/analysis/reactions/reaction_solver.dart';
import 'package:structlab/domain/models/structural_model.dart';

// The step by step as PURE DATA (no strings). The texts are built in
// l10n/strings_reactions_pt.dart. Values are in the internal convention.

const double _eps = 1e-9;

enum TermSource { concentrated, moment, distributed, reaction }

enum EquationKind { sumFx, sumFy, sumMoment }

/// One line of an equation.
///
/// Known term:   factor · arm = value   (arm is null when there is no lever
///               arm: force equations and pure moments; then value = factor).
/// Unknown term: [isUnknown] = true; [value] is the coefficient that
///               multiplies the unknown reaction ([arm], or 1).
class EquationTerm {
  const EquationTerm({
    required this.source,
    required this.component,
    required this.nodeId,
    required this.positionX,
    required this.value,
    this.endNodeId,
    this.factor,
    this.arm,
    this.reaction,
    this.isUnknown = false,
    this.decomposed = false,
  });

  final TermSource source;

  /// Which component of the force (fx / fy) or a moment.
  final ReactionKind component;

  /// Application node (distributed: start node; reaction: support node).
  final int nodeId;

  /// Distributed loads only: end node.
  final int? endNodeId;

  /// X of the application point (used to order the terms).
  final double positionX;

  final double? factor;
  final double? arm;
  final double value;

  /// Reaction terms only.
  final Reaction? reaction;
  final bool isUnknown;

  /// True when the load was split into Fx and Fy (inclined load).
  final bool decomposed;
}

sealed class ReactionStep {
  const ReactionStep();
}

/// Names of nodes and members, in order.
class NamesStep extends ReactionStep {
  const NamesStep({required this.nodeIds, required this.memberIds});
  final List<int> nodeIds;
  final List<int> memberIds;
}

/// Distributed loads replaced by their resultant. Only when they exist.
class EquivalentLoadsStep extends ReactionStep {
  const EquivalentLoadsStep(this.loads);
  final List<EquivalentLoad> loads;
}

/// Inclined forces split into Fx and Fy. Only when they exist.
class DecompositionStep extends ReactionStep {
  const DecompositionStep(this.actions);
  final List<AppliedAction> actions;
}

/// The unknown reactions (their values are not solved yet at this point).
class UnknownsStep extends ReactionStep {
  const UnknownsStep(this.reactions);
  final List<Reaction> reactions;
}

/// One equilibrium equation with exactly one unknown left to solve.
class EquationStep extends ReactionStep {
  const EquationStep({
    required this.kind,
    required this.terms,
    required this.solved,
    required this.coefficient,
    required this.knownSum,
    this.pivotNodeId,
  });

  final EquationKind kind;

  /// Only for [EquationKind.sumMoment].
  final int? pivotNodeId;
  final List<EquationTerm> terms;

  /// The reaction solved by this equation (with its value).
  final Reaction solved;

  /// coefficient · unknown + knownSum = 0
  final double coefficient;
  final double knownSum;

  double get result => solved.value;
}

/// Moment equilibrium about another point: must be zero.
class CheckStep extends ReactionStep {
  const CheckStep({
    required this.pivotNodeId,
    required this.terms,
    required this.sum,
  });
  final int pivotNodeId;
  final List<EquationTerm> terms;
  final double sum;
}

class SummaryStep extends ReactionStep {
  const SummaryStep(this.reactions);
  final List<Reaction> reactions;
}

int _compareNames(String a, String b) =>
    a.length != b.length ? a.length.compareTo(b.length) : a.compareTo(b);

double _clean(double v) => v.abs() < _eps ? 0.0 : v;

({bool applies, double? arm}) _arm(
  EquationKind kind,
  ReactionKind comp,
  Offset at,
  Offset? pivot,
) {
  switch (kind) {
    case EquationKind.sumFx:
      return (applies: comp == ReactionKind.fx, arm: null);
    case EquationKind.sumFy:
      return (applies: comp == ReactionKind.fy, arm: null);
    case EquationKind.sumMoment:
      final p = pivot!;
      switch (comp) {
        case ReactionKind.fx:
          return (applies: true, arm: -(at.dy - p.dy));
        case ReactionKind.fy:
          return (applies: true, arm: at.dx - p.dx);
        case ReactionKind.moment:
          return (applies: true, arm: null);
      }
  }
}

List<EquationTerm> _terms(
  EquationKind kind,
  Offset? pivot,
  List<AppliedAction> actions,
  List<Reaction> reactions,
  List<double?> values,
) {
  final terms = <EquationTerm>[];

  for (final a in actions) {
    final decomposed = a.fx.abs() > _eps && a.fy.abs() > _eps;
    final source = switch (a.kind) {
      ActionKind.concentrated => TermSource.concentrated,
      ActionKind.moment => TermSource.moment,
      ActionKind.distributed => TermSource.distributed,
    };
    for (final (comp, f) in [
      (ReactionKind.fx, a.fx),
      (ReactionKind.fy, a.fy),
      (ReactionKind.moment, a.moment),
    ]) {
      if (f.abs() < _eps) continue;
      final m = _arm(kind, comp, a.point, pivot);
      if (!m.applies) continue;
      final value = m.arm == null ? f : f * m.arm!;
      if (value.abs() < _eps) continue;
      terms.add(EquationTerm(
        source: source,
        component: comp,
        nodeId: a.nodeId,
        endNodeId: a.equivalent?.endNodeId,
        positionX: a.point.dx,
        factor: f,
        arm: m.arm,
        value: value,
        decomposed: decomposed,
      ));
    }
  }

  for (var i = 0; i < reactions.length; i++) {
    final r = reactions[i];
    final m = _arm(kind, r.kind, r.point, pivot);
    if (!m.applies) continue;
    final v = values[i];
    if (v == null) {
      final coef = m.arm ?? 1.0;
      if (coef.abs() < _eps) continue;
      terms.add(EquationTerm(
        source: TermSource.reaction,
        component: r.kind,
        nodeId: r.nodeId,
        positionX: r.point.dx,
        arm: m.arm,
        value: coef,
        reaction: r,
        isUnknown: true,
      ));
    } else {
      final value = v * (m.arm ?? 1.0);
      if (value.abs() < _eps) continue;
      terms.add(EquationTerm(
        source: TermSource.reaction,
        component: r.kind,
        nodeId: r.nodeId,
        positionX: r.point.dx,
        factor: v,
        arm: m.arm,
        value: value,
        reaction: r,
      ));
    }
  }
  return terms;
}

/// Support node with the most unknowns (first by name on a tie): moments
/// about it make most reactions disappear from the equation.
int _choosePivot(List<Reaction> reactions) {
  final counts = <int, int>{};
  for (final r in reactions) {
    counts[r.nodeId] = (counts[r.nodeId] ?? 0) + 1;
  }
  var best = reactions.first.nodeId;
  for (final r in reactions) {
    if (counts[r.nodeId]! > counts[best]!) best = r.nodeId;
  }
  return best;
}

/// Builds the step by step of the reactions, solving one unknown per
/// equation (an equation is used only when it has a single unknown left).
/// Order of preference: ΣM at the pivot, ΣFy, ΣFx, then ΣM at other supports.
/// Returns null if no such order exists (should not happen for stable
/// isostatic structures).
List<ReactionStep>? buildReactionSteps(
  StructuralModel model,
  ReactionSolution solution, {
  SignConvention convention = SignConvention.standard,
}) {
  final reactions = solution.reactions;
  final actions = solution.actions;
  if (reactions.isEmpty) return null;

  final labels = ModelLabels.of(model);
  final points = {for (final r in reactions) r.nodeId: r.point};
  final pivotNode = _choosePivot(reactions);
  final supportNodes = {for (final r in reactions) r.nodeId}.toList();

  final candidates = <(EquationKind, int?)>[
    (EquationKind.sumMoment, pivotNode),
    (EquationKind.sumFy, null),
    (EquationKind.sumFx, null),
  ];
  for (final id in supportNodes) {
    if (id != pivotNode) candidates.add((EquationKind.sumMoment, id));
  }

  final values = List<double?>.filled(reactions.length, null);
  final equations = <EquationStep>[];

  while (values.contains(null)) {
    EquationStep? found;
    for (final (kind, node) in candidates) {
      final pivot = node == null ? null : points[node];
      final terms = _terms(kind, pivot, actions, reactions, values);
      final unknowns = terms.where((t) => t.isUnknown).toList();
      if (unknowns.length != 1) continue;

      final coef = unknowns.first.value;
      final knownSum =
          terms.where((t) => !t.isUnknown).fold(0.0, (s, t) => s + t.value);
      final result = _clean(-knownSum / coef);
      final index = reactions.indexOf(unknowns.first.reaction!);
      final original = reactions[index];
      values[index] = result;

      found = EquationStep(
        kind: kind,
        pivotNodeId: node,
        terms: convention.orderTerms(terms, (t) => t.positionX),
        solved: Reaction(
          supportId: original.supportId,
          nodeId: original.nodeId,
          point: original.point,
          kind: original.kind,
          value: result,
        ),
        coefficient: coef,
        knownSum: knownSum,
      );
      break;
    }
    if (found == null) return null;
    equations.add(found);
  }

  final steps = <ReactionStep>[];

  final nodeIds = [for (final n in model.nodes) n.id]
    ..sort((a, b) => _compareNames(labels.node(a), labels.node(b)));
  final memberIds = [for (final m in model.members) m.id]
    ..sort((a, b) => _compareNames(labels.member(a), labels.member(b)));
  steps.add(NamesStep(nodeIds: nodeIds, memberIds: memberIds));

  final equivalents = [
    for (final a in actions)
      if (a.equivalent != null) a.equivalent!,
  ];
  if (equivalents.isNotEmpty) steps.add(EquivalentLoadsStep(equivalents));

  final inclined = [
    for (final a in actions)
      if (a.fx.abs() > _eps && a.fy.abs() > _eps) a,
  ];
  if (inclined.isNotEmpty) steps.add(DecompositionStep(inclined));

  steps.add(UnknownsStep(reactions));
  steps.addAll(equations);

  // Check: moments about the node farthest from the pivot.
  final pivotPoint = points[pivotNode]!;
  var farId = nodeIds.first;
  var farDist = -1.0;
  for (final id in nodeIds) {
    final d = (model.nodeById(id)!.position - pivotPoint).distance;
    if (d > farDist + _eps) {
      farDist = d;
      farId = id;
    }
  }
  final checkTerms = _terms(
    EquationKind.sumMoment,
    model.nodeById(farId)!.position,
    actions,
    reactions,
    values,
  );
  steps.add(CheckStep(
    pivotNodeId: farId,
    terms: convention.orderTerms(checkTerms, (t) => t.positionX),
    sum: checkTerms.fold(0.0, (s, t) => s + t.value),
  ));

  steps.add(SummaryStep([
    for (var i = 0; i < reactions.length; i++)
      Reaction(
        supportId: reactions[i].supportId,
        nodeId: reactions[i].nodeId,
        point: reactions[i].point,
        kind: reactions[i].kind,
        value: values[i]!,
      ),
  ]));
  return steps;
}