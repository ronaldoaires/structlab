enum LoadKind { concentrated, moment, uniform, triangular, trapezoidal }

/// A load applied to a node (concentrated) or between two nodes (distributed).
class StructuralLoad {
  StructuralLoad({
    required this.id,
    required this.kind,
    required this.nodeId,
    this.endNodeId,
    this.q1 = 10,
    this.q2 = 10,
    this.angleDegrees = -90,
  });

  final int id;
  final LoadKind kind;

  /// Concentrated: application node. Distributed: start node (left).
  final int nodeId;

  /// Distributed: end node (right). Null for concentrated loads.
  final int? endNodeId;

  /// Concentrated: kN. Moment: kN·m, positive = counterclockwise.
  /// Distributed: kN/m at the start node.
  double q1;

  /// Distributed: kN/m at the end node.
  double q2;

  /// Direction the load points to, in degrees. -90 = downward.
  double angleDegrees;

  StructuralLoad copy() => StructuralLoad(
        id: id,
        kind: kind,
        nodeId: nodeId,
        endNodeId: endNodeId,
        q1: q1,
        q2: q2,
        angleDegrees: angleDegrees,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'nodeId': nodeId,
        'endNodeId': endNodeId,
        'q1': q1,
        'q2': q2,
        'angleDegrees': angleDegrees,
      };

  factory StructuralLoad.fromJson(Map<String, dynamic> json) => StructuralLoad(
        id: json['id'] as int,
        kind: LoadKind.values.byName(json['kind'] as String),
        nodeId: json['nodeId'] as int,
        endNodeId: json['endNodeId'] as int?,
        q1: (json['q1'] as num).toDouble(),
        q2: (json['q2'] as num).toDouble(),
        angleDegrees: (json['angleDegrees'] as num).toDouble(),
      );
}