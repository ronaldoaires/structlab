import 'package:flutter/material.dart';
import 'package:structlab/analysis/internal_forces/integral_method.dart';
import 'package:structlab/analysis/internal_forces/internal_force_method.dart';
import 'package:structlab/analysis/internal_forces/internal_forces_model.dart';
import 'package:structlab/analysis/internal_forces/sampling.dart';
import 'package:structlab/analysis/naming/labels.dart';
import 'package:structlab/analysis/reactions/reaction_solver.dart';
import 'package:structlab/core/theme/colors.dart';
import 'package:structlab/domain/models/structural_model.dart';
import 'package:structlab/l10n/strings_internal_forces_pt.dart';
import 'package:structlab/results/widgets/force_diagram.dart';
import 'package:structlab/results/widgets/member_force_card.dart';
import 'package:structlab/results/widgets/sampling_dialog.dart';
import 'package:structlab/results/widgets/step_blocks.dart';
import 'package:structlab/services/entitlements.dart';

const List<InternalForceKind> _tabOrder = [
  InternalForceKind.shear,
  InternalForceKind.moment,
  InternalForceKind.normal,
];

/// Diagrams of V, M and N with the step by step of each member.
/// To use another calculation method, pass a different [method].
class InternalForcesScreen extends StatefulWidget {
  const InternalForcesScreen({
    super.key,
    required this.model,
    required this.reactions,
    required this.entitlements,
    this.method = const IntegralMethod(),
  });

  /// A snapshot of the model.
  final StructuralModel model;
  final ReactionSolution reactions;
  final Entitlements entitlements;
  final InternalForceMethod method;

  @override
  State<InternalForcesScreen> createState() => _InternalForcesScreenState();
}

class _InternalForcesScreenState extends State<InternalForcesScreen> {
  late final InternalForcesOutcome _outcome =
      widget.method.solve(widget.model, widget.reactions);
  late final ModelLabels _labels = ModelLabels.of(widget.model);

  SamplingConfig _global = SamplingConfig.standard;
  final Map<int, SamplingConfig> _perMember = {};

  SamplingConfig _configOf(int memberId) => _perMember[memberId] ?? _global;

  Future<void> _editGlobal() async {
    final result = await showDialog<SamplingConfig>(
      context: context,
      builder: (_) =>
          SamplingDialog(length: 0, config: _global, stepOnly: true),
    );
    if (result == null || !mounted) return;
    setState(() {
      _global = result;
      _perMember.clear();
    });
  }

  Future<void> _editMember(MemberInternalForces f) async {
    final result = await showDialog<SamplingConfig>(
      context: context,
      builder: (_) =>
          SamplingDialog(length: f.length, config: _configOf(f.memberId)),
    );
    if (result == null || !mounted) return;
    setState(() => _perMember[f.memberId] = result);
  }

  @override
  Widget build(BuildContext context) {
    final result = _outcome.result;
    if (result == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(internalForcesTitle),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: StepCard(
            child: Text(internalForcesFailureMessage(_outcome.failure!)),
          ),
        ),
      );
    }

    final samples = {
      for (final f in result.members)
        f.memberId: _configOf(f.memberId).points(f.length),
    };

    return DefaultTabController(
      length: _tabOrder.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(internalForcesTitle),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          actions: [
            IconButton(
              tooltip: samplingGlobalTooltip,
              onPressed: _editGlobal,
              icon: const Icon(Icons.tune),
            ),
          ],
          bottom: TabBar(
            labelColor: brandBlue,
            unselectedLabelColor: inkMuted,
            indicatorColor: brandBlue,
            tabs: [for (final k in _tabOrder) Tab(text: forceTabLabel(k))],
          ),
        ),
        body: TabBarView(
          children: [
            for (final k in _tabOrder)
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  Text(
                    forceKindTitle(k),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    methodIntegralName,
                    style: const TextStyle(fontSize: 12, color: inkMuted),
                  ),
                  const SizedBox(height: 10),
                  StepCard(
                    child: ForceDiagramView(
                      model: widget.model,
                      result: result,
                      kind: k,
                      labels: _labels,
                      samples: samples,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    forceConventionNote(k),
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: inkMuted,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    memberListTitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: inkMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final f in result.members) ...[
                    MemberForceCard(
                      forces: f,
                      kind: k,
                      labels: _labels,
                      sampling: _configOf(f.memberId),
                      canSeeSteps: widget.entitlements.canSeeSteps,
                      onEditSampling: () => _editMember(f),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}