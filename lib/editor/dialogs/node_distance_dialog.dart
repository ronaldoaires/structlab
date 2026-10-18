import 'package:flutter/material.dart';
import 'package:structlab/core/parse.dart';
import 'package:structlab/editor/widgets/number_field.dart';
import 'package:structlab/l10n/strings_pt.dart';

/// Edits a node's distance along its straight line of members.
/// Returns the distance from the left (or bottom) end, or null.
class NodeDistanceDialog extends StatefulWidget {
  const NodeDistanceDialog({
    super.key,
    required this.total,
    required this.fromLeft,
    required this.minFromLeft,
    required this.maxFromLeft,
    required this.vertical,
  });

  final double total;
  final double fromLeft;
  final double minFromLeft;
  final double maxFromLeft;
  final bool vertical;

  @override
  State<NodeDistanceDialog> createState() => _NodeDistanceDialogState();
}

class _NodeDistanceDialogState extends State<NodeDistanceDialog> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.fromLeft.toStringAsFixed(2));
  bool _fromLeft = true; // default: measured from the left
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _setSide(bool fromLeft) {
    if (fromLeft == _fromLeft) return;
    final v = parseNumber(_ctrl.text);
    setState(() {
      if (v != null) _ctrl.text = (widget.total - v).toStringAsFixed(2);
      _fromLeft = fromLeft;
      _error = null;
    });
  }

  void _save() {
    final v = parseNumber(_ctrl.text);
    if (v == null) {
      setState(() => _error = invalidNumberMsg);
      return;
    }
    final fl = _fromLeft ? v : widget.total - v;
    const margin = 0.01;
    if (fl <= widget.minFromLeft + margin ||
        fl >= widget.maxFromLeft - margin) {
      final lo =
          _fromLeft ? widget.minFromLeft : widget.total - widget.maxFromLeft;
      final hi =
          _fromLeft ? widget.maxFromLeft : widget.total - widget.minFromLeft;
      setState(() => _error = nodeRangeError(lo, hi));
      return;
    }
    Navigator.pop(context, fl);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(nodeDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nodeTotalLength(widget.total),
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                    value: true,
                    label: Text(
                        widget.vertical ? fromBottomLabel : fromLeftLabel)),
                ButtonSegment(
                    value: false,
                    label:
                        Text(widget.vertical ? fromTopLabel : fromRightLabel)),
              ],
              selected: {_fromLeft},
              onSelectionChanged: (set) => _setSide(set.first),
            ),
            const SizedBox(height: 14),
            NumberField(
              controller: _ctrl,
              label: distanceLabel,
              suffix: 'm',
              errorText: _error,
              autofocus: true,
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