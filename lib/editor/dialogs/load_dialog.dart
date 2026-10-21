import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:structlab/core/parse.dart';
import 'package:structlab/domain/catalog/load_catalog.dart';
import 'package:structlab/domain/models/load.dart';
import 'package:structlab/editor/widgets/number_field.dart';
import 'package:structlab/l10n/strings_pt.dart';

/// Edits a load's intensities and direction.
/// Returns (q1, q2, angle) or null. For a moment, q1 = q2 = signed value
/// (positive = counterclockwise) and angle = 0.
class LoadDialog extends StatefulWidget {
  const LoadDialog({
    super.key,
    required this.kind,
    required this.q1,
    required this.q2,
    required this.angle,
  });

  final LoadKind kind;
  final double q1;
  final double q2;
  final double angle;

  @override
  State<LoadDialog> createState() => _LoadDialogState();
}

class _LoadDialogState extends State<LoadDialog> {
  double _initialFirst() => switch (widget.kind) {
        LoadKind.triangular => math.max(widget.q1, widget.q2),
        LoadKind.moment => widget.q1.abs(),
        _ => widget.q1,
      };

  late final TextEditingController _c1 =
      TextEditingController(text: _initialFirst().toStringAsFixed(2));
  late final TextEditingController _c2 =
      TextEditingController(text: widget.q2.toStringAsFixed(2));
  late final TextEditingController _angleCtrl =
      TextEditingController(text: widget.angle.toStringAsFixed(0));
  late bool _peakRight = widget.q2 >= widget.q1;
  late bool _counterClockwise = widget.q1 >= 0;

  static const List<(String, double)> _directions = [
    (loadFromTop, -90.0),
    (loadFromBottom, 90.0),
    (loadFromLeft, 0.0),
    (loadFromRight, 180.0),
  ];

  @override
  void dispose() {
    _c1.dispose();
    _c2.dispose();
    _angleCtrl.dispose();
    super.dispose();
  }

  bool _angleIs(double target) {
    final a = parseNumber(_angleCtrl.text);
    if (a == null) return false;
    final diff = ((a - target) % 360 + 360) % 360;
    return diff < 0.5 || diff > 359.5;
  }

  void _save() {
    final v1 = parseNumber(_c1.text);
    if (v1 == null || v1 < 0) return;
    final a =
        widget.kind == LoadKind.moment ? 0.0 : parseNumber(_angleCtrl.text);
    if (a == null) return;

    switch (widget.kind) {
      case LoadKind.concentrated:
      case LoadKind.uniform:
        Navigator.pop(context, (v1, v1, a));
        break;
      case LoadKind.moment:
        final m = _counterClockwise ? v1 : -v1;
        Navigator.pop(context, (m, m, 0.0));
        break;
      case LoadKind.triangular:
        Navigator.pop(context, _peakRight ? (0.0, v1, a) : (v1, 0.0, a));
        break;
      case LoadKind.trapezoidal:
        final v2 = parseNumber(_c2.text);
        if (v2 == null || v2 < 0) return;
        Navigator.pop(context, (v1, v2, a));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    final unit = loadSpec(kind).unit;
    final isMoment = kind == LoadKind.moment;

    return AlertDialog(
      title: Text(propsLoadTitle(kind)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NumberField(
              controller: _c1,
              label: loadIntensityLabel(kind),
              suffix: unit,
              onSubmitted: isMoment ? _save : null,
            ),
            if (kind == LoadKind.trapezoidal) ...[
              const SizedBox(height: 12),
              NumberField(
                controller: _c2,
                label: loadIntensityRightLabel,
                suffix: unit,
              ),
            ],
            if (kind == LoadKind.triangular) ...[
              const SizedBox(height: 14),
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: false, label: Text(loadPeakLeft)),
                  ButtonSegment(value: true, label: Text(loadPeakRight)),
                ],
                selected: {_peakRight},
                onSelectionChanged: (set) =>
                    setState(() => _peakRight = set.first),
              ),
            ],
            if (isMoment) ...[
              const SizedBox(height: 14),
              SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: true, label: Text(momentCcw)),
                  ButtonSegment(value: false, label: Text(momentCw)),
                ],
                selected: {_counterClockwise},
                onSelectionChanged: (set) =>
                    setState(() => _counterClockwise = set.first),
              ),
            ],
            if (!isMoment) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final o in _directions)
                      ChoiceChip(
                        label:
                            Text(o.$1, style: const TextStyle(fontSize: 12)),
                        selected: _angleIs(o.$2),
                        onSelected: (_) => setState(
                            () => _angleCtrl.text = o.$2.toStringAsFixed(0)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              NumberField(
                controller: _angleCtrl,
                label: angleLabel,
                suffix: '°',
                helper: loadAngleHelper,
                signed: true,
                onSubmitted: _save,
              ),
            ],
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