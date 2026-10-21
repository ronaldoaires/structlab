import 'dart:async';
import 'dart:convert';
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
import 'package:structlab/services/entitlements.dart';
import 'package:structlab/services/project_repository.dart';
import 'package:structlab/domain/validation/structure_validator.dart';
import 'package:structlab/domain/validation/validation_report.dart';

/// Holds the editor state (model, undo, selection, active tool, current
/// project) and the actions that change it. Knows nothing about widgets or
/// dialogs.
class EditorController extends ChangeNotifier {
  EditorController({ProjectRepository? repo, Entitlements? entitlements})
    : repo = repo ?? ProjectRepository(),
      entitlements = entitlements ?? const Entitlements();

  final ProjectRepository repo;
  final Entitlements entitlements;

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

  /// Set by the screen: shows the validation report.
  void Function(ValidationReport report)? onValidated;

  /// Last validation. Cleared as soon as the model changes.
  ValidationReport? report;

  EditorTool activeTool = EditorTool.select;
  SelectedType selectedType = SelectedType.none;
  int? selectedId;
  String statusMessage = msgStart;

  // Drawing aids.
  bool snapEnabled = true;
  bool orthoEnabled = true;

  // View (zoom and pan). [pan] is in screen px, relative to the canvas center.
  static const double minZoom = 0.4;
  static const double maxZoom = 5.0;
  double zoom = 1.0;
  Offset pan = Offset.zero;

  /// Size of the canvas, set by the canvas widget (used to fit the view).
  Size viewSize = Size.zero;

  // Beam in progress.
  Offset? pendingBeamStart;
  Offset? previewEnd;

  // Types chosen in the Node, Support and Load menus.
  NodeKind nodeKind = NodeKind.rigid;
  SupportType supportType = SupportType.pin;
  LoadKind loadKind = LoadKind.concentrated;
  int? pendingLoadNodeId;

  // Gesture tracking.
  Offset? _pointerDownScreen;
  bool _pointerMoved = false;

  // Current project. [projectId] is null until the first save.
  String? projectId;
  String projectName = projectDefaultName;
  Timer? _autosaveTimer;
  String? _lastSavedKey;
  bool _loading = false;
  bool _saving = false;
  bool _resave = false;
  bool _limitWarned = false;
  bool _disposed = false;

  bool get canUndo => _undoStack.isNotEmpty;

  EditorToolHandler toolOf(EditorTool id) =>
      tools.firstWhere((t) => t.id == id);

  EditorToolHandler get activeHandler => toolOf(activeTool);

  // ---------------------------------------------------------------------------
  // Projects (open, new, rename, delete, autosave)
  // ---------------------------------------------------------------------------

  /// Reopens the last project. Call once when the screen starts.
  Future<void> init() async {
    final id = await repo.lastOpenedId();
    if (id == null) return;
    await _open(id);
  }

  String _keyFor(String name, Map<String, dynamic> json) =>
      '$name\u0000${jsonEncode(json)}';

  Future<bool> _open(String id) async {
    final stored = await repo.load(id);
    if (stored == null) return false;
    StructuralModel parsed;
    try {
      parsed = StructuralModel.fromJson(stored.modelJson);
    } catch (_) {
      return false;
    }
    _loading = true;
    model.restoreFrom(parsed);
    projectId = id;
    projectName = stored.name;
    _undoStack.clear();
    _resetTransient();
    zoom = 1.0;
    pan = Offset.zero;
    _lastSavedKey = _keyFor(projectName, model.toJson());
    _limitWarned = false;
    _loading = false;
    await repo.setLastOpened(id);
    status(msgProjectOpened(stored.name));
    return true;
  }

  /// Opens a saved project. Returns true on success.
  Future<bool> openProject(String id) async {
    if (id == projectId) return true;
    await flush();
    final ok = await _open(id);
    if (!ok) message(msgProjectLoadFailed);
    return ok;
  }

  void _startBlank() {
    _loading = true;
    model.clear();
    model.nextId = 1;
    projectId = null;
    projectName = projectDefaultName;
    _undoStack.clear();
    _resetTransient();
    zoom = 1.0;
    pan = Offset.zero;
    _lastSavedKey = null;
    _limitWarned = false;
    _loading = false;
  }

  /// Starts a new empty project. Returns true if it was created.
  Future<bool> newModel() async {
    if (model.isEmpty && projectId == null) {
      message(msgModelAlreadyEmpty);
      return false;
    }
    await flush();
    final count = await repo.count();
    if (!entitlements.canCreateProject(count)) {
      message(msgProjectLimit(entitlements.maxProjects));
      return false;
    }
    _startBlank();
    await repo.setLastOpened(null);
    status(msgNewModel);
    return true;
  }

  Future<void> renameProject(String id, String name) async {
    final clean = name.trim();
    if (clean.isEmpty) return;
    if (id == projectId || (projectId == null && id.isEmpty)) {
      projectName = clean;
      notifyListeners(); // autosave writes the new name
    } else {
      await repo.rename(id, clean);
    }
  }

  Future<void> deleteProject(String id) async {
    _autosaveTimer?.cancel();
    await repo.delete(id);
    if (id == projectId) {
      _startBlank();
      notifyListeners();
    }
  }

