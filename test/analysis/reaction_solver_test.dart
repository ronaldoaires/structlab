import 'package:flutter_test/flutter_test.dart';
import 'package:structlab/analysis/reactions/reaction_solver.dart';
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

double _val(ReactionSolution s, int nodeId, ReactionKind k) => s.reactions
    .firstWhere((r) => r.nodeId == nodeId && r.kind == k)
    .value;

void main() {
  test('simply supported beam: 10 kN point load + 5 kN/m over 4 m', () {
    final model = StructuralModel()
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

    final out = solveReactions(model);
    expect(out.isOk, isTrue);
    final s = out.solution!;
    expect(_val(s, 1, ReactionKind.fx), closeTo(0, 1e-9));
    expect(_val(s, 1, ReactionKind.fy), closeTo(17.5, 1e-9));
    expect(_val(s, 3, ReactionKind.fy), closeTo(12.5, 1e-9));
    // Equilibrium checks.
    expect(s.sumFx, closeTo(0, 1e-9));
    expect(s.sumFy, closeTo(0, 1e-9));
    expect(s.momentAbout(const Offset(4, 0)), closeTo(0, 1e-9));
    expect(s.momentAbout(const Offset(1, 0)), closeTo(0, 1e-9));
  });

  test('cantilever: fixed support gives Ay = 10 and M = +30 (ccw)', () {
    final model = StructuralModel()
      ..nodes.addAll([_n(1, 0, 0), _n(2, 3, 0)])
      ..members.add(_m(3, 1, 2))
      ..supports.add(_s(4, 1, SupportType.fixed))
      ..loads.add(StructuralLoad(
          id: 5,
          kind: LoadKind.concentrated,
          nodeId: 2,
          q1: 10,
          angleDegrees: -90));

    final s = solveReactions(model).solution!;
    expect(_val(s, 1, ReactionKind.fx), closeTo(0, 1e-9));
    expect(_val(s, 1, ReactionKind.fy), closeTo(10, 1e-9));
    expect(_val(s, 1, ReactionKind.moment), closeTo(30, 1e-9));
    expect(s.momentAbout(const Offset(3, 0)), closeTo(0, 1e-9));
  });

  test('applied moment creates a couple (counterclockwise positive)', () {
    final model = StructuralModel()
      ..nodes.addAll([_n(1, 0, 0), _n(2, 4, 0)])
      ..members.add(_m(3, 1, 2))
      ..supports.addAll([
        _s(4, 1, SupportType.pin),
        _s(5, 2, SupportType.roller),
      ])
      ..loads.add(StructuralLoad(
          id: 6, kind: LoadKind.moment, nodeId: 2, q1: 8, q2: 8));

    final s = solveReactions(model).solution!;
    expect(_val(s, 1, ReactionKind.fy), closeTo(2, 1e-9));
    expect(_val(s, 2, ReactionKind.fy), closeTo(-2, 1e-9));
  });

  test('horizontal load goes to the pin (negative = pointing left)', () {
    final model = StructuralModel()
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
          q1: 6,
          angleDegrees: 0));

    final s = solveReactions(model).solution!;
    expect(_val(s, 1, ReactionKind.fx), closeTo(-6, 1e-9));
    expect(_val(s, 1, ReactionKind.fy), closeTo(0, 1e-9));
    expect(_val(s, 2, ReactionKind.fy), closeTo(0, 1e-9));
  });

  test('column with a horizontal roller (rotation 90) at the top', () {
    final model = StructuralModel()
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

    final s = solveReactions(model).solution!;
    expect(_val(s, 2, ReactionKind.fx), closeTo(-6, 1e-9));
    expect(_val(s, 1, ReactionKind.fx), closeTo(0, 1e-9));
    expect(_val(s, 1, ReactionKind.fy), closeTo(0, 1e-9));
  });

  test('hyperstatic structure is refused', () {
    final model = StructuralModel()
      ..nodes.addAll([_n(1, 0, 0), _n(2, 2, 0), _n(3, 4, 0)])
      ..members.addAll([_m(4, 1, 2), _m(5, 2, 3)])
      ..supports.addAll([
        _s(6, 1, SupportType.pin),
        _s(7, 2, SupportType.roller),
        _s(8, 3, SupportType.roller),
      ]);

    final out = solveReactions(model);
    expect(out.isOk, isFalse);
    expect(out.failure, SolveFailure.hyperstatic);
  });

  test('model without supports is refused as invalid', () {
    final model = StructuralModel()
      ..nodes.addAll([_n(1, 0, 0), _n(2, 4, 0)])
      ..members.add(_m(3, 1, 2));

    expect(solveReactions(model).failure, SolveFailure.invalidModel);
  });
}