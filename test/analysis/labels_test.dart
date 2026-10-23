import 'package:flutter_test/flutter_test.dart';
import 'package:structlab/analysis/naming/labels.dart';
import 'package:structlab/domain/models/member.dart';
import 'package:structlab/domain/models/node.dart';
import 'package:structlab/domain/models/structural_model.dart';

void main() {
  test('letterLabel goes A..Z, AA, AB', () {
    expect(letterLabel(0), 'A');
    expect(letterLabel(25), 'Z');
    expect(letterLabel(26), 'AA');
    expect(letterLabel(27), 'AB');
  });

  test('nodes are named by x, then y, regardless of id', () {
    final m = StructuralModel();
    m.nodes.add(StructuralNode(id: 5, position: const Offset(4, 0)));
    m.nodes.add(StructuralNode(id: 2, position: const Offset(0, 0)));
    m.nodes.add(StructuralNode(id: 9, position: const Offset(2, 0)));
    m.nodes.add(StructuralNode(id: 7, position: const Offset(4, 3)));
    m.members.add(StructuralMember(id: 10, startNodeId: 9, endNodeId: 2));
    m.members.add(StructuralMember(id: 11, startNodeId: 9, endNodeId: 5));

    final l = ModelLabels.of(m);
    expect(l.node(2), 'A');
    expect(l.node(9), 'B');
    expect(l.node(5), 'C');
    expect(l.node(7), 'D');
    expect(l.member(10), 'AB'); // order does not depend on start/end
    expect(l.member(11), 'BC');
  });

  test('inserting a node renames the others', () {
    final m = StructuralModel();
    m.nodes.add(StructuralNode(id: 1, position: const Offset(0, 0)));
    m.nodes.add(StructuralNode(id: 2, position: const Offset(4, 0)));
    expect(ModelLabels.of(m).node(2), 'B');
    m.nodes.add(StructuralNode(id: 3, position: const Offset(2, 0)));
    expect(ModelLabels.of(m).node(2), 'C');
  });
}