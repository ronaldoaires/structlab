import 'package:flutter/material.dart';
import 'package:structlab/core/theme/colors.dart';
import 'package:structlab/editor/editor_controller.dart';
import 'package:structlab/l10n/strings_pt.dart';

/// Top bar: app name, undo, validate and options menu.
class EditorHeader extends StatelessWidget {
  const EditorHeader({
    super.key,
    required this.controller,
    required this.onValidate,
  });

  final EditorController controller;
  final VoidCallback onValidate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: lineColor)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: brandBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.architecture, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              appName,
              style: TextStyle(
                color: ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: undoTooltip,
            onPressed: controller.canUndo ? controller.undo : null,
            icon: const Icon(Icons.undo),
            color: ink,
          ),
          FilledButton.tonalIcon(
            onPressed: onValidate,
            icon: const Icon(Icons.check_circle_outline, size: 20),
            label: const Text(validateShortLabel),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 40),
              backgroundColor: brandTint,
              foregroundColor: brandBlue,
            ),
          ),
          PopupMenuButton<String>(
            tooltip: moreOptionsTooltip,
            iconColor: ink,
            onSelected: (value) {
              if (value == 'new') controller.newModel();
              if (value == 'about') {
                showAboutDialog(
                  context: context,
                  applicationName: appName,
                  applicationVersion: appVersion,
                  applicationLegalese: '$appLegalese\n$appSubtitle',
                );
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'new', child: Text(menuNewModel)),
              PopupMenuItem(value: 'about', child: Text(menuAbout)),
            ],
          ),
        ],
      ),
    );
  }
}