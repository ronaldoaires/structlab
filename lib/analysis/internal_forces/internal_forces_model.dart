import 'dart:math' as math;
import 'dart:ui';

import 'package:structlab/analysis/internal_forces/linear_load_fit.dart';
import 'package:structlab/analysis/internal_forces/polynomial.dart';
import 'package:structlab/analysis/reactions/reaction_solver.dart';
import 'package:structlab/domain/models/load.dart';

// Pure data (no strings). The texts are built in
// l10n/strings_internal_forces_pt.dart.
//
// Local axes of a member: t = from its LEFT node to its RIGHT node (for a
// vertical member: bottom to top) and n = t rotated 90° counterclockwise.
//
// Sign convention (internal):
//   V(x) = sum of the n-components of the external forces on the left part
//   N(x) = minus the sum of the t-components (tension is positive)
//   M(x) = V integrated; positive M tracts the side opposite to n
// so V(x) = K1 + ∫Q⊥ dx and M(x) = K2 + ∫V dx, as in the lecture notes.

enum InternalForceKind { normal, shear, moment }

enum ExternalActionKind { reaction, concentrated, moment, distributed }

/// A force (and/or moment) applied to the structure, in global axes.
class ExternalAction {
  const ExternalAction({
    required this.kind,
    required this.nodeId,
    required this.point,
    this.fx = 0,
    this.fy = 0,
    this.moment = 0,
    this.loadId,
    this.memberId,
    this.reaction,
  });

  final ExternalActionKind kind;

  /// Node where it acts (distributed: left node of the member).
  final int nodeId;
  final Offset point;
  final double fx;
  final double fy;

  /// Counterclockwise positive.
  final double moment;

  final int? loadId;

  /// Distributed loads only: the member that carries this piece of load.
  final int? memberId;

  /// Reactions only.
  final Reaction? reaction;
}

/// An external action seen from the start node of a member, in the local
/// axes of that member.
class StartContribution {
  const StartContribution({
    required this.action,
    required this.tangential,
    required this.normal,
    required this.moment,
  });

  final ExternalAction action;

  /// Force along the member (+t).
  final double tangential;

  /// Force perpendicular to the member (+n).
  final double normal;

  /// Moment about the start node, counterclockwise positive.
  final double moment;

  /// How much this action adds to K of [kind].
  double valueFor(InternalForceKind kind) => switch (kind) {
        InternalForceKind.shear => normal,
        InternalForceKind.moment => -moment,
        InternalForceKind.normal => -tangential,
      };
}

/// The end of the previous member, rotated into the axes of this member
/// (the normal of one member becomes the shear of the next).
class PreviousMemberTransfer {
  const PreviousMemberTransfer({
    required this.memberId,
    required this.endNormal,
    required this.endShear,
    required this.endMoment,
    required this.angleDegrees,
    required this.tangential,
    required this.normal,
    required this.moment,
  });

  final int memberId;

  /// N, V and M at the end of the previous member.
  final double endNormal;
  final double endShear;
  final double endMoment;

  /// Turn between the two members (counterclockwise positive).
  final double angleDegrees;

  /// Same meaning as in [StartContribution].
  final double tangential;
  final double normal;
  final double moment;

  double valueFor(InternalForceKind kind) => switch (kind) {
        InternalForceKind.shear => normal,
        InternalForceKind.moment => -moment,
        InternalForceKind.normal => -tangential,
      };
}

/// The part of a distributed load that lies on one member.
class DistributedPiece {
  const DistributedPiece({
    required this.loadId,
    required this.kind,
    required this.length,
    required this.angleDegrees,
    required this.normalFactor,
    required this.tangentialFactor,
    required this.fit,
  });

  final int loadId;
  final LoadKind kind;
  final double length;
  final double angleDegrees;

  /// Component of the load direction along n (perpendicular to the member).
  final double normalFactor;

  /// Component of the load direction along t.
  final double tangentialFactor;

  /// Q(x) over the member, from the matrix method.
  final LinearLoadFit fit;

  /// Load intensity (kN/m) at the start and at the end of the member.
  double get startIntensity => fit.ya;
  double get endIntensity => fit.yb;

  /// Perpendicular load, with sign: Q⊥(x).
  Polynomial get normalLoad => fit.polynomial.scaled(normalFactor);

  /// Load along the member, with sign: Q∥(x).
  Polynomial get tangentialLoad => fit.polynomial.scaled(tangentialFactor);
}

Polynomial _sum(Iterable<Polynomial> items) =>
    items.fold(Polynomial.zero, (a, b) => a + b);

/// N(x), V(x) and M(x) of one member, plus everything the step by step needs.
class MemberInternalForces {
  MemberInternalForces({
    required this.memberId,
    required this.startNodeId,
    required this.endNodeId,
    required this.length,
    required this.angleDegrees,
    required this.vertical,
    required this.contributions,
    required this.pieces,
    required this.startNormal,
    required this.startShear,
    required this.startMoment,
    this.previous,
  });

  final int memberId;

  /// Left (or bottom) node: x = 0.
  final int startNodeId;
  final int endNodeId;
  final double length;

  /// Direction of the member (t), degrees from the +x axis.
  final double angleDegrees;
  final bool vertical;

  /// Actions that arrive at the start node. When [previous] is not null,
  /// only the ones applied exactly at the start node are listed.
  final List<StartContribution> contributions;
  final PreviousMemberTransfer? previous;
  final List<DistributedPiece> pieces;

  /// Constants of integration: N, V (K1) and M (K2) at x = 0.
  final double startNormal;
  final double startShear;
  final double startMoment;

  late final Polynomial loadNormal = _sum(pieces.map((p) => p.normalLoad));
  late final Polynomial loadTangential =
      _sum(pieces.map((p) => p.tangentialLoad));

  /// ∫Q⊥ dx, without the constant.
  late final Polynomial shearIntegral = loadNormal.integral();
  late final Polynomial shear = shearIntegral.withConstant(startShear);

  /// ∫V dx, without the constant.
  late final Polynomial momentIntegral = shear.integral();
  late final Polynomial moment = momentIntegral.withConstant(startMoment);

  /// −∫Q∥ dx, without the constant.
  late final Polynomial normalIntegral = loadTangential.integral().scaled(-1);
  late final Polynomial normal = normalIntegral.withConstant(startNormal);

  Polynomial functionOf(InternalForceKind kind) => switch (kind) {
        InternalForceKind.normal => normal,
        InternalForceKind.shear => shear,
        InternalForceKind.moment => moment,
      };

  double valueAt(InternalForceKind kind, double x) => functionOf(kind).at(x);

  double startValue(InternalForceKind kind) => switch (kind) {
        InternalForceKind.normal => startNormal,
        InternalForceKind.shear => startShear,
        InternalForceKind.moment => startMoment,
      };
}

class InternalForcesResult {
  const InternalForcesResult({required this.methodId, required this.members});

  /// Which method produced this result (see [InternalForceMethod.id]).
  final String methodId;

  /// Ordered by member name (AB, BC...).
  final List<MemberInternalForces> members;

  MemberInternalForces? forMember(int memberId) {
    for (final m in members) {
      if (m.memberId == memberId) return m;
    }
    return null;
  }

  /// Largest absolute value of [kind] in the whole structure (used to scale
  /// the diagram).
  double maxAbs(InternalForceKind kind) {
    var best = 0.0;
    for (final m in members) {
      for (var i = 0; i <= 40; i++) {
        best = math.max(best, m.valueAt(kind, m.length * i / 40).abs());
      }
    }
    return best;
  }
}