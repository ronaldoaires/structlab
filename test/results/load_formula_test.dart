import 'package:flutter_test/flutter_test.dart';
import 'package:structlab/analysis/reactions/equivalent_loads.dart';
import 'package:structlab/domain/models/load.dart';
import 'package:structlab/domain/models/member.dart';
import 'package:structlab/domain/models/node.dart';
import 'package:structlab/domain/models/structural_model.dart';
import 'package:structlab/results/load_formula.dart';

String _plain(FormulaLine line) => line
    .map((p) => switch (p) {
          FormulaText() => p.text,
          FormulaFraction() => '${p.numerator}/${p.denominator}',
        })
    .join(' ');

EquivalentLoad _load(LoadKind kind, double q1, double q2) {
  final m = StructuralModel()
    ..nodes.addAll([
      StructuralNode(id: 1, position: const Offset(0, 0)),
      StructuralNode(id: 2, position: const Offset(4, 0)),
    ])
    ..members.add(StructuralMember(id: 3, startNodeId: 1, endNodeId: 2))
    ..loads.add(StructuralLoad(
      id: 4,
      kind: kind,
      nodeId: 1,
      endNodeId: 2,
      q1: q1,
      q2: q2,
    ));
  return equivalentLoads(m).single;
}

void main() {
  test('trapezoid 8 -> 12 over 4 m', () {
    final f = buildLoadFormulas(_load(LoadKind.trapezoidal, 8, 12));
    expect(_plain(f.resultant.symbolic), 'R = (H + h) · L/2');
    expect(_plain(f.resultant.substituted), 'R = (12 + 8) · 4/2');
    expect(_plain(f.resultant.result), 'R = 40 kN');
    expect(_plain(f.centroid.substituted),
        'CG = (12 + 2·8) · 4/3 · (12 + 8)');
    expect(_plain(f.centroid.result), 'CG = 1.87 m');
  });

  test('rectangle and triangle', () {
    final rect = buildLoadFormulas(_load(LoadKind.uniform, 5, 5));
    expect(_plain(rect.resultant.result), 'R = 20 kN');
    expect(_plain(rect.centroid.result), 'CG = 2 m');

    final tri = buildLoadFormulas(_load(LoadKind.triangular, 0, 9));
    expect(_plain(tri.resultant.result), 'R = 18 kN');
    expect(_plain(tri.centroid.result), 'CG = 1.33 m');
  });
}