import 'package:flutter/material.dart';
import 'package:structlab/editor/dialogs/edit_selected.dart';
import 'package:structlab/editor/editor_controller.dart';
import 'package:structlab/editor/editor_types.dart';
import 'package:structlab/editor/widgets/editor_canvas.dart';
import 'package:structlab/editor/widgets/editor_header.dart';
import 'package:structlab/editor/widgets/model_info_bar.dart';
import 'package:structlab/editor/widgets/properties_panel.dart';
import 'package:structlab/editor/widgets/status_bar.dart';
import 'package:structlab/editor/widgets/tool_bar.dart';

/// The editor screen: full-bleed canvas with floating controls on top.
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen>
    with WidgetsBindingObserver {
  final EditorController _c = EditorController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _c.onMessage = _showMessage;
    _c.onEditRequested = _edit;
    _c.init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _c.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Saves immediately when the app leaves the foreground.
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _c.flush();
    }
  }

  void _edit() => editSelected(context, _c);

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        // Keeps the message above the floating toolbar.
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 140),
        duration: const Duration(seconds: 2),
      ));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) => Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              EditorHeader(controller: _c, onValidate: _c.validateModel),
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: EditorCanvas(controller: _c)),
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ModelInfoBar(controller: _c),
                          StatusBar(text: _c.statusMessage),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_c.selectedType != SelectedType.none) ...[
                                PropertiesPanel(controller: _c, onEdit: _edit),
                                const SizedBox(height: 8),
                              ],
                              EditorToolBar(controller: _c),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}