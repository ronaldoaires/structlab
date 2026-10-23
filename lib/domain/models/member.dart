/// How the dimension of a member is shown on the canvas, and which values the
/// user defined: the length (parallel dimension) or the two legs (horizontal
/// span and height).
enum DimensionStyle { length, legs }

/// A straight bar connecting two nodes.
class StructuralMember {
  StructuralMember({
    required this.id,
    required this.startNodeId,
    required this.endNodeId,
    this.dimensionStyle = DimensionStyle.length,
  });

  final int id;
  final int startNodeId;
  final int endNodeId;
  DimensionStyle dimensionStyle;

  StructuralMember copy() => StructuralMember(
        id: id,
        startNodeId: startNodeId,
        endNodeId: endNodeId,
        dimensionStyle: dimensionStyle,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'startNodeId': startNodeId,
        'endNodeId': endNodeId,
        'dimensionStyle': dimensionStyle.name,
      };

  factory StructuralMember.fromJson(Map<String, dynamic> json) =>
      StructuralMember(
        id: json['id'] as int,
        startNodeId: json['startNodeId'] as int,
        endNodeId: json['endNodeId'] as int,
        dimensionStyle: DimensionStyle.values.asNameMap()[
                json['dimensionStyle'] as String?] ??
            DimensionStyle.length,
      );
}