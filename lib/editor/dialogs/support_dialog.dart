import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:structlab/domain/models/support.dart';
import 'package:structlab/editor/widgets/glyphs.dart';
import 'package:structlab/l10n/strings_pt.dart';

/// Edits a support's type and rotation. Returns (type, rotation) or null.
class SupportDialog extends StatefulWidget {
  const SupportDialog({super.key, required this.type, required this.rotation});

  final SupportType type;
  final int rotation;

  @override
  State<SupportDialog> createState() => _SupportDialogState();
}

class _SupportDialogState extends State<SupportDialog> {
  late SupportType _type = widget.type;
  late int _rotation = widget.rotation;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(supportDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Transform.rotate(
                angle: _rotation * math.pi / 180,
                child: SupportGlyph(type: _type, size: 56),
              ),
            ),
            const SizedBox(height: 16),
            const Text(supportTypeLabel,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                for (final t in SupportType.values)
                  ChoiceChip(
                    label: Text(supportShortName(t)),
                    selected: _type == t,
                    onSelected: (_) => setState(() => _type = t),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(supportPositionLabel,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                for (final r in const [0, 180, 90, 270])
                  ChoiceChip(
                    label: Text(supportSideName(r)),
                    selected: _rotation % 360 == r,
                    onSelected: (_) => setState(() => _rotation = r),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, (_type, _rotation)),
          child: const Text(saveLabel),
        ),
      ],
    );
  }
}