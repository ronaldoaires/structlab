import 'package:flutter/material.dart';
import 'package:structlab/editor/dialogs/edit_selected.dart';
import 'package:structlab/editor/editor_controller.dart';
import 'package:structlab/editor/widgets/editor_canvas.dart';
import 'package:structlab/editor/widgets/editor_header.dart';
import 'package:structlab/editor/widgets/model_info_bar.dart';
import 'package:structlab/editor/widgets/properties_panel.dart';
import 'package:structlab/editor/widgets/status_bar.dart';
import 'package:structlab/editor/widgets/tool_bar.dart';
import 'package:structlab/editor/widgets/validate_button.dart';

/// The editor screen: only assembles the pieces and wires the controller.
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final EditorController _c = EditorController();

  @override
  void initState() {
    super.initState();
    _c.onMessage = _showMessage;
    _c.onEditRequested = _edit;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _edit() => editSelected(context, _c);

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) => Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              EditorHeader(controller: _c),
              ModelInfoBar(controller: _c),
              Expanded(child: EditorCanvas(controller: _c)),
              StatusBar(text: _c.statusMessage),
              EditorToolBar(controller: _c),
              PropertiesPanel(controller: _c, onEdit: _edit),
              ValidateButton(onPressed: _c.validateModel),
            ],
          ),
        ),
      ),
    );
  }
}