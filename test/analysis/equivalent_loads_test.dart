import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:structlab/analysis/reactions/equivalent_loads.dart';
import 'package:structlab/domain/models/load.dart';
import 'package:structlab/domain/models/member.dart';
import 'package:structlab/domain/models/node.dart';
import 'package:structlab/domain/models/structural_model.dart';

void main() {
  group('trapezoidResultant', () {
    test('uniform: R = qL, centroid L/2', () {
      final r = trapezoidResultant(10, 10, 4)!;
      expect(r.force, closeTo(40, 1e-9));
      expect(r.centroid, closeTo(2, 1e-9));
    });

    test('triangular, peak on the right: R = qL/2, centroid 2L/3', () {
      final r = trapezoidResultant(0, 9, 3)!;
      expect(r.force, closeTo(13.5, 1e-9));
      expect(r.centroid, closeTo(2, 1e-9));
    });

    test('triangular, peak on the left: centroid L/3', () {
      final r = trapezoidResultant(9, 0, 3)!;
      expect(r.force, closeTo(13.5, 1e-9));
      expect(r.centroid, closeTo(1, 1e-9));
    });

    test('trapezoid 5 -> 10 over 4 m', () {
      final r = trapezoidResultant(5, 10, 4)!;
      expect(r.force, closeTo(30, 1e-9));
      expect(r.centroid, closeTo(4 * 25 / 45, 1e-9));
    });

    test('q1 + q2 = 0 returns null', () {
      expect(trapezoidResultant(0, 0, 4), isNull);
    });
  });

  group('equivalentLoads', () {
    StructuralModel beam() {
      final m = StructuralModel();
      m.nodes.add(StructuralNode(id: 1, position: const Offset(0, 0)));
      m.nodes.add(StructuralNode(id: 2, position: const Offset(4, 0)));
      m.members
          .add(StructuralMember(id: 3, startNodeId: 1, endNodeId: 2));
      return m;
    }

    test('downward trapezoid on a horizontal beam', () {
      final m = beam();
      m.loads.add(StructuralLoad(
        id: 4,
        kind: LoadKind.trapezoidal,
        nodeId: 1,
        endNodeId: 2,
        q1: 5,
        q2: 10,
        angleDegrees: -90,
      ));
      final eq = equivalentLoads(m).single;
      expect(eq.resultant, closeTo(30, 1e-9));
      expect(eq.point.dx, closeTo(2.2222, 1e-3));
      expect(eq.point.dy, closeTo(0, 1e-9));
      expect(eq.fx, closeTo(0, 1e-9));
      expect(eq.fy, closeTo(-30, 1e-9));
    });

    test('skips concentrated loads and zero loads', () {
      final m = beam();
      m.loads.add(StructuralLoad(
          id: 4, kind: LoadKind.concentrated, nodeId: 1));
      m.loads.add(StructuralLoad(
        id: 5,
        kind: LoadKind.uniform,
        nodeId: 1,
        endNodeId: 2,
        q1: 0,
        q2: 0,
      ));
      expect(equivalentLoads(m), isEmpty);
    });
  });
}