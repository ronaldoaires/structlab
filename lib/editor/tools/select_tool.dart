import 'package:flutter/material.dart';
import 'package:structlab/core/geometry.dart';
import 'package:structlab/domain/models/load.dart';
import 'package:structlab/editor/editor_controller.dart';
import 'package:structlab/editor/editor_types.dart';
import 'package:structlab/editor/tools/editor_tool.dart';
import 'package:structlab/editor/tools/hit_testing.dart';
import 'package:structlab/l10n/strings_pt.dart';

class SelectTool extends EditorToolHandler {
  @override
  EditorTool get id => EditorTool.select;

  @override
  String label(EditorController c) => toolSelectLabel;

  @override
  Widget icon(EditorController c, Color color) =>
      Icon(Icons.near_me_outlined, color: color, size: 22);

  @override
  String hint(EditorController c) => msgSelectToolHint;

  @override
  void onTap(EditorController c, Offset position) {
    final model = c.model;

    final node = nearestNode(model, position, tolerance: 0.28);
    if (node != null) {
      c.select(SelectedType.node, node.id);
      c.status(msgNodeSelected);
      return;
    }

    for (final support in model.supports) {
      final supportNode = model.nodeById(support.nodeId);
      if (supportNode != null &&
          (supportNode.position - position).distance < 0.55) {
        c.select(SelectedType.support, support.id);
        c.status(msgSupportSelected);
        return;
      }
    }

    for (final load in model.loads) {
      if (load.kind != LoadKind.concentrated) continue;
      if (distanceToConcentratedLoad(model, load, position) < 0.22) {
        c.select(SelectedType.load, load.id);
        c.status(msgLoadSelected);
        return;
      }
    }

    final tightMember = nearestMember(model, position, tolerance: 0.15);
    if (tightMember != null) {
      c.select(SelectedType.member, tightMember.id);
      c.status(msgMemberSelected);
      return;
    }

    for (final load in model.loads) {
      final poly = loadPolygon(model, load);
      if (poly != null && pointInPolygon(position, poly)) {
        c.select(SelectedType.load, load.id);
        c.status(msgLoadSelected);
        return;
      }
    }

    final member = nearestMember(model, position);
    if (member == null) {
      c.clearSelection();
      c.status(msgNothingSelected);
    } else {
      c.select(SelectedType.member, member.id);
      c.status(msgMemberSelected);
    }
  }
}