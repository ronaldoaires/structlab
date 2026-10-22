import 'package:flutter/material.dart';
import 'package:structlab/analysis/conventions/sign_convention.dart';
import 'package:structlab/analysis/naming/labels.dart';
import 'package:structlab/analysis/reactions/reaction_solver.dart';
import 'package:structlab/analysis/reactions/reaction_steps.dart';
import 'package:structlab/core/format_number.dart';
import 'package:structlab/core/theme/colors.dart';
import 'package:structlab/domain/models/structural_model.dart';
import 'package:structlab/l10n/strings_reactions_pt.dart';
import 'package:structlab/l10n/strings_results_pt.dart';
import 'package:structlab/results/steps_screen.dart';
import 'package:structlab/services/entitlements.dart';

import 'internal_forces_screen.dart';

import 'package:structlab/l10n/strings_internal_forces_pt.dart';

/// Results for everybody: support reactions, placeholders for the N, V and M
/// diagrams, and a big button to the step by step (subscribers only).
class ReactionsScreen extends StatefulWidget {
  const ReactionsScreen({
    super.key,
    required this.model,
    required this.entitlements,
  });

  /// A snapshot of the model (the editor keeps changing its own copy).
  final StructuralModel model;
  final Entitlements entitlements;

  @override
  State<ReactionsScreen> createState() => _ReactionsScreenState();
}

class _ReactionsScreenState extends State<ReactionsScreen> {
  static const SignConvention _convention = SignConvention.standard;

  late final ReactionOutcome _outcome = solveReactions(widget.model);
  late final ModelLabels _labels = ModelLabels.of(widget.model);
  late final List<ReactionStep>? _steps = _outcome.solution == null
      ? null
      : buildReactionSteps(
          widget.model,
          _outcome.solution!,
          convention: _convention,
        );

  void _openSteps() {
    final steps = _steps;
    if (steps == null) return;
    if (!widget.entitlements.canSeeSteps) {
      _showSubscribersOnly();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            StepsScreen(steps: steps, labels: _labels, convention: _convention),
      ),
    );
  }

  Future<void> _showSubscribersOnly() {
    return showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: brandTint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.lock_outline, color: brandBlue),
              ),
              const SizedBox(height: 12),
              const Text(
                stepsSubscribersTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                stepsSubscribersBody,
                style: TextStyle(fontSize: 14, height: 1.35, color: inkMuted),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(gotItLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final solution = _outcome.solution;
    final canSee = widget.entitlements.canSeeSteps;

    return Scaffold(
      appBar: AppBar(
        title: const Text(resultsTitle),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: solution == null
                ? [
                    _FailureCard(
                      message: solveFailureMessage(_outcome.failure!),
                    ),
                  ]
                : [
                    _ReactionsCard(
                      reactions: solution.reactions,
                      labels: _labels,
                      convention: _convention,
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InternalForcesScreen(
                              model: widget.model,
                              reactions: solution,
                              entitlements: widget.entitlements,
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.show_chart),
                        label: const Text(openInternalForcesLabel),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_steps == null)
                      const Text(
                        stepsUnavailable,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: inkMuted),
                      )
                    else ...[
                      SizedBox(
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: _openSteps,
                          icon: Icon(
                            canSee
                                ? Icons.format_list_numbered
                                : Icons.lock_outline,
                          ),
                          label: const Text(seeStepsLabel),
                          style: FilledButton.styleFrom(
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        seeStepsCaption,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: inkMuted),
                      ),
                    ],
                  ],
          ),
        ),
      ),
    );
  }
}

double _shown(Reaction r, SignConvention c) => switch (r.kind) {
  ReactionKind.fx => c.x(r.value),
  ReactionKind.fy => c.y(r.value),
  ReactionKind.moment => c.moment(r.value),
};

class _ReactionsCard extends StatelessWidget {
  const _ReactionsCard({
    required this.reactions,
    required this.labels,
    required this.convention,
  });

  final List<Reaction> reactions;
  final ModelLabels labels;
  final SignConvention convention;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: lineColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            reactionsCardTitle,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: ink,
            ),
          ),
          const SizedBox(height: 10),
          for (final r in reactions)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: brandTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      reactionName(r, labels),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: brandBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      // Magnitude only: the arrow already shows the real direction.
                      '${formatNumber(_shown(r, convention).abs())} '
                      '${reactionUnit(r.kind)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
                  ),
                  Text(
                    reactionArrow(r.kind, r.value),
                    style: const TextStyle(fontSize: 22, color: brandBlue),
                  ),
                ],
              ),
            ),
          const Text(
            reactionsCardNote,
            style: TextStyle(fontSize: 12, color: inkMuted),
          ),
        ],
      ),
    );
  }
}

class _FailureCard extends StatelessWidget {
  const _FailureCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: lineColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 14, height: 1.35, color: ink),
            ),
          ),
        ],
      ),
    );
  }
}
