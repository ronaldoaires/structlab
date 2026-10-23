import 'package:flutter/material.dart';
import 'package:structlab/analysis/internal_forces/internal_forces_model.dart';
import 'package:structlab/core/theme/colors.dart';
import 'package:structlab/l10n/strings_internal_forces_pt.dart';

/// Two color swatches that explain the sign colors of a diagram.
class DiagramLegend extends StatelessWidget {
  const DiagramLegend({super.key, required this.kind});

  final InternalForceKind kind;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 4,
      children: [
        _Item(color: diagramPositive, label: legendPositiveLabel(kind)),
        _Item(color: diagramNegative, label: legendNegativeLabel(kind)),
      ],
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            border: Border.all(color: color, width: 1.6),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: inkMuted,
          ),
        ),
      ],
    );
  }
}