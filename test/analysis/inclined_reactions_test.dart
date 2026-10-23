import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:structlab/analysis/reactions/reaction_solver.dart';
import 'package:structlab/domain/models/load.dart';
import 'package:structlab/domain/models/member.dart';
import 'package:structlab/domain/models/node.dart';
import 'package:structlab/domain/models/structural_model.dart';
import 'package:structlab/domain/models/support.dart';

void main() {
  test('FTool reference: triangular 0 -> 18 kN/m on a 6 x 2 m inclined beam',
      () {
    final model = StructuralModel()
      ..nodes.addAll([
        StructuralNode(id: 1, position: const Offset(0, 0)),
        StructuralNode(id: 2, position: const Offset(6, 2)),
      ])
      ..members.add(StructuralMember(id: 3, startNodeId: 1, endNodeId: 2))
      ..supports.addAll([
        StructuralSupport(id: 4, nodeId: 1, type: SupportType.pin),
        StructuralSupport(id: 5, nodeId: 2, type: SupportType.roller),
      ])
      ..loads.add(StructuralLoad(
        id: 6,
        kind: LoadKind.triangular,
        nodeId: 1,
        endNodeId: 2,
        q1: 0,
        q2: 18,
        angleDegrees: -90,
      ));

    final s = solveReactions(model).solution!;
    double v(int node, ReactionKind k) =>
        s.reactions.firstWhere((r) => r.nodeId == node && r.kind == k).value;

    final total = 18 * math.sqrt(40) / 2;
    expect(v(1, ReactionKind.fy), closeTo(total / 3, 1e-6)); // 18.97
    expect(v(2, ReactionKind.fy), closeTo(total * 2 / 3, 1e-6)); // 37.95
    expect(v(1, ReactionKind.fx), closeTo(0, 1e-9));
  });
}