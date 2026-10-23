import 'package:flutter_test/flutter_test.dart';
import 'package:structlab/analysis/conventions/sign_convention.dart';
import 'package:structlab/analysis/naming/labels.dart';
import 'package:structlab/analysis/reactions/reaction_solver.dart';
import 'package:structlab/analysis/reactions/reaction_steps.dart';
import 'package:structlab/domain/models/load.dart';
import 'package:structlab/domain/models/member.dart';
import 'package:structlab/domain/models/node.dart';
import 'package:structlab/domain/models/structural_model.dart';
import 'package:structlab/domain/models/support.dart';
import 'package:structlab/l10n/strings_reactions_pt.dart';

StructuralModel _beam() => StructuralModel()
  ..nodes.addAll([
    StructuralNode(id: 1, position: const Offset(0, 0)),
    StructuralNode(id: 2, position: const Offset(1, 0)),
    StructuralNode(id: 3, position: const Offset(4, 0)),
  ])
  ..members.addAll([
    StructuralMember(id: 4, startNodeId: 1, endNodeId: 2),
    StructuralMember(id: 5, startNodeId: 2, endNodeId: 3),
  ])
  ..supports.addAll([
    StructuralSupport(id: 6, nodeId: 1, type: SupportType.pin),
    StructuralSupport(id: 7, nodeId: 3, type: SupportType.roller),
  ])
  ..loads.addAll([
    StructuralLoad(
      id: 8,
      kind: LoadKind.concentrated,
      nodeId: 2,
      q1: 10,
      angleDegrees: -90,
    ),
    StructuralLoad(
      id: 9,
      kind: LoadKind.uniform,
      nodeId: 1,
      endNodeId: 3,
      q1: 5,
      q2: 5,
      angleDegrees: -90,
    ),
  ]);

void main() {
  final model = _beam();
  final labels = ModelLabels.of(model);
  const c = SignConvention.standard;
  final solution = solveReactions(model).solution!;
  final steps = buildReactionSteps(model, solution)!;
  final eqs = steps.whereType<EquationStep>().toList();

  test('titles', () {
    expect(reactionStepTitle(eqs[0], labels), 'ΣM em A = 0');
    expect(reactionStepTitle(eqs[1], labels), 'ΣFy = 0');
    expect(reactionStepTitle(eqs[2], labels), 'ΣFx = 0');
  });

  test('ΣM equation lines, as the student reads them', () {
    final lines = [
      for (final t in eqs[0].terms)
        termText(t, EquationKind.sumMoment, c, labels),
    ];
    expect(lines[0].source, 'Carga em B');
    expect(lines[0].calc, '−10 · 1');
    expect(lines[0].value, '−10');
    expect(lines[1].source, 'Resultante AC');
    expect(lines[1].calc, '−20 · 2');
    expect(lines[1].value, '−40');
    expect(lines[2].source, 'Reação VC');
    expect(lines[2].calc, '+4 · VC');
    expect(lines[2].value, isNull);

    expect(equationSumLine(eqs[0], labels, c), '4 · VC − 50 = 0');
    expect(equationResultLine(eqs[0], labels, c), 'VC = 50 / 4 = 12.5 kN ↑');
  });

  test('ΣFy and ΣFx lines', () {
    expect(equationSumLine(eqs[1], labels, c), 'VA − 17.5 = 0');
    expect(equationResultLine(eqs[1], labels, c), 'VA = 17.5 kN ↑');
    expect(equationResultLine(eqs[2], labels, c), 'HA = 0 kN');
  });

  test('equivalent load lines', () {
    final e = steps.whereType<EquivalentLoadsStep>().single.loads.single;
    expect(equivalentTitle(e, labels), 'Carga AC');
    expect(equivalentForceLine(e), 'R = q · L = 5 · 4 = 20 kN');
    expect(equivalentCentroidLine(e, labels), 'CG = L / 2 = 4 / 2 = 2 m');
  });

  test('check and summary', () {
    final check = steps.whereType<CheckStep>().single;
    expect(reactionStepTitle(check, labels), 'Verificação: ΣM em C = 0');
    expect(checkSumLine(check, c).endsWith('✓'), isTrue);

    final summary = steps.whereType<SummaryStep>().single;
    expect(
      reactionSummaryLine(summary.reactions[1], labels, c),
      'VA = 17.5 kN ↑',
    );
  });

  test('negative value is explained as opposite sense', () {
    final r = Reaction(
      supportId: 1,
      nodeId: 3,
      point: const Offset(4, 0),
      kind: ReactionKind.fy,
      value: -2,
    );
    // In 'negative value is explained as opposite sense':
    expect(
      reactionSummaryLine(r, labels, c),
      'VC = −2 kN → sentido contrário ao adotado: 2 kN ↓',
    );
  });

  test('flipped convention changes the shown sign only', () {
    const flipped = SignConvention(ySign: -1);
    final r = solution.reactions[1]; // Ay = +17.5 internal (up)
    // In 'flipped convention changes the shown sign only':
    expect(
      reactionSummaryLine(r.copyWithValue(17.5), labels, flipped),
      'VA = −17.5 kN → sentido contrário ao adotado: 17.5 kN ↑',
    );
  });

  test('solver failures have a message', () {
    for (final f in SolveFailure.values) {
      expect(solveFailureMessage(f), isNotEmpty);
    }
  });
}

extension on Reaction {
  Reaction copyWithValue(double v) => Reaction(
    supportId: supportId,
    nodeId: nodeId,
    point: point,
    kind: kind,
    value: v,
  );
}
