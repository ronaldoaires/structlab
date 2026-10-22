import 'package:structlab/analysis/internal_forces/internal_forces_model.dart';
import 'package:structlab/analysis/reactions/reaction_solver.dart';
import 'package:structlab/domain/models/structural_model.dart';

enum InternalForcesFailure {
  /// No usable members.
  invalidModel,

  /// The structure has a closed loop (or hinges) that this method cannot cut
  /// into free bodies.
  unsupportedStructure,
}

class InternalForcesOutcome {
  const InternalForcesOutcome.success(InternalForcesResult this.result)
      : failure = null;
  const InternalForcesOutcome.failed(InternalForcesFailure this.failure)
      : result = null;

  final InternalForcesResult? result;
  final InternalForcesFailure? failure;

  bool get isOk => result != null;
}

/// A way of getting N, V and M of a statically determinate structure whose
/// reactions are already known. To add a method (e.g. cutting sections,
/// direct equilibrium), implement this class and pass it to the results
/// screen: nothing else changes.
abstract class InternalForceMethod {
  const InternalForceMethod();

  /// Stable identifier, saved in [InternalForcesResult.methodId].
  String get id;

  InternalForcesOutcome solve(
    StructuralModel model,
    ReactionSolution reactions,
  );
}