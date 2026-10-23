import 'package:structlab/analysis/internal_forces/internal_force_method.dart';
import 'package:structlab/analysis/internal_forces/internal_forces_model.dart';
import 'package:structlab/analysis/internal_forces/linear_load_fit.dart';
import 'package:structlab/analysis/internal_forces/polynomial.dart';
import 'package:structlab/analysis/naming/labels.dart';
import 'package:structlab/core/format_number.dart';
import 'package:structlab/core/format_polynomial.dart';
import 'package:structlab/l10n/strings_pt.dart';
import 'package:structlab/l10n/strings_reactions_pt.dart';

// Texts (Portuguese) of the internal forces results. The analysis layer gives
// data only; everything the student reads is built here.

String _f(double v, {int decimals = 2}) => formatNumber(v, decimals: decimals);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

const String internalForcesTitle = 'Esforços internos';
const String openInternalForcesLabel = 'Ver diagramas de esforços';
const String internalForcesCaption =
    'Cortante, momento e normal pelo método das integrais.';
const String methodIntegralName = 'Método das integrais';

String internalForcesFailureMessage(InternalForcesFailure f) => switch (f) {
      InternalForcesFailure.invalidModel =>
        'Não há barras válidas para calcular os esforços.',
      InternalForcesFailure.unsupportedStructure =>
        'Esta estrutura tem um trecho fechado que o método das integrais ainda não resolve.',
    };

String forceTabLabel(InternalForceKind k) => switch (k) {
      InternalForceKind.shear => 'Cortante',
      InternalForceKind.moment => 'Momento',
      InternalForceKind.normal => 'Normal',
    };

String forceKindTitle(InternalForceKind k) => switch (k) {
      InternalForceKind.shear => 'Esforço cortante (V)',
      InternalForceKind.moment => 'Momento fletor (M)',
      InternalForceKind.normal => 'Esforço normal (N)',
    };

String forceSymbol(InternalForceKind k) => switch (k) {
      InternalForceKind.shear => 'V',
      InternalForceKind.moment => 'M',
      InternalForceKind.normal => 'N',
    };

String forceUnit(InternalForceKind k) =>
    k == InternalForceKind.moment ? 'kN·m' : 'kN';

String forceConventionNote(InternalForceKind k) => switch (k) {
      InternalForceKind.shear =>
        'Percorrendo a barra da esquerda para a direita (ou de baixo para cima), a cortante é positiva quando as forças à esquerda do corte apontam para o lado esquerdo da barra (para cima, nas barras horizontais).',
      InternalForceKind.moment =>
        'O momento é positivo quando traciona a fibra do lado direito do sentido da barra (embaixo, nas barras horizontais). O diagrama é desenhado do lado tracionado.',
      InternalForceKind.normal =>
        'A normal é positiva quando a barra está tracionada (sendo puxada) e negativa quando está comprimida.',
    };

const String diagramHint =
    'Toque ou arraste sobre o diagrama para ler os valores.';

String diagramReading(String member, double x, InternalForceKind k, double v) =>
    'Barra $member · x = ${_f(x)} m · ${forceSymbol(k)} = ${_f(v)} ${forceUnit(k)}';

const String memberListTitle = 'BARRA A BARRA';

String memberStepsTitle(String label) => 'Barra $label';

String memberDirectionName(bool vertical) =>
    vertical ? 'De baixo para cima' : 'Da esquerda para a direita';

String valueChipLabel(double x) => 'x = ${_f(x)} m';

String valueChipValue(InternalForceKind k, double v) =>
    '${_f(v)} ${forceUnit(k)}';

const String stepsLockedForForces =
    'O passo a passo (matriz, integrais e substituições) é um recurso para assinantes. Os diagramas e os valores continuam liberados.';

// ---------------------------------------------------------------------------
// Sampling dialog
// ---------------------------------------------------------------------------

const String samplingButtonLabel = 'Pontos';
const String samplingGlobalTooltip = 'Passo de cálculo';
const String samplingDialogTitle = 'Pontos de cálculo';
const String samplingStepOnlyTitle = 'Passo de cálculo';
const String samplingFromLabel = 'Início';
const String samplingToLabel = 'Fim';
const String samplingStepLabel = 'Passo';
const String samplingStepError = 'O passo precisa ser maior que zero.';

String samplingRangeError(double length) =>
    'Use valores entre 0 e ${_f(length)} m, com o início menor que o fim.';

// ---------------------------------------------------------------------------
// Step 1: value at the start of the member (K)
// ---------------------------------------------------------------------------

