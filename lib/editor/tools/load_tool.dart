import 'package:flutter/material.dart';
import 'package:structlab/core/theme/colors.dart';
import 'package:structlab/domain/catalog/load_catalog.dart';
import 'package:structlab/domain/models/load.dart';
import 'package:structlab/domain/rules/load_rules.dart';
import 'package:structlab/domain/rules/node_rules.dart';
import 'package:structlab/editor/editor_controller.dart';
import 'package:structlab/editor/editor_types.dart';
import 'package:structlab/editor/tools/editor_tool.dart';
import 'package:structlab/editor/tools/hit_testing.dart';
import 'package:structlab/editor/widgets/glyphs.dart';
import 'package:structlab/l10n/strings_pt.dart';

/// Places concentrated loads and moments on nodes and distributed loads
/// between two nodes. The toolbar button opens the load kind menu.
class LoadTool extends EditorToolHandler {
  @override
  EditorTool get id => EditorTool.load;

  @override
  String label(EditorController c) => loadShortName(c.loadKind);

  @override
  Widget icon(EditorController c, Color color) =>
      LoadGlyph(kind: c.loadKind, color: color, size: 24);

  @override
  String hint(EditorController c) => loadHint(c.loadKind);

  @override
  bool get hasMenu => true;

  @override
  Future<void> openMenu(BuildContext context, EditorController c) async {
    final result = await showModalBottomSheet<LoadKind>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                loadMenuTitle,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              for (final kind in LoadKind.values)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: SizedBox(
                    width: 40,
                    height: 40,
                    child: LoadGlyph(kind: kind, size: 34),
                  ),
                  title: Text(loadKindName(kind)),
                  subtitle: Text(loadKindHint(kind)),
                  trailing: c.loadKind == kind
                      ? const Icon(Icons.check, color: brandBlue)
                      : null,
                  onTap: () => Navigator.pop(context, kind),
                ),
            ],
          ),
        ),
      ),
    );
    if (result == null) return;
    c.setLoadKind(result);
  }

  @override
  void onTap(EditorController c, Offset position) {
    final model = c.model;
    final node = nearestNode(model, position);
    if (node == null) {
      c.message(msgLoadNeedNode);
      return;
    }

    if (c.loadKind == LoadKind.moment) {
      _addMoment(c, node.id);
      return;
    }

    if (c.loadKind == LoadKind.concentrated) {
      _addConcentrated(c, node.id);
      return;
    }

    final pendingId = c.pendingLoadNodeId;
    if (pendingId == null) {
      c.pendingLoadNodeId = node.id;
      c.status(msgLoadPickEnd);
      return;
    }
    if (pendingId == node.id) {
      c.message(msgLoadDifferentNode);
      return;
    }
    final first = model.nodeById(pendingId);
    if (first == null || !isStraightConnected(model, pendingId, node.id)) {
      c.pendingLoadNodeId = null;
      c.refresh();
      c.message(msgLoadSameLine);
      return;
    }

    final (left, right) = orderLeftRight(first, node);
    final overlaps = model.loads.any(
      (l) => l.endNodeId != null && distributedOverlap(model, left, right, l),
    );
    if (overlaps) {
      c.pendingLoadNodeId = null;
      c.refresh();
      c.message(msgLoadOverlap);
      return;
    }

    // Vertical span: the load comes from the right (180°) by default.
    final vertical = (left.position.dx - right.position.dx).abs() < 1e-6;

    c.saveUndo();
    final spec = loadSpec(c.loadKind);
    final load = StructuralLoad(
      id: model.newId(),
      kind: c.loadKind,
      nodeId: left.id,
      endNodeId: right.id,
      q1: spec.defaultQ1,
      q2: spec.defaultQ2,
      angleDegrees: vertical ? 0.0 : -90.0,
    );
    model.loads.add(load);
    c.pendingLoadNodeId = null;
    c.select(SelectedType.load, load.id);
    c.status(msgDistributedInserted(c.loadKind));
  }

  void _addConcentrated(EditorController c, int nodeId) {
    final freeAngle = firstFreeConcentratedAngle(
      c.model.loads,
      nodeId,
      vertical: nodeOnlyVertical(c.model, nodeId),
    );
    if (freeAngle == null) {
      c.message(msgLoadFull);
      return;
    }
    c.saveUndo();
    final load = StructuralLoad(
      id: c.model.newId(),
      kind: LoadKind.concentrated,
      nodeId: nodeId,
      angleDegrees: freeAngle,
    );
    c.model.loads.add(load);
    c.select(SelectedType.load, load.id);
    c.status(msgConcentratedInserted);
  }

  void _addMoment(EditorController c, int nodeId) {
    if (momentAt(c.model.loads, nodeId)) {
      c.message(msgMomentExists);
      return;
    }
    c.saveUndo();
    final spec = loadSpec(LoadKind.moment);
    final load = StructuralLoad(
      id: c.model.newId(),
      kind: LoadKind.moment,
      nodeId: nodeId,
      q1: spec.defaultQ1,
      q2: spec.defaultQ1,
      angleDegrees: 0,
    );
    c.model.loads.add(load);
    c.select(SelectedType.load, load.id);
    c.status(msgMomentInserted);
  }
}
