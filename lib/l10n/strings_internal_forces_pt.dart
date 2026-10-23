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
  InternalForcesFailure.unsupportedStructure => 'Esta estrutura tem um trecho fechado que o método das integrais ainda não resolve.',
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
  InternalForceKind.shear => 'Sinal: percorrendo a barra da esquerda para a direita (ou de baixo para cima), a cortante é positiva quando a parte da esquerda empurra a seção para cima (nas barras horizontais). Azul = positiva, vermelho = negativa.',
  InternalForceKind.moment => 'Sinal: o momento é positivo quando traciona as fibras de baixo (nas barras horizontais). O diagrama é desenhado do lado tracionado. Azul = positivo, vermelho = negativo.',
  InternalForceKind.normal => 'Sinal: a normal é positiva na tração (a barra está sendo puxada) e negativa na compressão (a barra está sendo apertada). Azul = tração, vermelho = compressão.',
};

/// One-sentence meaning of each internal force, for beginners.
String forceMeaning(InternalForceKind k) => switch (k) {
  InternalForceKind.shear => 'A cortante é a força que tenta "cortar" a barra, fazendo uma seção deslizar em relação à vizinha.',
  InternalForceKind.moment => 'O momento fletor mede o quanto a barra tende a dobrar (flexão). É ele que dimensiona a maioria das vigas.',
  InternalForceKind.normal => 'A normal é a força ao longo do eixo da barra: puxa (tração) ou aperta (compressão).',
};

/// Relation between diagrams worth remembering.
String forceTip(InternalForceKind k) => switch (k) {
  InternalForceKind.shear => 'Dica: onde a cortante muda de sinal (cruza o zero), o momento tem um máximo ou um mínimo.',
  InternalForceKind.moment => 'Dica: a inclinação do diagrama de momento em cada ponto é o valor da cortante naquele ponto.',
  InternalForceKind.normal =>
    'Dica: sem carga na direção da barra, a normal é constante ao longo dela.',
};

const String diagramHint =
    'Toque no diagrama para ler o valor naquele ponto.';

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
        'Imagine cortar a estrutura no início desta barra. K1 é a cortante nesse corte: a soma das forças perpendiculares à barra que atuam antes dela (reações, cargas concentradas e o que vem da barra anterior).',
      InternalForceKind.moment =>
        'K2 é o momento no início da barra. Se nenhum momento chega a esse ponto, K2 = 0 (como numa extremidade livre ou num apoio articulado). Se chega, usamos o valor do fim da barra anterior.',
      InternalForceKind.normal =>
        'K é a normal no início da barra: a soma das forças na direção dela que atuam antes do corte, com o sinal trocado (tração positiva). Quando a barra gira, a cortante da barra anterior passa a ser normal.',
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
    'Uma carga distribuída que varia de forma linear é uma reta Q(x). Para achá-la, usamos os dois pontos conhecidos (início e fim da carga na barra): x é a posição e y é a intensidade. Igualar o determinante a zero (regra de Sarrus) dá a equação da reta; isolando y, temos Q(x).';
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
    'O momento é sempre a integral da cortante: não precisa analisar sinais de cargas, só integrar V(x) e somar K2.';

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
    'Agora é só substituir x pelas posições ao longo da barra. O ponto inicial e o passo podem ser mudados no botão Pontos.';

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

String legendPositiveLabel(InternalForceKind k) => switch (k) {
      InternalForceKind.shear => 'Cortante positiva',
      InternalForceKind.moment => 'Momento positivo',
      InternalForceKind.normal => 'Tração',
    };

String legendNegativeLabel(InternalForceKind k) => switch (k) {
      InternalForceKind.shear => 'Cortante negativa',
      InternalForceKind.moment => 'Momento negativo',
      InternalForceKind.normal => 'Compressão',
    };