import 'package:structlab/domain/models/load.dart';

/// Static data about a load kind.
class LoadSpec {
  const LoadSpec({
    required this.kind,
    required this.isDistributed,
    required this.defaultQ1,
    required this.defaultQ2,
    required this.unit,
  });

  final LoadKind kind;
  final bool isDistributed;

  /// Default intensities when the load is created.
  final double defaultQ1;
  final double defaultQ2;

  final String unit;
}

const Map<LoadKind, LoadSpec> loadCatalog = {
  LoadKind.concentrated: LoadSpec(
    kind: LoadKind.concentrated,
    isDistributed: false,
    defaultQ1: 10,
    defaultQ2: 10,
    unit: 'kN',
  ),
  LoadKind.uniform: LoadSpec(
    kind: LoadKind.uniform,
    isDistributed: true,
    defaultQ1: 10,
    defaultQ2: 10,
    unit: 'kN/m',
  ),
  LoadKind.triangular: LoadSpec(
    kind: LoadKind.triangular,
    isDistributed: true,
    defaultQ1: 0,
    defaultQ2: 10,
    unit: 'kN/m',
  ),
  LoadKind.trapezoidal: LoadSpec(
    kind: LoadKind.trapezoidal,
    isDistributed: true,
    defaultQ1: 5,
    defaultQ2: 10,
    unit: 'kN/m',
  ),
};

LoadSpec loadSpec(LoadKind kind) => loadCatalog[kind]!;