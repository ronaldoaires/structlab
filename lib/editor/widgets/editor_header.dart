import 'package:flutter/material.dart';
import 'package:structlab/core/theme/colors.dart';
import 'package:structlab/editor/dialogs/project_dialogs.dart';
import 'package:structlab/editor/editor_controller.dart';
import 'package:structlab/editor/screens/projects_screen.dart';
import 'package:structlab/l10n/strings_pt.dart';

/// Top bar: project name, undo, validate and options menu.
class EditorHeader extends StatelessWidget {
  const EditorHeader({
    super.key,
    required this.controller,
    required this.onValidate,
  });

  final EditorController controller;
  final VoidCallback onValidate;

  Future<void> _rename(BuildContext context) async {
    final name = await askProjectName(context, controller.projectName);
    if (name == null) return;
    await controller.renameProject(controller.projectId ?? '', name);
  }

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
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => _rename(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      appName,
                      style: TextStyle(
                        color: inkMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      controller.projectName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
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
              if (value == 'projects') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProjectsScreen(controller: controller),
                  ),
                );
              }
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
              PopupMenuItem(value: 'projects', child: Text(menuProjects)),
              PopupMenuItem(value: 'new', child: Text(menuNewModel)),
              PopupMenuItem(value: 'about', child: Text(menuAbout)),
            ],
          ),
        ],
      ),
    );
  }
}