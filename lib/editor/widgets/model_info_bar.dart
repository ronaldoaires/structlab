import 'package:flutter/material.dart';
import 'package:structlab/editor/editor_controller.dart';
import 'package:structlab/l10n/strings_pt.dart';

/// Row above the canvas: snap/ortho toggles and the unit badge.
class ModelInfoBar extends StatelessWidget {
  const ModelInfoBar({super.key, required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          const Icon(Icons.grid_4x4, size: 16, color: Color(0xFF64748B)),
          const SizedBox(width: 6),
          const Text(
            model2dLabel,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 12),
          FilterChip(
            label: const Text(snapLabel, style: TextStyle(fontSize: 11)),
            selected: controller.snapEnabled,
            visualDensity: VisualDensity.compact,
            onSelected: controller.setSnap,
          ),
          const SizedBox(width: 6),
          FilterChip(
            label: const Text(orthoLabel, style: TextStyle(fontSize: 11)),
            selected: controller.orthoEnabled,
            visualDensity: VisualDensity.compact,
            onSelected: controller.setOrtho,
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              unitsLabel,
              style: TextStyle(
                color: Color(0xFF334155),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}