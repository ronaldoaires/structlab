import 'dart:math' as math;

import 'package:structlab/analysis/conventions/sign_convention.dart';
import 'package:structlab/analysis/naming/labels.dart';
import 'package:structlab/analysis/reactions/equivalent_loads.dart';
import 'package:structlab/analysis/reactions/reaction_solver.dart';
import 'package:structlab/analysis/reactions/reaction_steps.dart';
import 'package:structlab/core/format_number.dart';
import 'package:structlab/l10n/strings_pt.dart';

// Texts (Portuguese) of the reactions step by step. The analysis layer gives
// data only; everything the student reads is built here.

String _f(double v, {int decimals = 2}) => formatNumber(v, decimals: decimals);

String _paren(double v) => v < 0 ? '(${_f(v)})' : _f(v);

// ---------------------------------------------------------------------------
// Solver failures
// ---------------------------------------------------------------------------

String solveFailureMessage(SolveFailure f) => switch (f) {
  SolveFailure.invalidModel =>
    'Corrija os problemas do modelo antes de calcular. Toque em Validar para ver quais são.',
  SolveFailure.hypostatic =>
    'A estrutura é hipostática (não está travada) e não tem solução por equilíbrio.',
  SolveFailure.hyperstatic =>
    'A estrutura é hiperestática: o cálculo das reações precisa do método da rigidez, que ainda não está disponível.',
  SolveFailure.singular =>
    'Não foi possível resolver as equações de equilíbrio desta estrutura.',
};

// ---------------------------------------------------------------------------
// Names, units, directions
// ---------------------------------------------------------------------------

/// VA, HA, MA: V = vertical, H = horizontal, M = moment.
String reactionName(Reaction r, ModelLabels l) => switch (r.kind) {
  ReactionKind.fx => 'H${l.node(r.nodeId)}',
  ReactionKind.fy => 'V${l.node(r.nodeId)}',
  ReactionKind.moment => 'M${l.node(r.nodeId)}',
};

String reactionUnit(ReactionKind k) =>
    k == ReactionKind.moment ? 'kN·m' : 'kN';

/// Real direction of a reaction (from its internal sign): → ← ↑ ↓ ↺ ↻.
/// Empty when the value is zero.
String reactionArrow(ReactionKind k, double internalValue) {
  if (internalValue.abs() < 1e-9) return '';
  final positive = internalValue > 0;
  return switch (k) {
    ReactionKind.fx => positive ? '→' : '←',
    ReactionKind.fy => positive ? '↑' : '↓',
    ReactionKind.moment => positive ? '↺' : '↻',
  };
}

String actionName(AppliedAction a, ModelLabels l) => switch (a.kind) {
  ActionKind.concentrated => 'Carga em ${l.node(a.nodeId)}',
  ActionKind.moment => 'Momento em ${l.node(a.nodeId)}',
  ActionKind.distributed =>
    'Resultante ${l.node(a.nodeId)}${l.node(a.equivalent!.endNodeId)}',
};

int _compSign(SignConvention c, ReactionKind k) => switch (k) {
  ReactionKind.fx => c.xSign,
  ReactionKind.fy => c.ySign,
  ReactionKind.moment => c.momentSign,
};

int _eqSign(SignConvention c, EquationKind k) => switch (k) {
  EquationKind.sumFx => c.xSign,
  EquationKind.sumFy => c.ySign,
  EquationKind.sumMoment => c.momentSign,
};

// ---------------------------------------------------------------------------
// Convention
// ---------------------------------------------------------------------------

List<String> conventionLines(SignConvention c) => [
  'Força para ${c.xSign == 1 ? 'a direita' : 'a esquerda'} é positiva.',
  'Força para ${c.ySign == 1 ? 'cima' : 'baixo'} é positiva.',
  'Momento ${c.momentSign == 1 ? 'anti-horário' : 'horário'} é positivo.',
  c.termOrder == TermOrder.leftToRight
      ? 'Os termos são listados da esquerda para a direita.'
      : 'Os termos são listados da direita para a esquerda.',
];

// ---------------------------------------------------------------------------
// Step titles and intros
// ---------------------------------------------------------------------------

String reactionStepTitle(ReactionStep s, ModelLabels l) => switch (s) {
  NamesStep() => 'Nomes e convenção de sinais',
  EquivalentLoadsStep() => 'Cargas distribuídas: força equivalente',
  DecompositionStep() => 'Decomposição das cargas inclinadas',
  UnknownsStep() => 'Incógnitas: reações de apoio',
  EquationStep(:final kind, :final pivotNodeId) => switch (kind) {
    EquationKind.sumMoment => 'ΣM em ${l.node(pivotNodeId!)} = 0',
    EquationKind.sumFy => 'ΣFy = 0',
    EquationKind.sumFx => 'ΣFx = 0',
  },
  CheckStep(:final pivotNodeId) =>
    'Verificação: ΣM em ${l.node(pivotNodeId)} = 0',
  SummaryStep() => 'Resultado: reações de apoio',
};