  void _scheduleAutosave() {
    if (_disposed || _loading) return;
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(milliseconds: 800), _saveNow);
  }

  /// Saves right now (used when leaving the screen or the app).
  Future<void> flush() async {
    _autosaveTimer?.cancel();
    await _saveNow();
  }

  Future<void> _saveNow() async {
    if (_loading) return;
    if (_saving) {
      _resave = true;
      return;
    }
    if (model.isEmpty && projectId == null) return;

    final json = model
        .toJson(); // snapshot: safe even if the user keeps editing
    if (projectId != null && _keyFor(projectName, json) == _lastSavedKey) {
      return;
    }

    _saving = true;
    try {
      var id = projectId;
      if (id == null) {
        final count = await repo.count();
        if (!entitlements.canCreateProject(count)) {
          if (!_limitWarned) {
            _limitWarned = true;
            message(msgProjectLimit(entitlements.maxProjects));
          }
          return;
        }
        id = repo.newProjectId();
        projectId = id;
        if (projectName == projectDefaultName) {
          projectName = msgProjectAutoName(count + 1);
        }
        await repo.setLastOpened(id);
      }
      final name = projectName;
      await repo.save(id: id, name: name, modelJson: json);
      _lastSavedKey = _keyFor(name, json);
    } catch (e) {
      debugPrint('Autosave failed: $e');
    } finally {
      _saving = false;
      if (_resave) {
        _resave = false;
        _scheduleAutosave();
      }
    }
  }

  /// Every repaint request also schedules an autosave. The save is skipped
  /// when nothing changed (pan, zoom and status texts do not touch the file).
  @override
  void notifyListeners() {
    super.notifyListeners();
    _scheduleAutosave();
  }

  @override
  void dispose() {
    _disposed = true;
    _autosaveTimer?.cancel();
    unawaited(_saveNow());
    super.dispose();
  }

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

  /// Public snap (grid) for a model point.
  Offset snapPosition(Offset p) => _snapPoint(p);

  /// Pixels per meter at the current zoom.
  double get pxPerMeter => pixelsPerMeter * zoom;

  /// Converts a touch tolerance in meters (at zoom 1) to the current zoom, so
  /// the touch area stays the same size on screen.
  double tol(double meters) => meters / zoom;

  /// Moves/zooms the view. [prevFocal] and [focal] are the gesture center
  /// before and after; [scaleFactor] multiplies the zoom. The model point
  /// under the fingers stays under the fingers.
  void navigate({
    required Offset prevFocal,
    required Offset focal,
    required double scaleFactor,
    required Size size,
  }) {
    final center = Offset(size.width / 2, size.height / 2);
    final oldScale = pxPerMeter;
    final anchor = (prevFocal - center - pan) / oldScale;
    zoom = (zoom * scaleFactor).clamp(minZoom, maxZoom).toDouble();
    pan = focal - center - anchor * pxPerMeter;
    notifyListeners();
  }

  void resetView() {
    zoom = 1.0;
    pan = Offset.zero;
    notifyListeners();
  }

  /// Zooms and pans so the whole structure fits on screen, clear of the top
  /// chips and the bottom toolbar. Empty model: back to the default view.
  void fitView() {
    if (model.nodes.isEmpty || viewSize.isEmpty) {
      resetView();
      return;
    }
    var minX = double.infinity, maxX = -double.infinity;
    var minY = double.infinity, maxY = -double.infinity;
    for (final n in model.nodes) {
      minX = math.min(minX, n.position.dx);
      maxX = math.max(maxX, n.position.dx);
      minY = math.min(minY, n.position.dy);
      maxY = math.max(maxY, n.position.dy);
    }

    // Space taken by floating UI (px) and breathing room for supports/loads.
    const marginSide = 48.0, marginTop = 120.0, marginBottom = 200.0;
    final availW = math.max(100.0, viewSize.width - 2 * marginSide);
    final availH = math.max(100.0, viewSize.height - marginTop - marginBottom);

    final w = math.max(maxX - minX, 0.5);
    final h = math.max(maxY - minY, 0.5);
    final ppm = math.min(availW / w, availH / h);
    zoom = (ppm / pixelsPerMeter).clamp(minZoom, 2.0).toDouble();

    final center = Offset((minX + maxX) / 2, (minY + maxY) / 2);
    final viewCenter = Offset(viewSize.width / 2, viewSize.height / 2);
    final target = Offset(viewSize.width / 2, marginTop + availH / 2);
    pan = target - viewCenter - Offset(center.dx, -center.dy) * pxPerMeter;
    notifyListeners();
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
    report = null;
    _undoStack.add(model.copy());
    if (_undoStack.length > 50) _undoStack.removeAt(0);
  }

  void _resetTransient() {
    report = null;
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

  /// Clears the whole model. Undoable, so no confirmation is needed.
  void clearAll() {
    if (model.isEmpty) {
      message(msgModelAlreadyEmpty);
      return;
    }
    saveUndo();
    model.clear();
    _resetTransient();
    zoom = 1.0;
    pan = Offset.zero;
    status(msgCleared);
  }

  void validateModel() {
    final result = validateStructure(model);
    report = result;
    notifyListeners(); // repaints with the highlights
    onValidated?.call(result);
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

  void setNodeKind(NodeKind kind) {
    nodeKind = kind;
    status(nodeKindHint(kind));
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
        concentratedConflict(
          model.loads,
          load.nodeId,
          angleDegrees,
          ignoreId: load.id,
        )) {
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
        model.members.removeWhere(
          (e) => e.startNodeId == id || e.endNodeId == id,
        );
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
