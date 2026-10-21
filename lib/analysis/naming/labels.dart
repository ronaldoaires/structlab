import 'package:structlab/domain/models/structural_model.dart';

/// 0 -> A, 25 -> Z, 26 -> AA, 27 -> AB ...
String letterLabel(int index) {
  var n = index;
  var s = '';
  do {
    s = String.fromCharCode(65 + n % 26) + s;
    n = n ~/ 26 - 1;
  } while (n >= 0);
  return s;
}

/// Names of nodes (A, B, C...) and members (AB, BC...), computed from the
/// model. Nodes are ordered by x, then by y (bottom to top). Nothing is saved:
/// inserting a node renames the others automatically.
class ModelLabels {
  ModelLabels._(this._nodeLabels, this._memberLabels);

  final Map<int, String> _nodeLabels;
  final Map<int, String> _memberLabels;

  factory ModelLabels.of(StructuralModel model) {
    const tol = 1e-6;
    final sorted = [...model.nodes]
      ..sort((a, b) {
        final dx = a.position.dx - b.position.dx;
        if (dx.abs() > tol) return dx.compareTo(0);
        final dy = a.position.dy - b.position.dy;
        if (dy.abs() > tol) return dy.compareTo(0);
        return a.id.compareTo(b.id);
      });

    final order = <int, int>{};
    final nodeLabels = <int, String>{};
    for (var i = 0; i < sorted.length; i++) {
      order[sorted[i].id] = i;
      nodeLabels[sorted[i].id] = letterLabel(i);
    }

    final memberLabels = <int, String>{};
    for (final m in model.members) {
      final a = order[m.startNodeId];
      final b = order[m.endNodeId];
      if (a == null || b == null) continue;
      final lo = a < b ? a : b;
      final hi = a < b ? b : a;
      memberLabels[m.id] = letterLabel(lo) + letterLabel(hi);
    }
    return ModelLabels._(nodeLabels, memberLabels);
  }

  String node(int id) => _nodeLabels[id] ?? '?';
  String member(int id) => _memberLabels[id] ?? '?';
}