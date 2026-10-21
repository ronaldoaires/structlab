import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:structlab/analysis/conventions/sign_convention.dart';
import 'package:structlab/analysis/reactions/reaction_solver.dart';
import 'package:structlab/analysis/reactions/reaction_steps.dart';
import 'package:structlab/domain/models/load.dart';
import 'package:structlab/domain/models/member.dart';
import 'package:structlab/domain/models/node.dart';
import 'package:structlab/domain/models/structural_model.dart';
import 'package:structlab/domain/models/support.dart';

StructuralNode _n(int id, double x, double y) =>
    StructuralNode(id: id, position: Offset(x, y));

StructuralMember _m(int id, int a, int b) =>
    StructuralMember(id: id, startNodeId: a, endNodeId: b);

StructuralSupport _s(int id, int node, SupportType t, [int rot = 0]) =>
    StructuralSupport(id: id, nodeId: node, type: t, rotationDegrees: rot);

/// A pin, C roller, 10 kN at B (x = 1) and 5 kN/m over the whole beam.
StructuralModel beam() => StructuralModel()
  ..nodes.addAll([_n(1, 0, 0), _n(2, 1, 0), _n(3, 4, 0)])
  ..members.addAll([_m(4, 1, 2), _m(5, 2, 3)])
  ..supports.addAll([
    _s(6, 1, SupportType.pin),
    _s(7, 3, SupportType.roller),
  ])
  ..loads.addAll([
    StructuralLoad(
        id: 8,
        kind: LoadKind.concentrated,
        nodeId: 2,
        q1: 10,
        angleDegrees: -90),
    StructuralLoad(
        id: 9,
        kind: LoadKind.uniform,
        nodeId: 1,
        endNodeId: 3,
        q1: 5,
        q2: 5,
        angleDegrees: -90),
  ]);

StructuralModel cantilever() => StructuralModel()
  ..nodes.addAll([_n(1, 0, 0), _n(2, 3, 0)])
  ..members.add(_m(3, 1, 2))
  ..supports.add(_s(4, 1, SupportType.fixed))
  ..loads.add(StructuralLoad(
      id: 5,
      kind: LoadKind.concentrated,
      nodeId: 2,
      q1: 10,
      angleDegrees: -90));

StructuralModel column() => StructuralModel()
  ..nodes.addAll([_n(1, 0, 0), _n(2, 0, 3)])
  ..members.add(_m(3, 1, 2))
  ..supports.addAll([
    _s(4, 1, SupportType.pin),
    _s(5, 2, SupportType.roller, 90),
  ])
  ..loads.add(StructuralLoad(
      id: 6,
      kind: LoadKind.concentrated,
      nodeId: 2,
      q1: 6,
      angleDegrees: 0));

StructuralModel inclined() => StructuralModel()
  ..nodes.addAll([_n(1, 0, 0), _n(2, 4, 0)])
  ..members.add(_m(3, 1, 2))
  ..supports.addAll([
    _s(4, 1, SupportType.pin),
    _s(5, 2, SupportType.roller),
  ])
  ..loads.add(StructuralLoad(
      id: 6,
      kind: LoadKind.concentrated,
      nodeId: 2,
      q1: 10,
      angleDegrees: -45));

List<ReactionStep> _steps(StructuralModel m,
    {SignConvention c = SignConvention.standard}) {
  final solution = solveReactions(m).solution!;
  return buildReactionSteps(m, solution, convention: c)!;
}

void main() {
  test('beam example: order of the steps', () {
    final steps = _steps(beam());
    expect(steps.map((s) => s.runtimeType).toList(), [
      NamesStep,
      EquivalentLoadsStep,
      UnknownsStep,
      EquationStep,
      EquationStep,
      EquationStep,
      CheckStep,
      SummaryStep,
    ]);
  });

  test('beam example: ΣM at A solves C, then ΣFy, then ΣFx', () {
    final eqs = _steps(beam()).whereType<EquationStep>().toList();

    final m = eqs[0];
    expect(m.kind, EquationKind.sumMoment);
    expect(m.pivotNodeId, 1);
    expect(m.coefficient, closeTo(4, 1e-9));
    expect(m.knownSum, closeTo(-50, 1e-9));
    expect(m.result, closeTo(12.5, 1e-9));
    expect(m.terms.map((t) => t.source).toList(), [
      TermSource.concentrated,
      TermSource.distributed,
      TermSource.reaction,
    ]);
    expect(m.terms.map((t) => t.value).toList(), [-10, -40, 4]);

    expect(eqs[1].kind, EquationKind.sumFy);
    expect(eqs[1].result, closeTo(17.5, 1e-9));
    expect(eqs[2].kind, EquationKind.sumFx);
    expect(eqs[2].result, closeTo(0, 1e-9));
  });

  test('beam example: check at the farthest node sums to zero', () {
    final check = _steps(beam()).whereType<CheckStep>().single;
    expect(check.pivotNodeId, 3);
    expect(check.sum, closeTo(0, 1e-9));
  });

  test('right-to-left convention reverses the order of the terms', () {
    final eq = _steps(
      beam(),
      c: const SignConvention(termOrder: TermOrder.rightToLeft),
    ).whereType<EquationStep>().first;
    expect(eq.terms.map((t) => t.positionX).toList(), [4, 2, 1]);
  });

  test('inclined load adds a decomposition step', () {
    final steps = _steps(inclined());
    final dec = steps.whereType<DecompositionStep>().single;
    expect(dec.actions.length, 1);
    final first = steps.whereType<EquationStep>().first;
    expect(first.terms.where((t) => t.decomposed), isNotEmpty);
  });

  test('every model: steps agree with the solver and the check is zero', () {
    for (final model in [beam(), cantilever(), column(), inclined()]) {
      final solution = solveReactions(model).solution!;
      final steps = buildReactionSteps(model, solution)!;

      final eqs = steps.whereType<EquationStep>().toList();
      expect(eqs.length, solution.reactions.length);
      for (final eq in eqs) {
        final expected = solution.reactions.firstWhere(
          (r) => r.nodeId == eq.solved.nodeId && r.kind == eq.solved.kind,
        );
        expect(eq.result, closeTo(expected.value, 1e-9));
        expect(eq.coefficient * eq.result + eq.knownSum, closeTo(0, 1e-9));
      }
      expect(steps.whereType<CheckStep>().single.sum, closeTo(0, 1e-9));
    }
  });

  test('cantilever: ΣM at the fixed support solves the moment', () {
    final eqs = _steps(cantilever()).whereType<EquationStep>().toList();
    expect(eqs.first.solved.kind, ReactionKind.moment);
    expect(eqs.first.result, closeTo(30, 1e-9));
  });
}