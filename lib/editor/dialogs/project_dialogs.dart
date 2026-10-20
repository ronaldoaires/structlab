import 'package:flutter/material.dart';
import 'package:structlab/l10n/strings_pt.dart';

/// Asks for a project name. Returns the new name or null if cancelled.
Future<String?> askProjectName(BuildContext context, String initial) {
  return showDialog<String>(
    context: context,
    builder: (context) => _NameDialog(initial: initial),
  );
}

/// Asks for confirmation before deleting. Returns true if confirmed.
Future<bool> confirmDeleteProject(BuildContext context, String name) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text(deleteProjectTitle),
      content: Text(deleteProjectBody(name)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text(deleteLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});

  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    Navigator.pop(context, text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(renameProjectTitle),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(labelText: projectNameLabel),
        onSubmitted: (_) => _save(),
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