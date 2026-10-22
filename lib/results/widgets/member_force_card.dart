import 'package:flutter/material.dart';
import 'package:structlab/analysis/internal_forces/internal_forces_model.dart';
import 'package:structlab/analysis/internal_forces/polynomial.dart';
import 'package:structlab/analysis/internal_forces/sampling.dart';
import 'package:structlab/analysis/naming/labels.dart';
import 'package:structlab/core/theme/colors.dart';
import 'package:structlab/l10n/strings_internal_forces_pt.dart';
import 'package:structlab/results/widgets/matrix_view.dart';
import 'package:structlab/results/widgets/step_blocks.dart';

/// One member in one tab (N, V or M): the values at the chosen points and,
/// for subscribers, the step by step that leads to them.
class MemberForceCard extends StatelessWidget {
  const MemberForceCard({
    super.key,
    required this.forces,
    required this.kind,
    required this.labels,
    required this.sampling,
    required this.canSeeSteps,
    required this.onEditSampling,
  });

  final MemberInternalForces forces;
  final InternalForceKind kind;
  final ModelLabels labels;
  final SamplingConfig sampling;
  final bool canSeeSteps;
  final VoidCallback onEditSampling;

  @override
  Widget build(BuildContext context) {
    final f = forces;
    final poly = f.functionOf(kind);
    final points = sampling.points(f.length);

    return StepCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memberStepsTitle(labels.member(f.memberId)),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: ink,
                      ),
                    ),
                    Text(
                      memberDirectionName(f.vertical),
                      style: const TextStyle(fontSize: 13, color: inkMuted),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: onEditSampling,
                icon: const Icon(Icons.tune, size: 18),
                label: const Text(samplingButtonLabel),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final x in points)
                _ValueChip(x: x, value: poly.at(x), kind: kind),
            ],
          ),
          if (canSeeSteps)
            ..._steps(points, poly)
          else ...const [
            SizedBox(height: 14),
            _LockedNote(),
          ],
        ],
      ),
    );
  }

  List<Widget> _steps(List<double> points, Polynomial poly) {
    final f = forces;
    return [
      ..._startSection(),
      ..._loadSection(),
      StepSectionTitle(stepIntegrationTitle(kind)),
      if (kind == InternalForceKind.moment)
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: StepLine(momentIntegrationNote, color: inkMuted, size: 13),
        ),
      StepCard(
        color: brandTint,
        borderColor: brandTint,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, line) in integrationLines(f, kind).indexed)
              StepLine(
                line,
                mono: true,
                bold: i == integrationLines(f, kind).length - 1,
                color: i == integrationLines(f, kind).length - 1
                    ? brandBlue
                    : ink,
              ),
          ],
        ),
      ),
      StepSectionTitle(stepValuesTitle(kind)),
      const StepLine(stepValuesIntro, color: inkMuted, size: 13),
      const SizedBox(height: 6),
      StepCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final x in points)
              StepLine(evaluationLine(kind, poly, x), mono: true),
          ],
        ),
      ),
    ];
  }

  /// Step 1: the constant K (value at the start of the member).
  List<Widget> _startSection() {
    final f = forces;
    final lines = startLines(f, kind, labels);
    return [
      StepSectionTitle(stepStartTitle(kind)),
      StepLine(stepStartIntro(kind), color: inkMuted, size: 13),
      const SizedBox(height: 6),
      StepCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lines.isEmpty)
              StepLine(startNothingLine(kind))
            else
              for (final line in lines) StepLine(line),
          ],
        ),
      ),
      const SizedBox(height: 8),
      StepResultBox(text: startResultLine(kind, f.startValue(kind))),
    ];
  }

  /// Step 2: Q(x) from the matrix. The moment tab reuses V(x), so it has none.
  List<Widget> _loadSection() {
    if (kind == InternalForceKind.moment) return const [];
    final pieces = kind == InternalForceKind.normal
        ? [
            for (final p in forces.pieces)
              if (p.tangentialFactor.abs() > 1e-9) p,
          ]
        : forces.pieces;

    if (pieces.isEmpty) {
      if (kind == InternalForceKind.normal) return const [];
      return const [
        StepSectionTitle(stepFunctionTitle),
        StepLine(stepNoDistributedLoad),
      ];
    }

    return [
      const StepSectionTitle(stepFunctionTitle),
      const StepLine(stepFunctionIntro, color: inkMuted, size: 13),
      const SizedBox(height: 6),
      for (final p in pieces) ...[
        StepCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StepLine(pieceHeading(p), bold: true),
              const SizedBox(height: 8),
              LoadMatrixView(fit: p.fit),
              const SizedBox(height: 10),
              const StepLine(sarrusRuleNote, color: inkMuted, size: 12),
              StepLine(sarrusFilled(p.fit), mono: true),
              StepLine(sarrusSimplified(p.fit), mono: true),
              const SizedBox(height: 6),
              StepResultBox(text: loadFunctionLine(p.fit)),
              const SizedBox(height: 6),
              StepLine(loadDirectionNote(p, kind), color: inkMuted, size: 13),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    ];
  }
}

class _ValueChip extends StatelessWidget {
  const _ValueChip({required this.x, required this.value, required this.kind});

  final double x;
  final double value;
  final InternalForceKind kind;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: brandTint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            valueChipLabel(x),
            style: const TextStyle(fontSize: 11, color: inkMuted),
          ),
          Text(
            valueChipValue(kind, value),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: brandBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedNote extends StatelessWidget {
  const _LockedNote();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_outline, size: 18, color: inkMuted),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            stepsLockedForForces,
            style: TextStyle(fontSize: 13, height: 1.35, color: inkMuted),
          ),
        ),
      ],
    );
  }
}