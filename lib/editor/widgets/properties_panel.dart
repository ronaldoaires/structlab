import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:structlab/core/theme/colors.dart';
import 'package:structlab/domain/models/load.dart';
import 'package:structlab/domain/models/support.dart';
import 'package:structlab/domain/rules/node_rules.dart';
import 'package:structlab/editor/editor_controller.dart';
import 'package:structlab/editor/editor_types.dart';
import 'package:structlab/editor/widgets/glyphs.dart';
import 'package:structlab/l10n/strings_pt.dart';

/// Shows the data of the selected element with edit and delete buttons.
class PropertiesPanel extends StatelessWidget {
  const PropertiesPanel({
    super.key,
    required this.controller,
    required this.onEdit,
  });

  final EditorController controller;
  final VoidCallback onEdit;

  String _loadSpan(StructuralLoad load) {
    final endId = load.endNodeId;
    if (endId == null) return '';
    final a = controller.model.nodeById(load.nodeId);
    final b = controller.model.nodeById(endId);
    if (a == null || b == null) return '';
    return '${(b.position - a.position).distance.toStringAsFixed(2)} m';
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    String title = propsTitle;
    String subtitle = propsEmpty;
    IconData icon = Icons.tune;
    Widget? iconWidget;
    bool canEdit = false;
    bool canDelete = false;

    switch (c.selectedType) {
      case SelectedType.member:
        final member = c.selectedMember;
        final start =
            member == null ? null : c.model.nodeById(member.startNodeId);
        final end = member == null ? null : c.model.nodeById(member.endNodeId);
        title = propsMemberTitle;
        if (start == null || end == null) {
          subtitle = propsUnavailable;
        } else {
          final vec = end.position - start.position;
          subtitle = propsMemberSubtitle(
            vec.distance,
            math.atan2(vec.dy, vec.dx) * 180 / math.pi,
          );
        }
        icon = Icons.horizontal_rule;
        canEdit = member != null;
        canDelete = member != null;
        break;

      case SelectedType.support:
        final support = c.selectedSupport;
        title = propsSupportTitle;
        subtitle = support == null
            ? propsUnavailable
            : propsSupportSubtitle(support.type, support.rotationDegrees);
        iconWidget = Transform.rotate(
          angle: (support?.rotationDegrees ?? 0) * math.pi / 180,
          child: SupportGlyph(type: support?.type ?? SupportType.pin, size: 24),
        );
        canEdit = support != null;
        canDelete = support != null;
        break;

      case SelectedType.load:
        final load = c.selectedLoad;
        if (load == null) {
          title = propsLoadTitleFallback;
          subtitle = propsUnavailable;
        } else {
          title = propsLoadTitle(load.kind);
          subtitle = propsLoadSubtitle(load, _loadSpan(load));
          iconWidget = LoadGlyph(kind: load.kind, size: 24);
        }
        canEdit = load != null;
        canDelete = load != null;
        break;

      case SelectedType.node:
        final node = c.selectedNode;
        title = propsNodeTitle;
        if (node == null) {
          subtitle = propsUnavailable;
        } else {
          final info = nodeLineInfo(c.model, node.id);
          subtitle = propsNodeSubtitle(node.position.dx, node.position.dy);
          if (info != null) {
            subtitle += propsNodeDistances(
                info.fromLeft, info.total - info.fromLeft);
            canEdit = true;
          }
        }
        icon = Icons.circle_outlined;
        canDelete = node != null;
        break;

      case SelectedType.none:
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: iconWidget ?? Icon(icon, color: brandBlue, size: 20),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          if (canEdit)
            IconButton(
              tooltip: editTooltip,
              visualDensity: VisualDensity.compact,
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, color: brandBlue, size: 20),
            ),
          if (canDelete)
            IconButton(
              tooltip: deleteTooltip,
              visualDensity: VisualDensity.compact,
              onPressed: c.deleteSelected,
              icon: const Icon(Icons.delete_outline,
                  color: Color(0xFFB42318), size: 20),
            ),
        ],
      ),
    );
  }
}