import 'package:flutter/material.dart';
import 'package:structlab/core/theme/colors.dart';
import 'package:structlab/editor/editor_controller.dart';
import 'package:structlab/editor/tools/editor_tool.dart';

/// Floating pill toolbar, generated from the controller's list of tools.
class EditorToolBar extends StatelessWidget {
  const EditorToolBar({super.key, required this.controller});

  final EditorController controller;

  Future<void> _onToolTap(BuildContext context, EditorToolHandler tool) async {
    controller.setTool(tool.id);
    if (tool.hasMenu) await tool.openMenu(context, controller);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            for (final tool in controller.tools) _button(context, tool),
          ],
        ),
      ),
    );
  }

  Widget _button(BuildContext context, EditorToolHandler tool) {
    final isActive = controller.activeTool == tool.id;
    final color = isActive ? brandBlue : inkMuted;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: isActive ? brandTint : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _onToolTap(context, tool),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Center(child: tool.icon(controller, color)),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          tool.label(controller),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: color,
                            fontSize: 11.5,
                            fontWeight:
                                isActive ? FontWeight.w700 : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (tool.hasMenu)
                        Icon(Icons.arrow_drop_down, size: 14, color: color),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}