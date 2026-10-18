import 'package:flutter/material.dart';
import 'package:structlab/core/theme/colors.dart';
import 'package:structlab/editor/editor_controller.dart';
import 'package:structlab/editor/tools/editor_tool.dart';

/// Bottom toolbar, generated from the controller's list of tools.
class EditorToolBar extends StatelessWidget {
  const EditorToolBar({super.key, required this.controller});

  final EditorController controller;

  Future<void> _onToolTap(BuildContext context, EditorToolHandler tool) async {
    controller.setTool(tool.id);
    if (tool.hasMenu) await tool.openMenu(context, controller);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          for (final tool in controller.tools) _button(context, tool),
        ],
      ),
    );
  }

  Widget _button(BuildContext context, EditorToolHandler tool) {
    final isActive = controller.activeTool == tool.id;
    final color = isActive ? brandBlue : const Color(0xFF64748B);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: isActive ? const Color(0xFFE8EEFF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _onToolTap(context, tool),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Center(child: tool.icon(controller, color)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tool.label(controller),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isActive ? brandBlue : const Color(0xFF475569),
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
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