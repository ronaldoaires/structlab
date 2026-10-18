import 'package:flutter/material.dart';
import 'package:structlab/editor/editor_controller.dart';
import 'package:structlab/editor/editor_types.dart';

/// Base class of every editor tool. A tool knows its toolbar button (label
/// and icon), its hint text and how it reacts to touches.
///
/// To add a tool: create a subclass, add a value to [EditorTool] and add the
/// subclass to the `tools` list in [EditorController].
abstract class EditorToolHandler {
  EditorTool get id;

  String label(EditorController c);
  Widget icon(EditorController c, Color color);

  /// Text shown in the status bar when the tool is activated.
  String hint(EditorController c);

  /// True when tapping the toolbar button also opens a menu (support, load).
  bool get hasMenu => false;
  Future<void> openMenu(BuildContext context, EditorController c) async {}

  /// Pointer events. Positions are in model coordinates (meters).
  void onPointerDown(EditorController c, Offset position) {}
  void onPointerMove(EditorController c, Offset position) {}

  /// By default a pointer-up without movement is a tap.
  void onPointerUp(EditorController c, Offset position,
      {required bool moved}) {
    if (!moved) onTap(c, position);
  }

  void onCancel(EditorController c) {}
  void onTap(EditorController c, Offset position) {}
}