import 'dart:ui';

/// Kind of node. [hinge] is reserved for a future step (releases rotation).
enum NodeKind { rigid, hinge }

/// A point of the structure where members, supports and loads connect.
class StructuralNode {
  StructuralNode({
    required this.id,
    required this.position,
  });

  final int id;

  /// Position in model coordinates (meters).
  Offset position;

  StructuralNode copy() => StructuralNode(id: id, position: position);

  Map<String, dynamic> toJson() => {
        'id': id,
        'x': position.dx,
        'y': position.dy,
      };

  factory StructuralNode.fromJson(Map<String, dynamic> json) => StructuralNode(
        id: json['id'] as int,
        position: Offset(
          (json['x'] as num).toDouble(),
          (json['y'] as num).toDouble(),
        ),
      );
}