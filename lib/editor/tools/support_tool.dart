import 'package:flutter/material.dart';
import 'package:structlab/core/theme/colors.dart';
import 'package:structlab/domain/models/support.dart';
import 'package:structlab/editor/editor_controller.dart';
import 'package:structlab/editor/editor_types.dart';
import 'package:structlab/editor/tools/editor_tool.dart';
import 'package:structlab/editor/tools/hit_testing.dart';
import 'package:structlab/editor/widgets/glyphs.dart';
import 'package:structlab/l10n/strings_pt.dart';

/// Places supports on nodes. The toolbar button opens the type menu.
class SupportTool extends EditorToolHandler {
  @override
  EditorTool get id => EditorTool.support;

  @override
  String label(EditorController c) => supportShortName(c.supportType);

  @override
  Widget icon(EditorController c, Color color) =>
      SupportGlyph(type: c.supportType, color: color, size: 24);

  @override
  String hint(EditorController c) => msgSupportToolHint(c.supportType);

  @override
  bool get hasMenu => true;

  @override
  Future<void> openMenu(BuildContext context, EditorController c) async {
    final result = await showModalBottomSheet<SupportType>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(supportMenuTitle,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              for (final type in SupportType.values)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: SizedBox(
                    width: 40,
                    height: 40,
                    child: SupportGlyph(type: type, size: 34),
                  ),
                  title: Text(supportName(type)),
                  subtitle: Text(supportHint(type)),
                  trailing: c.supportType == type
                      ? const Icon(Icons.check, color: brandBlue)
                      : null,
                  onTap: () => Navigator.pop(context, type),
                ),
            ],
          ),
        ),
      ),
    );
    if (result == null) return;
    c.setSupportType(result);
  }

  @override
  void onTap(EditorController c, Offset position) {
    final node = nearestNode(c.model, position);
    if (node == null) {
      c.message(msgSupportNeedNode);
      return;
    }
    if (c.model.supports.any((s) => s.nodeId == node.id)) {
      c.message(msgSupportExists);
      return;
    }
    c.saveUndo();
    final support = StructuralSupport(
      id: c.model.newId(),
      nodeId: node.id,
      type: c.supportType,
    );
    c.model.supports.add(support);
    c.select(SelectedType.support, support.id);
    c.status(msgSupportInserted(c.supportType));
  }
}