String stepStartTitle(InternalForceKind k) => switch (k) {
      InternalForceKind.shear => '1. Cortante no início da barra (K1)',
      InternalForceKind.moment => '1. Momento no início da barra (K2)',
      InternalForceKind.normal => '1. Normal no início da barra (K)',
    };

String stepStartIntro(InternalForceKind k) => switch (k) {
      InternalForceKind.shear =>
        'K1 é o valor da cortante no ponto em que a barra começa. Ele vem da soma das forças perpendiculares à barra que atuam antes dela (reações, cargas concentradas e o fim da barra anterior).',
      InternalForceKind.moment =>
        'K2 é o valor do momento no início da barra. Se não chega momento, ele é nulo; se chega, usamos o valor do fim da barra anterior.',
      InternalForceKind.normal =>
        'K é a normal no início da barra: a soma das forças na direção da barra que atuam antes dela, com o sinal trocado (tração positiva). Quando a barra gira, a cortante da barra anterior vira normal.',
    };

String startConstantName(InternalForceKind k) => switch (k) {
      InternalForceKind.shear => 'K1',
      InternalForceKind.moment => 'K2',
      InternalForceKind.normal => 'K',
    };

String startNothingLine(InternalForceKind k) =>
    'Nada chega ao início da barra nesta direção: ${startConstantName(k)} = 0.';

String startResultLine(InternalForceKind k, double value) =>
    '${startConstantName(k)} = ${_f(value)} ${forceUnit(k)}';

String contributionName(ExternalAction a, ModelLabels l) => switch (a.kind) {
      ExternalActionKind.reaction => 'Reação ${reactionName(a.reaction!, l)}',
      ExternalActionKind.concentrated => 'Carga em ${l.node(a.nodeId)}',
      ExternalActionKind.moment => 'Momento em ${l.node(a.nodeId)}',
      ExternalActionKind.distributed =>
        'Resultante da carga na barra ${l.member(a.memberId!)}',
    };

/// Lines that explain where K comes from (only the ones that matter for [k]).
List<String> startLines(
  MemberInternalForces f,
  InternalForceKind k,
  ModelLabels l,
) {
  final lines = <String>[];
  final unit = forceUnit(k);

  final prev = f.previous;
  if (prev != null) {
    final name = l.member(prev.memberId);
    lines.add(
      'Fim da barra $name: N = ${_f(prev.endNormal)} kN · V = ${_f(prev.endShear)} kN · M = ${_f(prev.endMoment)} kN·m',
    );
    lines.add(
      prev.angleDegrees.abs() < 0.5
          ? 'As duas barras estão alinhadas, então os esforços continuam iguais.'
          : 'A barra muda de direção (${_f(prev.angleDegrees.abs(), decimals: 0)}°): a normal da barra anterior passa a atuar como cortante e a cortante como normal, com o sinal ajustado ao novo eixo.',
    );
    final v = prev.valueFor(k);
    if (v.abs() > 1e-9) {
      lines.add('Vem da barra $name: ${formatSigned(v)} $unit');
    }
  }

  for (final c in f.contributions) {
    final v = c.valueFor(k);
    if (v.abs() < 1e-9) continue;
    lines.add('${contributionName(c.action, l)}: ${formatSigned(v)} $unit');
  }
  return lines;
}

// ---------------------------------------------------------------------------
// Step 2: load function (matrix method)
// ---------------------------------------------------------------------------

const String stepFunctionTitle = '2. Função da carga (análise matricial)';
const String stepFunctionIntro =
    'Montamos a matriz com o ponto inicial e o ponto final da carga: x é a posição na barra e y é a intensidade. Igualamos o determinante a zero (regra de Sarrus: multiplicamos em diagonal, positivo de um lado e negativo do outro) e isolamos y, que é a função Q(x).';
const String stepNoDistributedLoad =
    'Não há carga distribuída nesta barra: Q(x) = 0.';
const String sarrusRuleNote =
    'Regra de Sarrus: (xa·yb + ya·x + xb·y) − (yb·x + xa·y + ya·xb) = 0';

String pieceHeading(DistributedPiece p) =>
    'Carga ${loadKindName(p.kind).toLowerCase()}: ${_f(p.startIntensity)} → ${_f(p.endIntensity)} kN/m em ${_f(p.length)} m';

String sarrusFilled(LinearLoadFit fit) {
  final xa = _f(fit.xa), ya = _f(fit.ya), xb = _f(fit.xb), yb = _f(fit.yb);
  return '($xa·$yb + $ya·x + $xb·y) − ($yb·x + $xa·y + $ya·$xb) = 0';
}

