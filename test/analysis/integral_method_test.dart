import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:structlab/analysis/internal_forces/integral_method.dart';
import 'package:structlab/analysis/internal_forces/internal_forces_model.dart';
import 'package:structlab/analysis/internal_forces/sampling.dart';
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

InternalForcesResult _solve(StructuralModel model) {
  final reactions = solveReactions(model).solution!;
  final out = const IntegralMethod().solve(model, reactions);
  expect(out.isOk, isTrue);
  return out.result!;
}

/// Portal frame of the lecture notes: A(0,0) pin, E(5,0) vertical roller,
/// triangular 0 -> 30 kN/m downward on BC and 30 -> 0 kN/m upward on CD.
StructuralModel _portal() => StructuralModel()
  ..nodes.addAll([
    _n(1, 0, 0),
    _n(2, 0, 3),
    _n(3, 3, 3),
    _n(4, 5, 3),
    _n(5, 5, 0),
  ])
  ..members.addAll([_m(6, 1, 2), _m(7, 2, 3), _m(8, 3, 4), _m(9, 5, 4)])
  ..supports.addAll([_s(10, 1, SupportType.pin), _s(11, 5, SupportType.roller)])
  ..loads.addAll([
    StructuralLoad(
      id: 12,
      kind: LoadKind.triangular,
      nodeId: 2,
      endNodeId: 3,
      q1: 0,
      q2: 30,
      angleDegrees: -90,
    ),
    StructuralLoad(
      id: 13,
      kind: LoadKind.triangular,
      nodeId: 3,
      endNodeId: 4,
      q1: 30,
      q2: 0,
      angleDegrees: 90,
    ),
  ]);

void main() {
  test('portal frame: column AB carries only a compression of 19 kN', () {
    final ab = _solve(_portal()).forMember(6)!;
    expect(ab.normal.at(0), closeTo(-19, 1e-9));
    expect(ab.normal.at(3), closeTo(-19, 1e-9));
    expect(ab.shear.at(1.5), closeTo(0, 1e-9));
    expect(ab.moment.at(3), closeTo(0, 1e-9));
  });

  test('portal frame: beam BC matches the lecture notes', () {
    final bc = _solve(_portal()).forMember(7)!;
    expect(bc.pieces.single.fit.slope, closeTo(10, 1e-9));
    expect(bc.startShear, closeTo(19, 1e-9));
    expect(bc.startMoment, closeTo(0, 1e-9));
    expect(bc.shear.at(1), closeTo(14, 1e-9));
    expect(bc.shear.at(2), closeTo(-1, 1e-9));
    expect(bc.shear.at(3), closeTo(-26, 1e-9));
    expect(bc.moment.at(1), closeTo(17.3333333, 1e-6));
    expect(bc.moment.at(2), closeTo(24.6666667, 1e-6));
    expect(bc.moment.at(3), closeTo(12, 1e-9));
    // The normal of AB became the shear of BC.
    expect(bc.previous!.memberId, 6);
    expect(bc.previous!.angleDegrees, closeTo(-90, 1e-9));
  });

  test('portal frame: beam CD matches the lecture notes', () {
    final cd = _solve(_portal()).forMember(8)!;
    expect(cd.pieces.single.fit.slope, closeTo(-15, 1e-9));
    expect(cd.pieces.single.fit.intercept, closeTo(30, 1e-9));
    expect(cd.startShear, closeTo(-26, 1e-9));
    expect(cd.startMoment, closeTo(12, 1e-9));
    expect(cd.shear.at(1), closeTo(-3.5, 1e-9));
    expect(cd.shear.at(2), closeTo(4, 1e-9));
    expect(cd.moment.at(1), closeTo(-1.5, 1e-9));
    expect(cd.moment.at(2), closeTo(0, 1e-9));
  });

  test('portal frame: right column is in tension and has no start member', () {
    final de = _solve(_portal()).forMember(9)!;
    expect(de.previous, isNull);
    expect(de.normal.at(1), closeTo(4, 1e-9));
    expect(de.moment.at(3), closeTo(0, 1e-9));
  });

  test('load that spans two members is split and chained', () {
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

    final r = _solve(model);
    final ab = r.forMember(4)!;
    final bc = r.forMember(5)!;
    expect(ab.shear.at(0), closeTo(17.5, 1e-9));
    expect(ab.shear.at(1), closeTo(12.5, 1e-9));
    expect(ab.moment.at(1), closeTo(15, 1e-9));
    expect(bc.previous!.memberId, 4);
    expect(bc.previous!.angleDegrees, closeTo(0, 1e-9));
    expect(bc.startShear, closeTo(2.5, 1e-9));
    expect(bc.shear.at(3), closeTo(-12.5, 1e-9));
    expect(bc.moment.at(0), closeTo(15, 1e-9));
    expect(bc.moment.at(3), closeTo(0, 1e-9));
  });

  group('SamplingConfig', () {
    test('default: every meter, last point included', () {
      expect(SamplingConfig.standard.points(3), [0, 1, 2, 3]);
      expect(SamplingConfig.standard.points(2.5), [0, 1, 2, 2.5]);
    });

    test('custom range and step', () {
      const c = SamplingConfig(from: 1, to: 3, step: 0.5);
      expect(c.points(4), [1, 1.5, 2, 2.5, 3]);
    });
  });
}