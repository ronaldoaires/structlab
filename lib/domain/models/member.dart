/// A straight bar connecting two nodes.
class StructuralMember {
  StructuralMember({
    required this.id,
    required this.startNodeId,
    required this.endNodeId,
  });

  final int id;
  final int startNodeId;
  final int endNodeId;

  StructuralMember copy() => StructuralMember(
        id: id,
        startNodeId: startNodeId,
        endNodeId: endNodeId,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'startNodeId': startNodeId,
        'endNodeId': endNodeId,
      };

  factory StructuralMember.fromJson(Map<String, dynamic> json) =>
      StructuralMember(
        id: json['id'] as int,
        startNodeId: json['startNodeId'] as int,
        endNodeId: json['endNodeId'] as int,
      );
}