String reactionStepIntro(ReactionStep s, ModelLabels l) => switch (s) {
  NamesStep() =>
    'Cada nó recebe uma letra (A, B, C…) da esquerda para a direita. As barras levam o nome dos seus nós (AB, BC…).',
  EquivalentLoadsStep() =>
    'Cada carga distribuída é trocada por uma única força, a resultante R, aplicada no centro de gravidade CG da carga.',
  DecompositionStep() =>
    'Forças inclinadas são separadas em componente horizontal (Fx) e vertical (Fy) para entrar nas equações. O ângulo é medido a partir do eixo x, no sentido anti-horário.',
  UnknownsStep() =>
    'Cada reação é adotada como positiva. Se o resultado sair negativo, ela atua no sentido contrário ao adotado.',
  EquationStep(:final kind, :final pivotNodeId) => switch (kind) {
    EquationKind.sumMoment =>
      'Somamos os momentos em torno de ${l.node(pivotNodeId!)}. As reações que passam por esse ponto têm braço zero e não aparecem.',
    EquationKind.sumFy => 'Soma das forças verticais.',
    EquationKind.sumFx => 'Soma das forças horizontais.',
  },
  CheckStep(:final pivotNodeId) =>
    'Se as reações estão certas, os momentos em torno de qualquer outro ponto também somam zero. Testamos em ${l.node(pivotNodeId)}.',
  SummaryStep() =>
    'Valor positivo: sentido adotado. Valor negativo: sentido contrário ao adotado.',
};

String equivalentTitle(EquivalentLoad e, ModelLabels l) =>
    'Carga ${l.node(e.startNodeId)}${l.node(e.endNodeId)}';

String equivalentShapeName(EquivalentLoad e) => switch (e.shape) {
  LoadShape.rectangle => 'Retangular',
  LoadShape.triangle => 'Triangular',
  LoadShape.trapezoid => 'Trapezoidal',
};

String equivalentForceLine(EquivalentLoad e) => switch (e.shape) {
  LoadShape.rectangle =>
    'R = q · L = ${_f(e.high)} · ${_f(e.length)} = ${_f(e.resultant)} kN',
  LoadShape.triangle =>
    'R = q · L / 2 = ${_f(e.high)} · ${_f(e.length)} / 2 = ${_f(e.resultant)} kN',
  LoadShape.trapezoid =>
    'R = (H + h) · L / 2 = (${_f(e.high)} + ${_f(e.low)}) · ${_f(e.length)} / 2'
        ' = ${_f(e.resultant)} kN',
};

String equivalentCentroidLine(EquivalentLoad e, ModelLabels l) {
  final cg = _f(e.centroidFromPeak);
  return switch (e.shape) {
    LoadShape.rectangle => 'CG = L / 2 = ${_f(e.length)} / 2 = $cg m',
    LoadShape.triangle => 'CG = L / 3 = ${_f(e.length)} / 3 = $cg m',
    LoadShape.trapezoid =>
      'CG = L · (H + 2·h) / (3 · (H + h)) = ${_f(e.length)} · '
          '(${_f(e.high)} + 2·${_f(e.low)}) / '
          '(3 · (${_f(e.high)} + ${_f(e.low)})) = $cg m',
  };
}

/// Where the CG is measured from. Empty for the rectangle (middle of the span).
String equivalentCentroidFrom(EquivalentLoad e, ModelLabels l) =>
    e.shape == LoadShape.rectangle
        ? ''
        : '(CG medido a partir de ${l.node(e.peakNodeId)}, lado da maior altura)';

/// [title, Fx line, Fy line] for an inclined force.
List<String> decompositionLines(AppliedAction a, ModelLabels l) {
  final mag = math.sqrt(a.fx * a.fx + a.fy * a.fy);
  final ang = math.atan2(a.fy, a.fx) * 180 / math.pi;
  final angText = '${_f(ang, decimals: 1)}°';
  return [
    '${actionName(a, l)}: ${_f(mag)} kN a $angText',
    'Fx = ${_f(mag)} · cos($angText) = ${_f(a.fx)} kN',
    'Fy = ${_f(mag)} · sen($angText) = ${_f(a.fy)} kN',
  ];
}

// ---------------------------------------------------------------------------
// Unknowns
// ---------------------------------------------------------------------------

List<String> unknownsLines(UnknownsStep s, ModelLabels l) {
  final byNode = <int, List<Reaction>>{};
  for (final r in s.reactions) {
    byNode.putIfAbsent(r.nodeId, () => []).add(r);
  }
  return [
    for (final e in byNode.entries)
      'Apoio em ${l.node(e.key)}: '
          '${e.value.map((r) => reactionName(r, l)).join(', ')}',
  ];
}

// ---------------------------------------------------------------------------
// Equation lines
// ---------------------------------------------------------------------------

