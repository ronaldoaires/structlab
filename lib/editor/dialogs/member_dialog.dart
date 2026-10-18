import 'package:flutter/material.dart';
import 'package:structlab/core/parse.dart';
import 'package:structlab/editor/widgets/number_field.dart';
import 'package:structlab/l10n/strings_pt.dart';

/// Edits a member's length and angle. Returns (length, angle) or null.
class MemberDialog extends StatefulWidget {
  const MemberDialog({super.key, required this.length, required this.angle});

  final double length;
  final double angle;

  @override
  State<MemberDialog> createState() => _MemberDialogState();
}

class _MemberDialogState extends State<MemberDialog> {
  late final TextEditingController _lengthCtrl =
      TextEditingController(text: widget.length.toStringAsFixed(2));
  late final TextEditingController _angleCtrl =
      TextEditingController(text: widget.angle.toStringAsFixed(1));

  @override
  void dispose() {
    _lengthCtrl.dispose();
    _angleCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final l = parseNumber(_lengthCtrl.text);
    final a = parseNumber(_angleCtrl.text);
    if (l != null && l > 0 && a != null) {
      Navigator.pop(context, (l, a));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(memberDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NumberField(
              controller: _lengthCtrl,
              label: lengthLabel,
              suffix: 'm',
            ),
            const SizedBox(height: 12),
            NumberField(
              controller: _angleCtrl,
              label: angleLabel,
              suffix: '°',
              helper: memberAngleHelper,
              signed: true,
              onSubmitted: _save,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(cancelLabel),
        ),
        FilledButton(onPressed: _save, child: const Text(saveLabel)),
      ],
    );
  }
}