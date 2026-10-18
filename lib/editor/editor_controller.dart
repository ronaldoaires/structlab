import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:structlab/core/constants.dart';
import 'package:structlab/domain/models/load.dart';
import 'package:structlab/domain/models/member.dart';
import 'package:structlab/domain/models/node.dart';
import 'package:structlab/domain/models/structural_model.dart';
import 'package:structlab/domain/models/support.dart';
import 'package:structlab/domain/rules/load_rules.dart';
import 'package:structlab/domain/rules/node_rules.dart';
import 'package:structlab/editor/editor_types.dart';
import 'package:structlab/editor/tools/beam_tool.dart';
import 'package:structlab/editor/tools/editor_tool.dart';
import 'package:structlab/editor/tools/hit_testing.dart';
import 'package:structlab/editor/tools/load_tool.dart';
import 'package:structlab/editor/tools/node_tool.dart';
import 'package:structlab/editor/tools/select_tool.dart';
import 'package:structlab/editor/tools/support_tool.dart';
import 'package:structlab/l10n/strings_pt.dart';

/// Holds the editor state (model, undo, selection, active tool) and the
/// actions that change it. Knows nothing about widgets or dialogs.
class EditorController extends ChangeNotifier {
  final StructuralModel model = StructuralModel();
  final List<StructuralModel> _undoStack = [];

  /// Toolbar order. To add or remove a tool, edit this list.
  final List<EditorToolHandler> tools = [
    SelectTool(),
    BeamTool(),
    NodeTool(),
    SupportTool(),
    LoadTool(),
  ];

  /// Set by the screen: shows a short message (snack bar).
  void Function(String message)? onMessage;

  /// Set by the screen: opens the edit dialog of the current selection.
  VoidCallback? onEditRequested;

  EditorTool activeTool = EditorTool.select;
  SelectedType selectedType = SelectedType.none;
  int? selectedId;
  String statusMessage = msgStart;

  // Drawing aids.
  bool snapEnabled = true;
  bool orthoEnabled = true;

  // Beam in progress.
  Offset? pendingBeamStart;
  Offset? previewEnd;

  // Types chosen in the Support and Load menus.
  SupportType supportType = SupportType.pin;
  LoadKind loadKind = LoadKind.concentrated;
  int? pendingLoadNodeId;

  // Gesture tracking.
  Offset? _pointerDownScreen;
  bool _pointerMoved = false;

  bool get canUndo => _undoStack.isNotEmpty;

  EditorToolHandler toolOf(EditorTool id) =>
      tools.firstWhere((t) => t.id == id);

  EditorToolHandler get activeHandler => toolOf(activeTool);

  // ---------------------------------------------------------------------------
  // Selection
  // ---------------------------------------------------------------------------

  StructuralNode? get selectedNode {
    for (final e in model.nodes) {
      if (e.id == selectedId) return e;
    }
    return null;
  }

  StructuralMember? get selectedMember {
    for (final e in model.members) {
      if (e.id == selectedId) return e;
    }
    return null;
  }

  StructuralSupport? get selectedSupport {
    for (final e in model.supports) {
      if (e.id == selectedId) return e;
    }
    return null;
  }

  StructuralLoad? get selectedLoad {
    for (final e in model.loads) {
      if (e.id == selectedId) return e;
    }
    return null;
  }

  void select(SelectedType type, int? id) {
    selectedType = type;
    selectedId = id;
  }

  void clearSelection() => select(SelectedType.none, null);

  // ---------------------------------------------------------------------------
  // Feedback (used by the tools)
  // ---------------------------------------------------------------------------

  /// Short pop-up message (snack bar).
  void message(String text) => onMessage?.call(text);

  /// Updates the status bar and repaints.
  void status(String text) {
    statusMessage = text;
    notifyListeners();
  }

  /// Repaints without changing the status text.
  void refresh() => notifyListeners();

  /// Asks the screen to open the edit dialog of the current selection.
  void requestEdit() => onEditRequested?.call();

  // ---------------------------------------------------------------------------
  // Drawing aids
  // ---------------------------------------------------------------------------

  void setSnap(bool value) {
    snapEnabled = value;
    notifyListeners();
  }

  void setOrtho(bool value) {
    orthoEnabled = value;
    notifyListeners();
  }

  double snapValue(double v) {
    if (!snapEnabled) return v;
    return (v / gridStep).round() * gridStep;
  }

  Offset _snapPoint(Offset p) {
    if (!snapEnabled) return p;
    return Offset(snapValue(p.dx), snapValue(p.dy));
  }

  /// First point: snaps to an existing node, otherwise to the grid.
  Offset resolveStartPoint(Offset raw) {
    final near = nearestNode(model, raw, tolerance: 0.35);
    if (near != null) return near.position;
    return _snapPoint(raw);
  }

  /// Second point: snaps to an existing node; otherwise applies the
  /// orthogonal lock (horizontal/vertical, ~15° tolerance) and grid snap.
  Offset resolveEndPoint(Offset start, Offset raw) {
    final near = nearestNode(model, raw, tolerance: 0.35);
    if (near != null) return near.position;

    if (orthoEnabled) {
      final dx = (raw.dx - start.dx).abs();
      final dy = (raw.dy - start.dy).abs();
      if (dy < dx * 0.27) {
        // Horizontal: keeps the start point's Y exactly.
        return Offset(snapValue(raw.dx), start.dy);
      }
      if (dx < dy * 0.27) {
        // Vertical: keeps the start point's X exactly.
        return Offset(start.dx, snapValue(raw.dy));
      }
    }
    return _snapPoint(raw);
  }