String sarrusSimplified(LinearLoadFit fit) =>
    formatLinearEquation(fit.xCoefficient, fit.yCoefficient, fit.constantTerm);

String loadFunctionLine(LinearLoadFit fit) =>
    'y = Q(x) = ${formatPolynomial(fit.polynomial)}';

String loadDirectionNote(DistributedPiece p, InternalForceKind k) {
  final isNormal = k == InternalForceKind.normal;
  final factor = isNormal ? p.tangentialFactor : p.normalFactor;
  if (factor.abs() < 1e-9) {
    return isNormal
        ? 'Esta carga é perpendicular à barra: ela não gera normal.'
        : 'Esta carga é paralela à barra: ela não gera cortante.';
  }
  if ((factor.abs() - 1).abs() < 1e-9) {
    return factor < 0
        ? 'A carga aponta contra o sentido positivo do esforço, então Q entra com sinal (−).'
        : 'A carga aponta a favor do sentido positivo do esforço, então Q entra com sinal (+).';
  }
  return 'A carga é inclinada em relação à barra: usamos só a componente ${isNormal ? 'na direção da barra' : 'perpendicular à barra'}, Q · ${_f(factor, decimals: 3)}.';
}

// ---------------------------------------------------------------------------
// Step 3: integration
// ---------------------------------------------------------------------------

String stepIntegrationTitle(InternalForceKind k) => switch (k) {
      InternalForceKind.shear => '3. Integrando a carga: cortante V(x)',
      InternalForceKind.moment => '2. Integrando a cortante: momento M(x)',
      InternalForceKind.normal => '2. Normal N(x)',
    };

const String momentIntegrationNote =
    'Aqui não é preciso analisar sinais: o momento é sempre a integral da cortante.';

/// The lines of the integration, the last one being the final function.
List<String> integrationLines(MemberInternalForces f, InternalForceKind k) {
  switch (k) {
    case InternalForceKind.shear:
      return [
        'V(x) = K1 + ∫ Q⊥(x) dx',
        if (!f.loadNormal.isZero)
          'V(x) = K1 + ∫ (${formatPolynomial(f.loadNormal)}) dx',
        'V(x) = ${formatPolynomial(f.shearIntegral, constantName: 'K1')}',
        'Com K1 = ${_f(f.startShear)}:  V(x) = ${formatPolynomial(f.shear)}',
      ];
    case InternalForceKind.moment:
      return [
        'M(x) = K2 + ∫ V(x) dx',
        'M(x) = K2 + ∫ (${formatPolynomial(f.shear)}) dx',
        'M(x) = ${formatPolynomial(f.momentIntegral, constantName: 'K2')}',
        'Com K2 = ${_f(f.startMoment)}:  M(x) = ${formatPolynomial(f.moment)}',
      ];
    case InternalForceKind.normal:
      if (f.loadTangential.isZero) {
        return [
          'Sem carga na direção da barra, a normal é constante: N(x) = K',
          'Com K = ${_f(f.startNormal)}:  N(x) = ${formatPolynomial(f.normal)}',
        ];
      }
      return [
        'N(x) = K − ∫ Q∥(x) dx',
        'N(x) = K − ∫ (${formatPolynomial(f.loadTangential)}) dx',
        'N(x) = ${formatPolynomial(f.normalIntegral, constantName: 'K')}',
        'Com K = ${_f(f.startNormal)}:  N(x) = ${formatPolynomial(f.normal)}',
      ];
  }
}

// ---------------------------------------------------------------------------
// Step 4: values at the points
// ---------------------------------------------------------------------------

String stepValuesTitle(InternalForceKind k) => switch (k) {
      InternalForceKind.shear => '4. Valores da cortante nos pontos',
      InternalForceKind.moment => '3. Valores do momento nos pontos',
      InternalForceKind.normal => '3. Valores da normal nos pontos',
    };

const String stepValuesIntro =
    'Basta substituir x pelas posições ao longo da barra (o ponto inicial e o passo podem ser mudados no botão Pontos).';

/// "V(1) = −5·1² + 19 = 14 kN"
String evaluationLine(InternalForceKind k, Polynomial p, double x) {
  final substituted = formatPolynomialAt(p, x);
  final result = _f(p.at(x));
  final head = '${forceSymbol(k)}(${_f(x)})';
  final unit = forceUnit(k);
  return substituted == result
      ? '$head = $result $unit'
      : '$head = $substituted = $result $unit';
}

const String diagramExpandTooltip = 'Ampliar diagrama';
const String diagramFitTooltip = 'Enquadrar diagrama';
const String diagramZoomHint =
    'Toque para ler valores. Arraste para mover e pince para ampliar.';