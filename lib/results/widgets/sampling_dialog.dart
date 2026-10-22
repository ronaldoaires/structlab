import 'package:flutter/material.dart';
import 'package:structlab/analysis/internal_forces/sampling.dart';
import 'package:structlab/core/parse.dart';
import 'package:structlab/editor/widgets/number_field.dart';
import 'package:structlab/l10n/strings_internal_forces_pt.dart';
import 'package:structlab/l10n/strings_pt.dart';

/// Edits which points of a member are listed. With [stepOnly] only the step
/// is asked (used for "all members"). Returns the new config or null.
class SamplingDialog extends StatefulWidget {
  const SamplingDialog({
    super.key,
    required this.length,
    required this.config,
    this.stepOnly = false,
  });

  final double length;
  final SamplingConfig config;
  final bool stepOnly;

  @override
  State<SamplingDialog> createState() => _SamplingDialogState();
}

class _SamplingDialogState extends State<SamplingDialog> {
  late final TextEditingController _from =
      TextEditingController(text: widget.config.from.toString());
  late final TextEditingController _to = TextEditingController(
      text: (widget.config.to ?? widget.length).toStringAsFixed(2));
  late final TextEditingController _step =
      TextEditingController(text: widget.config.step.toString());
  String? _error;

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    _step.dispose();
    super.dispose();
  }

  void _save() {
    final step = parseNumber(_step.text);
    if (step == null || step <= 0) {
      setState(() => _error = samplingStepError);
      return;
    }
    if (widget.stepOnly) {
      Navigator.pop(context, SamplingConfig(step: step));
      return;
    }
    final from = parseNumber(_from.text);
    final to = parseNumber(_to.text);
    if (from == null ||
        to == null ||
        from < 0 ||
        to > widget.length + 1e-6 ||
        from >= to) {
      setState(() => _error = samplingRangeError(widget.length));
      return;
    }
    final fullEnd = (to - widget.length).abs() < 1e-6;
    Navigator.pop(
      context,
      SamplingConfig(from: from, to: fullEnd ? null : to, step: step),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.stepOnly ? samplingStepOnlyTitle : samplingDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.stepOnly) ...[
              NumberField(
                controller: _from,
                label: samplingFromLabel,
                suffix: 'm',
              ),
              const SizedBox(height: 12),
              NumberField(
                controller: _to,
                label: samplingToLabel,
                suffix: 'm',
              ),
              const SizedBox(height: 12),
            ],
            NumberField(
              controller: _step,
              label: samplingStepLabel,
              suffix: 'm',
              errorText: _error,
              autofocus: widget.stepOnly,
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