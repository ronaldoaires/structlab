enum IssueSeverity { error, warning }

enum IssueCode {
  noMembers,
  noSupports,
  noLoads,
  looseNode,
  disconnected,
  hypostaticCount,
  unstableGeometry,
  invalidDistributedLoad,
  zeroLoad,
  crossingMembers,
  nodeOnMember,
}

/// Static classification of the structure.
enum Staticity { unknown, hypostatic, isostatic, hyperstatic }

/// One problem found by the validator. The text is built in l10n from
/// [code] and [args], so the domain stays free of strings.
class ValidationIssue {
  const ValidationIssue({
    required this.code,
    required this.severity,
    this.nodeIds = const [],
    this.memberIds = const [],
    this.args = const [],
  });

  final IssueCode code;
  final IssueSeverity severity;

  /// Elements to highlight on the canvas.
  final List<int> nodeIds;
  final List<int> memberIds;

  /// Numbers used in the message (reaction count, number of parts...).
  final List<num> args;
}

class ValidationReport {
  ValidationReport({
    required List<ValidationIssue> issues,
    required this.staticity,
    this.degree = 0,
    this.reactions = 0,
  }) : issues = List.unmodifiable(
          [...issues]
            ..sort((a, b) => a.severity.index.compareTo(b.severity.index)),
        );

  final List<ValidationIssue> issues;
  final Staticity staticity;

  /// Degree of hyperstaticity (only meaningful when hyperstatic).
  final int degree;

  /// Total number of support reactions.
  final int reactions;

  int get errorCount =>
      issues.where((i) => i.severity == IssueSeverity.error).length;
  int get warningCount =>
      issues.where((i) => i.severity == IssueSeverity.warning).length;

  bool get hasErrors => errorCount > 0;

  /// True when the solver can receive this structure.
  bool get canSolve => !hasErrors;

  Set<int> get flaggedNodeIds => {for (final i in issues) ...i.nodeIds};
  Set<int> get flaggedMemberIds => {for (final i in issues) ...i.memberIds};
}