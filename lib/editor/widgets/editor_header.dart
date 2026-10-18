import 'package:flutter/material.dart';
import 'package:structlab/core/theme/colors.dart';
import 'package:structlab/editor/editor_controller.dart';
import 'package:structlab/l10n/strings_pt.dart';

/// Top bar: app name, undo button and options menu.
class EditorHeader extends StatelessWidget {
  const EditorHeader({super.key, required this.controller});

  final EditorController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: darkNavy,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.architecture, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  appSubtitle,
                  style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: undoTooltip,
            onPressed: controller.canUndo ? controller.undo : null,
            icon: const Icon(Icons.undo, color: Colors.white),
          ),
          PopupMenuButton<String>(
            tooltip: moreOptionsTooltip,
            iconColor: Colors.white,
            onSelected: (value) {
              if (value == 'new') controller.newModel();
              if (value == 'about') {
                showAboutDialog(
                  context: context,
                  applicationName: appName,
                  applicationVersion: appVersion,
                  applicationLegalese: appLegalese,
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