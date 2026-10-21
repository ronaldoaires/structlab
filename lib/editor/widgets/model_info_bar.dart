import 'package:flutter/material.dart';
import 'package:structlab/core/theme/colors.dart';
import 'package:structlab/editor/editor_controller.dart';
import 'package:structlab/l10n/strings_pt.dart';

/// Chips floating over the top of the canvas: snap/ortho toggles, fit view
/// and clear.
class ModelInfoBar extends StatelessWidget {
  const ModelInfoBar({super.key, required this.controller});

  final EditorController controller;

  Widget _iconButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback onTap,
    Color color = ink,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: lineColor),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Row(
        children: [
          FilterChip(
            label: const Text(snapLabel),
            avatar: const Icon(Icons.grid_4x4, size: 16),
            selected: controller.snapEnabled,
            onSelected: controller.setSnap,
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text(orthoLabel),
            avatar: const Icon(Icons.straighten, size: 16),
            selected: controller.orthoEnabled,
            onSelected: controller.setOrtho,
          ),
          const Spacer(),
          _iconButton(
            tooltip: resetViewTooltip,
            icon: Icons.center_focus_strong_outlined,
            onTap: controller.fitView,
          ),
          const SizedBox(width: 8),
          _iconButton(
            tooltip: clearTooltip,
            icon: Icons.delete_sweep_outlined,
            color: danger,
            onTap: controller.clearAll,
          ),
        ],
      ),
    );
  }
}