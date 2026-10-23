import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:structlab/core/parse.dart';
import 'package:structlab/domain/models/member.dart';
import 'package:structlab/editor/widgets/number_field.dart';
import 'package:structlab/l10n/strings_pt.dart';

/// Edits a member either by length and angle, or by horizontal span and
/// height. The values typed are used as given (no values are corrected).
/// Returns (length, angle, style) or null.
class MemberDialog extends StatefulWidget {
  const MemberDialog({
    super.key,
    required this.length,
    required this.angle,
    required this.style,
  });

  final double length;
  final double angle;
  final DimensionStyle style;

  @override
  State<MemberDialog> createState() => _MemberDialogState();
}

class _MemberDialogState extends State<MemberDialog> {
  late final double _rad = widget.angle * math.pi / 180;

  /// Signed run (end - start) and rise of the member as it is now.
  late final double _dx = widget.length * math.cos(_rad);
  late final double _dy = widget.length * math.sin(_rad);

  /// Span and height need a horizontal run; a vertical member has none.
  late final bool _canUseLegs = _dx.abs() > 1e-6;

  late bool _legsMode = widget.style == DimensionStyle.legs && _canUseLegs;
  late bool _rightHigher = _dx >= 0 ? _dy >= 0 : _dy <= 0;

  late final TextEditingController _lengthCtrl =
      TextEditingController(text: widget.length.toStringAsFixed(2));
  late final TextEditingController _angleCtrl =
      TextEditingController(text: widget.angle.toStringAsFixed(1));
  late final TextEditingController _runCtrl =
      TextEditingController(text: _dx.abs().toStringAsFixed(2));
  late final TextEditingController _riseCtrl =
      TextEditingController(text: _dy.abs().toStringAsFixed(2));

  @override
  void dispose() {
    _lengthCtrl.dispose();
    _angleCtrl.dispose();
    _runCtrl.dispose();
    _riseCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_legsMode) {
      _saveLegs();
      return;
    }
    final l = parseNumber(_lengthCtrl.text);
    final a = parseNumber(_angleCtrl.text);
    if (l != null && l > 0 && a != null) {
      Navigator.pop(context, (l, a, DimensionStyle.length));
    }
  }

  void _saveLegs() {
    final run = parseNumber(_runCtrl.text);
    final rise = parseNumber(_riseCtrl.text);
    if (run == null || run <= 0 || rise == null || rise < 0) return;
    // The end node is the one that moves. It is the right node when the
    // current run (end - start) is positive.
    final endIsRight = _dx > 0;
    final endIsHigher = endIsRight == _rightHigher;
    final dx = endIsRight ? run : -run;
    final dy = endIsHigher ? rise : -rise;
    final length = math.sqrt(dx * dx + dy * dy);
    final angle = math.atan2(dy, dx) * 180 / math.pi;
    Navigator.pop(context, (length, angle, DimensionStyle.legs));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(memberDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_canUseLegs) ...[
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: false, label: Text(memberModeAngle)),
                  ButtonSegment(value: true, label: Text(memberModeRise)),
                ],
                selected: {_legsMode},
                onSelectionChanged: (set) =>
                    setState(() => _legsMode = set.first),
              ),
              const SizedBox(height: 14),
            ],
            if (_legsMode) ..._legsFields() else ..._angleFields(),
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

  List<Widget> _angleFields() => [
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
      ];

  List<Widget> _legsFields() => [
        const Text(memberHigherSideLabel,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: false, label: Text(sideLeftLabel)),
            ButtonSegment(value: true, label: Text(sideRightLabel)),
          ],
          selected: {_rightHigher},
          onSelectionChanged: (set) =>
              setState(() => _rightHigher = set.first),
        ),
        const SizedBox(height: 14),
        NumberField(
          controller: _runCtrl,
          label: runLabel,
          suffix: 'm',
        ),
        const SizedBox(height: 12),
        NumberField(
          controller: _riseCtrl,
          label: riseLabel,
          suffix: 'm',
          helper: memberRiseHelper,
          autofocus: true,
          onSubmitted: _save,
        ),
      ];
}