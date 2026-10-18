import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:structlab/domain/models/support.dart';
import 'package:structlab/domain/rules/node_rules.dart';
import 'package:structlab/editor/dialogs/load_dialog.dart';
import 'package:structlab/editor/dialogs/member_dialog.dart';
import 'package:structlab/editor/dialogs/node_distance_dialog.dart';
import 'package:structlab/editor/dialogs/support_dialog.dart';
import 'package:structlab/editor/editor_controller.dart';
import 'package:structlab/editor/editor_types.dart';
import 'package:structlab/l10n/strings_pt.dart';

/// Opens the edit dialog that matches the current selection and applies the
/// result to the controller.
Future<void> editSelected(BuildContext context, EditorController c) async {
  switch (c.selectedType) {
    case SelectedType.member:
      final member = c.selectedMember;
      if (member == null) return;
      final start = c.model.nodeById(member.startNodeId);
      final end = c.model.nodeById(member.endNodeId);
      if (start == null || end == null) return;
      final vec = end.position - start.position;
      final result = await showDialog<(double, double)>(
        context: context,
        builder: (context) => MemberDialog(
          length: vec.distance,
          angle: math.atan2(vec.dy, vec.dx) * 180 / math.pi,
        ),
      );
      if (result == null || !context.mounted) return;
      c.applyMember(result.$1, result.$2);
      break;

    case SelectedType.support:
      final support = c.selectedSupport;
      if (support == null) return;
      final result = await showDialog<(SupportType, int)>(
        context: context,
        builder: (context) => SupportDialog(
          type: support.type,
          rotation: support.rotationDegrees,
        ),
      );
      if (result == null || !context.mounted) return;
      c.applySupport(result.$1, result.$2);
      break;

    case SelectedType.load:
      final load = c.selectedLoad;
      if (load == null) return;
      final result = await showDialog<(double, double, double)>(
        context: context,
        builder: (context) => LoadDialog(
          kind: load.kind,
          q1: load.q1,
          q2: load.q2,
          angle: load.angleDegrees,
        ),
      );
      if (result == null || !context.mounted) return;
      c.applyLoad(result.$1, result.$2, result.$3);
      break;

    case SelectedType.node:
      final node = c.selectedNode;
      if (node == null) return;
      final info = nodeLineInfo(c.model, node.id);
      if (info == null) {
        c.message(msgNodePositionByMembers);
        return;
      }
      final result = await showDialog<double>(
        context: context,
        builder: (context) => NodeDistanceDialog(
          total: info.total,
          fromLeft: info.fromLeft,
          minFromLeft: info.minFromLeft,
          maxFromLeft: info.maxFromLeft,
          vertical: info.dir.dx.abs() < 1e-6,
        ),
      );
      if (result == null || !context.mounted) return;
      c.applyNodeDistance(info, result);
      break;

    case SelectedType.none:
      c.message(msgSelectToEdit);
      break;
  }
}