  // ---------------------------------------------------------------------------
  // Undo / model
  // ---------------------------------------------------------------------------

  void saveUndo() {
    _undoStack.add(model.copy());
    if (_undoStack.length > 50) _undoStack.removeAt(0);
  }

  void _resetTransient() {
    pendingBeamStart = null;
    previewEnd = null;
    pendingLoadNodeId = null;
    clearSelection();
  }

  void undo() {
    if (_undoStack.isEmpty) {
      message(msgNothingToUndo);
      return;
    }
    model.restoreFrom(_undoStack.removeLast());
    _resetTransient();
    status(msgUndone);
  }

  void newModel() {
    if (model.isEmpty) {
      message(msgModelAlreadyEmpty);
      return;
    }
    saveUndo();
    model.clear();
    _resetTransient();
    status(msgNewModel);
  }

  void validateModel() {
    if (model.members.isEmpty) {
      message(msgNeedBeam);
      return;
    }
    if (model.supports.isEmpty) {
      message(msgNeedSupport);
      return;
    }
    message(msgModelOk);
  }

  StructuralNode findOrCreateNode(Offset position) {
    for (final node in model.nodes) {
      if ((node.position - position).distance < 0.35) return node;
    }
    final node = StructuralNode(id: model.newId(), position: position);
    model.nodes.add(node);
    return node;
  }

  // ---------------------------------------------------------------------------
  // Pointer events: the active tool decides what to do
  // (positions in model coordinates, meters)
  // ---------------------------------------------------------------------------

  void pointerDown(Offset screen, Offset modelPos) {
    _pointerDownScreen = screen;
    _pointerMoved = false;
    activeHandler.onPointerDown(this, modelPos);
  }

  void pointerMove(Offset screen, Offset modelPos) {
    final down = _pointerDownScreen;
    if (down == null) return;
    if (!_pointerMoved && (screen - down).distance > 8) _pointerMoved = true;
    activeHandler.onPointerMove(this, modelPos);
  }

  void pointerUp(Offset screen, Offset modelPos) {
    if (_pointerDownScreen == null) return;
    _pointerDownScreen = null;
    activeHandler.onPointerUp(this, modelPos, moved: _pointerMoved);
  }

  void pointerCancel() {
    _pointerDownScreen = null;
    activeHandler.onCancel(this);
  }

  // ---------------------------------------------------------------------------
  // Tools and menus
  // ---------------------------------------------------------------------------

  void setTool(EditorTool tool) {
    activeTool = tool;
    pendingBeamStart = null;
    pendingLoadNodeId = null;
    previewEnd = null;
    clearSelection();
    statusMessage = toolOf(tool).hint(this);
    notifyListeners();
  }

  void setSupportType(SupportType type) {
    supportType = type;
    status(msgSupportChosen(type));
  }

  void setLoadKind(LoadKind kind) {
    loadKind = kind;
    pendingLoadNodeId = null;
    status(loadHint(kind));
  }

  // ---------------------------------------------------------------------------
  // Applying edits (called by the screen after a dialog returns)
  // ---------------------------------------------------------------------------

  void applyMember(double length, double angleDegrees) {
    final member = selectedMember;
    if (member == null) return;
    final start = model.nodeById(member.startNodeId);
    final end = model.nodeById(member.endNodeId);
    if (start == null || end == null) return;
    saveUndo();
    final rad = angleDegrees * math.pi / 180;
    end.position = Offset(
      start.position.dx + length * math.cos(rad),
      start.position.dy + length * math.sin(rad),
    );
    status(msgMemberUpdated);
  }

  void applySupport(SupportType type, int rotationDegrees) {
    final support = selectedSupport;
    if (support == null) return;
    saveUndo();
    support.type = type;
    support.rotationDegrees = rotationDegrees;
    status(msgSupportUpdated);
  }

  /// Returns false (and shows a message) when the new direction conflicts
  /// with another concentrated load at the same node.
  bool applyLoad(double q1, double q2, double angleDegrees) {
    final load = selectedLoad;
    if (load == null) return false;
    if (load.kind == LoadKind.concentrated &&
        concentratedConflict(model.loads, load.nodeId, angleDegrees,
            ignoreId: load.id)) {
      message(msgLoadDirectionTaken);
      return false;
    }
    saveUndo();
    load.q1 = q1;
    load.q2 = q2;
    load.angleDegrees = angleDegrees;
    status(msgLoadUpdated);
    return true;
  }

  void applyNodeDistance(NodeLineInfo info, double fromLeft) {
    final node = selectedNode;
    if (node == null) return;
    saveUndo();
    node.position = info.left.position + info.dir * fromLeft;
    status(msgNodePositioned(fromLeft));
  }

  void deleteSelected() {
    final id = selectedId;
    if (selectedType == SelectedType.none || id == null) {
      message(msgSelectToDelete);
      return;
    }
    saveUndo();
    switch (selectedType) {
      case SelectedType.member:
        model.members.removeWhere((e) => e.id == id);
        break;
      case SelectedType.support:
        model.supports.removeWhere((e) => e.id == id);
        break;
      case SelectedType.load:
        model.loads.removeWhere((e) => e.id == id);
        break;
      case SelectedType.node:
        model.members
            .removeWhere((e) => e.startNodeId == id || e.endNodeId == id);
        model.supports.removeWhere((e) => e.nodeId == id);
        model.loads.removeWhere((e) => e.nodeId == id || e.endNodeId == id);
        model.nodes.removeWhere((e) => e.id == id);
        break;
      case SelectedType.none:
        break;
    }
    clearSelection();
    status(msgDeleted);
  }
}