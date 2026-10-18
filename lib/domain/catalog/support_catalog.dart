import 'package:structlab/domain/models/support.dart';

/// Static data about a support type. The solver will read this.
class SupportSpec {
  const SupportSpec({
    required this.type,
    required this.reactionCount,
    required this.restrainsRotation,
  });

  final SupportType type;

  /// Number of reactions (translations + rotation) the support provides.
  final int reactionCount;

  final bool restrainsRotation;
}

const Map<SupportType, SupportSpec> supportCatalog = {
  SupportType.roller: SupportSpec(
    type: SupportType.roller,
    reactionCount: 1,
    restrainsRotation: false,
  ),
  SupportType.pin: SupportSpec(
    type: SupportType.pin,
    reactionCount: 2,
    restrainsRotation: false,
  ),
  SupportType.fixed: SupportSpec(
    type: SupportType.fixed,
    reactionCount: 3,
    restrainsRotation: true,
  ),
};

SupportSpec supportSpec(SupportType type) => supportCatalog[type]!;

/// True if the support prevents vertical displacement.
/// A roller restrains the axis between the node and the support:
/// rotation 0/180 (below/above) = vertical, 90/270 (left/right) = horizontal.
bool restrainsVertical(StructuralSupport s) => switch (s.type) {
      SupportType.roller => s.rotationDegrees % 180 == 0,
      _ => true,
    };

/// True if the support prevents horizontal displacement.
bool restrainsHorizontal(StructuralSupport s) => switch (s.type) {
      SupportType.roller => s.rotationDegrees % 180 != 0,
      _ => true,
    };