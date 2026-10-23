import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:structlab/core/theme/app_theme.dart';
import 'package:structlab/domain/models/load.dart';
import 'package:structlab/domain/models/member.dart';
import 'package:structlab/domain/models/node.dart';
import 'package:structlab/domain/models/structural_model.dart';
import 'package:structlab/domain/models/support.dart';
import 'package:structlab/l10n/strings_results_pt.dart';
import 'package:structlab/results/reactions_screen.dart';
import 'package:structlab/services/entitlements.dart';

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
        angleDegrees: -90),
    StructuralLoad(
        id: 9,
        kind: LoadKind.uniform,
        nodeId: 1,
        endNodeId: 3,
        q1: 5,
        q2: 5,
        angleDegrees: -90),
  ]);

Widget _app(Entitlements e) => MaterialApp(
      theme: buildAppTheme(),
      home: ReactionsScreen(model: _beam(), entitlements: e),
    );

Future<void> _tapSteps(WidgetTester tester) async {
  final button = find.text(seeStepsLabel);
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the reactions and the steps button', (tester) async {
    await tester.pumpWidget(_app(const Entitlements()));
    expect(find.text(reactionsCardTitle), findsOneWidget);
    expect(find.text('VA'), findsOneWidget);
    expect(find.text('VC'), findsOneWidget);
    expect(find.text(seeStepsLabel), findsOneWidget);
  });

  testWidgets('subscriber opens the step by step and moves forward',
      (tester) async {
    await tester.pumpWidget(_app(const Entitlements()));
    await _tapSteps(tester);
    expect(find.text(stepCounter(1, 7)), findsOneWidget);

    await tester.tap(find.text(nextLabel));
    await tester.pumpAndSettle();
    expect(find.text(stepCounter(2, 7)), findsOneWidget);
  });

  testWidgets('without subscription shows the subscribers sheet',
      (tester) async {
    await tester.pumpWidget(_app(const Entitlements(canSeeSteps: false)));
    await _tapSteps(tester);
    expect(find.text(stepsSubscribersTitle), findsOneWidget);
    expect(find.text(stepCounter(1, 7)), findsNothing);
  });
}