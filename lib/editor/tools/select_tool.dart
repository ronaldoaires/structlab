import 'package:flutter/material.dart';
import 'package:structlab/core/geometry.dart';
import 'package:structlab/domain/models/load.dart';
import 'package:structlab/domain/rules/node_rules.dart';
import 'package:structlab/editor/editor_controller.dart';
import 'package:structlab/editor/editor_types.dart';
import 'package:structlab/editor/tools/editor_tool.dart';
import 'package:structlab/editor/tools/hit_testing.dart';
import 'package:structlab/l10n/strings_pt.dart';

/// Selects elements by tapping. Dragging a node moves it:
/// - a node in the middle of a straight line slides along that line;
/// - any other node moves freely (with grid snap).
/// A move is refused if it would break a distributed load or put two nodes
/// on top of each other.
class SelectTool extends EditorToolHandler {
  // Drag state.
  int? _dragNodeId;
  NodeLineInfo? _dragInfo;
  Offset? _downPos;
  bool _dragging = false;
  bool _undoSaved = false;
  bool _warned = false;

  @override
  EditorTool get id => EditorTool.select;

  @override
  String label(EditorController c) => toolSelectLabel;

  @override
  Widget icon(EditorController c, Color color) =>
      Icon(Icons.near_me_outlined, color: color, size: 22);

  @override
  String hint(EditorController c) => msgSelectToolHint;

  // ---------------------------------------------------------------------------
  // Drag
  // ---------------------------------------------------------------------------

  @override
  void onPointerDown(EditorController c, Offset position) {
    _dragging = false;
    _undoSaved = false;
    _warned = false;
    _downPos = position;
    _dragNodeId = null;
    _dragInfo = null;

    final node = nearestNode(c.model, position, tolerance: c.tol(0.28));
    if (node != null) {
      _dragNodeId = node.id;
      _dragInfo = nodeLineInfo(c.model, node.id);
    }
  }

  @override
  void onPointerMove(EditorController c, Offset position) {
    final id = _dragNodeId;
    final down = _downPos;
    if (id == null || down == null) return;

    if (!_dragging) {
      // Only starts dragging after ~8 px, so taps do not move nodes.
      if ((position - down).distance * c.pxPerMeter <= 8) return;
      _dragging = true;
      c.select(SelectedType.node, id);
    }
    _moveNode(c, id, position);
  }

  void _moveNode(EditorController c, int id, Offset position) {
    final node = c.model.nodeById(id);
    if (node == null) return;

    final Offset target;
    final info = _dragInfo;
    if (info != null) {
      // Slides along the line, between the neighbor nodes.
      const margin = 0.1;
      final lo = info.minFromLeft + margin;
      final hi = info.maxFromLeft - margin;
      if (lo > hi) return;
      final d = c
          .snapValue(dot2(position - info.left.position, info.dir))
          .clamp(lo, hi)
          .toDouble();
      target = info.left.position + info.dir * d;
    } else {
      target = c.snapPosition(position);
    }

    if ((target - node.position).distance < 1e-9) return;

    final clash = c.model.nodes.any(
      (n) => n.id != id && (n.position - target).distance < 0.1,
    );
    if (clash) return;

    // Tries the move, checks the loads, and only then commits.
    final old = node.position;
    node.position = target;
    final ok = _loadsStillValid(c);
    node.position = old;
    if (!ok) {
      if (!_warned) {
        _warned = true;
        c.message(msgNodeMoveBlocked);
      }
      return;
    }

    if (!_undoSaved) {
      c.saveUndo();
      _undoSaved = true;
    }
    node.position = target;
    c.refresh();
  }

  /// Every distributed load needs its two nodes on the same straight line.
  bool _loadsStillValid(EditorController c) {
    for (final l in c.model.loads) {
      final endId = l.endNodeId;
      if (endId == null) continue;
      if (!isStraightConnected(c.model, l.nodeId, endId)) return false;
    }
    return true;
  }

  @override
  void onPointerUp(EditorController c, Offset position,
      {required bool moved}) {
    final wasDragging = _dragging;
    final saved = _undoSaved;
    _dragging = false;
    _dragNodeId = null;
    _dragInfo = null;

    if (wasDragging) {
      if (saved) {
        c.status(msgNodeMoved);
      } else {
        c.refresh();
      }
      return;
    }
    if (!moved) onTap(c, position);
  }

  @override
  void onCancel(EditorController c) {
    _dragging = false;
    _dragNodeId = null;
    _dragInfo = null;
  }

  // ---------------------------------------------------------------------------
  // Tap
  // ---------------------------------------------------------------------------

  @override
  void onTap(EditorController c, Offset position) {
    final model = c.model;

    final node = nearestNode(model, position, tolerance: c.tol(0.28));
    if (node != null) {
      c.select(SelectedType.node, node.id);
      c.status(msgNodeSelected);
      return;
    }

    for (final support in model.supports) {
      final supportNode = model.nodeById(support.nodeId);
      if (supportNode != null &&
          (supportNode.position - position).distance < c.tol(0.55)) {
        c.select(SelectedType.support, support.id);
        c.status(msgSupportSelected);
        return;
      }
    }

    for (final load in model.loads) {
      final double d;
      if (load.kind == LoadKind.concentrated) {
        d = distanceToConcentratedLoad(model, load, position,
            pxPerMeter: c.pxPerMeter);
      } else if (load.kind == LoadKind.moment) {
        d = distanceToMoment(model, load, position, pxPerMeter: c.pxPerMeter);
      } else {
        continue;
      }
      if (d < c.tol(0.22)) {
        c.select(SelectedType.load, load.id);
        c.status(msgLoadSelected);
        return;
      }
    }

    final tightMember = nearestMember(model, position, tolerance: c.tol(0.15));
    if (tightMember != null) {
      c.select(SelectedType.member, tightMember.id);
      c.status(msgMemberSelected);
      return;
    }

    for (final load in model.loads) {
      final poly = loadPolygon(model, load, pxPerMeter: c.pxPerMeter);
      if (poly != null && pointInPolygon(position, poly)) {
        c.select(SelectedType.load, load.id);
        c.status(msgLoadSelected);
        return;
      }
    }

    final member = nearestMember(model, position, tolerance: c.tol(0.28));
    if (member == null) {
      c.clearSelection();
      c.status(msgNothingSelected);
    } else {
      c.select(SelectedType.member, member.id);
      c.status(msgMemberSelected);
    }
  }
}