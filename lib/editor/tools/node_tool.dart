import 'package:flutter/material.dart';
import 'package:structlab/core/geometry.dart';
import 'package:structlab/core/theme/colors.dart';
import 'package:structlab/domain/models/member.dart';
import 'package:structlab/domain/models/node.dart';
import 'package:structlab/domain/rules/node_rules.dart';
import 'package:structlab/editor/editor_controller.dart';
import 'package:structlab/editor/editor_types.dart';
import 'package:structlab/editor/tools/editor_tool.dart';
import 'package:structlab/editor/tools/hit_testing.dart';
import 'package:structlab/l10n/strings_pt.dart';

/// Splits a member by creating a node on it, or edits an existing node.
/// The toolbar button opens a menu with the node kind (node or hinge).
class NodeTool extends EditorToolHandler {
  @override
  EditorTool get id => EditorTool.node;

  @override
  String label(EditorController c) => nodeKindShortName(c.nodeKind);

  @override
  Widget icon(EditorController c, Color color) =>
      Icon(Icons.add_circle_outline, color: color, size: 22);

  @override
  String hint(EditorController c) => nodeKindHint(c.nodeKind);

  @override
  bool get hasMenu => true;

  // Turn on NodeKind.hinge here when hinges are implemented, and handle it
  // in onTap (it should mark the node instead of only splitting the member).
  bool _isAvailable(NodeKind kind) => kind == NodeKind.rigid;

  @override
  Future<void> openMenu(BuildContext context, EditorController c) async {
    final result = await showModalBottomSheet<NodeKind>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(nodeMenuTitle,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              for (final kind in NodeKind.values)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  enabled: _isAvailable(kind),
                  leading: Icon(
                    kind == NodeKind.rigid
                        ? Icons.add_circle_outline
                        : Icons.radio_button_unchecked,
                    size: 28,
                  ),
                  title: Text(nodeKindName(kind)),
                  subtitle: Text(_isAvailable(kind)
                      ? nodeKindHint(kind)
                      : comingSoonLabel),
                  trailing: c.nodeKind == kind
                      ? const Icon(Icons.check, color: brandBlue)
                      : null,
                  onTap: _isAvailable(kind)
                      ? () => Navigator.pop(context, kind)
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
    if (result == null) return;
    c.setNodeKind(result);
  }

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