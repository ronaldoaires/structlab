import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:structlab/analysis/conventions/sign_convention.dart';
import 'package:structlab/analysis/naming/labels.dart';
import 'package:structlab/analysis/reactions/reaction_steps.dart';
import 'package:structlab/core/theme/colors.dart';
import 'package:structlab/l10n/strings_reactions_pt.dart';
import 'package:structlab/l10n/strings_results_pt.dart';

/// The step by step of the reactions, one step at a time.
class StepsScreen extends StatefulWidget {
  const StepsScreen({
    super.key,
    required this.steps,
    required this.labels,
    this.convention = SignConvention.standard,
  });

  final List<ReactionStep> steps;
  final ModelLabels labels;
  final SignConvention convention;

  @override
  State<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends State<StepsScreen> {
  int _index = 0;

  ModelLabels get _l => widget.labels;
  SignConvention get _c => widget.convention;

  void _go(int delta) {
    setState(() {
      _index = (_index + delta).clamp(0, widget.steps.length - 1).toInt();
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.steps.length;
    final step = widget.steps[_index];
    final last = _index == total - 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text(stepsTitle),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stepCounter(_index + 1, total),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: inkMuted),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_index + 1) / total,
                      minHeight: 6,
                      color: brandBlue,
                      backgroundColor: lineColor,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                key: ValueKey(_index), // each step starts at the top
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reactionStepTitle(step, _l),
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: ink),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      reactionStepIntro(step, _l),
                      style: const TextStyle(
                          fontSize: 14, height: 1.35, color: inkMuted),
                    ),
                    const SizedBox(height: 16),
                    _content(step),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _index == 0 ? null : () => _go(-1),
                      child: const Text(previousLabel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed:
                          last ? () => Navigator.pop(context) : () => _go(1),
                      child: Text(last ? finishLabel : nextLabel),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Content of each kind of step
  // ---------------------------------------------------------------------------

  Widget _content(ReactionStep step) => switch (step) {
        NamesStep s => _names(s),
        EquivalentLoadsStep s => _equivalents(s),
        DecompositionStep s => _decomposition(s),
        UnknownsStep s => _unknowns(s),
        EquationStep s => _equation(s),
        CheckStep s => _check(s),
        SummaryStep s => _summary(s),
      };

  Widget _names(NamesStep s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Line('$stepNodesLabel: ${s.nodeIds.map(_l.node).join(', ')}'),
              if (s.memberIds.isNotEmpty)
                _Line(
                    '$stepMembersLabel: ${s.memberIds.map(_l.member).join(', ')}'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          color: brandTint,
          borderColor: brandTint,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [for (final t in conventionLines(_c)) _Line(t)],
          ),
        ),
      ],
    );
  }

  Widget _equivalents(EquivalentLoadsStep s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final e in s.loads) ...[
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Line(equivalentTitle(e, _l), bold: true),
                const SizedBox(height: 8),
                _Line(equivalentForceLine(e), mono: true),
                _Line(equivalentCentroidLine(e, _l), mono: true),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _decomposition(DecompositionStep s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final a in s.actions) ...[
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, line) in decompositionLines(a, _l).indexed)
                  _Line(line, bold: i == 0, mono: i > 0),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _unknowns(UnknownsStep s) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [for (final line in unknownsLines(s, _l)) _Line(line)],
      ),
    );
  }

  Widget _equation(EquationStep s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final t in s.terms)
                _TermRow(
                  text: termText(t, s.kind, _c, _l),
                  unknown: t.isUnknown,
                ),
              const Divider(height: 20, color: lineColor),
              _Line(equationSumLine(s, _l, _c), mono: true, bold: true),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ResultBox(text: equationResultLine(s, _l, _c)),
      ],
    );
  }

  Widget _check(CheckStep s) {
    final ok = s.sum.abs() < 1e-6;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final t in s.terms)
                _TermRow(
                  text: termText(t, EquationKind.sumMoment, _c, _l),
                  unknown: false,
                ),
              const Divider(height: 20, color: lineColor),
              _Line(checkSumLine(s, _c), mono: true, bold: true),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ResultBox(
          text: checkSumLine(s, _c).split(' = ').last,
          color: ok ? success : danger,
        ),
      ],
    );
  }

  Widget _summary(SummaryStep s) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final r in s.reactions)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _Line(reactionSummaryLine(r, _l, _c),
                  bold: true, mono: true),
            ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Small building blocks
// -----------------------------------------------------------------------------

class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    this.color = Colors.white,
    this.borderColor = lineColor,
  });

  final Widget child;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.text, {this.bold = false, this.mono = false});

  final String text;
  final bool bold;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          height: 1.35,
          color: ink,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
          fontFeatures: mono ? const [FontFeature.tabularFigures()] : null,
        ),
      ),
    );
  }
}

/// "Carga em B     −10.00 · 1.00 = −10.00". The unknown is highlighted.
class _TermRow extends StatelessWidget {
  const _TermRow({required this.text, required this.unknown});

  final TermText text;
  final bool unknown;

  @override
  Widget build(BuildContext context) {
    final right = text.calc.isEmpty
        ? (text.value ?? '')
        : (text.value == null ? text.calc : '${text.calc} = ${text.value}');
    final color = unknown ? brandBlue : ink;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: unknown ? brandTint : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              text.source,
              style: TextStyle(
                fontSize: 13.5,
                color: color,
                fontWeight: unknown ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              right,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBox extends StatelessWidget {
  const _ResultBox({required this.text, this.color = brandBlue});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}