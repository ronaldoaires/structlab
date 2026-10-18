import 'package:flutter/material.dart';
import 'package:structlab/domain/models/member.dart';
import 'package:structlab/editor/editor_controller.dart';
import 'package:structlab/editor/editor_types.dart';
import 'package:structlab/editor/tools/editor_tool.dart';
import 'package:structlab/l10n/strings_pt.dart';

/// Draws a member by dragging, or by tapping two points (tap-tap mode).
class BeamTool extends EditorToolHandler {
  bool _startedThisGesture = false;

  @override
  EditorTool get id => EditorTool.beam;

  @override
  String label(EditorController c) => toolBeamLabel;

  @override
  Widget icon(EditorController c, Color color) =>
      Icon(Icons.horizontal_rule, color: color, size: 22);

  @override
  String hint(EditorController c) => msgBeamToolHint;

  @override
  void onPointerDown(EditorController c, Offset position) {
    _startedThisGesture = false;
    if (c.pendingBeamStart == null) {
      _startedThisGesture = true;
      c.pendingBeamStart = c.resolveStartPoint(position);
      c.previewEnd = null;
      c.status(msgBeamDragHint);
    } else {
      _updatePreview(c, position);
    }
  }

  @override
  void onPointerMove(EditorController c, Offset position) {
    if (c.pendingBeamStart != null) _updatePreview(c, position);
  }

  @override
  void onPointerUp(EditorController c, Offset position,
      {required bool moved}) {
    // Simple tap on the 1st point: wait for the 2nd tap (tap-tap mode).
    if (_startedThisGesture && !moved) {
      c.status(msgBeamEndHint);
      return;
    }
    _commit(c, position);
  }

  @override
  void onCancel(EditorController c) {
    if (_startedThisGesture) {
      c.pendingBeamStart = null;
      c.previewEnd = null;
      c.refresh();
    }
  }

  void _updatePreview(EditorController c, Offset raw) {
    final start = c.pendingBeamStart;
    if (start == null) return;
    c.previewEnd = c.resolveEndPoint(start, raw);
    c.refresh();
  }

  void _commit(EditorController c, Offset raw) {
    final startPosition = c.pendingBeamStart;
    if (startPosition == null) return;
    final position = c.resolveEndPoint(startPosition, raw);
    c.previewEnd = null;

    c.saveUndo();
    final startNode = c.findOrCreateNode(startPosition);
    final endNode = c.findOrCreateNode(position);

    if (startNode.id == endNode.id ||
        (startNode.position - endNode.position).distance < 0.1) {
      c.pendingBeamStart = null;
      c.status(msgBeamZero);
      return;
    }

    final duplicate = c.model.members.any((m) =>
        (m.startNodeId == startNode.id && m.endNodeId == endNode.id) ||
        (m.startNodeId == endNode.id && m.endNodeId == startNode.id));
    if (duplicate) {
      c.pendingBeamStart = null;
      c.status(msgBeamDuplicate);
      return;
    }

    final member = StructuralMember(
      id: c.model.newId(),
      startNodeId: startNode.id,
      endNodeId: endNode.id,
    );
    c.model.members.add(member);
    c.select(SelectedType.member, member.id);
    c.pendingBeamStart = null;
    c.status(msgBeamCreated);
  }
}