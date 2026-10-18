import 'package:flutter/material.dart';

/// Numeric text field that selects all its text when tapped or focused,
/// so the user can type the new value right away.
class NumberField extends StatefulWidget {
  const NumberField({
    super.key,
    required this.controller,
    required this.label,
    this.suffix,
    this.helper,
    this.errorText,
    this.signed = false,
    this.autofocus = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String? suffix;
  final String? helper;
  final String? errorText;
  final bool signed;
  final bool autofocus;
  final VoidCallback? onSubmitted;

  @override
  State<NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<NumberField> {
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
  }

  void _selectAll() {
    final c = widget.controller;
    c.selection = TextSelection(baseOffset: 0, extentOffset: c.text.length);
  }

  void _onFocusChange() {
    if (!_focus.hasFocus) return;
    // Wait one frame: the tap itself would otherwise move the cursor after
    // the selection is set.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focus.hasFocus) _selectAll();
    });
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: _focus,
      autofocus: widget.autofocus,
      keyboardType: TextInputType.numberWithOptions(
        decimal: true,
        signed: widget.signed,
      ),
      onTap: _selectAll,
      onSubmitted: widget.onSubmitted == null
          ? null
          : (_) => widget.onSubmitted!(),
      decoration: InputDecoration(
        labelText: widget.label,
        suffixText: widget.suffix,
        helperText: widget.helper,
        helperMaxLines: 2,
        errorText: widget.errorText,
        errorMaxLines: 3,
      ),
    );
  }
}