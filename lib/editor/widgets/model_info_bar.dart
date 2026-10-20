import 'package:flutter/material.dart';
import 'package:structlab/core/theme/colors.dart';
import 'package:structlab/editor/editor_controller.dart';
import 'package:structlab/l10n/strings_pt.dart';

/// Chips floating over the top of the canvas: snap/ortho toggles, reset view
/// and units.
class ModelInfoBar extends StatelessWidget {
  const ModelInfoBar({super.key, required this.controller});

  final EditorController controller;

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
          Tooltip(
            message: resetViewTooltip,
            child: Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: lineColor),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: controller.resetView,
                child: const SizedBox(
                  width: 34,
                  height: 34,
                  child: Icon(Icons.center_focus_strong_outlined,
                      size: 20, color: ink),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: lineColor),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              unitsLabel,
              style: TextStyle(
                color: ink,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}