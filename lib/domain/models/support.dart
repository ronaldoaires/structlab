enum SupportType { roller, pin, fixed }

/// A support attached to a node.
class StructuralSupport {
  StructuralSupport({
    required this.id,
    required this.nodeId,
    this.type = SupportType.pin,
    this.rotationDegrees = 0,
  });

  final int id;
  final int nodeId;
  SupportType type;

  /// 0 = support below the node, 90 = left, 180 = above, 270 = right.
  int rotationDegrees;

  StructuralSupport copy() => StructuralSupport(
        id: id,
        nodeId: nodeId,
        type: type,
        rotationDegrees: rotationDegrees,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nodeId': nodeId,
        'type': type.name,
        'rotationDegrees': rotationDegrees,
      };

  factory StructuralSupport.fromJson(Map<String, dynamic> json) =>
      StructuralSupport(
        id: json['id'] as int,
        nodeId: json['nodeId'] as int,
        type: SupportType.values.byName(json['type'] as String),
        rotationDegrees: json['rotationDegrees'] as int,
      );
}