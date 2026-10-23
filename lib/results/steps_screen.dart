import 'package:flutter/material.dart';
import 'package:structlab/analysis/conventions/sign_convention.dart';
import 'package:structlab/analysis/naming/labels.dart';
import 'package:structlab/analysis/reactions/equivalent_loads.dart';
import 'package:structlab/core/format_number.dart';
import 'package:structlab/analysis/reactions/reaction_steps.dart';
import 'package:structlab/core/theme/colors.dart';
import 'package:structlab/l10n/strings_reactions_pt.dart';
import 'package:structlab/l10n/strings_results_pt.dart';
import 'package:structlab/results/widgets/load_shape_painter.dart';
import 'package:structlab/results/widgets/right_triangle_painter.dart';
import 'package:structlab/results/load_formula.dart';
import 'package:structlab/results/widgets/formula_view.dart';

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

  /// The names/convention step is shown as a note under the first step,
  /// not as a step of its own.
  late final NamesStep? _notes = widget.steps
      .whereType<NamesStep>()
      .firstOrNull;
  late final List<ReactionStep> _steps = [
    for (final s in widget.steps)
      if (s is! NamesStep) s,
  ];

  ModelLabels get _l => widget.labels;
  SignConvention get _c => widget.convention;

  void _go(int delta) {
    setState(() {
      _index = (_index + delta).clamp(0, _steps.length - 1).toInt();
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _steps.length;
    final step = _steps[_index];
    final last = _index == total - 1;
    final notes = _notes;

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
                      color: inkMuted,
                    ),
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
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      reactionStepIntro(step, _l),
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: inkMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _content(step),
                    if (_index == 0 && notes != null) ...[
                      const SizedBox(height: 24),
                      _notesSection(notes),
                    ],
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
                      onPressed: last
                          ? () => Navigator.pop(context)
                          : () => _go(1),
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
                  '$stepMembersLabel: ${s.memberIds.map(_l.member).join(', ')}',
                ),
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

  Widget _notesSection(NamesStep s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          stepNotesTitle,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: inkMuted,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          reactionStepIntro(s, _l),
          style: const TextStyle(fontSize: 13, height: 1.35, color: inkMuted),
        ),
        const SizedBox(height: 10),
        _names(s),
      ],
    );
  }

  Widget _equivalents(EquivalentLoadsStep s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final e in s.loads) ...[
          _EquivalentLoadCard(load: e, labels: _l),
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
              child: _Line(
                reactionSummaryLine(r, _l, _c),
                bold: true,
                mono: true,
              ),
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

/// Shown under the length dimension L of an inclined member: where L comes
/// from. Sketch of the right triangle on the left, Pythagoras on the right.
class _PythagorasBlock extends StatelessWidget {
  const _PythagorasBlock({required this.load, required this.labels});

  final EquivalentLoad load;
  final ModelLabels labels;

  @override
  Widget build(BuildContext context) {
    final e = load;
    final formula = buildPythagorasFormula(e);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: brandTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            pythagorasTitle,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            pythagorasIntro(e, labels),
            style: const TextStyle(fontSize: 12.5, height: 1.35, color: inkMuted),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 96,
                child: CustomPaint(
                  painter: RightTrianglePainter(
                    legRatio: e.verticalLeg / e.horizontalLeg,
                    risesToRight: e.risesToRight,
                    horizontalLabel: horizontalLegLabel(e.horizontalLeg),
                    verticalLabel: verticalLegLabel(e.verticalLeg),
                    hypotenuseLabel: hypotenuseLabel,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FormulaLineView(line: formula.symbolic, color: brandBlue),
                    const SizedBox(height: 8),
                    FormulaLineView(line: formula.substituted),
                    const SizedBox(height: 8),
                    FormulaLineView(line: formula.result, bold: true),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Card of one distributed load: the figure, then the formulas side by side
/// (resultant on the left, CG on the right).
class _EquivalentLoadCard extends StatelessWidget {
  const _EquivalentLoadCard({required this.load, required this.labels});

  final EquivalentLoad load;
  final ModelLabels labels;

  Widget _columns(Widget left, Widget right) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: left),
        const VerticalDivider(width: 24, thickness: 1, color: lineColor),
        Expanded(child: right),
      ],
    ),
  );

  Widget _title(String text, {bool alignEnd = false}) => Text(
    text,
    textAlign: alignEnd ? TextAlign.end : TextAlign.start,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w800,
      color: ink,
    ),
  );

  Widget _symbolicColumn(
    String title,
    FormulaBlock block, {
    bool alignEnd = false,
  }) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: _title(title, alignEnd: alignEnd),
        ),
        const SizedBox(height: 8),
        FormulaLineView(
          line: block.symbolic,
          color: brandBlue,
          alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        ),
      ],
    );
  }

  Widget _valuesColumn(FormulaBlock block, {bool alignEnd = false}) {
    final alignment = alignEnd ? Alignment.centerRight : Alignment.centerLeft;
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        FormulaLineView(line: block.substituted, alignment: alignment),
        const SizedBox(height: 10),
        FormulaLineView(line: block.result, bold: true, alignment: alignment),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = load;
    String q(String name, double v) => '$name = ${formatNumber(v)} kN/m';

    // Labels: q (rectangle, triangle) or H and h (trapezoid).
    final (left, right) = switch (e.shape) {
      LoadShape.rectangle => (q('q', e.q1), null),
      LoadShape.triangle =>
        e.peakAtEnd ? (null, q('q', e.q2)) : (q('q', e.q1), null),
      LoadShape.trapezoid =>
        e.peakAtEnd
            ? (q('h', e.q1), q('H', e.q2))
            : (q('H', e.q1), q('h', e.q2)),
    };

    final formulas = buildLoadFormulas(e);
    final from = equivalentCentroidFrom(e, labels);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Line(
            '${equivalentTitle(e, labels)} · ${equivalentShapeName(e)}',
            bold: true,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 216,
            child: CustomPaint(
              size: Size.infinite,
              painter: LoadShapePainter(
                q1: e.q1,
                q2: e.q2,
                cgFraction: e.centroid / e.length,
                labelLeft: left,
                labelRight: right,
                leftSpanLabel: '${formatNumber(e.centroid)} m',
                rightSpanLabel: '${formatNumber(e.length - e.centroid)} m',
                startLabel: labels.node(e.startNodeId),
                endLabel: labels.node(e.endNodeId),
                resultantLabel: resultantFigureLabel(e.resultant),
                lengthLabel: spanLengthLabel(e.length),
              ),
            ),
          ),
          if (e.isInclined) ...[
            const SizedBox(height: 8),
            _PythagorasBlock(load: e, labels: labels),
          ],
          const Divider(height: 20, color: lineColor),
          Center(
            child: Text(
              formulaShapeTitle(e.shape),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _columns(
            _symbolicColumn(formulaResultantTitle, formulas.resultant),
            _symbolicColumn(
              formulaCentroidTitle,
              formulas.centroid,
              alignEnd: true,
            ),
          ),
          const Divider(height: 24, color: lineColor),
          _columns(
            _valuesColumn(formulas.resultant),
            _valuesColumn(formulas.centroid, alignEnd: true),
          ),
          if (from.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(from, style: const TextStyle(fontSize: 12, color: inkMuted)),
          ],
        ],
      ),
    );
  }
}