/// A line of an equation: "source   calc   = value".
/// [calc] is empty when there is no lever arm; [value] is null for the unknown.
class TermText {
  const TermText({required this.source, required this.calc, this.value});
  final String source;
  final String calc;
  final String? value;
}

String _termSource(EquationTerm t, ModelLabels l) {
  final suffix = !t.decomposed
      ? ''
      : switch (t.component) {
          ReactionKind.fx => ' (Fx)',
          ReactionKind.fy => ' (Fy)',
          ReactionKind.moment => '',
        };
  return switch (t.source) {
    TermSource.concentrated => 'Carga em ${l.node(t.nodeId)}$suffix',
    TermSource.moment => 'Momento em ${l.node(t.nodeId)}',
    TermSource.distributed =>
      'Resultante ${l.node(t.nodeId)}${l.node(t.endNodeId!)}$suffix',
    TermSource.reaction => 'Reação ${reactionName(t.reaction!, l)}',
  };
}

String _unknownPart(double coef, String name) {
  if ((coef.abs() - 1).abs() < 1e-9) return coef < 0 ? '$minusSign$name' : name;
  return '${_f(coef)} · $name';
}

TermText termText(
  EquationTerm t,
  EquationKind eq,
  SignConvention c,
  ModelLabels l,
) {
  final comp = _compSign(c, t.component);
  final e = _eqSign(c, eq);
  final source = _termSource(t, l);

  if (t.isUnknown) {
    final coef = (e * comp * t.value).toDouble();
    final name = reactionName(t.reaction!, l);
    final sign = coef < 0 ? minusSign : '+';
    final mag = (coef.abs() - 1).abs() < 1e-9
        ? name
        : '${_f(coef.abs())} · $name';
    return TermText(source: source, calc: '$sign$mag');
  }

  final factor = (comp * t.factor!).toDouble();
  final value = (e * t.value).toDouble();
  final calc = t.arm == null
      ? ''
      : '${formatSigned(factor)} · ${_paren((e * comp * t.arm!).toDouble())}';
  return TermText(source: source, calc: calc, value: formatSigned(value));
}

/// "4.00 · By − 50.00 = 0"
String equationSumLine(EquationStep s, ModelLabels l, SignConvention c) {
  final e = _eqSign(c, s.kind);
  final coefD = (e * _compSign(c, s.solved.kind) * s.coefficient).toDouble();
  final knownD = (e * s.knownSum).toDouble();
  final known = knownD.abs() < 1e-9
      ? ''
      : ' ${knownD < 0 ? minusSign : '+'} ${_f(knownD.abs())}';
  return '${_unknownPart(coefD, reactionName(s.solved, l))}$known = 0';
}

/// "By = 50.00 / 4.00 = 12.50 kN ↑"
String equationResultLine(EquationStep s, ModelLabels l, SignConvention c) {
  final e = _eqSign(c, s.kind);
  final sign = _compSign(c, s.solved.kind);
  final coefD = (e * sign * s.coefficient).toDouble();
  final knownD = (e * s.knownSum).toDouble();
  final name = reactionName(s.solved, l);
  final resD = (sign * s.result).toDouble();
  final arrow = reactionArrow(s.solved.kind, s.result);
  final tail =
      '${_f(resD)} ${reactionUnit(s.solved.kind)}${arrow.isEmpty ? '' : ' $arrow'}';
  if ((coefD - 1).abs() < 1e-9) return '$name = $tail';
  return '$name = ${_f(-knownD)} / ${_paren(coefD)} = $tail';
}

// ---------------------------------------------------------------------------
// Check and summary
// ---------------------------------------------------------------------------

/// "−70.00 + 40.00 + 30.00 = 0.00 ✓"
String checkSumLine(CheckStep s, SignConvention c) {
  final e = c.momentSign;
  final buf = StringBuffer();
  for (var i = 0; i < s.terms.length; i++) {
    final v = (e * s.terms[i].value).toDouble();
    if (i == 0) {
      buf.write(_f(v));
    } else {
      buf.write(' ${v < 0 ? minusSign : '+'} ${_f(v.abs())}');
    }
  }
  if (s.terms.isEmpty) buf.write(_f(0));
  buf.write(' = ${_f((e * s.sum).toDouble())}');
  buf.write(s.sum.abs() < 1e-6 ? ' ✓' : ' ✗');
  return buf.toString();
}

/// "Ay = 17.50 kN ↑". Negative values get the "opposite sense" note.
String reactionSummaryLine(Reaction r, ModelLabels l, SignConvention c) {
  final shown = (_compSign(c, r.kind) * r.value).toDouble();
  final arrow = reactionArrow(r.kind, r.value);
  final note = shown < -1e-9 ? ' (sentido contrário ao adotado)' : '';
  return '${reactionName(r, l)} = ${_f(shown)} ${reactionUnit(r.kind)}'
      '${arrow.isEmpty ? '' : ' $arrow'}$note';
}