import 'package:flutter/material.dart';
import 'package:structlab/core/geometry.dart';
import 'package:structlab/domain/models/member.dart';
import 'package:structlab/domain/models/node.dart';
import 'package:structlab/domain/rules/node_rules.dart';
import 'package:structlab/editor/editor_controller.dart';
import 'package:structlab/editor/editor_types.dart';
import 'package:structlab/editor/tools/editor_tool.dart';
import 'package:structlab/editor/tools/hit_testing.dart';
import 'package:structlab/l10n/strings_pt.dart';

/// Splits a member by creating a node on it, or edits an existing node.
class NodeTool extends EditorToolHandler {
  @override
  EditorTool get id => EditorTool.node;

  @override
  String label(EditorController c) => toolNodeLabel;

  @override
  Widget icon(EditorController c, Color color) =>
      Icon(Icons.add_circle_outline, color: color, size: 22);

  @override
  String hint(EditorController c) => msgNodeToolHint;

  @override
  void onTap(EditorController c, Offset position) {
    final model = c.model;

    final existing = nearestNode(model, position, tolerance: 0.28);
    if (existing != null) {
      c.select(SelectedType.node, existing.id);
      c.status(msgNodeSelected);
      c.requestEdit();
      return;
    }

    final member = nearestMember(model, position);
    if (member == null) {
      c.message(msgNodeTapMember);
      return;
    }
    final startNode = model.nodeById(member.startNodeId);
    final endNode = model.nodeById(member.endNodeId);
    if (startNode == null || endNode == null) return;

    final (left, right) = orderLeftRight(startNode, endNode);
    final dir = unitVec(right.position - left.position);
    final len = (right.position - left.position).distance;
    var d = dot2(position - left.position, dir).clamp(0.0, len).toDouble();
    d = c.snapValue(d);
    if (d < 0.05 || d > len - 0.05) {
      c.message(msgNodeTooClose);
      return;
    }
    final pos = left.position + dir * d;
    if (nearestNode(model, pos, tolerance: 0.05) != null) {
      c.message(msgNodeExists);
      return;
    }

    c.saveUndo();
    final node = StructuralNode(id: model.newId(), position: pos);
    model.nodes.add(node);
    model.members.removeWhere((m) => m.id == member.id);
    model.members.add(StructuralMember(
      id: model.newId(),
      startNodeId: member.startNodeId,
      endNodeId: node.id,
    ));
    model.members.add(StructuralMember(
      id: model.newId(),
      startNodeId: node.id,
      endNodeId: member.endNodeId,
    ));
    c.select(SelectedType.node, node.id);
    c.status(msgNodeCreated);
  }
}